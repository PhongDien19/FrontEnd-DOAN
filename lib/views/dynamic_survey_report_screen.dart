import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive.dart';
import '../viewmodels/dynamic_survey_report_viewmodels.dart';
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
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn phản hồi của bạn!'),
          backgroundColor: Color(0xFF00F5A0),
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
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Kết Quả Khảo Sát Động',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                    color: const Color(0xFF191922),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF00F5A0),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đánh Giá Từ AI',
                            style: TextStyle(
                              color: Colors.white,
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
                          color: const Color(0xFFD1D5DB),
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
                      color: Colors.white,
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
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF191922),
                        side: const BorderSide(color: Color(0xFF00F5A0)),
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
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 28)),

                // Đánh giá phản hồi
                Container(
                  padding: EdgeInsets.all(Responsive.s(context, 16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191922),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh Giá Độ Hài Lòng',
                        style: TextStyle(
                          color: Colors.white,
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
                              color: const Color(0xFFFFD166),
                              size: 28,
                            ),
                            onPressed: () => setState(() => _rating = idx + 1),
                          );
                        }),
                      ),
                      TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Nhập ý kiến đóng góp của bạn...',
                          hintStyle: TextStyle(color: Color(0xFF5E6072)),
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
                            style: TextStyle(color: Color(0xFF00F5A0)),
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
