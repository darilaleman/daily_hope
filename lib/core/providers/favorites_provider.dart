import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/models/daily_text_model.dart';
import '../../data/local/hive/hive_service.dart';

class FavoritesNotifier extends StateNotifier<List<DailyTextModel>> {
  FavoritesNotifier() : super([]) {
    loadFavorites();
  }

  /// Carga los favoritos desde Hive
  void loadFavorites() {
    state = HiveService.getFavorites();
  }

  /// Agrega o elimina un texto de favoritos
  Future<void> toggleFavorite(DailyTextModel text) async {
    final isFav = isFavorite(text.id);

    if (isFav) {
      await HiveService.removeFavorite(text.id);
    } else {
      await HiveService.addFavorite(text);
    }

    loadFavorites();
  }

  /// Verifica si un texto es favorito
  bool isFavorite(String id) {
    return state.any((fav) => fav.id == id);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<DailyTextModel>>((ref) {
  return FavoritesNotifier();
});
