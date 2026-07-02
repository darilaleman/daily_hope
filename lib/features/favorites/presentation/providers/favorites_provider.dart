import 'package:flutter/foundation.dart';
import '../../../../data/local/models/daily_text_model.dart';
import '../../../../data/local/hive/hive_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<DailyTextModel> _favorites = [];
  List<DailyTextModel> get favorites => _favorites;

  Future<void> loadFavorites() async {
    _favorites = HiveService.getFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String id) async {
    await HiveService.removeFavorite(id);
    _favorites.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
