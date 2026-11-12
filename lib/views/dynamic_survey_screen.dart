import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/dynamic_survey_viewmodel.dart';
import 'dynamic_survey_report_screen.dart';

class DynamicSurveyScreen extends StatefulWidget {
  const DynamicSurveyScreen({super.key});

  @override
  State<DynamicSurveyScreen> createState() => _DynamicSurveyScreenState();
}

class _DynamicSurveyScreenState extends State<DynamicSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetCareerController = TextEditingController();
  final _ageController = TextEditingController();

  String _mode = 'DISCOVER';
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
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.targetJob.isNotEmpty) {
        _targetCareerController.text = auth.targetJob;
      }
      if (auth.educationLevel.isNotEmpty) {
        setState(() => _educationLevel = auth.educationLevel);
      }
    });
  }

  @override
  void dispose() {
    _targetCareerController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _startSurvey(DynamicSurveyViewModel vm) {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    vm.initSurvey(
      mode: _mode,
      targetCareer: _targetCareerController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      education: _educationLevel,
      hobby: auth.hobby,
      onError: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      },
    );
  }

  void _submitSurvey(DynamicSurveyViewModel vm) async {
    final success = await vm.submitSurvey((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    });

    if (!mounted) return;

    if (success && vm.surveyResult != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DynamicSurveyReportScreen(resultData: vm.surveyResult!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicSurveyViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            title: Text(
              'Khảo Sát Động Hướng Nghiệp',
              style: TextStyle(
                fontSize: Responsive.font(context, 16),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
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

  Widget _buildBody(DynamicSurveyViewModel vm) {
    switch (vm.step) {
      case 0:
        return _buildConfigForm(vm);
      case 1:
        return _buildLoadingState(
          'AI đang khởi tạo bộ câu hỏi khảo sát động...',
        );
      case 2:
        return _buildQuestionsFlow(vm);
      case 3:
        return _buildLoadingState('AI đang tổng hợp và phân tích kết quả...');
      default:
        return _buildConfigForm(vm);
    }
  }

  Widget _buildConfigForm(DynamicSurveyViewModel vm) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.s(context, 16)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.quiz_rounded,
                    color: AppColors.primaryDark,
                    size: 32,
                  ),
                  SizedBox(width: Responsive.s(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khảo Sát Động Tinh Chỉnh',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 15),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: Responsive.s(context, 4)),
                        Text(
                          'AI sẽ tự động sinh câu hỏi thông minh theo định hướng riêng của bạn.',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 12),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.s(context, 20)),

            // Chọn Chế độ khảo sát
            Text(
              'Chế Độ Khảo Sát',
              style: TextStyle(
                fontSize: Responsive.font(context, 14),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: Responsive.s(context, 10)),
            Row(
              children: [
                Expanded(
                  child: _buildModeTile(
                    'DISCOVER',
                    'Khám Phá',
                    Icons.explore_outlined,
                  ),
                ),
                SizedBox(width: Responsive.s(context, 10)),
                Expanded(
                  child: _buildModeTile(
                    'TARGET',
                    'Mục Tiêu Nâng Cao',
                    Icons.track_changes_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.s(context, 20)),

            TextFormField(
              controller: _targetCareerController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Ngành nghề quan tâm / mục tiêu',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'VD: Thiết kế Đồ họa, AI Engineer',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: Responsive.s(context, 16)),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Tuổi',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.s(context, 12)),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _educationLevel,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Trình độ',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _educationOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _educationLevel = val);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.s(context, 28)),

            SizedBox(
              height: Responsive.s(context, 48),
              child: ElevatedButton.icon(
                onPressed: () => _startSurvey(vm),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text(
                  'BẮT ĐẦU KHẢO SÁT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTile(String modeKey, String title, IconData icon) {
    final isSelected = _mode == modeKey;
    return InkWell(
      onTap: () => setState(() => _mode = modeKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Responsive.s(context, 12)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: Responsive.s(context, 6)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.font(context, 12),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsFlow(DynamicSurveyViewModel vm) {
    if (vm.questions.isEmpty) {
      return const Center(
        child: Text(
          'Không có câu hỏi.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    final q = vm.questions[vm.currentIndex];
    final title =
        q['questionText'] ?? q['question'] ?? 'Câu hỏi ${vm.currentIndex + 1}';
    final rawOptions = q['options'] as List? ?? [];
    final selectedOpt = vm.answers[vm.currentIndex];

    return Column(
      children: [
        LinearProgressIndicator(
          value: (vm.currentIndex + 1) / vm.questions.length,
          backgroundColor: AppColors.surface,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.s(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Câu ${vm.currentIndex + 1} / ${vm.questions.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.font(context, 13),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 12)),
                Container(
                  padding: EdgeInsets.all(Responsive.s(context, 18)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 15),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 20)),
                ...List.generate(rawOptions.length, (optIdx) {
                  final optText = rawOptions[optIdx].toString();
                  final isSel = selectedOpt == optIdx;
                  return Container(
                    margin: EdgeInsets.only(bottom: Responsive.s(context, 10)),
                    child: InkWell(
                      onTap: () => vm.selectOption(vm.currentIndex, optIdx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(Responsive.s(context, 14)),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          optText,
                          style: TextStyle(
                            color: isSel
                                ? AppColors.textPrimary
                                : AppColors.textBody,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
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
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (vm.currentIndex > 0)
                OutlinedButton(
                  onPressed: () => vm.previousQuestion(),
                  child: const Text(
                    'Trước',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (vm.currentIndex < vm.questions.length - 1)
                ElevatedButton(
                  onPressed: () => vm.nextQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Tiếp Theo'),
                )
              else
                ElevatedButton(
                  onPressed: selectedOpt != null
                      ? () => _submitSurvey(vm)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'HOÀN THÀNH',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: Responsive.s(context, 16)),
          Text(
            msg,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: Responsive.font(context, 13),
            ),
          ),
        ],
      ),
    );
  }
}
