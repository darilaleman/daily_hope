import 'dart:ui';

class DeviceUtils {
  /// Obtiene el idioma del dispositivo (es, en, etc.)
  static String getDeviceLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;

    // Solo soportamos español e inglés
    if (languageCode == 'en') return 'en';
    return 'es'; // Por defecto español
  }

  /// Verifica si es la primera vez que se abre la app
  static bool isFirstLaunch() {
    // Se manejará en HiveService
    return true;
  }
}
