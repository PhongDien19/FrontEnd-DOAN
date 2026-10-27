import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class ComprehensiveReportViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _report;
  Map<String, dynamic>? get report => _report;

  Future<void> fetchReport(AuthProvider auth) async {
    if (!auth.isAuthenticated) {
      _isLoading = false;
      _errorMessage =
          'Bạn cần đăng nhập để xem báo cáo hướng nghiệp toàn diện.';
      notifyListeners();
      return;
    }

    final profile = auth.userProfile;
    final hasHolland = profile != null && profile['hollandScores'] != null;
    final hasPersonality =
        profile != null && profile['personalityScores'] != null;

    if (!hasHolland && !hasPersonality) {
      _isLoading = false;
      _errorMessage = 'Bạn chưa hoàn thành bài trắc nghiệm nào.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final contextData = {
      'targetJob': auth.targetJob,
      'age': profile['age'] ?? 18,
      'educationLevel': auth.educationLevel,
      'hobby': auth.hobby,
    };

    final result = await ApiService.getComprehensiveAssessment(
      auth.userId!,
      contextData,
    );

    _isLoading = false;
    if (result['success'] == true &&
        result['comprehensiveAssessment'] != null) {
      _report = result['comprehensiveAssessment'];
    } else {
      _errorMessage = result['message'] ?? 'Không thể tải báo cáo từ AI.';
    }
    notifyListeners();
  }
}
