import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/home_viewmodel.dart';
import 'assessment_flow_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'test_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      context.read<HomeViewModel>().fetchDashboardData(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.s(context, 6)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(width: Responsive.s(context, 10)),
            Text(
              'Hướng Nghiệp AI',
              style: TextStyle(
                fontSize: Responsive.font(context, 16),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              auth.isAuthenticated ? Icons.person_rounded : Icons.login_rounded,
              color: auth.isAuthenticated
                  ? AppColors.success
                  : AppColors.textPrimary,
            ),
            tooltip: auth.isAuthenticated ? 'Hồ Sơ' : 'Đăng Nhập',
            onPressed: () {
              if (auth.isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.s(context, 16)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.contentMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner chào mừng
                  _buildWelcomeBanner(context, auth),
                  SizedBox(height: Responsive.s(context, 20)),

                  _buildAssessmentCard(context),
                  SizedBox(height: Responsive.s(context, 24)),

                  Text(
                    'Các phần trong bài đánh giá',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 12)),
                  _buildPillarGrid(context),
                  SizedBox(height: Responsive.s(context, 24)),

                  // Lịch sử đánh giá gần đây
                  if (auth.isAuthenticated) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kết Quả Gần Đây',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TestHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.s(context, 8)),
                    _buildRecentHistoryList(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, AuthProvider auth) {
    final name = auth.isAuthenticated && auth.fullName.isNotEmpty
        ? auth.fullName
        : 'Bạn';

    return Container(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào, $name! 👋',
            style: TextStyle(
              fontSize: Responsive.font(context, 20),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: Responsive.s(context, 6)),
          Text(
            'Khám phá tiềm năng cá nhân và định hình lộ trình sự nghiệp tối ưu cùng AI.',
            style: TextStyle(
              fontSize: Responsive.font(context, 13),
              color: AppColors.textPrimary.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.s(context, 12)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: AppColors.success,
              size: Responsive.s(context, 28),
            ),
          ),
          SizedBox(width: Responsive.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh Giá Hướng Nghiệp Toàn Diện',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.s(context, 4)),
                Text(
                  'Trả lời từng phần để nhận gợi ý ngành phù hợp từ hệ thống',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 11),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssessmentFlowScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 12),
                vertical: Responsive.s(context, 8),
              ),
            ),
            child: const Text(
              'Bắt đầu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarGrid(BuildContext context) {
    final pillars = [
      {
        'title': 'Hồ sơ học tập',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'title': 'Tính cách',
        'icon': Icons.psychology_alt_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Sở thích nghề nghiệp',
        'icon': Icons.palette_rounded,
        'color': AppColors.error,
      },
      {
        'title': 'Năng lực ngoại ngữ',
        'icon': Icons.translate_rounded,
        'color': AppColors.warning,
      },
      {
        'title': 'Cơ hội nghề nghiệp',
        'icon': Icons.work_outline_rounded,
        'color': AppColors.success,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pillars.length,
      itemBuilder: (context, index) {
        final p = pillars[index];
        return Container(
          padding: EdgeInsets.all(Responsive.s(context, 14)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                p['icon'] as IconData,
                color: p['color'] as Color,
                size: Responsive.s(context, 26),
              ),
              Text(
                p['title'] as String,
                style: TextStyle(
                  fontSize: Responsive.font(context, 13),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentHistoryList(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (vm.recentHistory.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.s(context, 16)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Chưa có bài kiểm tra nào được thực hiện.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.font(context, 12),
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return Column(
          children: vm.recentHistory.map((item) {
            final flow = item['flow'] == 'flow_b'
                ? 'Đánh giá ngành mục tiêu'
                : 'Khám phá ngành phù hợp';
            final audience = item['audience'] == 'freshman'
                ? 'Sinh viên năm nhất'
                : 'Học sinh THPT';
            final date = item['createdAt'] ?? '';
            return Container(
              margin: EdgeInsets.only(bottom: Responsive.s(context, 8)),
              padding: EdgeInsets.all(Responsive.s(context, 12)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    item['status'] == 'completed'
                        ? Icons.check_circle_rounded
                        : Icons.pending_outlined,
                    color: item['status'] == 'completed'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  SizedBox(width: Responsive.s(context, 10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flow,
                          style: TextStyle(
                            fontSize: Responsive.font(context, 13),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$audience · ${item['status'] == 'completed' ? 'Đã hoàn thành' : 'Đang thực hiện'}',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 10),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date.toString(),
                            style: TextStyle(
                              fontSize: Responsive.font(context, 10),
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
