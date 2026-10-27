import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QuickExploreViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _exploreData;
  Map<String, dynamic>? get exploreData => _exploreData;

  Future<void> searchCareer(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.searchCareer({'keyword': trimmed});

    _isLoading = false;
    if (res['success'] == true) {
      _exploreData = res['data'] ?? res;
    } else {
      _errorMessage =
          res['message'] ?? 'Không tìm thấy thông tin cho ngành này.';
    }
    notifyListeners();
  }
}
