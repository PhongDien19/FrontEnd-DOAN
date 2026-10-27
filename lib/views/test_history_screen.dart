import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import '../viewmodels/test_history_viewmodels.dart';

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
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Lịch Sử Kiểm Tra',
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<TestHistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (vm.historyList.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa thực hiện bài kiểm tra nào.',
                style: TextStyle(color: Color(0xFF888B9B)),
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
              final title = item['testName'] ?? 'Bài Kiểm Tra';
              final date = item['createdAt'] ?? '';

              return Container(
                padding: EdgeInsets.all(Responsive.s(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFF191922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Color(0xFF00F5A0),
                    ),
                    SizedBox(width: Responsive.s(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.font(context, 14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (date.toString().isNotEmpty)
                            Text(
                              date.toString(),
                              style: TextStyle(
                                color: const Color(0xFF888B9B),
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
