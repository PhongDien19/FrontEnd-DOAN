import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import 'dynamic_survey_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _quickQuestionController = TextEditingController();
  bool _isConsulting = false;
  String? _consultResponse;

  // State nhận diện chế độ tư vấn: 'AI' (chung), 'HOC' (trường học), 'LAM' (công ty)
  String _currentMode = 'AI';

  // Định nghĩa bảng màu Light Mode
  final Color primaryOrange = const Color(0xFFF59E0B);
  final Color bgColor = const Color(0xFFFAFAFA);
  final Color textDark = const Color(0xFF1F2937);
  final Color textGray = const Color(0xFF4B5563);

  @override
  void dispose() {
    _quickQuestionController.dispose();
    super.dispose();
  }

  void _sendQuickConsult({String mode = 'AI'}) async {
    final query = _quickQuestionController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên ngành nghề hoặc câu hỏi của bạn!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isConsulting = true;
      _consultResponse = null;
      _currentMode = mode; // Lưu chế độ đang truy vấn
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userContext = {
      'targetJob': auth.targetJob,
      'educationLevel': auth.educationLevel,
      'age': auth.userProfile?['age'] ?? 18,
      'hobby': auth.hobby,
      'requestType':
          mode, // Gửi xuống API để AI/Backend biết yêu cầu Học hay Làm
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
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
              ),
              const SizedBox(height: 20),
              Text(
                'Khởi động Career Pathway...',
                style: TextStyle(
                  color: textGray,
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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        title: Row(
          children: [
            Text(
              'Career ',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: textDark,
              ),
            ),
            Text(
              'Pathway',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: primaryOrange,
              ),
            ),
          ],
        ),
        actions: [
          auth.isAuthenticated
              ? IconButton(
                  icon: Icon(Icons.account_circle_outlined, color: textGray),
                  tooltip: 'Trang cá nhân',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                )
              : TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(
                    'Đăng nhập',
                    style: GoogleFonts.outfit(
                      color: primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
        ],
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: 20,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withValues(alpha: 0.03),
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
                color: primaryOrange.withValues(alpha: 0.03),
              ),
            ),
          ),

          RefreshIndicator(
            onRefresh: () => auth.refreshProfile(),
            color: primaryOrange,
            backgroundColor: Colors.white,
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
                        backgroundColor: primaryOrange.withValues(alpha: 0.15),
                        child: Text(
                          auth.fullName.isNotEmpty
                              ? auth.fullName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
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
                                color: textGray,
                              ),
                            ),
                            Text(
                              auth.fullName.isNotEmpty
                                  ? auth.fullName
                                  : 'Thành viên',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Thẻ: Đánh Giá Toàn Diện
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
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
                                  color: textDark,
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
                            color: textGray,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: completedCount / 4.0,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryOrange,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 20),

                        // Nút Cam chính: Chuyển sang DynamicSurveyScreen()
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DynamicSurveyScreen(),
                              ),
                            ).then((_) {
                              if (!context.mounted) return;
                              Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).refreshProfile();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                completedCount == 4
                                    ? 'Xem Báo Cáo Chi Tiết'
                                    : 'Bắt đầu khảo sát',
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

                  // Khung chat tư vấn hướng nghiệp nhanh
                  Text(
                    'Tư Vấn Hướng Nghiệp Nhanh',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Ô nhập từ khoá ngành nghề hoặc câu hỏi
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quickQuestionController,
                                style: TextStyle(color: textDark, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Nhập ngành nghề (VD: IT, Marketing, Logistics)...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (_) =>
                                    _sendQuickConsult(mode: 'AI'),
                              ),
                            ),
                            IconButton(
                              icon: _isConsulting && _currentMode == 'AI'
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              primaryOrange,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: primaryOrange,
                                    ),
                              onPressed: _isConsulting
                                  ? null
                                  : () => _sendQuickConsult(mode: 'AI'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 2. Hai Option Box: HỌC & LÀM
                        Row(
                          children: [
                            // Option 1: HỌC Ở ĐÂU? (Trường học)
                            Expanded(
                              child: _buildActionOptionBox(
                                title: 'Học ở đâu?',
                                subtitle: 'Các trường đào tạo',
                                icon: Icons.school_outlined,
                                color: const Color(
                                  0xFF3B82F6,
                                ), // Màu xanh dương
                                isLoading:
                                    _isConsulting && _currentMode == 'HOC',
                                onTap: _isConsulting
                                    ? null
                                    : () => _sendQuickConsult(mode: 'HOC'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Option 2: LÀM Ở ĐÂU? (Việc làm, công ty)
                            Expanded(
                              child: _buildActionOptionBox(
                                title: 'Làm ở đâu?',
                                subtitle: 'Công ty tuyển dụng',
                                icon: Icons.work_outline_rounded,
                                color: const Color(0xFF10B981), // Màu xanh lá
                                isLoading:
                                    _isConsulting && _currentMode == 'LAM',
                                onTap: _isConsulting
                                    ? null
                                    : () => _sendQuickConsult(mode: 'LAM'),
                              ),
                            ),
                          ],
                        ),

                        // 3. Phản hồi từ AI
                        if (_consultResponse != null) ...[
                          const Divider(color: Color(0xFFE5E7EB), height: 24),
                          Row(
                            children: [
                              Icon(
                                _currentMode == 'HOC'
                                    ? Icons.school
                                    : (_currentMode == 'LAM'
                                          ? Icons.work
                                          : Icons.auto_awesome),
                                size: 16,
                                color: primaryOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentMode == 'HOC'
                                    ? 'Danh Sách Trường Đào Tạo:'
                                    : (_currentMode == 'LAM'
                                          ? 'Công Ty & Nhu Cầu Tuyển Dụng:'
                                          : 'AI Phản Hồi:'),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _consultResponse!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textGray,
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
                      color: textDark,
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
                        accentColor: const Color(0xFFFF7A00),
                        isCompleted: hasHolland,
                      ),
                      _buildPillarCard(
                        title: 'Tính Cách (MBTI)',
                        description: 'Xác định MBTI & Big 5 đặc trưng bản thân',
                        icon: Icons.psychology_outlined,
                        accentColor: const Color(0xFF7C4DFF),
                        isCompleted: hasPersonality,
                      ),
                      _buildPillarCard(
                        title: 'Năng Lực Nhận Thức',
                        description: 'Đánh giá tư duy Logic, Số học & Ngôn ngữ',
                        icon: Icons.lightbulb_outline_rounded,
                        accentColor: const Color(0xFF00B0FF),
                        isCompleted: hasCognitive,
                      ),
                      _buildPillarCard(
                        title: 'Giá Trị Cá Nhân',
                        description:
                            'Xác định các giá trị cốt lõi khi làm việc',
                        icon: Icons.star_border_rounded,
                        accentColor: const Color(0xFFFFD600),
                        isCompleted: hasValues,
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

  // Widget hỗ trợ tạo Option Box (Học / Làm)
  Widget _buildActionOptionBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10, color: textGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? accentColor.withValues(alpha: 0.5)
              : const Color(0xFFE5E7EB),
          width: isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
