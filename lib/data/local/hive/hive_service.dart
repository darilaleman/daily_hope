import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_text_model.dart';

/// Servicio de persistencia local usando Hive.
///
/// Estrategia de claves:
/// - Textos diarios: "{year}-{month}-{day}" → UN registro con ambos idiomas
/// - Historial: "history_{isoDate}" → UN registro con ambos idiomas
/// - Favoritos: "{textId}" → UN registro con ambos idiomas
/// - Settings: "{key}" → valor simple
///
/// Reglas:
/// - Nunca se guarda el idioma en la clave (el idioma es un filtro de presentación)
/// - Cada registro contiene ES + EN completos
/// - Al cambiar idioma, NO se consulta Hive de nuevo
class HiveService {
  static const String _dailyBox = 'daily_texts';
  static const String _favoritesBox = 'favorites';
  static const String _settingsBox = 'settings';

  static bool _migrated = false;

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_dailyBox);
    await Hive.openBox(_favoritesBox);
    await Hive.openBox(_settingsBox);

    await _migrateOldData();
  }

  /// Migra claves antiguas del formato "{date}_{lang}" al nuevo formato "{date}".
  static Future<void> _migrateOldData() async {
    if (_migrated) return;
    _migrated = true;

    final box = Hive.box(_dailyBox);
    final keysToMigrate = <String>[];
    final merged = <String, Map<String, dynamic>>{};

    for (final key in box.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('history_')) continue;

      String? lang;
      String? datePart;
      if (keyStr.endsWith('_es')) {
        lang = 'es';
        datePart = keyStr.substring(0, keyStr.length - 3);
      } else if (keyStr.endsWith('_en')) {
        lang = 'en';
        datePart = keyStr.substring(0, keyStr.length - 3);
      }

      if (lang != null && datePart != null) {
        keysToMigrate.add(keyStr);
        try {
          final data = jsonDecode(box.get(keyStr)) as Map<String, dynamic>;

          if (data.containsKey('titleEs') || data.containsKey('titleEn')) {
            merged.putIfAbsent(datePart, () => data);
            continue;
          }

          final existing = merged[datePart] ?? {};
          final oldTitle = data['title'] as String? ?? '';
          final oldContent = data['content'] as String? ?? '';
          final oldRef = data['reference'] as String?;

          if (lang == 'es') {
            existing['titleEs'] = oldTitle;
            existing['contentEs'] = oldContent;
            existing['referenceEs'] = oldRef;
          } else {
            existing['titleEn'] = oldTitle;
            existing['contentEn'] = oldContent;
            existing['referenceEn'] = oldRef;
          }

          existing.putIfAbsent('id', () => data['id'] ?? '');
          existing.putIfAbsent('date', () => data['date'] ?? '');
          existing.putIfAbsent('source', () => data['source'] ?? 'local');
          existing.putIfAbsent(
              'category', () => data['category'] ?? 'reflection');

          merged[datePart] = existing;
        } catch (_) {}
      }
    }

    for (final entry in merged.entries) {
      await box.put(entry.key, jsonEncode(entry.value));
    }

    if (keysToMigrate.isNotEmpty) {
      await box.deleteAll(keysToMigrate);
    }
  }

  /// Genera la clave canónica para una fecha: "YYYY-M-D"
  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  /// Guarda el texto del día (registro completo con ambos idiomas).
  static Future<void> saveDailyText(DailyTextModel text) async {
    final box = Hive.box(_dailyBox);
    final key = _dateKey(text.date);
    await box.put(key, jsonEncode(text.toJson()));
  }

  /// Obtiene el texto del día (registro completo con ES + EN).
  static DailyTextModel? getDailyText(DateTime date) {
    final box = Hive.box(_dailyBox);
    final key = _dateKey(date);
    final data = box.get(key);
    if (data == null) return null;
    try {
      return DailyTextModel.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  /// Verifica si existe texto para una fecha (sin cargar el contenido).
  static bool hasDailyText(DateTime date) {
    final box = Hive.box(_dailyBox);
    return box.containsKey(_dateKey(date));
  }

  /// Agrega un texto al historial.
  static Future<void> addToHistory(DailyTextModel text) async {
    final box = Hive.box(_dailyBox);
    final key = 'history_${text.date.toIso8601String()}';
    await box.put(key, jsonEncode(text.toJson()));
  }

  /// Obtiene todo el historial, ordenado del más reciente al más antiguo.
  static List<DailyTextModel> getHistory() {
    final box = Hive.box(_dailyBox);
    final texts = <DailyTextModel>[];
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    for (final key in box.keys) {
      final keyStr = key.toString();
      if (!keyStr.startsWith('history_')) continue;
      try {
        final data = jsonDecode(box.get(key));
        final text = DailyTextModel.fromJson(data);
        final textDate = DateTime(
          text.date.year,
          text.date.month,
          text.date.day,
        );
        if (textDate.isAfter(todayNormalized)) continue;
        texts.add(text);
      } catch (_) {}
    }
    texts.sort((a, b) => b.date.compareTo(a.date));
    return texts;
  }

  /// Limpia todo el historial.
  static Future<void> clearHistory() async {
    final box = Hive.box(_dailyBox);
    final keysToRemove =
        box.keys.where((key) => key.toString().startsWith('history_')).toList();
    await box.deleteAll(keysToRemove);
  }

  /// Agrega a favoritos.
  static Future<void> addFavorite(DailyTextModel text) async {
    final box = Hive.box(_favoritesBox);
    await box.put(text.id, jsonEncode(text.toJson()));
  }

  /// Remueve de favoritos.
  static Future<void> removeFavorite(String id) async {
    final box = Hive.box(_favoritesBox);
    await box.delete(id);
  }

  /// Verifica si es favorito.
  static bool isFavorite(String id) {
    final box = Hive.box(_favoritesBox);
    return box.containsKey(id);
  }

  /// Obtiene todos los favoritos.
  static List<DailyTextModel> getFavorites() {
    final box = Hive.box(_favoritesBox);
    final favorites = <DailyTextModel>[];
    for (final key in box.keys) {
      try {
        final data = jsonDecode(box.get(key));
        favorites.add(DailyTextModel.fromJson(data));
      } catch (_) {}
    }
    return favorites;
  }

  /// Guarda un valor de configuración.
  static Future<void> setSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  /// Obtiene un valor de configuración.
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }
}
