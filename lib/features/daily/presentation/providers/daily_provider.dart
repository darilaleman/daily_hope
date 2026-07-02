import 'package:flutter/foundation.dart';
import '../../../../data/local/models/daily_text_model.dart';
import '../../../../data/local/hive/hive_service.dart';
import '../../../../data/repositories/daily_text_repository.dart';

class DailyProvider extends ChangeNotifier {
  final DailyTextRepository _repository = DailyTextRepository();

  DailyTextModel? _dailyText;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _error;

  DailyTextModel? get dailyText => _dailyText;
  bool get isLoading => _isLoading;
  bool get isFavorite => _isFavorite;
  String? get error => _error;

  /// Carga el texto del día
  Future<void> loadDailyText() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyText = await _repository.getDailyText();
      if (_dailyText != null) {
        _isFavorite = HiveService.isFavorite(_dailyText!.id);
      }
    } catch (e) {
      _error = 'Error al cargar el texto: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle favorito
  Future<void> toggleFavorite() async {
    if (_dailyText == null) return;

    if (_isFavorite) {
      await HiveService.removeFavorite(_dailyText!.id);
    } else {
      await HiveService.addFavorite(_dailyText!);
    }

    _isFavorite = !_isFavorite;
    notifyListeners();
  }
}
