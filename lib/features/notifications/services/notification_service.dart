import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Inicializa el plugin de notificaciones
  /// Debe llamarse UNA sola vez al inicio de la app (en main.dart)
  static Future<void> init() async {
    if (_isInitialized) return;

    // Inicializar zonas horarias
    tz_data.initializeTimeZones();

    // Configurar zona horaria local
    // Usamos la zona horaria del dispositivo
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✓ Zona horaria configurada: $timeZoneName');
    } catch (e) {
      // Si falla, usar una zona por defecto
      tz.setLocalLocation(tz.getLocation('America/New_York'));
      debugPrint(
          '⚠️ No se pudo detectar zona horaria, usando America/New_York');
    }

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
  }

  /// Maneja cuando el usuario toca una notificación
  static void _onTapped(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
    // Aquí puedes agregar navegación a una pantalla específica si lo deseas
  }

  /// Solicita permisos de notificación
  /// En Android 13+ es obligatorio pedir permiso explícito
  static Future<bool> requestPermissions() async {
    // Android 13+ (API 33+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      debugPrint(
          '🔔 Permisos Android: ${granted ? "concedidos" : "denegados"}');
      return granted;
    }

    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      debugPrint('🔔 Permisos iOS: ${granted ? "concedidos" : "denegados"}');
      return granted;
    }

    return true;
  }

  /// Programa una notificación diaria a la hora especificada
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    // Cancelar notificaciones anteriores para evitar duplicados
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint('🔔 Programando notificación para: $scheduled');

    const androidDetails = AndroidNotificationDetails(
      'daily_hope_channel',
      'Esperanza Diaria',
      channelDescription: 'Recibe tu mensaje de esperanza cada día',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
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
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('✓ Notificación programada correctamente');
  }

  /// Cancela todas las notificaciones programadas
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('✓ Todas las notificaciones canceladas');
  }

  /// Verifica si hay notificaciones programadas (para debugging)
  static Future<void> printPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('📋 Notificaciones pendientes: ${pending.length}');
    for (var notification in pending) {
      debugPrint('  - ID: ${notification.id}, Título: ${notification.title}');
    }
  }
}
