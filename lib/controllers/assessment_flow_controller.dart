import 'package:flutter/foundation.dart';
import '../models/assessment_flow_model.dart';
import '../services/api_service.dart';

class AssessmentFlowController extends ChangeNotifier {
  AssessmentFlowController({AssessmentFlowModel? model})
    : _model = model ?? AssessmentFlowModel();

  final AssessmentFlowModel _model;

  int get step => _model.step;
  String get assessmentId => _model.assessmentId;
  String get section => _model.section;
  List<dynamic> get questions => _model.questions;
  List<dynamic> get majors => _model.majors;
  bool get isLoadingMajors => _model.isLoadingMajors;
  String? get majorsError => _model.majorsError;
  int get currentQuestionIndex => _model.currentQuestionIndex;
  Map<String, dynamic> get answers => _model.answers;
  Map<String, dynamic>? get result => _model.result;
  String? get errorMessage => _model.errorMessage;
  bool get trustSubmitted => _model.trustSubmitted;
  bool get isSubmittingTrust => _model.isSubmittingTrust;
  String? get trustAction => _model.trustAction;
  bool get canRetry => _model.canRetry;
  bool get allQuestionsAnswered => _model.allQuestionsAnswered;
  bool get hasAnsweredCurrentQuestion => _model.hasAnsweredCurrentQuestion;

  void reset() {
    _model.reset();
    notifyListeners();
  }

  Future<void> loadMajors() async {
    _model.isLoadingMajors = true;
    _model.majorsError = null;
    _model.majors = [];
    notifyListeners();

    final response = await ApiService.getMajors();
    if (response['success'] == true && response['majors'] is List) {
      _model.majors = response['majors'] as List;
    } else {
      _model.majorsError =
          response['message']?.toString() ?? 'Không thể tải danh sách ngành.';
    }

    _model.isLoadingMajors = false;
    notifyListeners();
  }

  Future<bool> startAssessment({
    required String flow,
    required String audience,
    String? userId,
    String? targetMajorId,
    int? certaintyLevel,
    String? targetReason,
    required Function(String) onError,
  }) async {
    _model.step = 1;
    _model.result = null;
    _model.errorMessage = null;
    _model.retryResult = false;
    _model.retrySection = false;
    notifyListeners();

    final response = await ApiService.startAssessment(
      flow: flow,
      audience: audience,
      userId: userId,
      targetMajorId: targetMajorId,
      certaintyLevel: certaintyLevel,
      targetReason: targetReason,
    );

    final assessment = response['assessment'];
    if (response['success'] != true || assessment is! Map) {
      _model.step = 0;
      notifyListeners();
      onError(response['message']?.toString() ?? 'Không thể bắt đầu đánh giá.');
      return false;
    }

    _model.assessmentId = assessment['id']?.toString() ?? '';
    _model.section = assessment['currentSection']?.toString() ?? '';
    if (_model.assessmentId.isEmpty || _model.section.isEmpty) {
      _model.step = 0;
      notifyListeners();
      onError('Máy chủ trả về phiên đánh giá không hợp lệ.');
      return false;
    }

    return _loadSection(onError);
  }

  Future<bool> _loadSection(Function(String) onError) async {
    _model.step = 1;
    _model.retrySection = false;
    _model.errorMessage = null;
    _model.currentQuestionIndex = 0;
    _model.answers.clear();
    notifyListeners();

    final response = await ApiService.getAssessmentQuestions(
      _model.assessmentId,
      _model.section,
    );
    if (response['success'] != true || response['questions'] is! List) {
      _model.errorMessage =
          response['message']?.toString() ?? 'Không thể tải câu hỏi.';
      _model.retryResult = false;
      _model.retrySection = true;
      _model.step = 5;
      notifyListeners();
      onError(_model.errorMessage!);
      return false;
    }

    _model.questions = response['questions'] as List;
    if (_model.questions.isEmpty) {
      _model.errorMessage =
          'Phần đánh giá "${_model.section}" hiện chưa có câu hỏi.';
      _model.retryResult = false;
      _model.retrySection = true;
      _model.step = 5;
      notifyListeners();
      onError(_model.errorMessage!);
      return false;
    }

    _model.errorMessage = null;
    _model.retrySection = false;
    _model.step = 2;
    notifyListeners();
    return true;
  }

  void selectAnswer(String questionId, dynamic answer) {
    _model.selectAnswer(questionId, answer);
    notifyListeners();
  }

  void goToPreviousQuestion() {
    if (_model.currentQuestionIndex > 0) {
      _model.currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToNextQuestion() {
    if (_model.currentQuestionIndex < _model.questions.length - 1 &&
        _model.hasAnsweredCurrentQuestion) {
      _model.currentQuestionIndex++;
      notifyListeners();
    }
  }

  Future<bool> submitCurrentSection({required Function(String) onError}) async {
    if (!_model.allQuestionsAnswered) {
      onError('Vui lòng trả lời tất cả câu hỏi trước khi tiếp tục.');
      return false;
    }

    _model.step = 3;
    notifyListeners();

    final formattedAnswers = _model.questions.map<Map<String, dynamic>>((
      question,
    ) {
      final questionId = question['id'].toString();
      final scoring = question['scoring'];
      return {
        'questionId': questionId,
        'userAnswer': _answerForSubmission(
          question,
          _model.answers[questionId],
        ),
        if (scoring is Map && scoring['dimension'] != null)
          'dimension': scoring['dimension'],
        if (scoring is Map) 'scoreContribution': scoring,
      };
    }).toList();

    final response = await ApiService.submitAssessmentSection(
      assessmentId: _model.assessmentId,
      sectionType: _model.section,
      answers: formattedAnswers,
    );
    if (response['success'] != true) {
      _model.step = 2;
      notifyListeners();
      onError(response['message']?.toString() ?? 'Không thể gửi câu trả lời.');
      return false;
    }

    if (response['isCompleted'] == true ||
        response['nextSection'] == 'completed') {
      return _loadResult(onError);
    }

    final nextSection = response['nextSection']?.toString();
    if (nextSection == null || nextSection.isEmpty) {
      _model.errorMessage = 'Máy chủ chưa xác định phần đánh giá tiếp theo.';
      _model.retryResult = false;
      _model.retrySection = false;
      _model.step = 5;
      notifyListeners();
      onError(_model.errorMessage!);
      return false;
    }

    _model.section = nextSection;
    return _loadSection(onError);
  }

  dynamic _answerForSubmission(Map question, dynamic answer) {
    final options = question['options'];
    if (options is! List) return answer;

    dynamic resolveOption(dynamic selectedKey) {
      for (final option in options) {
        if (option is! Map) continue;
        final optionId = option['id'] ?? option['value'] ?? option['text'];
        if (optionId?.toString() == selectedKey?.toString()) {
          return option['value'] ?? option['id'] ?? option['text'];
        }
      }
      return selectedKey;
    }

    if (answer is List) {
      return answer.map(resolveOption).toList();
    }
    return resolveOption(answer);
  }

  Future<bool> _loadResult(Function(String) onError) async {
    final response = await ApiService.getAssessmentResult(_model.assessmentId);
    if (response['success'] != true || response['result'] is! Map) {
      _model.errorMessage =
          response['message']?.toString() ??
          'Đã hoàn thành bài nhưng không thể tải kết quả.';
      _model.retryResult = true;
      _model.retrySection = false;
      _model.step = 5;
      notifyListeners();
      onError(_model.errorMessage!);
      return false;
    }

    _model.result = Map<String, dynamic>.from(response['result'] as Map);
    _model.errorMessage = null;
    _model.trustSubmitted = false;
    _model.isSubmittingTrust = false;
    _model.trustAction = null;
    _model.step = 4;
    notifyListeners();
    return true;
  }

  Future<void> retryPending(Function(String) onError) async {
    if (_model.retryResult) {
      _model.step = 3;
      notifyListeners();
      await _loadResult(onError);
      return;
    }

    if (_model.retrySection) {
      await _loadSection(onError);
    }
  }

  Future<bool> submitTrustFeedback({
    required int trustScore,
    required String feedbackText,
    required Function(String) onError,
  }) async {
    if (_model.isSubmittingTrust || _model.trustSubmitted) return false;
    _model.isSubmittingTrust = true;
    notifyListeners();

    final response = await ApiService.submitAssessmentTrustCheck(
      assessmentId: _model.assessmentId,
      trustScore: trustScore,
      feedbackText: feedbackText,
    );
    _model.isSubmittingTrust = false;
    if (response['success'] != true) {
      notifyListeners();
      onError(response['message']?.toString() ?? 'Không thể gửi phản hồi.');
      return false;
    }

    _model.trustSubmitted = true;
    _model.trustAction = response['actionTaken']?.toString();
    notifyListeners();
    return true;
  }
}
