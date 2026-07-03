import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../local/models/daily_text_model.dart';
import '../local/hive/hive_service.dart';
import '../remote/ai_text_service.dart';
import '../../core/utils/date_utils.dart';

class DailyTextRepository {
  List<Map<String, dynamic>>? _reflections;
  List<Map<String, dynamic>>? _prayers;
  String _currentLanguage = 'es';
  bool _isPrefetching = false;

  void Function(bool isWorking, int progress)? onPrefetchStatusChanged;

  Future<void> _loadTexts({String language = 'es'}) async {
    _currentLanguage = language;
    _reflections = null;
    _prayers = null;

    // Reflexiones según idioma
    final reflectionsFile = language == 'en'
        ? 'assets/texts/en_reflections.json'
        : 'assets/texts/es_reflections.json';

    try {
      final reflectionsJson = await rootBundle.loadString(reflectionsFile);
      _reflections =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsJson));
      print(' Cargadas ${_reflections!.length} reflexiones en $language');
    } catch (_) {
      _reflections = [];
    }

    // ✅ Oraciones según idioma (CORREGIDO)
    final prayersFile = language == 'en'
        ? 'assets/texts/en_prayers.json'
        : 'assets/texts/es_prayers.json';

    try {
      final prayersJson = await rootBundle.loadString(prayersFile);
      _prayers = List<Map<String, dynamic>>.from(jsonDecode(prayersJson));
      print('🙏 Cargadas ${_prayers!.length} oraciones en $language');
    } catch (_) {
      print('⚠️ No se pudo cargar $prayersFile, usando lista vacía');
      _prayers = [];
    }
  }

  Future<DailyTextModel> getDailyText() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final language =
        HiveService.getSetting<String>('language', defaultValue: 'es') ?? 'es';

    await _loadTexts(language: language);

    // 1. ¿Ya existe texto para hoy en este idioma?
    final cached = HiveService.getDailyText(today, language: language);
    if (cached != null) {
      // En background, asegurar que ambos idiomas estén pre-generados para el futuro
      _prefetchFutureTexts();
      return cached;
    }

    // 2. No existe → generar local instantáneo
    print('⚡ Generando texto local para hoy en $language');
    final localText = await _getLocalTextForDate(today, language);
    await HiveService.saveDailyText(localText);
    await _addToHistory(localText);

    // 3. En background: pre-generar para AMBOS idiomas
    _prefetchFutureTexts();

    return localText;
  }

  void _prefetchFutureTexts() {
    if (_isPrefetching) return;
    _isPrefetching = true;

    onPrefetchStatusChanged?.call(true, 0);

    Future.delayed(Duration.zero, () async {
      try {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final futureDate = todayNormalized.add(const Duration(days: 1));

        // Generar para AMBOS idiomas
        final languages = ['es', 'en'];
        int progress = 0;

        for (final lang in languages) {
          await _loadTexts(language: lang);

          // Verificar si ya existe
          final existing = HiveService.getDailyText(futureDate, language: lang);
          if (existing != null) {
            progress++;
            onPrefetchStatusChanged?.call(true, progress);
            continue;
          }

          print('🤖 Generando texto para mañana en $lang...');

          // Intentar con IA
          DailyTextModel? aiText;
          try {
            final aiData =
                await AITextService.generateReflection(language: lang)
                    .timeout(const Duration(seconds: 30));

            if (aiData != null && aiData['content'] != null) {
              aiText = DailyTextModel(
                id: 'ai_${AppDateUtils.dayOfYear(futureDate)}_${lang}_${DateTime.now().millisecondsSinceEpoch}',
                title: aiData['title'] ?? 'Reflexión del Día',
                content: aiData['content'] ?? '',
                reference: aiData['reference'],
                language: lang,
                category: 'reflexion',
                date: futureDate,
                source: 'ai',
              );
            }
          } catch (e) {
            print('️ IA falló para $lang: $e');
          }

          if (aiText != null) {
            await HiveService.saveDailyText(aiText);
          } else {
            final localText = await _getLocalTextForDate(futureDate, lang);
            await HiveService.saveDailyText(localText);
          }

          progress++;
          onPrefetchStatusChanged?.call(true, progress);

          // Pausa entre idiomas
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        onPrefetchStatusChanged?.call(false, 2);
      } catch (e) {
        print('❌ Error en pre-generación: $e');
        onPrefetchStatusChanged?.call(false, 0);
      } finally {
        _isPrefetching = false;
      }
    });
  }

  Future<DailyTextModel> _getLocalTextForDate(
      DateTime date, String language) async {
    // Cargar el JSON correcto según idioma
    await _loadTexts(language: language);

    final allTexts = <Map<String, dynamic>>[];
    if (_reflections != null) allTexts.addAll(_reflections!);
    if (_prayers != null) allTexts.addAll(_prayers!);

    if (allTexts.isEmpty) return _getFallbackText(date, language);

    final dayOfYear = AppDateUtils.dayOfYear(date);
    final index = dayOfYear % allTexts.length;
    final selected = allTexts[index];

    return DailyTextModel(
      id: selected['id'] ?? 'local_$dayOfYear',
      title: selected['title'] ?? 'Reflexión',
      content: selected['content'] ?? '',
      reference: selected['reference'],
      language: language,
      category: selected['category'] ?? 'motivacion',
      date: date,
      source: 'local',
    );
  }

  DailyTextModel _getFallbackText(DateTime date, String language) {
    return DailyTextModel(
      id: 'fallback',
      title:
          _currentLanguage == 'en' ? 'Keep Moving Forward' : 'Sigue Adelante',
      content: _currentLanguage == 'en'
          ? 'Every new day is an opportunity to start over. Trust the process and remember you have the strength to move forward.'
          : 'Cada nuevo día es una oportunidad para comenzar de nuevo. Confía en el proceso y recuerda que tienes la fuerza para salir adelante.',
      date: date,
      language: _currentLanguage,
      source: 'fallback',
    );
  }

  Future<void> _addToHistory(DailyTextModel text) async {
    final history = HiveService.getHistory();
    final exists =
        history.any((item) => AppDateUtils.isSameDay(item.date, text.date));

    if (!exists) {
      await HiveService.addToHistory(text);
    }
  }

  void forcePrefetch() {
    _isPrefetching = false;
    _prefetchFutureTexts();
  }
}
