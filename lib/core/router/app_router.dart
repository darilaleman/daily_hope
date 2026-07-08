import 'package:flutter/material.dart';
import '../../features/daily/presentation/screens/daily_screen.dart';
import '../../features/daily/presentation/screens/favorites_screen.dart';
import '../../features/daily/presentation/screens/history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  /// Genera las rutas de la aplicación según el nombre proporcionado
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const DailyScreen());
      case '/favorites':
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case '/history':
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no definida: ${settings.name}')),
          ),
        );
    }
  }
}
