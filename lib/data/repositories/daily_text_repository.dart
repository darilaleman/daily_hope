import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../local/models/daily_text_model.dart';
import '../local/hive/hive_service.dart';
import '../remote/ai_text_service.dart';
import '../../core/utils/date_utils.dart';

class DailyTextRepository {
  static List<Map<String, dynamic>>? _reflectionsEs;
  static List<Map<String, dynamic>>? _reflectionsEn;
  static bool _jsonsLoaded = false;

  bool _isPrefetching = false;
  void Function(bool isWorking, int progress)? onPrefetchStatusChanged;

  /// Carga los JSONs locales UNA sola vez (cache estático)
  /// Solo carga reflections (sin prayers)
  Future<void> _loadJsonsIfNeeded() async {
    if (_jsonsLoaded) return;

    try {
      final reflectionsEsJson =
          await rootBundle.loadString('assets/texts/es_reflections.json');
      _reflectionsEs =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsEsJson));

      final reflectionsEnJson =
          await rootBundle.loadString('assets/texts/en_reflections.json');
      _reflectionsEn =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsEnJson));

      _jsonsLoaded = true;
    } catch (e) {
      _reflectionsEs = [];
      _reflectionsEn = [];
      _jsonsLoaded = true;
    }
  }

  /// Obtiene el texto del día (registro completo con ES + EN).
  Future<DailyTextModel> getDailyText() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _recoverIncompleteTexts();

    final cached = HiveService.getDailyText(today);
    if (cached != null) {
      await _addToHistory(cached);
      _prefetchMultipleDays();
      return cached;
    }

    await _loadJsonsIfNeeded();
    final localText = _getLocalTextForDate(today);
    await HiveService.saveDailyText(localText);
    await _addToHistory(localText);

    _prefetchMultipleDays();

    return localText;
  }

  /// Busca registros incompletos en días pasados y los completa con local
  Future<void> _recoverIncompleteTexts() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 1; i <= 7; i++) {
      final date = today.subtract(Duration(days: i));
      final text = HiveService.getDailyText(date);

      if (text != null && !text.isComplete) {
        await _loadJsonsIfNeeded();
        final localText = _getLocalTextForDate(date);

        final recovered = DailyTextModel(
          id: text.id,
          date: text.date,
          source: text.source,
          category: text.category,
          titleEs: text.titleEs.isNotEmpty ? text.titleEs : localText.titleEs,
          contentEs:
              text.contentEs.isNotEmpty ? text.contentEs : localText.contentEs,
          referenceEs: text.referenceEs ?? localText.referenceEs,
          titleEn: text.titleEn.isNotEmpty ? text.titleEn : localText.titleEn,
          contentEn:
              text.contentEn.isNotEmpty ? text.contentEn : localText.contentEn,
          referenceEn: text.referenceEn ?? localText.referenceEn,
        );

        await HiveService.saveDailyText(recovered);
      }
    }
  }

  /// Genera texto IA para múltiples días en background (ES + EN juntos)
  void _prefetchMultipleDays() {
    if (_isPrefetching) return;
    _isPrefetching = true;
    onPrefetchStatusChanged?.call(true, 0);

    Timer(const Duration(seconds: 2), () async {
      try {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);

        final daysToGenerate = <DateTime>[];
        for (int i = 1; i <= 3; i++) {
          final futureDate = todayNormalized.add(Duration(days: i));
          final existing = HiveService.getDailyText(futureDate);
          if (existing == null || !existing.isComplete) {
            daysToGenerate.add(futureDate);
          }
        }

        if (daysToGenerate.isEmpty) {
          onPrefetchStatusChanged?.call(false, 1);
          return;
        }

        final aiResults = await AITextService.generateMultipleDaysBilingual(
          daysToGenerate: daysToGenerate.length,
        );

        int savedCount = 0;
        for (int i = 0;
            i < daysToGenerate.length && i < aiResults.length;
            i++) {
          final date = daysToGenerate[i];
          final aiData = aiResults[i];

          final aiText = DailyTextModel(
            id: 'ai_${AppDateUtils.dayOfYear(date)}_${DateTime.now().millisecondsSinceEpoch}_$i',
            date: date,
            source: 'ai',
            category: 'reflection',
            titleEs: aiData['titleEs'] ?? '',
            contentEs: aiData['contentEs'] ?? '',
            titleEn: aiData['titleEn'] ?? '',
            contentEn: aiData['contentEn'] ?? '',
          );

          if (aiText.isComplete) {
            await HiveService.saveDailyText(aiText);
            savedCount++;
          } else {
            await _loadJsonsIfNeeded();
            final localText = _getLocalTextForDate(date);
            await HiveService.saveDailyText(localText);
            savedCount++;
          }
        }

        for (int i = aiResults.length; i < daysToGenerate.length; i++) {
          final date = daysToGenerate[i];
          await _loadJsonsIfNeeded();
          final localText = _getLocalTextForDate(date);
          await HiveService.saveDailyText(localText);
          savedCount++;
        }

        onPrefetchStatusChanged?.call(false, savedCount);
      } catch (e) {
        onPrefetchStatusChanged?.call(false, 0);
      } finally {
        _isPrefetching = false;
      }
    });
  }

  /// Genera texto local para una fecha (ambos idiomas)
  /// IMPORTANTE: Usa el MISMO índice para ES y EN (están sincronizados)
  DailyTextModel _getLocalTextForDate(DateTime date) {
    if (_reflectionsEs == null ||
        _reflectionsEn == null ||
        _reflectionsEs!.isEmpty ||
        _reflectionsEn!.isEmpty) {
      return _getFallbackText(date);
    }

    final seed = _dateHash(date);
    final index = seed % _reflectionsEs!.length;

    final selectedEs = _reflectionsEs![index];
    final selectedEn = _reflectionsEn![index];

    return DailyTextModel(
      id: 'local_${seed}_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      source: 'local',
      category: 'reflection',
      titleEs: selectedEs['title'] ?? '',
      contentEs: selectedEs['content'] ?? '',
      referenceEs: selectedEs['reference'],
      titleEn: selectedEn['title'] ?? '',
      contentEn: selectedEn['content'] ?? '',
      referenceEn: selectedEn['reference'],
    );
  }

  /// Hash determinístico basado en la fecha
  int _dateHash(DateTime date) {
    int hash = date.year * 73856093;
    hash ^= date.month * 19349663;
    hash ^= date.day * 83492791;
    hash = hash.abs();
    hash = (hash * 2654435761) % 2147483647;
    return hash;
  }

  /// Texto fallback si no hay JSONs locales
  DailyTextModel _getFallbackText(DateTime date) {
    return DailyTextModel(
      id: 'fallback',
      date: date,
      source: 'fallback',
      category: 'reflection',
      titleEs: 'Sigue Adelante',
      contentEs:
          'Cada nuevo día es una oportunidad para comenzar de nuevo. Confía en el proceso y recuerda que tienes la fuerza para salir adelante.',
      titleEn: 'Keep Moving Forward',
      contentEn:
          'Every new day is an opportunity to start over. Trust the process and remember you have the strength to move forward.',
    );
  }

  /// Agrega texto al historial
  Future<void> _addToHistory(DailyTextModel text) async {
    final history = HiveService.getHistory();
    final exists =
        history.any((item) => AppDateUtils.isSameDay(item.date, text.date));
    if (!exists) {
      await HiveService.addToHistory(text);
    }
  }
}
