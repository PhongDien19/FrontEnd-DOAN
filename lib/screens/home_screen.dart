import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'dynamic_survey_report_screen.dart' show DynamicSurveyReportScreen;
import 'login_screen.dart';
import 'profile_screen.dart';
import 'assessment_flow_screen.dart';
import 'comprehensive_report_screen.dart';
import 'test_history_screen.dart'; // Import màn hình Lịch sử

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _quickQuestionController = TextEditingController();
  bool _isConsulting = false;
  String? _consultResponse;

  @override
  void dispose() {
    _quickQuestionController.dispose();
    super.dispose();
  }

  void _sendQuickConsult() async {
    final query = _quickQuestionController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isConsulting = true;
      _consultResponse = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userContext = {
      'targetJob': auth.targetJob,
      'educationLevel': auth.educationLevel,
      'age': auth.userProfile?['age'] ?? 18,
      'hobby': auth.hobby,
    };

    final result = await ApiService.consultCareer({
      'question': query,
      'userContext': userContext,
    });

    setState(() {
      _isConsulting = false;
      if (result['success'] == true || result['advice'] != null) {
        _consultResponse = result['advice'];
      } else {
        _consultResponse =
            'Không thể kết nối dịch vụ tư vấn AI. Vui lòng thử lại!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.userProfile;

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F13),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
              SizedBox(height: 20),
              Text(
                'Khởi động Career Pathway...',
                style: TextStyle(
                  color: Color(0xFF888B9B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasHolland = profile != null && profile['hollandScores'] != null;
    final hasPersonality =
        profile != null && profile['personalityScores'] != null;
    final hasCognitive = profile != null && profile['cognitiveScores'] != null;
    final hasValues = profile != null && profile['valuesScores'] != null;

    final completedCount =
        (hasHolland ? 1 : 0) +
        (hasPersonality ? 1 : 0) +
        (hasCognitive ? 1 : 0) +
        (hasValues ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922).withValues(alpha: 0.8),
        elevation: 0,
        title: Text(
          'Career Pathway',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử AI',
            onPressed: () {
              // Đã thêm .toString() để ép kiểu dữ liệu an toàn
              final currentUserId =
                  (auth.userProfile?['id'] ??
                          auth.userProfile?['_id'] ??
                          'mock_user_id')
                      .toString();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TestHistoryScreen(userId: currentUserId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          auth.isAuthenticated
              ? IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Đăng xuất',
                  onPressed: () {
                    auth.logout();
                  },
                )
              : IconButton(
                  icon: const Icon(
                    Icons.login_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                  tooltip: 'Đăng nhập',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
              ),
            ),
          ),

          RefreshIndicator(
            onRefresh: () => auth.refreshProfile(),
            color: const Color(0xFF6C63FF),
            backgroundColor: const Color(0xFF191922),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(
                          0xFF6C63FF,
                        ).withValues(alpha: 0.2),
                        child: Text(
                          auth.fullName.isNotEmpty
                              ? auth.fullName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF888B9B),
                              ),
                            ),
                            Text(
                              auth.fullName.isNotEmpty
                                  ? auth.fullName
                                  : 'Thành viên',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F37C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Đánh Giá Toàn Diện',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$completedCount/4 Bài',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Hoàn thành 4 trụ cột trắc nghiệm: Sở thích (Holland), Tính cách (MBTI), Năng lực và Hệ giá trị để nhận báo cáo hướng nghiệp AI chi tiết.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: completedCount / 4.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ComprehensiveReportScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                completedCount == 4
                                    ? 'Xem Báo Cáo Chi Tiết'
                                    : 'Xem Lộ Trình Đánh Giá',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Khảo Sát Hướng Nghiệp Động AI',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '15 Câu Hỏi',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Khảo sát kịch bản tình huống được AI tạo lập thời gian thực. Đánh giá đa chiều (Holland, Big Five, SCCT) và hỗ trợ chế độ khảo sát ẩn danh.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.75),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DynamicSurveyReportScreen(
                                  sessionId: '',
                                ),
                              ),
                            ).then((_) {
                              if (!context.mounted) {
                                return;
                              }
                              Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).refreshProfile();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Bắt Đầu Đánh Giá Ngay',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.bolt,
                                size: 16,
                                color: Color(0xFFFFD600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Tư Vấn Hướng Nghiệp Nhanh',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191922),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2C2C3E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quickQuestionController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Ví dụ: Học ngành IT ra trường làm gì?',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF5E6072),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (_) => _sendQuickConsult(),
                              ),
                            ),
                            IconButton(
                              icon: _isConsulting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6C63FF),
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Color(0xFF6C63FF),
                                    ),
                              onPressed: _isConsulting
                                  ? null
                                  : _sendQuickConsult,
                            ),
                          ],
                        ),
                        if (_consultResponse != null) ...[
                          const Divider(color: Color(0xFF2C2C3E), height: 24),
                          Text(
                            'AI Phản Hồi:',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF00F2FE),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _consultResponse!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFC3C5E0),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    '4 Trụ Cột Hướng Nghiệp',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildPillarCard(
                        title: 'Holland (Sở thích)',
                        description:
                            'Khám phá nhóm sở thích nghề nghiệp (RIASEC)',
                        icon: Icons.palette_outlined,
                        gradientColors: [
                          const Color(0xFFFF5252),
                          const Color(0xFFFF7A00),
                        ],
                        isCompleted: hasHolland,
                        onPressed: () => _startAssessment('holland'),
                      ),
                      _buildPillarCard(
                        title: 'Tính Cách (MBTI)',
                        description: 'Xác định MBTI & Big 5 đặc trưng bản thân',
                        icon: Icons.psychology_outlined,
                        gradientColors: [
                          const Color(0xFF7C4DFF),
                          const Color(0xFFB388FF),
                        ],
                        isCompleted: hasPersonality,
                        onPressed: () => _startAssessment('personality'),
                      ),
                      _buildPillarCard(
                        title: 'Năng Lực Nhận Thức',
                        description: 'Đánh giá tư duy Logic, Số học & Ngôn ngữ',
                        icon: Icons.lightbulb_outline_rounded,
                        gradientColors: [
                          const Color(0xFF00E676),
                          const Color(0xFF00B0FF),
                        ],
                        isCompleted: hasCognitive,
                        onPressed: () => _startAssessment('cognitive'),
                      ),
                      _buildPillarCard(
                        title: 'Giá Trị Cá Nhân',
                        description:
                            'Xác định các giá trị cốt lõi khi làm việc',
                        icon: Icons.star_border_rounded,
                        gradientColors: [
                          const Color(0xFFFFD600),
                          const Color(0xFFFF8F00),
                        ],
                        isCompleted: hasValues,
                        onPressed: () => _startAssessment('values'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startAssessment(String testType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentFlowScreen(testType: testType),
      ),
    ).then((_) {
      if (!mounted) {
        return;
      }
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    });
  }

  Widget _buildPillarCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isCompleted,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF191922),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? gradientColors[0].withValues(alpha: 0.5)
                : const Color(0xFF2C2C3E),
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gradientColors[0].withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: gradientColors[0], size: 24),
                ),
                if (isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF888B9B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  isCompleted ? 'Xem lại' : 'Bắt đầu',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: gradientColors[0],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: gradientColors[0],
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
