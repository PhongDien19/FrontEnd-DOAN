import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/test_history_viewmodel.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      context.read<TestHistoryViewModel>().fetchHistory(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Lịch Sử Đánh Giá',
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
      body: Consumer<TestHistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (vm.historyList.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa thực hiện bài kiểm tra nào.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(Responsive.s(context, 16)),
            itemCount: vm.historyList.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: Responsive.s(context, 10)),
            itemBuilder: (context, index) {
              final item = vm.historyList[index];
              final title = item['flow'] == 'flow_b'
                  ? 'Đánh giá ngành mục tiêu'
                  : 'Khám phá ngành phù hợp';
              final date = item['createdAt'] ?? '';
              final audience = item['audience'] == 'freshman'
                  ? 'Sinh viên năm nhất'
                  : 'Học sinh THPT';
              final status = item['status'] == 'completed'
                  ? 'Đã hoàn thành'
                  : 'Đang thực hiện';
              final result = item['result'];
              final fitScore = result is Map ? result['fitScore'] : null;

              return Container(
                padding: EdgeInsets.all(Responsive.s(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['status'] == 'completed'
                          ? Icons.assignment_turned_in_rounded
                          : Icons.pending_actions_rounded,
                      color: item['status'] == 'completed'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    SizedBox(width: Responsive.s(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: Responsive.font(context, 14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            [
                              audience,
                              status,
                              if (date.toString().isNotEmpty) date.toString(),
                            ].join(' · '),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: Responsive.font(context, 11),
                            ),
                          ),
                          if (fitScore != null)
                            Text(
                              'Mức độ phù hợp: $fitScore%',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: Responsive.font(context, 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
