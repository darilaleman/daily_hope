import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../local/models/daily_text_model.dart';
import '../local/hive/hive_service.dart';
import '../remote/ai_text_service.dart';
import '../../core/utils/date_utils.dart';

/// Repositorio de textos diarios.
///
/// Reglas:
/// - Los JSONs locales se cargan UNA sola vez (cache en memoria)
/// - La IA se llama UNA sola vez por día (genera ES + EN juntos)
/// - getDailyText() NO tiene lógica de idioma
/// - El idioma es solo un filtro de presentación en la UI
class DailyTextRepository {
  // Cache de JSONs locales
  static List<Map<String, dynamic>>? _reflectionsEs;
  static List<Map<String, dynamic>>? _prayersEs;
  static List<Map<String, dynamic>>? _reflectionsEn;
  static List<Map<String, dynamic>>? _prayersEn;
  static bool _jsonsLoaded = false;

  bool _isPrefetching = false;
  void Function(bool isWorking, int progress)? onPrefetchStatusChanged;

  /// Carga los JSONs locales UNA sola vez (cache estático)
  Future<void> _loadJsonsIfNeeded() async {
    if (_jsonsLoaded) return;

    try {
      // Español
      final reflectionsEsJson =
          await rootBundle.loadString('assets/texts/es_reflections.json');
      _reflectionsEs =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsEsJson));
      print('✓ Cargadas ${_reflectionsEs!.length} reflexiones ES');

      final prayersEsJson =
          await rootBundle.loadString('assets/texts/es_prayers.json');
      _prayersEs = List<Map<String, dynamic>>.from(jsonDecode(prayersEsJson));
      print('🙏 Cargadas ${_prayersEs!.length} oraciones ES');

      // Inglés
      final reflectionsEnJson =
          await rootBundle.loadString('assets/texts/en_reflections.json');
      _reflectionsEn =
          List<Map<String, dynamic>>.from(jsonDecode(reflectionsEnJson));
      print('✓ Cargadas ${_reflectionsEn!.length} reflexiones EN');

      final prayersEnJson =
          await rootBundle.loadString('assets/texts/en_prayers.json');
      _prayersEn = List<Map<String, dynamic>>.from(jsonDecode(prayersEnJson));
      print('🙏 Cargadas ${_prayersEn!.length} oraciones EN');

      _jsonsLoaded = true;
    } catch (e) {
      print('❌ Error cargando JSONs: $e');
      _reflectionsEs = [];
      _prayersEs = [];
      _reflectionsEn = [];
      _prayersEn = [];
      _jsonsLoaded = true;
    }
  }

  /// Obtiene el texto del día (registro completo con ES + EN).
  ///
  /// Flujo:
  /// 1. ¿Existe en Hive? → devolver inmediatamente
  /// 2. No existe → generar local (ambos idiomas) → guardar en Hive
  /// 3. En background → prefetch mañana
  ///
  /// IMPORTANTE: Este método NO tiene lógica de idioma.
  /// El idioma se filtra en la UI con text.title(lang), text.content(lang), etc.
  Future<DailyTextModel> getDailyText() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. ¿Ya existe texto para hoy?
    final cached = HiveService.getDailyText(today);
    if (cached != null) {
      // En background, asegurar que mañana esté generado
      _prefetchTomorrow();
      return cached;
    }

    // 2. No existe → generar local instantáneo (ambos idiomas)
    print('⚡ Generando texto local para hoy (ambos idiomas)');
    await _loadJsonsIfNeeded();
    final localText = _getLocalTextForDate(today);
    await HiveService.saveDailyText(localText);
    await _addToHistory(localText);

    // 3. En background: generar IA para mañana
    _prefetchTomorrow();

    return localText;
  }

  /// Genera texto IA para mañana en background (ES + EN juntos)
  void _prefetchTomorrow() {
    if (_isPrefetching) return;
    _isPrefetching = true;
    onPrefetchStatusChanged?.call(true, 0);

    Future.delayed(Duration.zero, () async {
      try {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final tomorrow = todayNormalized.add(const Duration(days: 1));

        // Verificar si ya existe para mañana
        final existing = HiveService.getDailyText(tomorrow);
        if (existing != null && existing.isComplete) {
          print('✓ Texto para mañana ya existe y está completo');
          onPrefetchStatusChanged?.call(false, 1);
          return;
        }

        print('🤖 Generando texto IA para mañana (ES + EN)...');

        // Intentar con IA (un solo request genera ambos idiomas)
        DailyTextModel? aiText;
        try {
          final aiData = await AITextService.generateReflectionBilingual()
              .timeout(const Duration(seconds: 35));

          if (aiData != null &&
              aiData['contentEs'] != null &&
              aiData['contentEn'] != null) {
            aiText = DailyTextModel(
              id: 'ai_${AppDateUtils.dayOfYear(tomorrow)}_${DateTime.now().millisecondsSinceEpoch}',
              date: tomorrow,
              source: 'ai',
              category: 'reflection',
              titleEs: aiData['titleEs'] ?? '',
              contentEs: aiData['contentEs'] ?? '',
              titleEn: aiData['titleEn'] ?? '',
              contentEn: aiData['contentEn'] ?? '',
            );
          }
        } catch (e) {
          print('⚠️ IA falló: $e');
        }

        // Si IA falló, usar local como fallback
        if (aiText == null) {
          await _loadJsonsIfNeeded();
          aiText = _getLocalTextForDate(tomorrow);
        }

        await HiveService.saveDailyText(aiText);
        print('✓ Guardado texto para mañana (ES + EN)');
        onPrefetchStatusChanged?.call(false, 1);
      } catch (e) {
        print('❌ Error en pre-generación: $e');
        onPrefetchStatusChanged?.call(false, 0);
      } finally {
        _isPrefetching = false;
      }
    });
  }

  /// Genera texto local para una fecha (ambos idiomas)
  DailyTextModel _getLocalTextForDate(DateTime date) {
    final allTextsEs = <Map<String, dynamic>>[];
    final allTextsEn = <Map<String, dynamic>>[];

    if (_reflectionsEs != null) allTextsEs.addAll(_reflectionsEs!);
    if (_prayersEs != null) allTextsEs.addAll(_prayersEs!);
    if (_reflectionsEn != null) allTextsEn.addAll(_reflectionsEn!);
    if (_prayersEn != null) allTextsEn.addAll(_prayersEn!);

    // Si no hay textos locales, usar fallback
    if (allTextsEs.isEmpty || allTextsEn.isEmpty) {
      return _getFallbackText(date);
    }

    final dayOfYear = AppDateUtils.dayOfYear(date);
    final indexEs = dayOfYear % allTextsEs.length;
    final indexEn = dayOfYear % allTextsEn.length;

    final selectedEs = allTextsEs[indexEs];
    final selectedEn = allTextsEn[indexEn];

    return DailyTextModel(
      id: 'local_${dayOfYear}_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      source: 'local',
      category: selectedEs['category'] ?? 'reflection',
      titleEs: selectedEs['title'] ?? '',
      contentEs: selectedEs['content'] ?? '',
      referenceEs: selectedEs['reference'],
      titleEn: selectedEn['title'] ?? '',
      contentEn: selectedEn['content'] ?? '',
      referenceEn: selectedEn['reference'],
    );
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

  /// Fuerza la pre-generación (útil para testing)
  void forcePrefetch() {
    _isPrefetching = false;
    _prefetchTomorrow();
  }
}
