class AssessmentFlowModel {
  int step = 0;
  String assessmentId = '';
  String section = '';
  List<dynamic> questions = [];
  List<dynamic> majors = [];
  bool isLoadingMajors = false;
  String? majorsError;
  int currentQuestionIndex = 0;
  final Map<String, dynamic> answers = {};
  Map<String, dynamic>? result;
  String? errorMessage;
  bool trustSubmitted = false;
  bool isSubmittingTrust = false;
  String? trustAction;
  bool retryResult = false;
  bool retrySection = false;

  bool get canRetry => retryResult || retrySection;

  bool get allQuestionsAnswered => questions.every((question) {
    final questionId = question['id']?.toString();
    return questionId != null && _hasValidAnswer(answers[questionId]);
  });

  bool get hasAnsweredCurrentQuestion {
    if (questions.isEmpty) return false;
    final questionId = questions[currentQuestionIndex]['id']?.toString();
    return questionId != null && _hasValidAnswer(answers[questionId]);
  }

  void selectAnswer(String questionId, dynamic answer) {
    answers[questionId] = answer;
  }

  void reset() {
    step = 0;
    assessmentId = '';
    section = '';
    questions = [];
    currentQuestionIndex = 0;
    answers.clear();
    result = null;
    errorMessage = null;
    trustSubmitted = false;
    isSubmittingTrust = false;
    trustAction = null;
    retryResult = false;
    retrySection = false;
  }

  bool _hasValidAnswer(dynamic answer) {
    if (answer == null) return false;
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is List) return answer.isNotEmpty;
    if (answer is Map) return answer.isNotEmpty;
    return true;
  }
}
