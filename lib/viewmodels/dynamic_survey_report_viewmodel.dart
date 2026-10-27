import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DynamicSurveyReportViewModel extends ChangeNotifier {
  bool _isSubmittingFeedback = false;
  bool get isSubmittingFeedback => _isSubmittingFeedback;

  Future<bool> sendFeedback({
    required String surveyId,
    required int rating,
    required String comment,
    Function(String)? onError,
  }) async {
    _isSubmittingFeedback = true;
    notifyListeners();

    final res = await ApiService.feedbackSurvey(surveyId, rating, comment);

    _isSubmittingFeedback = false;
    notifyListeners();

    if (res['success'] == true) {
      return true;
    } else {
      onError?.call(res['message'] ?? 'Gửi phản hồi thất bại.');
      return false;
    }
  }
}
