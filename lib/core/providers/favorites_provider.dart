import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/models/daily_text_model.dart';
import '../../data/local/hive/hive_service.dart';

class FavoritesNotifier extends StateNotifier<List<DailyTextModel>> {
  FavoritesNotifier() : super([]) {
    loadFavorites();
  }

  void loadFavorites() {
    state = HiveService.getFavorites();
  }

  Future<void> toggleFavorite(DailyTextModel text) async {
    final isFav = isFavorite(text.id);

    if (isFav) {
      await HiveService.removeFavorite(text.id);
    } else {
      await HiveService.addFavorite(text);
    }

    // Recargar lista
    loadFavorites();
  }

  bool isFavorite(String id) {
    return state.any((fav) => fav.id == id);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<DailyTextModel>>((ref) {
  return FavoritesNotifier();
});
