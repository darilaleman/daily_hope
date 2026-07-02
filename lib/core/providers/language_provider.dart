import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/translations.dart';
import '../../data/local/hive/hive_service.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_loadSavedLanguage());

  static String _loadSavedLanguage() {
    return HiveService.getSetting<String>('language', defaultValue: 'es') ??
        'es';
  }

  String get languageCode => state;

  String t(String key) {
    return AppTranslations.translate(key, state);
  }

  Future<void> setLanguage(String newLanguage) async {
    if (state == newLanguage) return;

    state = newLanguage;
    await HiveService.setSetting('language', newLanguage);

    // Invalidar el texto de hoy para que se regenere en el nuevo idioma
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    await HiveService.getDailyTextsBox().delete(todayKey);

    print('🌐 Idioma cambiado a $newLanguage, caché de hoy invalidado');
  }

  String get currentLanguageName {
    return state == 'en' ? 'English' : 'Español';
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
