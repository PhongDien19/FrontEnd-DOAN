import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
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
        _options = testData['options'] ?? [
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
          content: Text(
            result['message'] ?? 'Lỗi sinh câu hỏi.',
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
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
      await _showLoginRequiredDialog();
    } else {
      if (!mounted) return;
      setState(() => _step = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi chấm bài.',
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showLoginRequiredDialog() async {
    if (!mounted) return;
    setState(() => _step = 2);

    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 20),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: const Color(0xFF6C63FF),
              size: Responsive.s(context, 28),
            ),
            SizedBox(width: Responsive.s(context, 10)),
            Expanded(
              child: Text(
                'Yêu cầu đăng nhập',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.font(context, 18),
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
            fontSize: Responsive.font(context, 13),
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
                fontSize: Responsive.font(context, 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 12),
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              'Đăng nhập',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.font(context, 14),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (!mounted) return;

    final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
    if (updatedAuth.isAuthenticated) {
      await updatedAuth.claimTestResult(_sessionId);
      if (!mounted) return;
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _testTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.font(context, 18),
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.s(context, 24)),
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
        return _buildLoadingState(
          'AI đang chấm điểm và phân tích kết quả...',
        );
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
              padding: EdgeInsets.all(Responsive.s(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 20),
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: Responsive.s(context, 40),
                    color: const Color(0xFF6C63FF),
                  ),
                  SizedBox(height: Responsive.s(context, 12)),
                  Text(
                    'Cá Nhân Hóa Đánh Giá',
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 8)),
                  Text(
                    'AI sẽ tự động điều chỉnh bộ câu hỏi dựa theo mục tiêu của bạn.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: Responsive.font(context, 12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.s(context, 24)),
            _buildTextField(
              _targetJobController,
              'Công việc mục tiêu',
              'Ví dụ: Lập trình viên',
            ),
            SizedBox(height: Responsive.s(context, 20)),
            _buildTextField(
              _ageController,
              'Tuổi của bạn',
              '18',
              isNumber: true,
            ),
            SizedBox(height: Responsive.s(context, 20)),
            _buildTextField(
              _hobbyController,
              'Sở thích & Điểm mạnh',
              'Ví dụ: Đọc sách',
            ),
            SizedBox(height: Responsive.s(context, 36)),
            ElevatedButton(
              onPressed: _generateQuestions,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.s(context, 16),
                ),
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: Text(
                'Bắt đầu làm bài',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.font(context, 16),
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
      style: TextStyle(
        fontSize: Responsive.font(context, 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: Responsive.font(context, 14),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: Responsive.font(context, 13),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 16),
          ),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 16),
          ),
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
          SizedBox(height: Responsive.s(context, 30)),
          Text(
            loadingText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 14),
              color: Colors.grey.shade700,
            ),
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
          minHeight: Responsive.s(context, 6),
        ),
        SizedBox(height: Responsive.s(context, 40)),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(Responsive.s(context, 28)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.s(context, 24),
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                qText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: Responsive.font(context, 18),
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: Responsive.s(context, 40)),
        _buildLikertOptions(),
      ],
    );
  }

  Widget _buildLikertOptions() {
    return Column(
      children: _options.map((opt) {
        final isSelected = _answers[_currentQuestionIndex] == opt;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.s(context, 12),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _selectAnswer(opt),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.s(context, 16),
                ),
                backgroundColor: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 12),
                  ),
                ),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: Responsive.font(context, 14),
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
          Icon(
            Icons.cloud_done_rounded,
            size: Responsive.s(context, 64),
            color: Colors.green,
          ),
          SizedBox(height: Responsive.s(context, 20)),
          Text(
            'Đã Hoàn Thành!',
            style: GoogleFonts.outfit(
              fontSize: Responsive.font(context, 22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.s(context, 40)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 32),
                vertical: Responsive.s(context, 12),
              ),
            ),
            child: Text(
              'Xem kết quả',
              style: TextStyle(fontSize: Responsive.font(context, 14)),
            ),
          ),
        ],
      ),
    );
  }
}
