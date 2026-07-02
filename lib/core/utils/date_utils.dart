class AppDateUtils {
  /// Retorna el día del año (1-365/366)
  static int dayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays;
  }

  /// Formatea la fecha en español (Día de la semana, Día de Mes de Año)
  static String formatDateES(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    return '${days[date.weekday % 7]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  /// Formatea la fecha en inglés (Día de la semana, Mes Día, Año)
  static String formatDateEN(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Método universal que elige el formato según el idioma
  static String formatDate(DateTime date, String languageCode) {
    if (languageCode == 'en') return formatDateEN(date);
    return formatDateES(date);
  }

  /// Formatea fecha corta en español (DD/MM/YYYY)
  static String formatDateShortES(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatea fecha corta en inglés (MM/DD/YYYY)
  static String formatDateShortEN(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Método universal para fecha corta
  static String formatDateShort(DateTime date, String languageCode) {
    if (languageCode == 'en') return formatDateShortEN(date);
    return formatDateShortES(date);
  }

  /// Verifica si dos fechas son el mismo día
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
