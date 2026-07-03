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
    // NO invalidamos el caché porque ahora tenemos ambos idiomas
    // El DailyScreen solo necesita recargar para leer el texto en el nuevo idioma
    print('🌍 Idioma cambiado a $newLanguage (cambio instantáneo)');
  }

  String get currentLanguageName {
    return state == 'en' ? 'English' : 'Español';
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
