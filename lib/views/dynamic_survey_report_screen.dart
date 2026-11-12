import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/dynamic_survey_report_viewmodel.dart';
import 'chat_screen.dart';

class DynamicSurveyReportScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;

  const DynamicSurveyReportScreen({super.key, required this.resultData});

  @override
  State<DynamicSurveyReportScreen> createState() =>
      _DynamicSurveyReportScreenState();
}

class _DynamicSurveyReportScreenState extends State<DynamicSurveyReportScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitFeedback(DynamicSurveyReportViewModel vm) async {
    final surveyId = widget.resultData['surveyId']?.toString() ?? 'survey_123';
    final success = await vm.sendFeedback(
      surveyId: surveyId,
      rating: _rating,
      comment: _commentController.text.trim(),
      onError: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn phản hồi của bạn!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        widget.resultData['summary']?.toString() ?? 'Chưa có tóm tắt.';
    final rawCareers = widget.resultData['recommendedCareers'] as List? ?? [];
    final careers = rawCareers.map((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Kết Quả Khảo Sát Động',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<DynamicSurveyReportViewModel>(
        builder: (context, vm, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.s(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tóm tắt kết quả
                Container(
                  padding: EdgeInsets.all(Responsive.s(context, 18)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đánh Giá Từ AI',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.s(context, 12)),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: Responsive.font(context, 13),
                          color: AppColors.textBody,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.s(context, 20)),

                // Gợi ý ngành
                if (careers.isNotEmpty) ...[
                  Text(
                    'Ngành Nghề Phù Hợp',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: Responsive.font(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 12)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: careers.map((c) {
                      return Chip(
                        label: Text(
                          c,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.success),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: Responsive.s(context, 24)),
                ],

                // Nút hỏi thêm AI
                SizedBox(
                  width: double.infinity,
                  height: Responsive.s(context, 48),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            initialContext: {'recommendedCareers': careers},
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum_rounded),
                    label: const Text('Trao Đổi Thêm Với Cố Vấn AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 28)),

                // Đánh giá phản hồi
                Container(
                  padding: EdgeInsets.all(Responsive.s(context, 16)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh Giá Độ Hài Lòng',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 10)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (idx) {
                          return IconButton(
                            icon: Icon(
                              idx < _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.warning,
                              size: 28,
                            ),
                            onPressed: () => setState(() => _rating = idx + 1),
                          );
                        }),
                      ),
                      TextField(
                        controller: _commentController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Nhập ý kiến đóng góp của bạn...',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          border: InputBorder.none,
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 10)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: vm.isSubmittingFeedback
                              ? null
                              : () => _submitFeedback(vm),
                          child: const Text(
                            'Gửi Phản Hồi',
                            style: TextStyle(color: AppColors.success),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
