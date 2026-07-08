import '../../../data/local/hive/hive_service.dart';

class StreakService {
  /// Obtiene la racha actual
  static int getCurrentStreak() {
    return HiveService.getSetting<int>('current_streak', defaultValue: 0) ?? 0;
  }

  /// Obtiene la racha máxima
  static int getMaxStreak() {
    return HiveService.getSetting<int>('max_streak', defaultValue: 0) ?? 0;
  }

  /// Obtiene la fecha de la última lectura
  static DateTime? getLastReadDate() {
    final dateStr = HiveService.getSetting<String>('last_read_date');
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Actualiza el streak cuando el usuario lee el texto del día
  static Future<void> markTodayAsRead() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastRead = getLastReadDate();

    int currentStreak = getCurrentStreak();
    int maxStreak = getMaxStreak();

    if (lastRead == null) {
      currentStreak = 1;
    } else {
      final lastReadDay = DateTime(lastRead.year, lastRead.month, lastRead.day);

      if (_isSameDay(lastReadDay, today)) {
        return;
      } else if (_isYesterday(lastReadDay, today)) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    }

    if (currentStreak > maxStreak) {
      maxStreak = currentStreak;
      await HiveService.setSetting('max_streak', maxStreak);
    }

    await HiveService.setSetting('current_streak', currentStreak);
    await HiveService.setSetting('last_read_date', today.toIso8601String());
  }

  /// Verifica si dos fechas son el mismo día
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Verifica si date1 es ayer respecto a date2
  static bool _isYesterday(DateTime date1, DateTime date2) {
    final yesterday = date2.subtract(const Duration(days: 1));
    return _isSameDay(date1, yesterday);
  }
}
