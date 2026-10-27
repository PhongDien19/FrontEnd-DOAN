import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class TestHistoryViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<dynamic> _historyList = [];
  List<dynamic> get historyList => _historyList;

  Future<void> fetchHistory(AuthProvider auth) async {
    if (auth.userId == null) {
      _isLoading = false;
      _errorMessage = 'Bạn cần đăng nhập để xem lịch sử.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.getHistory(auth.userId!);

    _isLoading = false;
    if (res['success'] == true && res['history'] != null) {
      _historyList = res['history'] as List? ?? [];
    } else {
      _errorMessage = res['message'] ?? 'Không thể tải lịch sử làm bài.';
    }
    notifyListeners();
  }
}
