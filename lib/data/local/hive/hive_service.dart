import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_text_model.dart';

class HiveService {
  static const String _dailyBox = 'daily_texts';
  static const String _favoritesBox = 'favorites';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_dailyBox);
    await Hive.openBox(_favoritesBox);
    await Hive.openBox(_settingsBox);
  }

  // ============ TEXTOS DIARIOS ============

  /// Guarda el texto del día
  static Future<void> saveDailyText(DailyTextModel text) async {
    final box = Hive.box(_dailyBox);
    final key = '${text.date.year}-${text.date.month}-${text.date.day}';
    await box.put(key, jsonEncode(text.toJson()));
  }

  /// Obtiene el texto del día (si existe)
  static DailyTextModel? getDailyText(DateTime date) {
    final box = Hive.box(_dailyBox);
    final key = '${date.year}-${date.month}-${date.day}';
    final data = box.get(key);
    if (data == null) return null;
    return DailyTextModel.fromJson(jsonDecode(data));
  }

  /// Obtiene SOLO los textos que el usuario realmente vio (historial real)
  static List<DailyTextModel> getHistory() {
    final box = Hive.box(_dailyBox);
    final texts = <DailyTextModel>[];
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    for (final key in box.keys) {
      final keyStr = key.toString();

      // Solo incluir entradas con prefijo "history_"
      if (!keyStr.startsWith('history_')) continue;

      try {
        final data = jsonDecode(box.get(key));
        final text = DailyTextModel.fromJson(data);

        // Solo incluir textos de hoy o anteriores (nunca futuros)
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

  // ============ FAVORITOS ============

  /// Agrega a favoritos
  static Future<void> addFavorite(DailyTextModel text) async {
    final box = Hive.box(_favoritesBox);
    await box.put(text.id, jsonEncode(text.toJson()));
  }

  /// Remueve de favoritos
  static Future<void> removeFavorite(String id) async {
    final box = Hive.box(_favoritesBox);
    await box.delete(id);
  }

  /// Verifica si es favorito
  static bool isFavorite(String id) {
    final box = Hive.box(_favoritesBox);
    return box.containsKey(id);
  }

  /// Obtiene todos los favoritos
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

  // ============ CONFIGURACIÓN ============

  static Future<void> setSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  static Box getDailyTextsBox() => Hive.box(_dailyBox);

  /// Agrega texto al historial
  static Future<void> addToHistory(DailyTextModel text) async {
    final box = Hive.box(_dailyBox);
    final key = 'history_${text.date.toIso8601String()}';
    await box.put(key, jsonEncode(text.toJson()));
  }

  /// Limpia todo el historial
  static Future<void> clearHistory() async {
    final box = Hive.box(_dailyBox);
    final keysToRemove =
        box.keys.where((key) => key.toString().startsWith('history_')).toList();
    await box.deleteAll(keysToRemove);
  }
}
