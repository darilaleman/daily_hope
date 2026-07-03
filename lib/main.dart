import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive/hive_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'core/utils/device_utils.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await NotificationService.init();

  // Detectar idioma del dispositivo en la primera apertura
  _initializeLanguage();

  runApp(const ProviderScope(child: MyApp()));
}

void _initializeLanguage() {
  final savedLanguage = HiveService.getSetting<String>('language');

  if (savedLanguage == null) {
    // Primera vez: usar idioma del dispositivo
    final deviceLang = DeviceUtils.getDeviceLanguage();
    HiveService.setSetting('language', deviceLang);
    print('🌍 Primera apertura: idioma del dispositivo = $deviceLang');
  } else {
    print('🌍 Idioma guardado: $savedLanguage');
  }
}
