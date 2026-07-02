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

    final reflectionsFile = language == 'en'
        ? 'assets/texts/en_reflections.json'
        : 'assets/texts/es_reflections.json';

    try {
      final reflectionsJson = await rootBundle.loadString(reflectionsFile);
      _reflections =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsJson));
    } catch (_) {
      _reflections = [];
    }

    try {
      final prayersJson =
          await rootBundle.loadString('assets/texts/prayers.json');
      _prayers = List<Map<String, dynamic>>.from(jsonDecode(prayersJson));
    } catch (_) {
      _prayers = [];
    }
  }

  Future<DailyTextModel> getDailyText() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final language =
        HiveService.getSetting<String>('language', defaultValue: 'es') ?? 'es';
    await _loadTexts(language: language);

    // Verificar si el texto en caché es del idioma correcto
    final cached = HiveService.getDailyText(today);
    if (cached != null && cached.language == language) {
      _prefetchFutureTexts();
      return cached;
    }

    // Si el caché es de otro idioma o no existe, regenerar
    print('⚡ Generando texto para hoy en idioma: $language');
    final localText = await _getLocalTextForDate(today);
    await HiveService.saveDailyText(localText);

    // SOLO agregar al historial el texto de HOY (no futuros)
    await _addToHistory(localText);

    _prefetchFutureTexts();

    return localText;
  }

  void _prefetchFutureTexts() {
    if (_isPrefetching) return;
    _isPrefetching = true;

    onPrefetchStatusChanged?.call(true, 0);

    Future.delayed(Duration.zero, () async {
      try {
        await _loadTexts(language: _currentLanguage);
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);

        // Solo pre-generar MAÑANA (1 día), no más
        // Esto evita saturar la API y reduce errores 429
        final futureDate = todayNormalized.add(const Duration(days: 1));

        onPrefetchStatusChanged?.call(true, 0);

        final existing = HiveService.getDailyText(futureDate);
        if (existing != null && existing.language == _currentLanguage) {
          print('✅ Mañana ya tiene texto en el idioma correcto');
          onPrefetchStatusChanged?.call(false, 1);
          return;
        }

        print(
            '🤖 Generando texto para mañana (${AppDateUtils.formatDateShort(futureDate, _currentLanguage)})...');

        // Retry con backoff para errores 429/502
        DailyTextModel? aiText;
        int attempts = 0;
        const maxAttempts = 2;

        while (attempts < maxAttempts && aiText == null) {
          attempts++;
          try {
            final aiData = await AITextService.generateReflection(
                    language: _currentLanguage)
                .timeout(const Duration(seconds: 30));

            if (aiData != null &&
                aiData['content'] != null &&
                aiData['content'].toString().isNotEmpty) {
              aiText = DailyTextModel(
                id: 'ai_${AppDateUtils.dayOfYear(futureDate)}_${DateTime.now().millisecondsSinceEpoch}',
                title: aiData['title'] ?? 'Reflexión del Día',
                content: aiData['content'] ?? '',
                reference: aiData['reference'],
                language: _currentLanguage,
                category: 'reflexion',
                date: futureDate,
                source: 'ai',
              );
            }
          } catch (e) {
            print('⚠️ Intento $attempts falló: $e');
            if (attempts < maxAttempts) {
              // Esperar 5 segundos antes de reintentar
              await Future.delayed(const Duration(seconds: 5));
            }
          }
        }

        if (aiText != null) {
          await HiveService.saveDailyText(aiText);
          // ⚠️ NO agregar al historial (solo cuando el usuario lo vea)
          print('✅ Texto IA guardado para mañana');
        } else {
          final localText = await _getLocalTextForDate(futureDate);
          await HiveService.saveDailyText(localText);
          print('️ IA falló, guardando local para mañana');
        }

        onPrefetchStatusChanged?.call(false, 1);
      } catch (e) {
        print('❌ Error en pre-generación: $e');
        onPrefetchStatusChanged?.call(false, 0);
      } finally {
        _isPrefetching = false;
      }
    });
  }

  Future<DailyTextModel> _getLocalTextForDate(DateTime date) async {
    final allTexts = <Map<String, dynamic>>[];
    if (_reflections != null) allTexts.addAll(_reflections!);
    if (_prayers != null) allTexts.addAll(_prayers!);

    if (allTexts.isEmpty) return _getFallbackText(date);

    final history = HiveService.getHistory();
    final shownIds = history
        .where((item) => item.source == 'local' || item.source == 'fallback')
        .map((item) => item.id)
        .toSet();

    final availableTexts =
        allTexts.where((text) => !shownIds.contains(text['id'])).toList();

    final textsToUse = availableTexts.isEmpty ? allTexts : availableTexts;

    final dayOfYear = AppDateUtils.dayOfYear(date);
    final index = dayOfYear % textsToUse.length;
    final selected = textsToUse[index];

    return DailyTextModel(
      id: selected['id'] ?? 'local_$dayOfYear',
      title: selected['title'] ?? 'Reflexión',
      content: selected['content'] ?? '',
      reference: selected['reference'],
      language: _currentLanguage,
      category: selected['category'] ?? 'motivacion',
      date: date,
      source: 'local',
    );
  }

  DailyTextModel _getFallbackText(DateTime date) {
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
