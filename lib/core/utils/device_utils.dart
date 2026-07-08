import 'dart:ui';

class DeviceUtils {
  /// Obtiene el idioma del dispositivo (es, en, etc.)
  static String getDeviceLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;

    if (languageCode == 'en') return 'en';
    return 'es';
  }
}
