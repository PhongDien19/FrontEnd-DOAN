import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
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

  String _currentMode = 'AI';

  String? _consultResponse;
  Map<String, dynamic>? _consultStructured;

  bool _consultHasError = false;
  String? _consultErrorMessage;
  bool _consultIsNetworkError = false;

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
        SnackBar(
          content: Text(
            'Vui lòng nhập tên ngành nghề hoặc câu hỏi của bạn!',
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      await _promptLoginBeforeConsult(mode);
      if (!mounted) return;
      if (!auth.isAuthenticated) return;
    }

    setState(() {
      _isConsulting = true;
      _consultResponse = null;
      _consultStructured = null;
      _consultHasError = false;
      _consultErrorMessage = null;
      _consultIsNetworkError = false;
      _currentMode = mode;
    });

    final userContext = {
      'targetJob': auth.targetJob,
      'educationLevel': auth.educationLevel,
      'age': auth.userProfile?['age'] ?? 18,
      'hobby': auth.hobby,
      'requestType': mode,
    };

    final result = await ApiService.consultCareer({
      'question': query,
      'userContext': userContext,
    });

    setState(() {
      _isConsulting = false;

      final aiSuccess = result['success'] == true;
      final aiFailed = result['success'] == false;
      final hasAdvice = result['advice'] != null;
      final advice = result['advice'];

      if (aiSuccess && hasAdvice) {
        if (advice is Map<String, dynamic>) {
          _consultStructured = advice;
          _consultResponse = (advice['summary'] is String)
              ? advice['summary'] as String
              : null;
        } else if (advice is String) {
          _consultResponse = advice;
          _consultStructured = null;
        } else {
          _consultResponse = null;
          _consultStructured = null;
          _consultHasError = true;
        }
        _consultHasError = false;
      } else if (aiFailed) {
        _consultResponse = null;
        _consultStructured = null;
        _consultHasError = true;

        final serverMsg = result['errorMessage'] ?? result['message'];
        _consultErrorMessage = (serverMsg is String && serverMsg.isNotEmpty)
            ? serverMsg
            : 'Dịch vụ tư vấn AI tạm thời gián đoạn. Vui lòng thử lại sau giây lát!';

        final msg = _consultErrorMessage!.toLowerCase();
        _consultIsNetworkError =
            !msg.contains('gemini') &&
            !msg.contains('quota') &&
            !msg.contains('ai ') &&
            !msg.contains('tư vấn') &&
            !msg.contains('gián đoạn');
      } else {
        _consultResponse = null;
        _consultStructured = null;
        _consultHasError = true;
        _consultErrorMessage =
            'Phản hồi từ máy chủ không hợp lệ. Vui lòng thử lại!';
        _consultIsNetworkError = false;
      }
    });
  }

  Future<void> _promptLoginBeforeConsult(String mode) async {
    _currentMode = mode;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.s(context, 16)),
        ),
        title: Text(
          'Yêu cầu đăng nhập',
          style: TextStyle(fontSize: Responsive.font(context, 18)),
        ),
        content: Text(
          'Bạn cần đăng nhập để sử dụng tính năng Tư vấn nhanh. '
          'Đăng nhập ngay để nhận gợi ý nghề nghiệp phù hợp với bạn.',
          style: TextStyle(fontSize: Responsive.font(context, 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Để sau',
              style: TextStyle(fontSize: Responsive.font(context, 14)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Đăng nhập',
              style: TextStyle(fontSize: Responsive.font(context, 14)),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (shouldLogin != true) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
              SizedBox(height: Responsive.s(context, 20)),
              Text(
                'Khởi động Career Pathway...',
                style: TextStyle(
                  color: textGray,
                  fontSize: Responsive.font(context, 14),
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
    final hasCognitive =
        profile != null && profile['cognitiveScores'] != null;
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
                fontSize: Responsive.font(context, 22),
                color: textDark,
              ),
            ),
            Text(
              'Pathway',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: Responsive.font(context, 22),
                color: primaryOrange,
              ),
            ),
          ],
        ),
        actions: [
          auth.isAuthenticated
              ? IconButton(
                  icon: Icon(
                    Icons.account_circle_outlined,
                    color: textGray,
                    size: Responsive.s(context, 24),
                  ),
                  tooltip: 'Trang cá nhân',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
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
                      fontSize: Responsive.font(context, 14),
                    ),
                  ),
                ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: Responsive.s(context, 20),
            left: -Responsive.s(context, 100),
            child: Container(
              width: Responsive.s(context, 300),
              height: Responsive.s(context, 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: Responsive.s(context, 50),
            right: -Responsive.s(context, 100),
            child: Container(
              width: Responsive.s(context, 300),
              height: Responsive.s(context, 300),
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
              padding: EdgeInsets.all(Responsive.s(context, 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: Responsive.s(context, 28),
                        backgroundColor: primaryOrange.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          auth.fullName.isNotEmpty
                              ? auth.fullName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.outfit(
                            fontSize: Responsive.font(context, 22),
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.s(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: GoogleFonts.inter(
                                fontSize: Responsive.font(context, 14),
                                color: textGray,
                              ),
                            ),
                            Text(
                              auth.fullName.isNotEmpty
                                  ? auth.fullName
                                  : 'Thành viên',
                              style: GoogleFonts.outfit(
                                fontSize: Responsive.font(context, 20),
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.s(context, 24)),

                  Container(
                    padding: EdgeInsets.all(Responsive.s(context, 24)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        Responsive.s(context, 20),
                      ),
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
                                  fontSize: Responsive.font(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.s(context, 10)),
                        Text(
                          'Hoàn thành 4 trụ cột trắc nghiệm: Sở thích (Holland), Tính cách (MBTI), Năng lực và Hệ giá trị để nhận báo cáo hướng nghiệp AI chi tiết.',
                          style: GoogleFonts.inter(
                            fontSize: Responsive.font(context, 13),
                            color: textGray,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: Responsive.s(context, 20)),
                        LinearProgressIndicator(
                          value: completedCount / 4.0,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryOrange,
                          ),
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 4),
                          ),
                          minHeight: Responsive.s(context, 6),
                        ),
                        SizedBox(height: Responsive.s(context, 20)),

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
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.s(context, 14),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.s(context, 14),
                              ),
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
                                  fontSize: Responsive.font(context, 15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: Responsive.s(context, 8)),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: Responsive.s(context, 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 28)),

                  Text(
                    'Tìm Hiểu Hướng Nghiệp Nhanh',
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 18),
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 12)),
                  Container(
                    padding: EdgeInsets.all(Responsive.s(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        Responsive.s(context, 16),
                      ),
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
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quickQuestionController,
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: Responsive.font(context, 14),
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Nhập ngành nghề (VD: IT, Marketing, Logistics)...',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: Responsive.font(context, 13),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: Responsive.s(context, 8),
                                  ),
                                ),
                                onSubmitted: (_) =>
                                    _sendQuickConsult(mode: 'AI'),
                              ),
                            ),
                            IconButton(
                              icon: _isConsulting && _currentMode == 'AI'
                                  ? SizedBox(
                                      width: Responsive.s(context, 18),
                                      height: Responsive.s(context, 18),
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
                                      size: Responsive.s(context, 22),
                                    ),
                              onPressed: _isConsulting
                                  ? null
                                  : () => _sendQuickConsult(mode: 'AI'),
                            ),
                          ],
                        ),

                        SizedBox(height: Responsive.s(context, 12)),

                        Row(
                          children: [
                            Expanded(
                              child: _buildActionOptionBox(
                                title: 'Học ở đâu?',
                                subtitle: 'Các trường đào tạo',
                                icon: Icons.school_outlined,
                                color: const Color(0xFF3B82F6),
                                isLoading:
                                    _isConsulting && _currentMode == 'HOC',
                                onTap: _isConsulting
                                    ? null
                                    : () => _sendQuickConsult(mode: 'HOC'),
                              ),
                            ),
                            SizedBox(width: Responsive.s(context, 12)),
                            Expanded(
                              child: _buildActionOptionBox(
                                title: 'Làm ở đâu?',
                                subtitle: 'Công ty tuyển dụng',
                                icon: Icons.work_outline_rounded,
                                color: const Color(0xFF10B981),
                                isLoading:
                                    _isConsulting && _currentMode == 'LAM',
                                onTap: _isConsulting
                                    ? null
                                    : () => _sendQuickConsult(mode: 'LAM'),
                              ),
                            ),
                          ],
                        ),

                        if (_consultResponse != null ||
                            _consultStructured != null ||
                            _consultHasError) ...[
                          Divider(
                            color: const Color(0xFFE5E7EB),
                            height: Responsive.s(context, 24),
                          ),

                          if (!_consultHasError)
                            Row(
                              children: [
                                Icon(
                                  _currentMode == 'HOC'
                                      ? Icons.school
                                      : (_currentMode == 'LAM'
                                            ? Icons.work
                                            : Icons.auto_awesome),
                                  size: Responsive.s(context, 16),
                                  color: primaryOrange,
                                ),
                                SizedBox(width: Responsive.s(context, 6)),
                                Text(
                                  _currentMode == 'HOC'
                                      ? 'Danh Sách Trường Đào Tạo:'
                                      : (_currentMode == 'LAM'
                                            ? 'Công Ty & Nhu Cầu Tuyển Dụng:'
                                            : 'AI Phản Hồi:'),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.font(context, 14),
                                    color: primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          if (!_consultHasError)
                            SizedBox(height: Responsive.s(context, 8)),

                          if (_consultHasError)
                            _buildErrorBox(
                              title: _consultIsNetworkError
                                  ? 'Mất kết nối tới máy chủ'
                                  : 'Dịch vụ tư vấn AI tạm thời gián đoạn',
                              message: _consultErrorMessage ??
                                  'Không thể kết nối dịch vụ tư vấn AI. Vui lòng thử lại sau giây lát!',
                            )
                          else ...[
                            if (_currentMode != 'AI' &&
                                _consultResponse != null &&
                                _consultResponse!.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(
                                  Responsive.s(context, 12),
                                ),
                                margin: EdgeInsets.only(
                                  bottom: Responsive.s(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.s(context, 12),
                                  ),
                                  border: Border.all(
                                    color: primaryOrange.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _consultResponse!,
                                  style: GoogleFonts.inter(
                                    fontSize: Responsive.font(context, 13),
                                    color: textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                            if (_currentMode == 'HOC' &&
                                _consultStructured != null)
                              _buildSchoolList(_consultStructured!),

                            if (_currentMode == 'LAM' &&
                                _consultStructured != null)
                              _buildCompanyList(_consultStructured!),

                            if (_currentMode == 'AI' &&
                                _consultResponse != null &&
                                _consultStructured == null)
                              Container(
                                padding: EdgeInsets.all(
                                  Responsive.s(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.s(context, 12),
                                  ),
                                ),
                                child: Text(
                                  _consultResponse!,
                                  style: GoogleFonts.inter(
                                    fontSize: Responsive.font(context, 13),
                                    color: textGray,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 28)),

                  Text(
                    '4 Trụ Cột Hướng Nghiệp',
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 18),
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 16)),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Responsive.s(context, 16),
                    crossAxisSpacing: Responsive.s(context, 16),
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
                        description:
                            'Xác định MBTI & Big 5 đặc trưng bản thân',
                        icon: Icons.psychology_outlined,
                        accentColor: const Color(0xFF7C4DFF),
                        isCompleted: hasPersonality,
                      ),
                      _buildPillarCard(
                        title: 'Năng Lực Nhận Thức',
                        description:
                            'Đánh giá tư duy Logic, Số học & Ngôn ngữ',
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
                  SizedBox(height: Responsive.s(context, 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolList(Map<String, dynamic> data) {
    final raw = data['schools'];
    final schools = (raw is List)
        ? raw.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    if (schools.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        text:
            'Chưa có dữ liệu trường đào tạo. Vui lòng thử lại với từ khóa khác.',
      );
    }

    final blue = const Color(0xFF3B82F6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: schools.map((s) {
        final name = (s['schoolName'] ?? 'Trường chưa rõ').toString();
        final major = (s['major'] ?? '').toString();
        final loc = (s['location'] ?? '').toString();
        final desc = (s['description'] ?? '').toString();
        final benchmark = (s['benchmarks'] ?? 'Đang cập nhật').toString();
        final official = (s['officialLink'] ?? '').toString();
        final admission = (s['admissionLink'] ?? '').toString();

        return Container(
          margin: EdgeInsets.only(bottom: Responsive.s(context, 12)),
          padding: EdgeInsets.all(Responsive.s(context, 14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 14),
            ),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: Responsive.s(context, 40),
                    height: Responsive.s(context, 40),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        Responsive.s(context, 10),
                      ),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: blue,
                      size: Responsive.s(context, 22),
                    ),
                  ),
                  SizedBox(width: Responsive.s(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.font(context, 15),
                            color: textDark,
                          ),
                        ),
                        if (major.isNotEmpty)
                          Text(
                            'Ngành: $major',
                            style: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 12),
                              color: blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (loc.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: Responsive.s(context, 2),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: Responsive.s(context, 12),
                                  color: const Color(0xFF6B7280),
                                ),
                                SizedBox(width: Responsive.s(context, 3)),
                                Text(
                                  loc,
                                  style: GoogleFonts.inter(
                                    fontSize: Responsive.font(context, 11),
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                SizedBox(height: Responsive.s(context, 8)),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 12),
                    color: textGray,
                    height: 1.4,
                  ),
                ),
              ],
              SizedBox(height: Responsive.s(context, 10)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.s(context, 10)),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      size: Responsive.s(context, 14),
                      color: blue,
                    ),
                    SizedBox(width: Responsive.s(context, 6)),
                    Expanded(
                      child: Text(
                        'Điểm chuẩn: $benchmark',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          color: blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (official.isNotEmpty || admission.isNotEmpty) ...[
                SizedBox(height: Responsive.s(context, 8)),
                Wrap(
                  spacing: Responsive.s(context, 8),
                  children: [
                    if (official.isNotEmpty)
                      _buildLinkChip(
                        icon: Icons.language_rounded,
                        label: 'Trang chủ',
                        color: blue,
                        url: official,
                      ),
                    if (admission.isNotEmpty)
                      _buildLinkChip(
                        icon: Icons.app_registration_rounded,
                        label: 'Tuyển sinh',
                        color: primaryOrange,
                        url: admission,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanyList(Map<String, dynamic> data) {
    final raw = data['companies'];
    final companies = (raw is List)
        ? raw.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    if (companies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline_rounded,
        text:
            'Chưa có dữ liệu công ty tuyển dụng. Vui lòng thử lại với từ khóa khác.',
      );
    }

    final green = const Color(0xFF10B981);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: companies.map((c) {
        final name = (c['companyName'] ?? 'Công ty chưa rõ').toString();
        final industry = (c['industry'] ?? '').toString();
        final loc = (c['location'] ?? '').toString();
        final desc = (c['description'] ?? '').toString();
        final positions = (c['positions'] ?? 'Đang cập nhật').toString();
        final careerLink = (c['careerLink'] ?? '').toString();
        final demand = (c['demandLevel'] ?? '').toString();

        Color demandColor = const Color(0xFF6B7280);
        if (demand.toLowerCase().contains('cao')) {
          demandColor = green;
        } else if (demand.toLowerCase().contains('đang tuyển')) {
          demandColor = primaryOrange;
        }

        return Container(
          margin: EdgeInsets.only(bottom: Responsive.s(context, 12)),
          padding: EdgeInsets.all(Responsive.s(context, 14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 14),
            ),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: Responsive.s(context, 40),
                    height: Responsive.s(context, 40),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        Responsive.s(context, 10),
                      ),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: green,
                      size: Responsive.s(context, 22),
                    ),
                  ),
                  SizedBox(width: Responsive.s(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.font(context, 15),
                            color: textDark,
                          ),
                        ),
                        if (industry.isNotEmpty)
                          Text(
                            industry,
                            style: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 12),
                              color: green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (loc.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: Responsive.s(context, 2),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: Responsive.s(context, 12),
                                  color: const Color(0xFF6B7280),
                                ),
                                SizedBox(width: Responsive.s(context, 3)),
                                Expanded(
                                  child: Text(
                                    loc,
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.font(context, 11),
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (demand.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 8),
                        vertical: Responsive.s(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: demandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 20),
                        ),
                      ),
                      child: Text(
                        demand,
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 10),
                          color: demandColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                SizedBox(height: Responsive.s(context, 8)),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 12),
                    color: textGray,
                    height: 1.4,
                  ),
                ),
              ],
              SizedBox(height: Responsive.s(context, 10)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.s(context, 10)),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: Responsive.s(context, 14),
                      color: green,
                    ),
                    SizedBox(width: Responsive.s(context, 6)),
                    Expanded(
                      child: Text(
                        'Vị trí: $positions',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          color: green,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (careerLink.isNotEmpty) ...[
                SizedBox(height: Responsive.s(context, 8)),
                _buildLinkChip(
                  icon: Icons.open_in_new_rounded,
                  label: 'Xem trang tuyển dụng',
                  color: green,
                  url: careerLink,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLinkChip({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () async {
        try {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.s(context, 10),
          vertical: Responsive.s(context, 6),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 8),
          ),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.s(context, 13), color: color),
            SizedBox(width: Responsive.s(context, 4)),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: Responsive.font(context, 11),
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox({required String message, String? title}) {
    final lowerMsg = message.toLowerCase();
    final isQuotaIssue = lowerMsg.contains('quota') ||
        lowerMsg.contains('429') ||
        lowerMsg.contains('too many requests') ||
        lowerMsg.contains('rate limit') ||
        lowerMsg.contains('vượt quá') ||
        lowerMsg.contains('giới hạn');
    final hint = isQuotaIssue
        ? 'API Gemini miễn phí hiện đã hết hạn mức trong ngày. Vui lòng thử lại sau hoặc vào ngày mai.'
        : 'Vui lòng kiểm tra kết nối mạng hoặc thử lại sau ít phút.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(
          Responsive.s(context, 12),
        ),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isQuotaIssue
                    ? Icons.hourglass_top_rounded
                    : Icons.error_outline_rounded,
                color: const Color(0xFFDC2626),
                size: Responsive.s(context, 20),
              ),
              SizedBox(width: Responsive.s(context, 8)),
              Expanded(
                child: Text(
                  title ??
                      (isQuotaIssue
                          ? 'API tạm hết hạn mức miễn phí'
                          : 'Không thể kết nối tư vấn AI'),
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 13),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 6)),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 12),
              color: const Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
          SizedBox(height: Responsive.s(context, 8)),
          Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 12),
              fontStyle: FontStyle.italic,
              color: const Color(0xFF7F1D1D),
              height: 1.4,
            ),
          ),
          SizedBox(height: Responsive.s(context, 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _isConsulting
                    ? null
                    : () => _sendQuickConsult(mode: _currentMode),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF991B1B),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.s(context, 12),
                    vertical: Responsive.s(context, 6),
                  ),
                  minimumSize: Size(0, Responsive.s(context, 32)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.refresh_rounded,
                  size: Responsive.s(context, 16),
                ),
                label: Text(
                  'Thử lại',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(
          Responsive.s(context, 12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: Responsive.s(context, 32),
            color: const Color(0xFF9CA3AF),
          ),
          SizedBox(height: Responsive.s(context, 8)),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 12),
              color: textGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

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
      borderRadius: BorderRadius.circular(Responsive.s(context, 12)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.s(context, 10),
          vertical: Responsive.s(context, 10),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 12),
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.s(context, 8)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 8),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: Responsive.s(context, 18),
                      height: Responsive.s(context, 18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: Responsive.s(context, 18),
                    ),
            ),
            SizedBox(width: Responsive.s(context, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 13),
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: Responsive.font(context, 10),
                      color: textGray,
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

  Widget _buildPillarCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isCompleted,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.s(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.s(context, 20),
        ),
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
                padding: EdgeInsets.all(Responsive.s(context, 8)),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 12),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: Responsive.s(context, 24),
                ),
              ),
              if (isCompleted)
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: Responsive.s(context, 20),
                ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 14)),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: Responsive.font(context, 15),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: Responsive.s(context, 6)),
          Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 11),
              color: const Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
