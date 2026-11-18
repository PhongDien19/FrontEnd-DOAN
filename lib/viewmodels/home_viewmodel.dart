import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class HomeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _recentHistory = [];
  List<dynamic> get recentHistory => _recentHistory;

  /// Xóa dữ liệu khi đăng xuất để không lộ lịch sử của tài khoản trước.
  void clear() {
    _recentHistory = [];
    notifyListeners();
  }

  Future<void> fetchDashboardData(AuthProvider auth) async {
    if (!auth.isAuthenticated || auth.userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getHistory(auth.userId!);
      if (res['success'] == true && res['history'] != null) {
        _recentHistory = (res['history'] as List).take(3).toList();
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
