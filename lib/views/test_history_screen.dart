import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_result.dart';
import '../services/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/compare_viewmodel.dart';
import '../viewmodels/test_history_viewmodel.dart';
import '../views/compare.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      context.read<CompareViewModel>().clear(); // bỏ lựa chọn cũ nếu còn
      context.read<TestHistoryViewModel>().fetchHistory(auth);
    });
  }

  void _toggleSelecting() {
    setState(() => _selecting = !_selecting);
    if (!_selecting) context.read<CompareViewModel>().clear();
  }

  void _onTapItem(TestResult test) {
    final reason = context.read<CompareViewModel>().toggle(test);
    if (reason != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selecting ? 'Chọn 2 bài để so sánh' : 'Lịch Sử Đánh Giá',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _selecting ? 'Hủy chọn' : 'So sánh bài test',
            icon: Icon(
              _selecting ? Icons.close_rounded : Icons.compare_arrows_rounded,
            ),
            onPressed: _toggleSelecting,
          ),
        ],
      ),
      bottomNavigationBar: _selecting ? _buildCompareBar() : null,
      body: Consumer<TestHistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
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
              final raw = vm.historyList[index];
              if (raw is! Map) return const SizedBox.shrink();
              return _buildItem(
                TestResult.fromJson(Map<String, dynamic>.from(raw)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCompareBar() {
    return Consumer<CompareViewModel>(
      builder: (context, cmp, _) {
        final count = cmp.selected.length;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(Responsive.s(context, 12)),
            child: SizedBox(
              height: Responsive.s(context, 48),
              child: ElevatedButton.icon(
                onPressed: cmp.canCompare
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompareScreen(),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: Text(
                  cmp.canCompare
                      ? 'So sánh 2 bài'
                      : 'Chọn 2 bài để so sánh ($count/2)',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(TestResult test) {
    final audience = test.audience == 'freshman'
        ? 'Sinh viên năm nhất'
        : 'Học sinh THPT';
    final status = test.isCompleted ? 'Đã hoàn thành' : 'Đang thực hiện';

    return Consumer<CompareViewModel>(
      builder: (context, cmp, _) {
        final selected = _selecting && cmp.isSelected(test);
        return Opacity(
          opacity: _selecting && !test.isCompleted ? 0.5 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _selecting ? () => _onTapItem(test) : null,
            child: Container(
              padding: EdgeInsets.all(Responsive.s(context, 16)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primaryDark : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (_selecting)
                    Padding(
                      padding: EdgeInsets.only(
                        right: Responsive.s(context, 12),
                      ),
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.textHint,
                      ),
                    ),
                  Icon(
                    test.isCompleted
                        ? Icons.assignment_turned_in_rounded
                        : Icons.pending_actions_rounded,
                    color: test.isCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  SizedBox(width: Responsive.s(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.title,
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
                            if (test.createdAtLabel.isNotEmpty)
                              test.createdAtLabel,
                          ].join(' · '),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.font(context, 11),
                          ),
                        ),
                        if (test.fitScore != null)
                          Text(
                            'Mức độ phù hợp: ${test.fitScore!.toStringAsFixed(0)}%',
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
            ),
          ),
        );
      },
    );
  }
}
