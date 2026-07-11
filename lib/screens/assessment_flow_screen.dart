import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'comprehensive_report_screen.dart';
import 'login_screen.dart';

class AssessmentFlowScreen extends StatefulWidget {
  final String testType;

  const AssessmentFlowScreen({super.key, required this.testType});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _targetJobController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _ageController = TextEditingController();
  String _educationLevel = 'Đại học';

  String _testName = '';
  String _sessionId = '';
  List<dynamic> _questions = [];
  List<dynamic> _options = [];
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfileContext();
  }

  void _loadUserProfileContext() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated && auth.userProfile != null) {
      final p = auth.userProfile!;
      _targetJobController.text = p['targetJob'] ?? '';
      _hobbyController.text = p['interests'] ?? p['hobby'] ?? '';
      _ageController.text = (p['age'] ?? 18).toString();
      _educationLevel = p['educationLevel'] ?? 'Đại học';
    } else {
      _ageController.text = '18';
    }
  }

  @override
  void dispose() {
    _targetJobController.dispose();
    _hobbyController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String get _testTitle {
    switch (widget.testType) {
      case 'holland':
        return 'Bài Test Sở Thích Holland';
      case 'personality':
        return 'Bài Test Tính Cách MBTI & Big 5';
      case 'cognitive':
        return 'Bài Test Năng Lực Nhận Thức';
      case 'values':
        return 'Bài Test Hệ Giá Trị Cá Nhân';
      default:
        return 'Khảo sát Hướng Nghiệp';
    }
  }

  void _generateQuestions() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = 1);

    final contextData = {
      'targetJob': _targetJobController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 18,
      'educationLevel': _educationLevel,
    };

    final result = await ApiService.generateTest(widget.testType, contextData);

    if (result['success'] == true) {
      setState(() {
        _sessionId =
            result['sessionId'] ??
            ApiService.generateSessionId(widget.testType);
        final testData = result['test'] ?? result;
        _testName = testData['testName'] ?? _testTitle;
        _questions = testData['questions'] ?? [];
        _options =
            testData['options'] ??
            [
              "Hoàn toàn không đúng",
              "Không đúng",
              "Khó nói",
              "Đúng",
              "Hoàn toàn đúng",
            ];
        _currentQuestionIndex = 0;
        _answers.clear();
        _step = 2;
      });
    } else {
      if (!mounted) return;
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Lỗi sinh câu hỏi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _selectAnswer(dynamic answer) {
    setState(() => _answers[_currentQuestionIndex] = answer);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() => _currentQuestionIndex++);
      } else {
        _submitAssessment();
      }
    });
  }

  void _submitAssessment() async {
    setState(() => _step = 3);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final formattedQuestions = List<Map<String, dynamic>>.generate(
      _questions.length,
      (idx) {
        final q = _questions[idx];
        final Map<String, dynamic> qMap = {
          'questionText': q['question'] ?? q['questionText'] ?? '',
          'userAnswer': (_answers[idx] ?? '').toString(),
          'order': idx + 1,
        };
        return qMap;
      },
    );

    await ApiService.saveQuestions(
      sessionId: _sessionId,
      userId: auth.userId,
      testName: _testName,
      questions: formattedQuestions,
      userContext: {},
    );
    final evalResult = await ApiService.evaluateTest(_sessionId);

    if (evalResult['success'] == true) {
      if (auth.isAuthenticated) {
        await auth.claimTestResult(_sessionId);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ComprehensiveReportScreen(),
            ),
          );
        }
        return;
      }
      // Chưa đăng nhập: hiển thị dialog yêu cầu đăng nhập để xem kết quả.
      await _showLoginRequiredDialog();
    } else {
      if (!mounted) return;
      setState(() => _step = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi chấm bài.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Hiển thị dialog yêu cầu đăng nhập trước khi xem kết quả bài test
  // (Holland / MBTI / Cognitive / Values).
  Future<void> _showLoginRequiredDialog() async {
    if (!mounted) return;
    setState(() => _step = 2); // Cho phép làm lại hoặc đăng nhập

    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF6C63FF),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yêu cầu đăng nhập',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn đã hoàn thành bài test. Vui lòng đăng nhập để xem kết quả phân tích chi tiết.',
          style: GoogleFonts.inter(
            color: Colors.grey.shade700,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Để sau',
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Đăng nhập',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !mounted) {
      return;
    }

    // Mở màn hình đăng nhập
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (!mounted) return;

    final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
    if (updatedAuth.isAuthenticated) {
      // Đồng bộ kết quả với user vừa đăng nhập
      await updatedAuth.claimTestResult(_sessionId);
      if (!mounted) return;
      // Navigate tới màn comprehensive report
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ComprehensiveReportScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Màu nền sáng
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _testTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildContextSetupForm();
      case 1:
        return _buildLoadingState(
          'AI đang thiết kế các câu hỏi cá nhân hóa...',
        );
      case 2:
        return _buildQuestionCard();
      case 3:
        return _buildLoadingState('AI đang chấm điểm và phân tích kết quả...');
      case 4:
        return _buildClaimPrompt();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContextSetupForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 40,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cá Nhân Hóa Đánh Giá',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI sẽ tự động điều chỉnh bộ câu hỏi dựa theo mục tiêu của bạn.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              _targetJobController,
              'Công việc mục tiêu',
              'Ví dụ: Lập trình viên',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _ageController,
              'Tuổi của bạn',
              '18',
              isNumber: true,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _hobbyController,
              'Sở thích & Điểm mạnh',
              'Ví dụ: Đọc sách',
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _generateQuestions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: Text(
                'Bắt đầu làm bài',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String loadingText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 30),
          Text(
            loadingText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final qText =
        currentQuestion['question'] ?? currentQuestion['questionText'] ?? '';
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                qText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        _buildLikertOptions(),
      ],
    );
  }

  Widget _buildLikertOptions() {
    return Column(
      children: _options.map((opt) {
        final isSelected = _answers[_currentQuestionIndex] == opt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _selectAnswer(opt),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white,
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClaimPrompt() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.cloud_done_rounded, size: 64, color: Colors.green),
          const SizedBox(height: 20),
          Text(
            'Đã Hoàn Thành!',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Xem kết quả'),
          ),
        ],
      ),
    );
  }
}
