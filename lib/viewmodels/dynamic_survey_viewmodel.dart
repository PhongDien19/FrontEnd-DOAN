import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DynamicSurveyViewModel extends ChangeNotifier {
  int _step =
      0; // 0: Config input, 1: Loading, 2: Questions flow, 3: Submitting
  int get step => _step;

  String _sessionId = '';
  String get sessionId => _sessionId;

  List<dynamic> _questions = [];
  List<dynamic> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final Map<int, int> _answers = {}; // question_index -> answer_option_index
  Map<int, int> get answers => _answers;

  Map<String, dynamic>? _surveyResult;
  Map<String, dynamic>? get surveyResult => _surveyResult;

  void setStep(int s) {
    _step = s;
    notifyListeners();
  }

  Future<bool> initSurvey({
    required String mode,
    String? targetCareer,
    int? age,
    String? education,
    String? location,
    String? hobby,
    Function(String)? onError,
  }) async {
    _step = 1;
    notifyListeners();

    final res = await ApiService.initSurvey(
      mode,
      targetCareer,
      age: age,
      education: education,
      location: location,
      hobby: hobby,
    );

    if (res['success'] == true && res['questions'] != null) {
      _sessionId = res['sessionId'] ?? ApiService.generateSessionId('survey');
      _questions = res['questions'] as List? ?? [];
      _currentIndex = 0;
      _answers.clear();
      _step = 2;
      notifyListeners();
      return true;
    } else {
      _step = 0;
      notifyListeners();
      onError?.call(res['message'] ?? 'Khởi tạo khảo sát thất bại.');
      return false;
    }
  }

  void selectOption(int questionIndex, int optionIndex) {
    _answers[questionIndex] = optionIndex;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  Future<bool> submitSurvey(Function(String)? onError) async {
    _step = 3;
    notifyListeners();

    final List<int> answerList = List.generate(
      _questions.length,
      (index) => _answers[index] ?? 0,
    );

    final res = await ApiService.submitSurvey(_sessionId, answerList);

    if (res['success'] == true) {
      _surveyResult = res['result'] ?? res;
      _step = 0;
      notifyListeners();
      return true;
    } else {
      _step = 2;
      notifyListeners();
      onError?.call(res['message'] ?? 'Nộp bài khảo sát thất bại.');
      return false;
    }
  }
}
