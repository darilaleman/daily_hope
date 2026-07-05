class AppTranslations {
  /// Textos en español
  static const Map<String, String> es = {
    'app_name': 'Esperanza Diaria',
    'tab_today': 'HOY',
    'tab_favorites': 'FAVORITOS',
    'tab_history': 'HISTORIAL',
    'settings': 'Configuración',
    'header_title': 'ESPERANZA DIARIA',
    'save': 'Guardar',
    'saved': 'Guardado',
    'share': 'Compartir',
    'no_text_available': 'No hay texto disponible',
    'error_loading': 'Error: ',
    'saved_to_favorites': '❤️ Guardado en favoritos',
    'removed_from_favorites': 'Eliminado de favoritos',
    'phrase_of_the_day': '📚 Frase del Día',
    'personalized_reflection': '✨ Reflexión Personalizada',
    'no_favorites_yet': 'Aún no tienes favoritos',
    'tap_heart_to_save': 'Toca el ❤️ en un texto para guardarlo',
    'favorites': 'Favoritos',
    'delete_from_favorites': 'Eliminado de favoritos',
    'no_history_yet': 'No hay historial aún',
    'texts_will_appear_here': 'Los textos del día aparecerán aquí',
    'history': 'Historial',
    'clear_history': 'Limpiar historial',
    'clear_history_confirm':
        '¿Estás seguro de que quieres eliminar todo el historial? Esta acción no se puede deshacer.',
    'cancel': 'Cancelar',
    'delete': 'Eliminar',
    'history_cleared': 'Historial eliminado',
    'notifications': 'Notificaciones',
    'receive_daily_message': 'Recibe cada día un mensaje de esperanza',
    'enable_daily_notifications': 'Activar notificaciones diarias',
    'notifications_active': ' Activa',
    'notifications_disabled': 'Desactivada',
    'tap_to_change_time': 'Toca para cambiar la hora',
    'about': 'Acerca de',
    'version': 'Versión 1.0.0',
    'local_texts': 'Textos locales',
    'daily_reflections_and_prayers': 'Reflexiones y oraciones diarias',
    'language': 'Idioma',
    'select_language': 'Seleccionar idioma',
    'spanish': 'Español',
    'english': 'English',
    'notification_permission_denied': 'Permiso de notificaciones denegado',
    'refresh': 'Refrescar',
    'get_another_text': 'Obtener otro texto',
    // ✅ NUEVAS TRADUCCIONES
    'remove': 'Eliminar',
    'remove_from_favorites': 'Eliminar de favoritos',
    'remove_from_favorites_confirm':
        '¿Estás seguro de que quieres eliminar este texto de favoritos?',
  };

  /// Textos en inglés
  static const Map<String, String> en = {
    'app_name': 'Daily Hope',
    'tab_today': 'TODAY',
    'tab_favorites': 'FAVORITES',
    'tab_history': 'HISTORY',
    'settings': 'Settings',
    'header_title': 'DAILY HOPE',
    'save': 'Save',
    'saved': 'Saved',
    'share': 'Share',
    'no_text_available': 'No text available',
    'error_loading': 'Error: ',
    'saved_to_favorites': '❤️ Saved to favorites',
    'removed_from_favorites': 'Removed from favorites',
    'phrase_of_the_day': '📚 Phrase of the Day',
    'personalized_reflection': '✨ Personalized Reflection',
    'no_favorites_yet': 'No favorites yet',
    'tap_heart_to_save': 'Tap the ❤️ on a text to save it',
    'favorites': 'Favorites',
    'delete_from_favorites': 'Removed from favorites',
    'no_history_yet': 'No history yet',
    'texts_will_appear_here': "Today's texts will appear here",
    'history': 'History',
    'clear_history': 'Clear history',
    'clear_history_confirm':
        'Are you sure you want to clear all history? This action cannot be undone.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'history_cleared': 'History cleared',
    'notifications': 'Notifications',
    'receive_daily_message': 'Receive a message of hope every day',
    'enable_daily_notifications': 'Enable daily notifications',
    'notifications_active': '🔔 Active',
    'notifications_disabled': 'Disabled',
    'tap_to_change_time': 'Tap to change time',
    'about': 'About',
    'version': 'Version 1.0.0',
    'local_texts': 'Local texts',
    'daily_reflections_and_prayers': 'Daily reflections and prayers',
    'language': 'Language',
    'select_language': 'Select language',
    'spanish': 'Español',
    'english': 'English',
    'notification_permission_denied': 'Notification permission denied',
    'refresh': 'Refresh',
    'get_another_text': 'Get another text',
    // ✅ NEW TRANSLATIONS
    'remove': 'Remove',
    'remove_from_favorites': 'Remove from favorites',
    'remove_from_favorites_confirm':
        'Are you sure you want to remove this text from favorites?',
  };

  /// Obtiene el mapa de traducciones según el idioma
  static Map<String, String> getTranslations(String languageCode) {
    return languageCode == 'en' ? en : es;
  }

  /// Traduce una clave
  static String translate(String key, String languageCode) {
    final translations = getTranslations(languageCode);
    return translations[key] ?? key;
  }
}
