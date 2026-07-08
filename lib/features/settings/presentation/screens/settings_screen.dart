import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/translations.dart';
import '../../../../data/local/hive/hive_service.dart';
import '../../../notifications/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = false;
  int _hour = 9;
  int _minute = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _notificationsEnabled = HiveService.getSetting<bool>(
            'notifications_enabled',
            defaultValue: false,
          ) ??
          false;
      _hour =
          HiveService.getSetting<int>('notification_hour', defaultValue: 9) ??
              9;
      _minute =
          HiveService.getSetting<int>('notification_minute', defaultValue: 0) ??
              0;
    });
  }

  /// ✅ CORREGIDO: Siempre actualiza la UI, incluso con errores
  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermissions();

      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Permiso denegado. Ve a Ajustes del teléfono y activa las notificaciones para Daily Hope.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final success =
          await NotificationService.scheduleDaily(hour: _hour, minute: _minute);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Error al programar. Verifica los permisos en Ajustes.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      await NotificationService.cancelAll();
    }

    await HiveService.setSetting('notifications_enabled', value);

    if (mounted) {
      setState(() => _notificationsEnabled = value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? '🔔 Notificaciones activadas para ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}'
              : '🔕 Notificaciones desactivadas'),
          backgroundColor: const Color(0xFFB8996A),
        ),
      );
    }
  }

  /// ✅ CORREGIDO: Siempre actualiza la UI, incluso con errores
  Future<void> _changeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFB8996A)),
        ),
        child: child!,
      ),
    );

    if (picked == null) return; // Usuario canceló

    // ✅ Actualizar variables inmediatamente
    final newHour = picked.hour;
    final newMinute = picked.minute;

    // ✅ Guardar en Hive PRIMERO
    await HiveService.setSetting('notification_hour', newHour);
    await HiveService.setSetting('notification_minute', newMinute);

    // ✅ Actualizar UI INMEDIATAMENTE (aunque falle la notificación)
    if (mounted) {
      setState(() {
        _hour = newHour;
        _minute = newMinute;
      });
    }

    // Reprogramar notificación si está activa
    if (_notificationsEnabled) {
      try {
        final success = await NotificationService.scheduleDaily(
          hour: newHour,
          minute: newMinute,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? '🔔 Hora actualizada: '
                        '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}'
                    : '⚠️ Hora guardada, pero hubo un problema con la notificación',
              ),
              backgroundColor:
                  success ? const Color(0xFFB8996A) : Colors.orange,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error reprogramando: $e');
      }
    }
  }

  /// ✅ NUEVO: Botón para probar notificaciones
  Future<void> _testNotification() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final success = await NotificationService.scheduleTestNotification(
        seconds: 5,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '🔔 Prueba enviada. Espera 5 segundos...'
                  : '❌ Error. Revisa los permisos.',
            ),
            backgroundColor: success ? const Color(0xFFB8996A) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLanguageSelector() async {
    final notifier = ref.read(languageProvider.notifier);
    final currentLang = ref.read(languageProvider);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5EDE3),
        title: Text(
          notifier.t('select_language'),
          style: const TextStyle(color: Color(0xFF3D3D3D)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('es', '🇪🇸 Español', currentLang),
            const SizedBox(height: 8),
            _languageOption('en', '🇺🇸 English', currentLang),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String code, String label, String currentLang) {
    final isSelected = currentLang == code;
    return InkWell(
      onTap: () async {
        await ref.read(languageProvider.notifier).setLanguage(code);
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB8996A).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB8996A)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF3D3D3D),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFB8996A)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    String t(String key) => AppTranslations.translate(key, lang);

    return Scaffold(
      backgroundColor: const Color(0xFFE8DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('settings'),
          style: const TextStyle(color: Color(0xFF3D3D3D)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tarjeta de idioma
          Card(
            color: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.language, color: Color(0xFFB8996A)),
                      SizedBox(width: 12),
                      Text(
                        'Idioma / Language',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.translate,
                      color: Color(0xFFB8996A),
                    ),
                    title: Text(
                      t('language'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    subtitle: Text(
                      lang == 'en' ? 'English' : 'Español',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB8996A),
                    ),
                    onTap: _showLanguageSelector,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tarjeta de notificaciones
          Card(
            color: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFFB8996A),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        t('notifications'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('receive_daily_message'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t('enable_daily_notifications'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    subtitle: Text(
                      _notificationsEnabled
                          ? '${t('notifications_active')} — ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}'
                          : t('notifications_disabled'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                    value: _notificationsEnabled,
                    activeThumbColor: const Color(0xFFB8996A),
                    onChanged: _isLoading ? null : _toggleNotifications,
                  ),
                  if (_notificationsEnabled) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time,
                        color: Color(0xFFB8996A),
                      ),
                      title: Text(
                        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      subtitle: Text(t('tap_to_change_time')),
                      trailing: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF6B6B6B),
                        size: 20,
                      ),
                      onTap: _changeTime,
                    ),
                    const Divider(),
                    // ✅ NUEVO: Botón para probar notificaciones
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.bug_report_outlined,
                        color: Color(0xFF6B6B6B),
                      ),
                      title: const Text(
                        'Probar notificación',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      subtitle: const Text(
                        'Envía una notificación en 5 segundos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                      trailing: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFB8996A),
                              ),
                            )
                          : const Icon(
                              Icons.play_arrow,
                              color: Color(0xFFB8996A),
                            ),
                      onTap: _isLoading ? null : _testNotification,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tarjeta de información
          Card(
            color: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFB8996A)),
                      SizedBox(width: 12),
                      Text(
                        'Acerca de / About',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t('app_name'),
                      style: const TextStyle(color: Color(0xFF3D3D3D)),
                    ),
                    subtitle: Text(
                      t('version'),
                      style: const TextStyle(color: Color(0xFF6B6B6B)),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t('local_texts'),
                      style: const TextStyle(color: Color(0xFF3D3D3D)),
                    ),
                    subtitle: Text(
                      t('daily_reflections_and_prayers'),
                      style: const TextStyle(color: Color(0xFF6B6B6B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
