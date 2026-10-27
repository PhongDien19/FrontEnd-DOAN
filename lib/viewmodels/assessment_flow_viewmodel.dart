import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssessmentFlowViewModel extends ChangeNotifier {
  int _step = 0;
  int get step => _step;

  String _sessionId = '';
  String get sessionId => _sessionId;

  String _testName = '';
  String get testName => _testName;

  List<dynamic> _questions = [];
  List<dynamic> get questions => _questions;

  List<dynamic> _options = [];
  List<dynamic> get options => _options;

  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  final Map<int, dynamic> _answers = {};
  Map<int, dynamic> get answers => _answers;

  void setStep(int s) {
    _step = s;
    notifyListeners();
  }

  Future<bool> generateQuestions(
    String testType,
    Map<String, dynamic> contextData,
    Function(String) onError,
  ) async {
    _step = 1;
    notifyListeners();

    final result = await ApiService.generateTest(testType, contextData);

    if (result['success'] == true) {
      final testData = result['test'] ?? result;
      _sessionId =
          result['sessionId'] ?? ApiService.generateSessionId(testType);
      _testName = testData['testName'] ?? '';
      _questions = testData['questions'] ?? [];
      _options = testData['options'] ?? [];
      _currentQuestionIndex = 0;
      _answers.clear();
      _step = 2;
      notifyListeners();
      return true;
    } else {
      _step = 0;
      notifyListeners();
      onError(result['message'] ?? 'Lỗi sinh câu hỏi.');
      return false;
    }
  }

  void selectAnswer(dynamic answer, Function() onComplete) {
    _answers[_currentQuestionIndex] = answer;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        notifyListeners();
      } else {
        onComplete();
      }
    });
  }

  Future<bool> submitAssessment(String userId, Function(String) onError) async {
    _step = 3;
    notifyListeners();

    final formattedQuestions = List<Map<String, dynamic>>.generate(
      _questions.length,
      (idx) => {
        'questionText':
            _questions[idx]['question'] ??
            _questions[idx]['questionText'] ??
            '',
        'userAnswer': (_answers[idx] ?? '').toString(),
        'order': idx + 1,
      },
    );

    await ApiService.saveQuestions(
      sessionId: _sessionId,
      userId: userId,
      testName: _testName,
      questions: formattedQuestions,
      userContext: {},
    );

    final evalResult = await ApiService.evaluateTest(_sessionId);

    if (evalResult['success'] == true) {
      return true;
    } else {
      _step = 2;
      notifyListeners();
      onError('Lỗi chấm bài.');
      return false;
    }
  }
}
