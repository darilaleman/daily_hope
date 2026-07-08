import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Inicializa el plugin de notificaciones
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inicializar timezones
      tz_data.initializeTimeZones();

      // 2. Obtener timezone correcto usando flutter_timezone
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).toString();
      debugPrint('🕐 Timezone detectado: $timeZoneName');

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('✓ Zona horaria configurada: $timeZoneName');
      } catch (e) {
        debugPrint(
            '⚠️ Error con timezone $timeZoneName, usando America/New_York');
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      }

      // 3. Crear canal de notificaciones manualmente (más fiable)
      await _createNotificationChannel();

      // 4. Configurar inicialización
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onTapped,
      );

      _isInitialized = true;
      debugPrint('✓ NotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  /// Crea el canal de notificaciones manualmente
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_hope_channel',
      'Esperanza Diaria',
      description: 'Recibe tu mensaje de esperanza cada día',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.createNotificationChannel(channel);
      debugPrint('✓ Canal de notificaciones creado');
    }
  }

  /// Maneja cuando el usuario toca una notificación
  static void _onTapped(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
  }

  /// Verifica si los permisos están concedidos
  static Future<bool> arePermissionsGranted() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.areNotificationsEnabled() ?? false;
        debugPrint(
            '🔔 Verificación de permisos: ${granted ? "CONCEDIDOS" : "DENEGADOS"}');
        return granted;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error verificando permisos: $e');
      return false;
    }
  }

  /// Verifica si puede programar alarmas exactas (Android 14+)
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final canSchedule =
            await android.canScheduleExactNotifications() ?? false;
        debugPrint(
            '⏰ Exact Alarms: ${canSchedule ? "PERMITIDO" : "NO PERMITIDO"}');
        return canSchedule;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error verificando exact alarms: $e');
      return false;
    }
  }

  /// Solicita permisos de notificación
  static Future<bool> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission() ?? false;
        debugPrint(
            '🔔 Permisos Android: ${granted ? "CONCEDIDOS" : "DENEGADOS"}');

        if (granted) {
          // Verificar también exact alarms
          final canSchedule = await canScheduleExactAlarms();
          if (!canSchedule) {
            debugPrint('⚠️ Exact alarms no permitidos, abriendo ajustes...');
            await android.requestExactAlarmsPermission();
          }
        }

        return granted;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        debugPrint('🔔 Permisos iOS: ${granted ? "CONCEDIDOS" : "DENEGADOS"}');
        return granted;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Diagnóstico completo del estado de notificaciones
  static Future<void> diagnostic() async {
    debugPrint('\n========== DIAGNÓSTICO DE NOTIFICACIONES ==========');

    // 1. Permisos
    final hasPermission = await arePermissionsGranted();
    debugPrint('📋 Permisos: ${hasPermission ? "✅ OK" : "❌ DENEGADOS"}');

    // 2. Exact Alarms
    final canSchedule = await canScheduleExactAlarms();
    debugPrint('⏰ Exact Alarms: ${canSchedule ? "✅ OK" : "❌ NO PERMITIDO"}');

    // 3. Canal
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final channels = await android.getNotificationChannels();
      debugPrint('📢 Canales: ${channels?.length ?? 0}');
      if (channels != null && channels.isNotEmpty) {
        for (var channel in channels) {
          debugPrint('   - ${channel.id}: ${channel.name}');
        }
      }
    }

    // 4. Notificaciones pendientes
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('📅 Notificaciones pendientes: ${pending.length}');
    for (var p in pending) {
      debugPrint('   - ID: ${p.id}, Título: ${p.title}');
    }

    debugPrint('==================================================\n');
  }

  /// Programa una notificación diaria
  static Future<bool> scheduleDaily({
    required int hour,
    required int minute,
  }) async {
    try {
      if (!_isInitialized) await init();

      // Diagnóstico antes de programar
      await diagnostic();

      final hasPermission = await arePermissionsGranted();
      if (!hasPermission) {
        debugPrint('⚠️ No se puede programar: permisos denegados');
        return false;
      }

      await _plugin.cancelAll();

      final now = tz.TZDateTime.now(tz.local);
      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      debugPrint(
          '🔔 Programando para: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      debugPrint('🔔 Hora actual: ${now.hour}:${now.minute}');
      debugPrint('🔔 Diferencia: ${scheduled.difference(now).inHours} horas');

      const androidDetails = AndroidNotificationDetails(
        'daily_hope_channel',
        'Esperanza Diaria',
        channelDescription: 'Recibe tu mensaje de esperanza cada día',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        0,
        '🌅 Frase del Día',
        'Toca para leer tu mensaje de esperanza',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Notificación programada correctamente');

      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('📋 Notificaciones pendientes: ${pending.length}');

      return true;
    } catch (e) {
      debugPrint('❌ Error programando notificación: $e');
      return false;
    }
  }

  /// Programa una notificación de prueba
  static Future<bool> scheduleTestNotification({int seconds = 5}) async {
    try {
      if (!_isInitialized) await init();

      // Primero probar con show() para verificar que el plugin funciona
      debugPrint('🧪 Probando con show() primero...');
      const androidDetails = AndroidNotificationDetails(
        'daily_hope_channel',
        'Esperanza Diaria',
        channelDescription: 'Notificación de prueba',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        998,
        '🔔 Prueba Inmediata',
        'Si ves esto, el plugin funciona',
        details,
      );

      debugPrint('✅ show() ejecutado correctamente');

      // Ahora probar con zonedSchedule
      final hasPermission = await arePermissionsGranted();
      if (!hasPermission) {
        debugPrint('⚠️ No se puede programar prueba: permisos denegados');
        return false;
      }

      final now = tz.TZDateTime.now(tz.local);
      final scheduled = now.add(Duration(seconds: seconds));

      debugPrint('🔔 Prueba programada en $seconds segundos');
      debugPrint('🔔 Hora actual: ${now.hour}:${now.minute}:${now.second}');
      debugPrint(
          '🔔 Hora programada: ${scheduled.hour}:${scheduled.minute}:${scheduled.second}');

      await _plugin.zonedSchedule(
        999,
        '🔔 Notificación de prueba',
        'Si ves esto, las notificaciones funcionan.',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );

      debugPrint('✅ Prueba programada');

      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('📋 Notificaciones pendientes: ${pending.length}');

      return true;
    } catch (e) {
      debugPrint('❌ Error en prueba: $e');
      return false;
    }
  }

  /// Cancela todas las notificaciones
  static Future<bool> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('✅ Notificaciones canceladas');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelando: $e');
      return false;
    }
  }
}
