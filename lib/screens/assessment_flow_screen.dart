import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'comprehensive_report_screen.dart';

class AssessmentFlowScreen extends StatefulWidget {
  final String testType; // 'holland', 'personality', 'cognitive', 'values'

  const AssessmentFlowScreen({super.key, required this.testType});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  // Trạng thái màn hình: 0: Nhập context, 1: Đang tạo câu hỏi, 2: Trả lời câu hỏi, 3: Đang chấm điểm, 4: Đăng nhập/Xác nhận lưu
  int _step = 0;

  // Form inputs
  final _formKey = GlobalKey<FormState>();
  final _targetJobController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _ageController = TextEditingController();
  String _educationLevel = 'Đại học';

  // Câu hỏi & Câu trả lời từ API
  String _testName = '';
  String _sessionId = '';
  List<dynamic> _questions = [];
  List<dynamic> _options = [];

  // Trạng thái câu trả lời người dùng
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _answers = {}; // index -> answer (string hoặc int)

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _step = 1;
    });

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
      if (!mounted) {
        return;
      }
      setState(() {
        _step = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Lỗi sinh câu hỏi. Vui lòng thử lại!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _selectAnswer(dynamic answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });

    // Tự động chuyển câu hỏi sau 250ms để tăng trải nghiệm mượt mà
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        _submitAssessment();
      }
    });
  }

  void _submitAssessment() async {
    setState(() {
      _step = 3;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userContext = {
      'targetJob': _targetJobController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 18,
      'educationLevel': _educationLevel,
    };

    // 1. Tạo danh sách câu hỏi kèm câu trả lời chuẩn hóa để lưu DB
    final formattedQuestions = List<Map<String, dynamic>>.generate(
      _questions.length,
      (idx) {
        final q = _questions[idx];
        final qText = q['question'] ?? q['questionText'] ?? '';
        final ans = _answers[idx] ?? '';

        final Map<String, dynamic> qMap = {
          'questionText': qText,
          'userAnswer': ans.toString(),
          'order': idx + 1,
        };

        if (widget.testType == 'holland') {
          qMap['hollandType'] = q['hollandType'];
        } else if (widget.testType == 'personality') {
          qMap['trait'] = q['trait'];
        } else if (widget.testType == 'cognitive') {
          qMap['type'] = q['type'];
          qMap['correctAnswer'] = q['correctAnswer'];
        } else if (widget.testType == 'values') {
          qMap['valueType'] = q['valueType'];
        }

        return qMap;
      },
    );

    // Lưu câu hỏi & câu trả lời
    await ApiService.saveQuestions(
      sessionId: _sessionId,
      userId: auth.userId,
      testName: _testName,
      questions: formattedQuestions,
      userContext: userContext,
    );

    // 2. Gọi API đánh giá tương ứng
    final evalResult = await ApiService.evaluateTest(_sessionId);

    if (evalResult['success'] == true) {
      // 3. Nếu đã đăng nhập thì tự động claim kết quả
      if (auth.isAuthenticated) {
        final claimRes = await auth.claimTestResult(_sessionId);
        if (claimRes['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bài làm đã được chấm và lưu thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ComprehensiveReportScreen(),
              ),
            );
          }
          return;
        }
      }

      // Nếu chưa đăng nhập, chuyển sang bước yêu cầu login để claim kết quả
      setState(() {
        _step = 4;
      });
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _step = 2; // Quay lại bước làm bài để làm lại hoặc thử lại
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            evalResult['message'] ?? 'Lỗi chấm bài. Vui lòng gửi lại!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          _testTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == 2) {
              // Yêu cầu xác nhận thoát khi đang làm bài
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF191922),
                  title: Text(
                    'Hủy bỏ bài test?',
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                  content: Text(
                    'Mọi câu trả lời của bạn sẽ không được lưu.',
                    style: GoogleFonts.inter(color: const Color(0xFF888B9B)),
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Tiếp tục làm',
                        style: TextStyle(color: Color(0xFF6C63FF)),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text(
                        'Thoát',
                        style: TextStyle(color: Colors.redAccent),
                      ),
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
          // Background Glows
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
        return _buildContextSetupForm();
      case 1:
        return _buildLoadingState(
          'AI đang thiết kế các câu hỏi cá nhân hóa dành riêng cho bạn...',
        );
      case 2:
        return _buildQuestionCard();
      case 3:
        return _buildLoadingState(
          'AI đang chấm điểm và phân tích kết quả trắc nghiệm...',
        );
      case 4:
        return _buildClaimPrompt();
      default:
        return const SizedBox.shrink();
    }
  }

  // Bước 0: Setup thông tin đầu vào
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
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2C2C3E)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 40,
                    color: Color(0xFF00F2FE),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cá Nhân Hóa Đánh Giá',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI sẽ tự động điều chỉnh bộ câu hỏi dựa theo công việc mong muốn, độ tuổi và sở thích học tập để cho kết quả chính xác nhất.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF888B9B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Target Job
            TextFormField(
              controller: _targetJobController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Công việc mục tiêu / Ngành mong muốn',
                labelStyle: const TextStyle(
                  color: Color(0xFF7A7C93),
                  fontSize: 13,
                ),
                hintText: 'Ví dụ: Lập trình viên, Giáo viên, Thiết kế đồ họa',
                hintStyle: const TextStyle(
                  color: Color(0xFF5E6072),
                  fontSize: 13,
                ),
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
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Vui lòng nhập công việc mục tiêu'
                  : null,
            ),
            const SizedBox(height: 20),

            // Age
            TextFormField(
              controller: _ageController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tuổi của bạn',
                labelStyle: const TextStyle(
                  color: Color(0xFF7A7C93),
                  fontSize: 13,
                ),
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
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập độ tuổi';
                }
                final parsed = int.tryParse(val);
                if (parsed == null || parsed <= 0 || parsed > 100) {
                  return 'Tuổi không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Education Level Dropdown
            DropdownButtonFormField<String>(
              initialValue: _educationLevel,
              style: const TextStyle(color: Colors.white),
              dropdownColor: const Color(0xFF191922),
              decoration: InputDecoration(
                labelText: 'Trình độ học vấn',
                labelStyle: const TextStyle(
                  color: Color(0xFF7A7C93),
                  fontSize: 13,
                ),
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
              items: ['Cấp 2', 'Cấp 3', 'Đại học', 'Sau Đại học']
                  .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _educationLevel = val);
                }
              },
            ),
            const SizedBox(height: 20),

            // Hobbies
            TextFormField(
              controller: _hobbyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Sở thích & Điểm mạnh cá nhân',
                labelStyle: const TextStyle(
                  color: Color(0xFF7A7C93),
                  fontSize: 13,
                ),
                hintText: 'Ví dụ: Đọc sách, Chơi game, Lắp ráp mô hình',
                hintStyle: const TextStyle(
                  color: Color(0xFF5E6072),
                  fontSize: 13,
                ),
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
            ),
            const SizedBox(height: 36),

            // Button Start
            ElevatedButton(
              onPressed: _generateQuestions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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

  // Bước 1 & 3: Loading AI
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
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loadingText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF888B9B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Bước 2: Hiển thị Thẻ câu hỏi và lựa chọn trả lời
  Widget _buildQuestionCard() {
    if (_questions.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final qText =
        currentQuestion['question'] ?? currentQuestion['questionText'] ?? '';
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress and Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Câu hỏi ${_currentQuestionIndex + 1}/${_questions.length}',
              style: GoogleFonts.outfit(
                color: const Color(0xFF888B9B),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.outfit(
                color: const Color(0xFF00F2FE),
                fontWeight: FontWeight.bold,
              ),
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
                ),
              ],
            ),
            child: Center(
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
        const SizedBox(height: 40),

        // Answers options container
        if (widget.testType == 'cognitive')
          _buildCognitiveOptions(currentQuestion['options'] ?? [])
        else
          _buildLikertOptions(),
      ],
    );
  }

  Widget _buildLikertOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _options.map((opt) {
        final isSelected = _answers[_currentQuestionIndex] == opt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: OutlinedButton(
            onPressed: () => _selectAnswer(opt),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: isSelected
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF191922),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF2C2C3E),
                width: 1.5,
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFFC3C5E0),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCognitiveOptions(List<dynamic> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((opt) {
        final optStr = opt.toString();
        // Lấy chữ A, B, C hoặc D từ "A. Lựa chọn"
        final code = optStr.startsWith(RegExp(r'[A-D]\.')) ? optStr[0] : optStr;
        final isSelected = _answers[_currentQuestionIndex] == code;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: OutlinedButton(
            onPressed: () => _selectAnswer(code),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: isSelected
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF191922),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF2C2C3E),
                width: 1.5,
              ),
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              optStr,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFFC3C5E0),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Bước 4: Nếu nộp bài thành công nhưng chưa login -> Nhắc nhở lưu kết quả
  Widget _buildClaimPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2C2C3E)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  size: 64,
                  color: Color(0xFF00F5A0),
                ),
                const SizedBox(height: 20),
                Text(
                  'Đã Chấm Điểm Xong!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kết quả bài trắc nghiệm của bạn hiện đã sẵn sàng. Vui lòng đăng nhập hoặc đăng ký tài khoản để xem chi tiết điểm số và lưu vĩnh viễn vào hồ sơ hướng nghiệp.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF888B9B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Quay trở lại màn hình Home và tự động mở Login
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: Text(
              'Đăng nhập để xem kết quả',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Quay lại trang chủ',
              style: GoogleFonts.outfit(
                color: const Color(0xFF888B9B),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
