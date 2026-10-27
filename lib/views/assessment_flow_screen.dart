import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import '../viewmodels/assessment_flow_viewmodels.dart';
import 'comprehensive_report_screen.dart';

class AssessmentFlowScreen extends StatefulWidget {
  final String testType; // 'holland', 'personality', 'cognitive', 'values'

  const AssessmentFlowScreen({super.key, required this.testType});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetJobController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  String _educationLevel = 'Đại học';

  final List<String> _educationOptions = [
    'Học sinh THCS',
    'Học sinh THPT',
    'Cao đẳng',
    'Đại học',
    'Đã đi làm',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.targetJob.isNotEmpty) {
        _targetJobController.text = auth.targetJob;
      }
      if (auth.userProfile?['age'] != null) {
        _ageController.text = auth.userProfile!['age'].toString();
      }
      if (auth.educationLevel.isNotEmpty) {
        setState(() {
          _educationLevel = auth.educationLevel;
        });
      }
    });
  }

  @override
  void dispose() {
    _targetJobController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getTestTitle() {
    switch (widget.testType.toLowerCase()) {
      case 'holland':
        return 'Trắc Nghiệm Sở Thích Holland';
      case 'personality':
        return 'Trắc Nghiệm Tính Cách MBTI';
      case 'cognitive':
        return 'Đánh Giá Năng Lực Nhận Thức';
      case 'values':
        return 'Đánh Giá Giá Trị Nghề Nghiệp';
      default:
        return 'Bài Trắc Nghiệm Hướng Nghiệp';
    }
  }

  void _startAssessment(AssessmentFlowViewModel vm) {
    if (!_formKey.currentState!.validate()) return;

    final contextData = {
      'targetJob': _targetJobController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 18,
      'educationLevel': _educationLevel,
      'notes': _notesController.text.trim(),
    };

    vm.generateQuestions(widget.testType, contextData, (errorMsg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _submitAssessment(AssessmentFlowViewModel vm) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId ?? '';

    final success = await vm.submitAssessment(userId, (errorMsg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    if (!mounted) return;

    if (success) {
      if (auth.isAuthenticated) {
        await auth.claimTestResult(vm.sessionId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn thành bài trắc nghiệm!'),
          backgroundColor: Color(0xFF00F5A0),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ComprehensiveReportScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentFlowViewModel>(
      builder: (context, vm, child) {
        return PopScope(
          canPop: vm.step == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _showExitDialog(vm);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0F0F13),
            appBar: AppBar(
              backgroundColor: const Color(0xFF191922),
              elevation: 0,
              title: Text(
                _getTestTitle(),
                style: TextStyle(
                  fontSize: Responsive.font(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (vm.step == 0) {
                    Navigator.pop(context);
                  } else {
                    _showExitDialog(vm);
                  }
                },
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: _buildBodyByStep(vm),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyByStep(AssessmentFlowViewModel vm) {
    switch (vm.step) {
      case 0:
        return _buildStep0InputForm(vm);
      case 1:
        return _buildLoadingWidget('AI đang tạo bộ câu hỏi trắc nghiệm...');
      case 2:
        return _buildStep2QuestionFlow(vm);
      case 3:
        return _buildLoadingWidget('AI đang chấm điểm và phân tích kết quả...');
      default:
        return _buildStep0InputForm(vm);
    }
  }

  Widget _buildStep0InputForm(AssessmentFlowViewModel vm) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.s(context, 20)),
            decoration: BoxDecoration(
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.s(context, 12)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.assignment_ind_rounded,
                    color: const Color(0xFF6C63FF),
                    size: Responsive.s(context, 28),
                  ),
                ),
                SizedBox(width: Responsive.s(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thiết Lập Ngữ Cảnh AI',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 4)),
                      Text(
                        'Cung cấp thêm thông tin để AI cá nhân hóa bộ câu hỏi chính xác nhất cho bạn.',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 12),
                          color: const Color(0xFF888B9B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.s(context, 24)),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _targetJobController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ngành nghề / Công việc mục tiêu (tùy chọn)',
                    labelStyle: const TextStyle(color: Color(0xFF888B9B)),
                    hintText:
                        'Ví dụ: Lập trình viên Flutter, Marketing Manager',
                    hintStyle: const TextStyle(color: Color(0xFF5E6072)),
                    prefixIcon: const Icon(
                      Icons.work_outline_rounded,
                      color: Color(0xFF6C63FF),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF191922),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C63FF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 16)),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Tuổi',
                          labelStyle: const TextStyle(color: Color(0xFF888B9B)),
                          prefixIcon: const Icon(
                            Icons.cake_outlined,
                            color: Color(0xFF6C63FF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF191922),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C63FF),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed < 10 || parsed > 90) {
                              return 'Tuổi 10 - 90';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: Responsive.s(context, 12)),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _educationLevel,
                        dropdownColor: const Color(0xFF191922),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Trình độ',
                          labelStyle: const TextStyle(color: Color(0xFF888B9B)),
                          prefixIcon: const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF6C63FF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF191922),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _educationOptions.map((edu) {
                          return DropdownMenuItem(
                            value: edu,
                            child: Text(
                              edu,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _educationLevel = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.s(context, 16)),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú / Kỳ vọng thêm về bản thân',
                    labelStyle: const TextStyle(color: Color(0xFF888B9B)),
                    hintText:
                        'Nhập định hướng, điểm mạnh hoặc sở thích cá nhân...',
                    hintStyle: const TextStyle(color: Color(0xFF5E6072)),
                    filled: true,
                    fillColor: const Color(0xFF191922),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C63FF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 28)),
                SizedBox(
                  height: Responsive.s(context, 50),
                  child: ElevatedButton.icon(
                    onPressed: () => _startAssessment(vm),
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: Text(
                      'BẮT ĐẦU LÀM BÀI TRẮC NGHIỆM',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 14),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2QuestionFlow(AssessmentFlowViewModel vm) {
    if (vm.questions.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy danh sách câu hỏi.',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.font(context, 14),
          ),
        ),
      );
    }

    final totalQuestions = vm.questions.length;
    final currentIndex = vm.currentQuestionIndex;
    final currentQuestion = vm.questions[currentIndex];
    final selectedAnswer = vm.answers[currentIndex];

    final questionText =
        currentQuestion['question'] ??
        currentQuestion['questionText'] ??
        'Câu hỏi ${currentIndex + 1}';

    final optionsList = currentQuestion['options'] as List? ?? vm.options;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.s(context, 20),
            vertical: Responsive.s(context, 12),
          ),
          color: const Color(0xFF191922),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu hỏi ${currentIndex + 1} / $totalQuestions',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 13),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  Text(
                    '${((currentIndex + 1) / totalQuestions * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 12),
                      color: const Color(0xFF888B9B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.s(context, 8)),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / totalQuestions,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF0F0F13),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.s(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.s(context, 20)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191922),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    questionText,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 20)),
                ...List.generate(optionsList.length, (optIndex) {
                  final rawOpt = optionsList[optIndex];
                  final String optionText = (rawOpt is Map)
                      ? (rawOpt['text'] ??
                            rawOpt['label'] ??
                            rawOpt.values.first.toString())
                      : rawOpt.toString();

                  final bool isSelected =
                      (selectedAnswer == optionText ||
                      selectedAnswer == optIndex);

                  return Container(
                    margin: EdgeInsets.only(bottom: Responsive.s(context, 12)),
                    child: InkWell(
                      onTap: () {
                        vm.selectAnswer(optionText, () {
                          _submitAssessment(vm);
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.s(context, 16),
                          vertical: Responsive.s(context, 14),
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                              : const Color(0xFF191922),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withValues(alpha: 0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: Responsive.s(context, 24),
                              height: Responsive.s(context, 24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFF6C63FF)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFF5E6072),
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            SizedBox(width: Responsive.s(context, 12)),
                            Expanded(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  fontSize: Responsive.font(context, 13),
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFD1D5DB),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(Responsive.s(context, 16)),
          decoration: const BoxDecoration(color: Color(0xFF191922)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentIndex > 0)
                OutlinedButton.icon(
                  onPressed: () {
                    if (vm.currentQuestionIndex > 0) {
                      vm.selectAnswer(vm.answers[currentIndex - 1], () {});
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Câu Trước',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5E6072)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (currentIndex == totalQuestions - 1)
                ElevatedButton.icon(
                  onPressed: selectedAnswer != null
                      ? () => _submitAssessment(vm)
                      : null,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('NỘP BÀI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5A0),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.s(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              strokeWidth: 3,
            ),
            SizedBox(height: Responsive.s(context, 20)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.font(context, 14),
                color: const Color(0xFF888B9B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(AssessmentFlowViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191922),
        title: const Text(
          'Thoát làm bài trắc nghiệm?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Các câu trả lời hiện tại sẽ bị hủy nếu bạn thoát ngay bây giờ.',
          style: TextStyle(color: Color(0xFF888B9B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF888B9B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              vm.setStep(0);
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Thoát màn hình
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}
