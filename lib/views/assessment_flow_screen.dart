import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import '../controllers/assessment_flow_controller.dart';

class AssessmentFlowScreen extends StatefulWidget {
  const AssessmentFlowScreen({super.key});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetReasonController = TextEditingController();
  final _trustFeedbackController = TextEditingController();
  String _flow = 'main';
  String _audience = 'student';
  String? _targetMajorId;
  int _certaintyLevel = 7;
  int _trustScore = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = context.read<AssessmentFlowController>();
        controller.reset();
        controller.loadMajors();
      }
    });
  }

  @override
  void dispose() {
    _targetReasonController.dispose();
    _trustFeedbackController.dispose();
    super.dispose();
  }

  Future<void> _startAssessment(AssessmentFlowController vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (_flow == 'flow_b' && _targetMajorId == null) {
      _showMessage('Vui lòng chọn ngành muốn đánh giá.');
      return;
    }

    final auth = context.read<AuthProvider>();
    await vm.startAssessment(
      flow: _flow,
      audience: _audience,
      userId: auth.userId,
      targetMajorId: _flow == 'flow_b' ? _targetMajorId : null,
      certaintyLevel: _flow == 'flow_b' ? _certaintyLevel : null,
      targetReason: _flow == 'flow_b'
          ? _targetReasonController.text.trim()
          : null,
      onError: _showMessage,
    );
  }

  Future<void> _submitSection(AssessmentFlowController vm) async {
    await vm.submitCurrentSection(onError: _showMessage);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _sectionTitle(String section) {
    const titles = {
      'profile': 'Thông tin học tập',
      'personality': 'Tính cách',
      'holland': 'Sở thích nghề nghiệp',
      'language': 'Năng lực ngoại ngữ',
      'career_opportunity': 'Cơ hội nghề nghiệp',
    };
    return titles[section] ?? 'Đánh giá hướng nghiệp';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentFlowController>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F13),
          appBar: AppBar(
            backgroundColor: const Color(0xFF191922),
            title: Text(
              vm.step == 4 ? 'Kết quả hướng nghiệp' : 'Đánh giá hướng nghiệp',
              style: TextStyle(
                fontSize: Responsive.font(context, 16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                if (vm.step == 0 || vm.step == 4) {
                  Navigator.pop(context);
                } else {
                  _showMessage('Hãy hoàn thành phần đánh giá hiện tại trước.');
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
                child: _buildBody(vm),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(AssessmentFlowController vm) {
    switch (vm.step) {
      case 0:
        return _buildSetupForm(vm);
      case 1:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        );
      case 2:
        return _buildQuestion(vm);
      case 3:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text(
                'Đang lưu câu trả lời và tính điểm...',
                style: TextStyle(color: Color(0xFFB7B8C5)),
              ),
            ],
          ),
        );
      case 4:
        return _buildResult(vm);
      case 5:
        return _buildErrorState(vm);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorState(AssessmentFlowController vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.orangeAccent,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              vm.errorMessage ?? 'Không thể tải dữ liệu đánh giá.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            if (vm.canRetry)
              FilledButton.icon(
                onPressed: () => vm.retryPending(_showMessage),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                ),
              )
            else
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay về'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm(AssessmentFlowController vm) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _introCard(
              Icons.auto_awesome_rounded,
              'Đánh giá theo từng phần',
              'Câu hỏi được lấy từ ngân hàng đánh giá của hệ thống. Kết quả sẽ tổng hợp mức độ phù hợp và ngành học gợi ý.',
            ),
            SizedBox(height: Responsive.s(context, 20)),
            _fieldLabel('Đối tượng'),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              dropdownColor: const Color(0xFF191922),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Chọn đối tượng'),
              items: const [
                DropdownMenuItem(
                  value: 'student',
                  child: Text('Học sinh THPT'),
                ),
                DropdownMenuItem(
                  value: 'freshman',
                  child: Text('Sinh viên năm nhất'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _audience = value);
              },
            ),
            SizedBox(height: Responsive.s(context, 18)),
            _fieldLabel('Mục tiêu đánh giá'),
            _buildFlowChoice(
              title: 'Khám phá ngành phù hợp',
              description: 'Hệ thống gợi ý các ngành dựa trên câu trả lời.',
              value: 'main',
              icon: Icons.explore_rounded,
            ),
            SizedBox(height: Responsive.s(context, 10)),
            _buildFlowChoice(
              title: 'Đánh giá một ngành cụ thể',
              description: 'So sánh hồ sơ của bạn với ngành đang quan tâm.',
              value: 'flow_b',
              icon: Icons.track_changes_rounded,
            ),
            if (_flow == 'flow_b') ...[
              SizedBox(height: Responsive.s(context, 16)),
              _fieldLabel('Ngành muốn đánh giá'),
              if (vm.isLoadingMajors)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                )
              else if (vm.majors.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.majorsError ?? 'Chưa có dữ liệu ngành.',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    TextButton(
                      onPressed: vm.loadMajors,
                      child: const Text('Thử tải lại'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  initialValue:
                      vm.majors.any(
                        (major) => major['id']?.toString() == _targetMajorId,
                      )
                      ? _targetMajorId
                      : null,
                  dropdownColor: const Color(0xFF191922),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Chọn ngành'),
                  items: vm.majors
                      .map<DropdownMenuItem<String>>(
                        (major) => DropdownMenuItem(
                          value: major['id']?.toString(),
                          child: Text(
                            major['name']?.toString() ?? 'Ngành chưa có tên',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _targetMajorId = value);
                  },
                ),
              SizedBox(height: Responsive.s(context, 16)),
              _fieldLabel('Mức độ chắc chắn (1–10)'),
              DropdownButtonFormField<int>(
                initialValue: _certaintyLevel,
                dropdownColor: const Color(0xFF191922),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Mức độ chắc chắn'),
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _certaintyLevel = value);
                },
              ),
              SizedBox(height: Responsive.s(context, 16)),
              _fieldLabel('Lý do chọn ngành (không bắt buộc)'),
              TextFormField(
                controller: _targetReasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  'Điều gì khiến bạn quan tâm ngành này?',
                ),
              ),
            ],
            SizedBox(height: Responsive.s(context, 24)),
            FilledButton.icon(
              onPressed: vm.isLoadingMajors && _flow == 'flow_b'
                  ? null
                  : () => _startAssessment(vm),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Bắt đầu đánh giá'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowChoice({
    required String title,
    required String description,
    required String value,
    required IconData icon,
  }) {
    final selected = _flow == value;
    return InkWell(
      onTap: () => setState(() => _flow = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF191922),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF6C63FF) : Colors.white54,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: const Color(0xFF00F5A0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF888B9B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(AssessmentFlowController vm) {
    final question = vm.questions[vm.currentQuestionIndex];
    final questionId = question['id']?.toString() ?? '';
    final answer = vm.answers[questionId];
    final progress = (vm.currentQuestionIndex + 1) / vm.questions.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _sectionTitle(vm.section),
            style: const TextStyle(
              color: Color(0xFF00F5A0),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF292936),
            color: const Color(0xFF6C63FF),
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            'Câu ${vm.currentQuestionIndex + 1} / ${vm.questions.length}',
            style: const TextStyle(color: Color(0xFF888B9B)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question['text']?.toString() ??
                      question['questionText']?.toString() ??
                      'Câu hỏi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnswerInput(question, questionId, answer),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: vm.currentQuestionIndex == 0
                    ? null
                    : vm.goToPreviousQuestion,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Quay lại'),
              ),
              const Spacer(),
              if (vm.currentQuestionIndex < vm.questions.length - 1)
                FilledButton.icon(
                  onPressed: vm.hasAnsweredCurrentQuestion
                      ? vm.goToNextQuestion
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Tiếp tục'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: vm.allQuestionsAnswered
                      ? () => _submitSection(vm)
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Hoàn thành phần'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(Map question, String questionId, dynamic answer) {
    final type = question['type']?.toString() ?? '';
    if (type == 'text') {
      return TextFormField(
        key: ValueKey(questionId),
        initialValue: answer?.toString(),
        maxLines: 4,
        onChanged: (value) {
          context.read<AssessmentFlowController>().selectAnswer(
            questionId,
            value,
          );
        },
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration('Nhập câu trả lời'),
      );
    }

    final options = question['options'] is List
        ? question['options'] as List
        : <dynamic>[];
    if (type == 'likert5' && options.isEmpty) {
      return Row(
        children: List.generate(5, (index) {
          final value = index + 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _answerTile(
                label: '$value',
                selected: answer == value || answer?.toString() == '$value',
                onTap: () => context
                    .read<AssessmentFlowController>()
                    .selectAnswer(questionId, value),
                compact: true,
              ),
            ),
          );
        }),
      );
    }

    final isMultiple = type == 'multi_choice' || type == 'ranking';
    if (options.isEmpty) {
      return const Text(
        'Câu hỏi này chưa có lựa chọn khả dụng.',
        style: TextStyle(color: Colors.redAccent),
      );
    }

    return Column(
      children: options.map<Widget>((option) {
        final selectionKey = option is Map
            ? option['id'] ?? option['value'] ?? option['text']
            : option;
        final label = option is Map
            ? option['text'] ?? option['label'] ?? selectionKey
            : option;
        final selected = answer is List
            ? answer.any(
                (selectedValue) =>
                    selectedValue?.toString() == selectionKey?.toString(),
              )
            : answer?.toString() == selectionKey?.toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _answerTile(
            label: label?.toString() ?? '',
            selected: selected,
            onTap: () {
              final controller = context.read<AssessmentFlowController>();
              if (isMultiple) {
                final selectedValues = answer is List
                    ? List<dynamic>.from(answer)
                    : <dynamic>[];
                final alreadySelected = selectedValues.any(
                  (selectedValue) =>
                      selectedValue?.toString() == selectionKey?.toString(),
                );
                if (alreadySelected) {
                  selectedValues.removeWhere(
                    (selectedValue) =>
                        selectedValue?.toString() == selectionKey?.toString(),
                  );
                } else {
                  selectedValues.add(selectionKey);
                }
                controller.selectAnswer(questionId, selectedValues);
              } else {
                controller.selectAnswer(questionId, selectionKey);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _answerTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: compact ? null : double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 14,
          vertical: compact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.18)
              : const Color(0xFF22222D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: compact
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (!compact)
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFF00F5A0) : Colors.white54,
                size: 20,
              ),
            if (!compact) const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFCBCBD4),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(AssessmentFlowController vm) {
    final result = vm.result ?? {};
    final majors = result['recommendedMajors'] is List
        ? result['recommendedMajors'] as List
        : <dynamic>[];
    final strengths = result['strengths'] is List
        ? (result['strengths'] as List)
              .map((value) => value.toString())
              .toList()
        : <String>[];
    final improvements = result['improvementAreas'] is List
        ? (result['improvementAreas'] as List)
              .map((value) => value.toString())
              .toList()
        : <String>[];
    final score = result['fitScore'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _introCard(
            Icons.verified_rounded,
            result['fitLevel']?.toString() ?? 'Đã hoàn thành đánh giá',
            'Kết quả được tổng hợp từ các câu trả lời và hồ sơ ngành trên hệ thống.',
          ),
          if (score != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$score%',
                    style: const TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Mức độ phù hợp tổng thể',
                    style: TextStyle(color: Color(0xFFB7B8C5)),
                  ),
                ],
              ),
            ),
          ],
          _buildResultBreakdown(result),
          if (majors.isNotEmpty) ...[
            const SizedBox(height: 22),
            _fieldLabel('Ngành học được gợi ý'),
            ...majors.map((major) {
              if (major is! Map) return const SizedBox.shrink();
              final schools = major['suggestedSchools'] is List
                  ? major['suggestedSchools'] as List
                  : <dynamic>[];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF191922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            major['majorName']?.toString() ??
                                major['name']?.toString() ??
                                'Ngành học',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (major['fitScore'] != null)
                          Text(
                            '${major['fitScore']}%',
                            style: const TextStyle(
                              color: Color(0xFF00F5A0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (schools.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Trường gợi ý: ${schools.take(2).map((school) => school is Map ? school['universityName'] : null).whereType<String>().join(', ')}',
                        style: const TextStyle(
                          color: Color(0xFF888B9B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    _buildMajorDetails(major),
                  ],
                ),
              );
            }),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _fieldLabel('Điểm mạnh'),
            ...strengths.map(_bulletItem),
          ],
          if (improvements.isNotEmpty) ...[
            const SizedBox(height: 12),
            _fieldLabel('Có thể phát triển'),
            ...improvements.map(_bulletItem),
          ],
          if (result['actionRecommendation'] != null) ...[
            const SizedBox(height: 16),
            _fieldLabel('Định hướng tiếp theo'),
            Text(
              result['actionRecommendation'].toString(),
              style: const TextStyle(color: Color(0xFFCBCBD4), height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
          _fieldLabel('Bạn có tin tưởng kết quả này không?'),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: vm.trustSubmitted
                    ? null
                    : () => setState(() => _trustScore = index + 1),
                icon: Icon(
                  index < _trustScore ? Icons.star_rounded : Icons.star_border,
                  color: const Color(0xFFFFD166),
                  size: 30,
                ),
              ),
            ),
          ),
          TextFormField(
            controller: _trustFeedbackController,
            enabled: !vm.trustSubmitted && !vm.isSubmittingTrust,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Góp ý thêm (không bắt buộc)'),
          ),
          const SizedBox(height: 10),
          if (vm.trustSubmitted)
            Text(
              vm.trustAction ?? 'Cảm ơn bạn đã gửi phản hồi.',
              style: const TextStyle(color: Color(0xFF00F5A0), height: 1.4),
            )
          else
            OutlinedButton.icon(
              onPressed: vm.isSubmittingTrust
                  ? null
                  : () async {
                      final submitted = await vm.submitTrustFeedback(
                        trustScore: _trustScore,
                        feedbackText: _trustFeedbackController.text.trim(),
                        onError: _showMessage,
                      );
                      if (submitted) {
                        _showMessage('Đã ghi nhận phản hồi của bạn.');
                      }
                    },
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(
                vm.isSubmittingTrust ? 'Đang gửi...' : 'Gửi đánh giá kết quả',
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Về trang chủ'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBreakdown(Map<String, dynamic> result) {
    final personality = result['personalityScores'] is Map
        ? Map<String, dynamic>.from(result['personalityScores'] as Map)
        : <String, dynamic>{};
    final holland = result['hollandScores'] is Map
        ? Map<String, dynamic>.from(result['hollandScores'] as Map)
        : <String, dynamic>{};
    final dimensions = personality['dimensions'] is Map
        ? Map<String, dynamic>.from(personality['dimensions'] as Map)
        : <String, dynamic>{};
    final normalizedHolland = holland['normalizedScores'] is Map
        ? Map<String, dynamic>.from(holland['normalizedScores'] as Map)
        : <String, dynamic>{};

    final scores = <(String, dynamic)>[
      ('Ngoại ngữ', result['languageScore']),
      ('Học tập', result['profileScore']),
      ('Cơ hội nghề nghiệp', result['careerScore']),
    ].where((item) => item.$2 != null).toList();
    final personalityType = personality['mbtiType']?.toString();
    final hollandCode = holland['topCode']?.toString();

    if (scores.isEmpty &&
        personalityType == null &&
        hollandCode == null &&
        normalizedHolland.isEmpty &&
        dimensions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF191922),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Kết quả theo từng trụ cột'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (personalityType != null)
                  _resultTag('Tính cách', personalityType),
                if (hollandCode != null) _resultTag('Holland', hollandCode),
                ...scores.map((item) => _resultTag(item.$1, '${item.$2}/100')),
                ...dimensions.entries.map((entry) {
                  final detail = entry.value;
                  if (detail is! Map || detail['selected'] == null) {
                    return const SizedBox.shrink();
                  }
                  return _resultTag(entry.key, detail['selected'].toString());
                }),
              ],
            ),
            if (normalizedHolland.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Điểm sở thích Holland',
                style: TextStyle(
                  color: Color(0xFFB7B8C5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...normalizedHolland.entries.map((entry) {
                final value = double.tryParse(entry.value.toString());
                if (value == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (value / 100).clamp(0, 1),
                          color: const Color(0xFF6C63FF),
                          backgroundColor: const Color(0xFF292936),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${value.round()}%',
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: Color(0xFFB7B8C5)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22222D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildMajorDetails(Map major) {
    final components = major['componentScores'] is Map
        ? Map<String, dynamic>.from(major['componentScores'] as Map)
        : <String, dynamic>{};
    final careerPaths = major['careerPaths'] is List
        ? (major['careerPaths'] as List).map((item) => item.toString()).toList()
        : <String>[];
    final relatedMajors = major['relatedMajors'] is List
        ? (major['relatedMajors'] as List)
              .map((item) => item.toString())
              .toList()
        : <String>[];

    if (components.isEmpty && careerPaths.isEmpty && relatedMajors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (major['category'] != null)
            Text(
              'Lĩnh vực: ${major['category']}',
              style: const TextStyle(color: Color(0xFF888B9B), fontSize: 12),
            ),
          if (components.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: components.entries
                  .where((entry) => entry.value != null)
                  .map((entry) => _resultTag(entry.key, '${entry.value}/100'))
                  .toList(),
            ),
          if (careerPaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Vị trí nghề nghiệp: ${careerPaths.join(', ')}',
                style: const TextStyle(color: Color(0xFFB7B8C5), fontSize: 12),
              ),
            ),
          if (relatedMajors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Ngành liên quan: ${relatedMajors.join(', ')}',
                style: const TextStyle(color: Color(0xFFB7B8C5), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF00F5A0),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFFCBCBD4))),
          ),
        ],
      ),
    );
  }

  Widget _introCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF888B9B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF888B9B)),
      filled: true,
      fillColor: const Color(0xFF191922),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
      ),
    );
  }
}
