import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'dynamic_survey_report_screen.dart';

class DynamicSurveyFlowScreen extends StatefulWidget {
  const DynamicSurveyFlowScreen({super.key});

  @override
  State<DynamicSurveyFlowScreen> createState() => _DynamicSurveyFlowScreenState();
}

class _DynamicSurveyFlowScreenState extends State<DynamicSurveyFlowScreen> {
  // 0: Chọn Chế độ, 1: Loading khởi tạo, 2: Làm bài, 3: Đang chấm điểm, 4: Yêu cầu Login/Register
  int _step = 0;

  // Cấu hình chế độ
  String _mode = 'Discovery'; // 'Targeted' hoặc 'Discovery'
  final _targetCareerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Dữ liệu khảo sát từ server
  String _sessionId = '';
  String _testName = 'Khảo sát Hướng nghiệp Động AI';
  List<dynamic> _questions = [];

  // Trạng thái câu trả lời
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {}; // index -> weight (1-5)

  // Trạng thái đăng nhập tại bước 4
  bool _isLoginTab = true;
  final _authFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isAuthenticating = false;
  String? _authError;

  @override
  void dispose() {
    _targetCareerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // Khởi tạo khảo sát động từ AI
  void _initDynamicSurvey() async {
    if (_mode == 'Targeted' && !_formKey.currentState!.validate()) return;

    setState(() {
      _step = 1;
    });

    final targetCareer = _mode == 'Targeted' ? _targetCareerController.text.trim() : null;
    final result = await ApiService.initSurvey(_mode, targetCareer);

    if (result['success'] == true && result['survey'] != null) {
      setState(() {
        _sessionId = result['sessionId'];
        _testName = result['survey']['testName'] ?? 'Khảo sát Hướng nghiệp Động AI';
        _questions = result['survey']['questions'] ?? [];
        _currentQuestionIndex = 0;
        _answers.clear();
        _step = 2;
      });
    } else {
      setState(() {
        _step = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Lỗi khởi tạo khảo sát. Vui lòng thử lại!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Chọn câu trả lời
  void _selectOption(int weight) {
    setState(() {
      _answers[_currentQuestionIndex] = weight;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        _submitSurvey();
      }
    });
  }

  // Nộp bài khảo sát
  void _submitSurvey() async {
    setState(() {
      _step = 3;
    });

    final answerWeights = List<int>.generate(
      _questions.length,
      (idx) => _answers[idx] ?? 3,
    );

    final result = await ApiService.submitSurvey(_sessionId, answerWeights);

    if (result['success'] == true) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        // Tự động claim kết quả (nếu server chưa claim tự động)
        final claimRes = await auth.claimTestResult(_sessionId);
        if (mounted) {
          if (claimRes['success'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DynamicSurveyReportScreen(
                  sessionId: _sessionId,
                  initialReport: claimRes['evaluation'] ?? result['evaluation'],
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DynamicSurveyReportScreen(
                  sessionId: _sessionId,
                  initialReport: result['evaluation'],
                ),
              ),
            );
          }
        }
      } else {
        // Yêu cầu đăng nhập để claim kết quả
        setState(() {
          _step = 4;
        });
      }
    } else {
      setState(() {
        _step = 2;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Lỗi gửi kết quả chấm điểm.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Đăng nhập / Đăng ký inline và đồng bộ kết quả
  void _handleAuth() async {
    if (!_authFormKey.currentState!.validate()) return;

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    Map<String, dynamic> res;

    if (_isLoginTab) {
      res = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      res = await auth.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
      );
      if (res['success'] == true) {
        // Đăng ký xong tự động đăng nhập luôn
        res = await auth.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    }

    if (res['success'] == true) {
      // Đồng bộ kết quả test
      final claimRes = await auth.claimTestResult(_sessionId);
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicSurveyReportScreen(
              sessionId: _sessionId,
              initialReport: claimRes['evaluation'] ?? res['profile']?['careerFitResult'],
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authError = res['message'] ?? 'Có lỗi xảy ra. Vui lòng kiểm tra lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          _step == 4 ? 'Đăng Nhập Nhận Kết Quả' : _testName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == 2) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF191922),
                  title: Text('Hủy bỏ khảo sát?', style: GoogleFonts.outfit(color: Colors.white)),
                  content: Text('Mọi câu trả lời của bạn sẽ bị hủy và không lưu lại.', style: GoogleFonts.inter(color: const Color(0xFF888B9B))),
                  actions: [
                    TextButton(
                      child: const Text('Tiếp tục làm', style: TextStyle(color: Color(0xFF6C63FF))),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Hủy bỏ', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildModeSelector();
      case 1:
        return _buildLoadingState('AI đang khởi tạo bộ khảo sát kịch bản 15 câu tình huống cá nhân hóa...');
      case 2:
        return _buildQuestionCard();
      case 3:
        return _buildLoadingState('AI đang phân tích câu trả lời của bạn, tính toán điểm số và lập lộ trình hướng nghiệp...');
      case 4:
        return _buildAuthForm();
      default:
        return const SizedBox.shrink();
    }
  }

  // Bước 0: Chọn Chế độ
  Widget _buildModeSelector() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2C2C3E)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.psychology_alt_rounded, size: 48, color: Color(0xFF00F2FE)),
                  const SizedBox(height: 16),
                  Text(
                    'Khảo Sát Động Trí Tuệ Nhân Tạo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bộ câu hỏi tình huống thay đổi động dựa trên nhu cầu của bạn. Tự động chấm điểm tích hợp Holland (50%), Big Five (30%) và SCCT (20%).',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888B9B), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Chọn chế độ khảo sát:',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Mode Selection Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'Discovery'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191922),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _mode == 'Discovery' ? const Color(0xFF6C63FF) : const Color(0xFF2C2C3E),
                          width: _mode == 'Discovery' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.explore_outlined, color: _mode == 'Discovery' ? const Color(0xFF6C63FF) : const Color(0xFF888B9B)),
                          const SizedBox(height: 8),
                          Text(
                            'Khám Phá',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: _mode == 'Discovery' ? Colors.white : const Color(0xFF888B9B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chưa định hướng',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5E6072)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = 'Targeted'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191922),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _mode == 'Targeted' ? const Color(0xFF00F2FE) : const Color(0xFF2C2C3E),
                          width: _mode == 'Targeted' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.track_changes_rounded, color: _mode == 'Targeted' ? const Color(0xFF00F2FE) : const Color(0xFF888B9B)),
                          const SizedBox(height: 8),
                          Text(
                            'Mục Tiêu',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: _mode == 'Targeted' ? Colors.white : const Color(0xFF888B9B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã chọn sẵn ngành',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5E6072)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Target Career Input Form (Targeted mode only)
            if (_mode == 'Targeted') ...[
              TextFormField(
                controller: _targetCareerController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nhập ngành/nghề nghiệp mục tiêu của bạn',
                  labelStyle: const TextStyle(color: Color(0xFF7A7C93), fontSize: 13),
                  hintText: 'Ví dụ: Trí tuệ nhân tạo, Thiết kế nội thất',
                  hintStyle: const TextStyle(color: Color(0xFF5E6072), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF191922),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2C2C3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00F2FE)),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập ngành nghề mục tiêu' : null,
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initDynamicSurvey,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: _mode == 'Discovery' ? const Color(0xFF6C63FF) : const Color(0xFF00F2FE),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Khởi tạo bài Khảo sát',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: _mode == 'Discovery' ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khung loading
  Widget _buildLoadingState(String loadingText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Đang kết nối AI...',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              loadingText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888B9B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // Khung câu hỏi
  Widget _buildQuestionCard() {
    if (_questions.isEmpty) return const SizedBox.shrink();

    final currentQuestion = _questions[_currentQuestionIndex];
    final qText = currentQuestion['questionText'] ?? '';
    final options = currentQuestion['options'] as List<dynamic>? ?? [];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Câu hỏi ${_currentQuestionIndex + 1}/${_questions.length}',
              style: GoogleFonts.outfit(color: const Color(0xFF888B9B), fontWeight: FontWeight.bold),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.outfit(color: const Color(0xFF00F2FE), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF191922),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 40),

        // Question Container
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2C2C3E)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  qText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Answers options (Dynamic from AI)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.map((opt) {
            final optText = opt['text']?.toString() ?? '';
            final weight = int.tryParse(opt['weight']?.toString() ?? '3') ?? 3;
            final isSelected = _answers[_currentQuestionIndex] == weight;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlinedButton(
                onPressed: () => _selectOption(weight),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF191922),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF2C2C3E),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  optText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFFC3C5E0),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Bước 4: Yêu cầu Đăng nhập/Đăng ký inline
  Widget _buildAuthForm() {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          key: _authFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF191922),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2C2C3E)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_person_rounded, size: 52, color: Color(0xFF6C63FF)),
                    const SizedBox(height: 16),
                    Text(
                      'Xem Báo Cáo Định Hướng',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI đã chấm điểm khảo sát của bạn xong! Vui lòng đăng nhập hoặc tạo tài khoản để đồng bộ kết quả và xem báo cáo lộ trình chi tiết.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888B9B), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF191922),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLoginTab = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLoginTab ? const Color(0xFF6C63FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đăng Nhập',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: _isLoginTab ? Colors.white : const Color(0xFF888B9B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLoginTab = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLoginTab ? const Color(0xFF6C63FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đăng Ký',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: !_isLoginTab ? Colors.white : const Color(0xFF888B9B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_authError != null) ...[
                Text(
                  _authError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
              ],

              // Full Name (Only for Registration)
              if (!_isLoginTab) ...[
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    labelStyle: const TextStyle(color: Color(0xFF7A7C93), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF191922),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF2C2C3E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Email
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ Email / Tên đăng nhập',
                  labelStyle: const TextStyle(color: Color(0xFF7A7C93), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF191922),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2C2C3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập email' : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: const TextStyle(color: Color(0xFF7A7C93), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF191922),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2C2C3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Mật khẩu phải từ 6 ký tự' : null,
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isAuthenticating ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: const Color(0xFF6C63FF),
                ),
                child: _isAuthenticating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isLoginTab ? 'Đăng Nhập & Đồng Bộ' : 'Tạo Tài Khoản & Đồng Bộ',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy bỏ và Quay lại Trang chủ',
                  style: GoogleFonts.outfit(color: const Color(0xFF888B9B), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
