import 'package:flutter/foundation.dart';
import '../../../../data/local/models/daily_text_model.dart';
import '../../../../data/local/hive/hive_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<DailyTextModel> _history = [];
  List<DailyTextModel> get history => _history;

  void loadHistory() {
    _history = HiveService.getHistory();
    notifyListeners();
  }
}
