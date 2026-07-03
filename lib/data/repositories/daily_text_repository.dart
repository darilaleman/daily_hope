import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../local/models/daily_text_model.dart';
import '../local/hive/hive_service.dart';
import '../remote/ai_text_service.dart';
import '../../core/utils/date_utils.dart';

class DailyTextRepository {
  List<Map<String, dynamic>>? _reflections;
  List<Map<String, dynamic>>? _prayers;
  bool _isPrefetching = false;

  void Function(bool isWorking, int progress)? onPrefetchStatusChanged;

  Future<void> _loadTexts({String language = 'es'}) async {
    _reflections = null;
    _prayers = null;

    final reflectionsFile = language == 'en'
        ? 'assets/texts/en_reflections.json'
        : 'assets/texts/es_reflections.json';
    try {
      final reflectionsJson = await rootBundle.loadString(reflectionsFile);
      _reflections =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsJson));
      print('✓ Cargadas ${_reflections!.length} reflexiones en $language');
    } catch (_) {
      _reflections = [];
    }

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

  /// Obtiene el texto del día para el idioma actual
  /// Si no existe, genera local instantáneo y programa IA para mañana en background
  Future<DailyTextModel> getDailyText() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final language =
        HiveService.getSetting<String>('language', defaultValue: 'es') ?? 'es';

    // 1. ¿Ya existe texto para hoy en este idioma?
    final cached = HiveService.getDailyText(today, language: language);
    if (cached != null) {
      // En background, asegurar que mañana esté generado en ambos idiomas
      _prefetchTomorrow();
      return cached;
    }

    // 2. No existe → generar local instantáneo
    print('⚡ Generando texto local para hoy en $language');
    await _loadTexts(language: language);
    final localText = await _getLocalTextForDate(today, language);
    await HiveService.saveDailyText(localText);
    await _addToHistory(localText);

    // 3. En background: generar IA para mañana en AMBOS idiomas
    _prefetchTomorrow();

    return localText;
  }

  /// Genera texto IA para mañana en ambos idiomas (es y en)
  void _prefetchTomorrow() {
    if (_isPrefetching) return;
    _isPrefetching = true;
    onPrefetchStatusChanged?.call(true, 0);

    Future.delayed(Duration.zero, () async {
      try {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final tomorrow = todayNormalized.add(const Duration(days: 1));

        // Verificar si ya existe para mañana en ambos idiomas
        final existingEs = HiveService.getDailyText(tomorrow, language: 'es');
        final existingEn = HiveService.getDailyText(tomorrow, language: 'en');

        if (existingEs != null && existingEn != null) {
          print('✓ Textos para mañana ya existen en ambos idiomas');
          onPrefetchStatusChanged?.call(false, 2);
          return;
        }

        print('🤖 Generando texto IA para mañana en ambos idiomas...');

        // Generar en español
        if (existingEs == null) {
          await _generateAndSaveAI(tomorrow, 'es');
          onPrefetchStatusChanged?.call(true, 1);
        }

        // Pausa breve entre llamadas API
        await Future.delayed(const Duration(milliseconds: 500));

        // Generar en inglés
        if (existingEn == null) {
          await _generateAndSaveAI(tomorrow, 'en');
          onPrefetchStatusChanged?.call(true, 2);
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

  /// Genera texto IA para una fecha e idioma específico y lo guarda
  Future<void> _generateAndSaveAI(DateTime date, String language) async {
    try {
      final aiData = await AITextService.generateReflection(language: language)
          .timeout(const Duration(seconds: 30));

      if (aiData != null && aiData['content'] != null) {
        final aiText = DailyTextModel(
          id: 'ai_${AppDateUtils.dayOfYear(date)}_${language}_${DateTime.now().millisecondsSinceEpoch}',
          title: aiData['title'] ?? 'Reflexión del Día',
          content: aiData['content'] ?? '',
          reference: aiData['reference'],
          language: language,
          category: 'reflexion',
          date: date,
          source: 'ai',
        );
        await HiveService.saveDailyText(aiText);
        print('✓ Guardado texto IA para $date en $language');
      }
    } catch (e) {
      print('⚠️ IA falló para $language: $e');
      // Si falla IA, generar local como fallback
      await _loadTexts(language: language);
      final localText = await _getLocalTextForDate(date, language);
      await HiveService.saveDailyText(localText);
      print('✓ Guardado texto local para $date en $language (fallback)');
    }
  }

  Future<DailyTextModel> _getLocalTextForDate(
      DateTime date, String language) async {
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
      title: language == 'en' ? 'Keep Moving Forward' : 'Sigue Adelante',
      content: language == 'en'
          ? 'Every new day is an opportunity to start over. Trust the process and remember you have the strength to move forward.'
          : 'Cada nuevo día es una oportunidad para comenzar de nuevo. Confía en el proceso y recuerda que tienes la fuerza para salir adelante.',
      date: date,
      language: language,
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

  /// Fuerza la pre-generación (útil para testing)
  void forcePrefetch() {
    _isPrefetching = false;
    _prefetchTomorrow();
  }
}
