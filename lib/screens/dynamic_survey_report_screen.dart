import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

enum CareerPath { study, work }

class DynamicSurveyReportScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? initialReport;

  /// Hướng đi người dùng đã chọn ngay từ form nhập thông tin:
  /// 'study' (Đi học) hoặc 'work' (Đi Làm). Áp dụng cho Discovery mode.
  /// Targeted mode bỏ qua tham số này.
  final String selectedPath;

  const DynamicSurveyReportScreen({
    super.key,
    required this.sessionId,
    this.initialReport,
    this.selectedPath = 'study',
  });

  @override
  State<DynamicSurveyReportScreen> createState() =>
      _DynamicSurveyReportScreenState();
}

class _DynamicSurveyReportScreenState extends State<DynamicSurveyReportScreen> {
  late Map<String, dynamic> _report;
  bool _feedbackSent = false;
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSendingFeedback = false;

  // Hướng đi lấy trực tiếp từ tham số widget (đã được user chọn từ form).
  // Trước đây dùng state nội bộ + filter 2 tab để đổi, nay bỏ filter.
  CareerPath get _selectedPath =>
      widget.selectedPath == 'work' ? CareerPath.work : CareerPath.study;

  @override
  void initState() {
    super.initState();
    _report = widget.initialReport ?? {};
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Ép kiểu an toàn: chuyển bất kỳ giá trị dynamic nào về String, tránh crash khi AI
  // trả về dữ liệu không đúng schema (number, Map, List...).
  static String _safeString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    if (v is num) return v.toString();
    if (v is bool) return v.toString();
    if (v is List) return fallback;
    if (v is Map) return fallback;
    return v.toString();
  }

  static List<String> _safeStringList(dynamic v, {List<String> fallback = const []}) {
    if (v == null) return List<String>.from(fallback);
    if (v is List) {
      final result = <String>[];
      for (final item in v) {
        if (item is String) {
          result.add(item);
        } else if (item is Map) {
          final name = item['companyName'] ?? item['name'];
          if (name is String) result.add(name);
        }
        // bỏ qua các kiểu khác (num, bool, List lồng) để tránh render crash
      }
      return result;
    }
    return List<String>.from(fallback);
  }

  static Map<String, dynamic>? _safeMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  void _submitFeedback() async {
    setState(() {
      _isSendingFeedback = true;
    });

    final res = await ApiService.feedbackSurvey(
      widget.sessionId,
      _rating,
      _commentController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSendingFeedback = false;
      if (res['success'] == true) {
        _feedbackSent = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['success'] == true
              ? 'Cảm ơn phản hồi của bạn!'
              : (res['message'] ?? 'Lỗi gửi phản hồi.'),
        ),
        backgroundColor: res['success'] == true
            ? Colors.green
            : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (_report.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Báo Cáo AI',
            style: GoogleFonts.outfit(color: Colors.black87),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy dữ liệu báo cáo.',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    final double rawScore =
        double.tryParse(_report['score']?.toString() ?? '0') ?? 0.0;
    final String status = _report['status'] ?? 'Failed';
    final bool isPassed = status.toLowerCase() == 'passed' || rawScore > 3.0;

    final Color statusColor = isPassed
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);

    final summary = _safeString(_report['summary']);
    final strengths = _safeStringList(_report['strengths']);
    final weaknesses = _safeStringList(_report['weaknesses']);
    final advice = _safeString(_report['advice']);

    final roadmap = _safeStringList(_report['roadmap']);
    final certificates = _safeStringList(_report['certificates']);
    final onetMatches = _safeStringList(_report['onetMatches']);

    final String mode = _safeString(_report['mode']);
    final String targetCareer = _safeString(_report['targetCareer'] ?? _report['careerName'] ?? _report['career'] ?? '');
    final compatibleCareers =
        (_report['compatibleCareers'] is List) ? (_report['compatibleCareers'] as List) : <dynamic>[];
    final String basicSalary = _safeString(_report['basicSalary']);
    final String laborMarket = _safeString(_report['laborMarket']);
    final trainingInstitutions =
        (_report['trainingInstitutions'] is List || _report['schools'] is List)
            ? (_report['trainingInstitutions'] ?? _report['schools']) as List
            : <dynamic>[];
    final targetCompanies =
        (_report['companies'] is List || _report['companyDetails'] is List)
            ? (_report['companies'] ?? _report['companyDetails']) as List
            : <dynamic>[];

    String displayMode = mode;
    if (displayMode.isEmpty) {
      if (compatibleCareers.isNotEmpty) {
        displayMode = 'Discovery';
      } else if (roadmap.isNotEmpty ||
          basicSalary.isNotEmpty ||
          laborMarket.isNotEmpty) {
        displayMode = 'Targeted';
      } else {
        displayMode = 'Discovery';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Báo Cáo Khảo Sát Động AI',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner nhắc đăng nhập
                if (!authProvider.isAuthenticated) ...[
                  _buildLoginBanner(),
                  const SizedBox(height: 20),
                ],

                // ========== ĐIỂM PHÙ HỢP TỔNG QUAN ==========
                if (displayMode.toLowerCase() != 'discovery') ...[
                  _buildMatchScoreCard(rawScore, status, isPassed, statusColor, targetCareer),
                  const SizedBox(height: 20),
                ],

                // ========== THỨ TỰ HIỂN THỊ THỐNG NHẤT (áp dụng cho cả Discovery & Targeted) ==========
// 1. Filter Đi học / Đi làm (chỉ Discovery)
// 2. Điểm Mạnh & Tố Chất Cần Rèn (đầu trang)
// 3. Lời nói ngắn / Người dùng thể hiện
// 4. Lộ trình phát triển
// 5. Cơ hội việc làm / Trường đào tạo
// 6. Lời khuyên hướng nghiệp

// 2. ĐIỂM MẠNH & TỐ CHẤT CẦN RÈN — luôn ở trên cùng
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: _buildListItemBox(
        title: 'Điểm Mạnh',
        items: strengths,
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF059669),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: _buildListItemBox(
        title: 'Tố Chất Cần Rèn',
        items: weaknesses,
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
      ),
    ),
  ],
),
const SizedBox(height: 20),

// 3. LỜI NÓI NGẮN / NGƯỜI DÙNG THỂ HIỆN
if (summary.isNotEmpty) ...[
  _buildUserExpressedCard(summary, displayMode),
  const SizedBox(height: 20),
],

// 4. LỘ TRÌNH PHÁT TRIỂN — hiển thị cho cả Discovery & Targeted (dùng chung 1 card)
if (roadmap.isNotEmpty) ...[
  _buildCard(
    title: 'Lộ Trình Phát Triển',
    icon: Icons.trending_up_rounded,
    iconColor: displayMode.toLowerCase() == 'discovery' &&
            _selectedPath == CareerPath.work
        ? const Color(0xFF059669)
        : const Color(0xFF0284C7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(roadmap.length, (idx) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor:
                      const Color(0xFF0284C7).withValues(alpha: 0.1),
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (idx < roadmap.length - 1)
                  Container(
                    width: 1.5,
                    height: 35,
                    color: const Color(0xFFE5E7EB),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  roadmap[idx],
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    ),
  ),
  const SizedBox(height: 20),
],

// 5. CƠ HỘI VIỆC LÀM / TRƯỜNG ĐÀO TẠO
if (displayMode.toLowerCase() == 'discovery' &&
    compatibleCareers.isNotEmpty) ...[
  // Badge thông báo hướng đi đã chọn từ form (thay cho filter 2 tab cũ)
  _buildSelectedPathBadge(),
  const SizedBox(height: 16),
  // Discovery: hiển thị theo hướng đã chọn (trường đào tạo cho Đi học, thị trường tuyển dụng cho Đi Làm)
  _buildDiscoverySection(compatibleCareers),
  const SizedBox(height: 20),
] else ...[
  // Targeted: hiển thị các thông tin về ngành nghề mục tiêu
  if (certificates.isNotEmpty) ...[
    _buildCard(
      title: 'Chứng Chỉ Cần Thiết',
      icon: Icons.school_outlined,
      iconColor: const Color(0xFF9333EA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: certificates
            .map(
              (cert) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: Color(0xFF9333EA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert,
                        style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
    const SizedBox(height: 20),
  ],
  if (onetMatches.isNotEmpty) ...[
    _buildCard(
      title: 'Cơ Hội Việc Làm (O*NET)',
      icon: Icons.work_history_outlined,
      iconColor: const Color(0xFFEA580C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: onetMatches
            .map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_border_rounded,
                      size: 16,
                      color: Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job,
                        style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
    const SizedBox(height: 20),
  ],
  if (basicSalary.isNotEmpty) ...[
    _buildCard(
      title: 'Mức Lương Cơ Bản tại Việt Nam',
      icon: Icons.monetization_on_outlined,
      iconColor: const Color(0xFF059669),
      child: Text(
        basicSalary,
        style: GoogleFonts.inter(
          color: const Color(0xFF4B5563),
          fontSize: 13,
          height: 1.4,
        ),
      ),
    ),
    const SizedBox(height: 20),
  ],
  if (laborMarket.isNotEmpty) ...[
    _buildCard(
      title: 'Thị Trường Lao Động tại Việt Nam',
      icon: Icons.bar_chart_rounded,
      iconColor: const Color(0xFFEA580C),
      child: Text(
        laborMarket,
        style: GoogleFonts.inter(
          color: const Color(0xFF4B5563),
          fontSize: 13,
          height: 1.4,
        ),
      ),
    ),
    const SizedBox(height: 20),
  ],
    if (trainingInstitutions.isNotEmpty) ...[
      _buildCard(
        title: 'Trường Đào Tạo Đề Xuất',
        icon: Icons.school_rounded,
        iconColor: const Color(0xFF0284C7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: trainingInstitutions
              .whereType<Map>()
              .map((sch) => _buildSchoolItem(sch, const Color(0xFF0284C7)))
              .toList(),
        ),
      ),
      const SizedBox(height: 20),
    ],
    if (targetCompanies.isNotEmpty) ...[
      _buildCard(
        title: 'Doanh Nghiệp Tuyển Dụng Tiêu Biểu',
        icon: Icons.business_center_rounded,
        iconColor: const Color(0xFF059669),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: targetCompanies
              .whereType<Map>()
              .map((comp) => _buildCompanyItem(comp, const Color(0xFF059669)))
              .toList(),
        ),
      ),
      const SizedBox(height: 20),
    ],
  ],

// 6. LỜI KHUYÊN HƯỚNG NGHIỆP — luôn hiển thị cuối cùng
_buildCard(
  title: 'Lời Khuyên Hướng Nghiệp',
  icon: Icons.lightbulb_outline_rounded,
  iconColor: const Color(0xFFD97706),
  child: Text(
    advice,
    style: GoogleFonts.inter(
      color: const Color(0xFF4B5563),
      fontSize: 13,
      height: 1.5,
    ),
  ),
),
const SizedBox(height: 20),

                // Đánh giá
                _buildFeedbackSection(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== WIDGET ĐIỂM PHÙ HỢP TỔNG QUAN ==========
  Widget _buildMatchScoreCard(double score, String status, bool isPassed, Color statusColor, String targetCareer) {
    // Nếu điểm số <= 5, ta coi như thang điểm 5 và nhân với 20 để quy đổi ra phần trăm khi phân cấp độ.
    // Ngược lại, nếu điểm số > 5, ta coi như thang điểm 100.
    final double percentage = (score <= 5) ? (score / 5 * 100) : score;

    // Màu sắc theo mức độ phù hợp
    Color scoreColor;
    String scoreText;
    if (percentage >= 80) {
      scoreColor = const Color(0xFF059669);
      scoreText = 'Phù hợp cao';
    } else if (percentage >= 60) {
      scoreColor = const Color(0xFF0284C7);
      scoreText = 'Phù hợp khá';
    } else if (percentage >= 40) {
      scoreColor = const Color(0xFFD97706);
      scoreText = 'Phù hợp trung bình';
    } else {
      scoreColor = const Color(0xFFDC2626);
      scoreText = 'Cần cải thiện';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.trending_up_rounded,
                  color: scoreColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetCareer.isNotEmpty
                          ? 'Độ Phù Hợp: $targetCareer'
                          : 'Điểm Phù Hợp Ngành Nghề',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kết quả đánh giá từ thuật toán AI',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Hiển thị điểm số lớn
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score <= 5 ? score.toStringAsFixed(2) : score.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  height: 1,
                ),
              ),
              Text(
                score <= 5 ? ' / 5' : '%',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: scoreColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Thanh tiến trình
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (score / (score <= 5 ? 5 : 100)).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          // Nhãn mức độ phù hợp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              scoreText,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BADGE HƯỚNG ĐI ĐÃ CHỌN (thay thế filter 2 tab cũ) ---
  Widget _buildSelectedPathBadge() {
    final bool isStudy = _selectedPath == CareerPath.study;
    final Color color = isStudy ? const Color(0xFF0284C7) : const Color(0xFF059669);
    final String label = isStudy ? '🎓 Hướng Đi Học' : '💼 Hướng Đi Làm';
    final String desc = isStudy
        ? 'Danh sách trường đào tạo & ngành phù hợp'
        : 'Danh sách công ty tuyển dụng & vị trí phù hợp';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isStudy ? Icons.school_rounded : Icons.work_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET NGƯỜI DÙNG THỂ HIỆN / LỜI NÓI NGẮN ---
  // Discovery: tiêu đề đổi theo nhánh (Đi học / Đi làm).
  // Targeted: hiển thị tiêu đề chung "Lời nói ngắn về bạn".
  Widget _buildUserExpressedCard(String summary, String displayMode) {
    final bool isStudy = _selectedPath == CareerPath.study;
    final bool isDiscovery = displayMode.toLowerCase() == 'discovery';

    final String cardTitle = 'Lời nói ngắn về bạn';
    final Color themeColor = isDiscovery
        ? (isStudy
            ? const Color(0xFF0284C7)
            : const Color(0xFF059669))
        : const Color(0xFF6366F1); // Tím indigo cho chế độ Targeted
    final IconData iconData = isDiscovery
        ? (isStudy
            ? Icons.school_outlined
            : Icons.work_outline_rounded)
        : Icons.format_quote_rounded;
    final String subTitle = isDiscovery
        ? (isStudy
            ? 'Phù hợp với môi trường học tập'
            : 'Phù hợp với môi trường làm việc')
        : 'Đánh giá tổng quan tính cách & năng lực';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      subTitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DISCOVERY: TÙY BIẾN THEO FILTER ĐI HỌC / ĐI LÀM ---
  Widget _buildDiscoverySection(List<dynamic> careers) {
    final bool isStudy = _selectedPath == CareerPath.study;
    final Color themeColor = isStudy
        ? const Color(0xFF0284C7)
        : const Color(0xFF059669);

    return _buildCard(
      title: isStudy
          ? 'Ngành Nghề Tối Ưu & Trường Đào Tạo'
          : 'Ngành Nghề Tối Ưu & Thị Trường Tuyển Dụng',
      icon: isStudy ? Icons.school_rounded : Icons.work_history_rounded,
      iconColor: themeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: careers.map((item) {
          final career = _safeString(item['career'], fallback: 'Chưa rõ tên ngành');
          final reason = _safeString(item['reason']);
          final matchRate = _safeString(item['matchRate'], fallback: 'Cao');

          // Lấy dữ liệu tùy theo nhánh (Fallback nếu AI chưa trả code)
          final studyInfo = _safeMap(item['studyInfo']);
          final topSchools = _safeStringList(
            studyInfo?['topSchools'],
            fallback: ['Đại học Bách Khoa', 'Đại học Quốc Gia', 'Đại học RMIT / FPT'],
          );

          final workInfo = _safeMap(item['workInfo']);
          final hiringCompanies = _safeStringList(
            workInfo?['hiringCompanies'],
            fallback: [
              'FPT Software / Telecom',
              'Tập đoàn Viettel',
              'Các công ty đa quốc gia',
            ],
          );
          final marketDemand = _safeString(
            workInfo?['marketDemand'],
            fallback: 'Nhu cầu cao, mức lương hấp dẫn',
          );

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Ngành Nghề & Độ Tương Thích
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 20,
                            color: themeColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              career,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Phù hợp: $matchRate',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lý do tương thích
                Text(
                  reason,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),

                // HIỂN THỊ ĐỘNG THEO NHÁNH ĐI HỌC HOẶC ĐI LÀM
                if (isStudy) ...[
                  if (item['trainingInstitutions'] != null &&
                      (item['trainingInstitutions'] as List).isNotEmpty) ...[
                    Text(
                      '🏛️ Các trường đào tạo đề xuất:',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(item['trainingInstitutions'] as List)
                        .whereType<Map>()
                        .map((sch) => _buildSchoolItem(sch, themeColor)),
                  ] else ...[
                    Text(
                      '🏛️ Top các trường đào tạo nổi bật:',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: topSchools.map((school) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            school,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ] else ...[
                  if (item['companyDetails'] != null &&
                      (item['companyDetails'] as List).isNotEmpty) ...[
                    Text(
                      '🏢 Cơ hội việc làm nổi bật:',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(item['companyDetails'] as List)
                        .whereType<Map>()
                        .map((comp) => _buildCompanyItem(comp, themeColor)),
                  ] else ...[
                    Text(
                      '🏢 Công ty & Tập đoàn đang tuyển dụng:',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hiringCompanies.map((company) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            company,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🔥 Thị trường: $marketDemand',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- CÁC HÀM HỖ TRỢ GIỮ NGUYÊN HOẶC TÁCH NHỎ CHO SẠCH ---
  Widget _buildLoginBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF97316),
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khảo sát ẩn danh',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đăng nhập để lưu kết quả này vào lịch sử hướng nghiệp cá nhân của bạn.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            // ĐÃ SỬA: Viết lại bằng async/await cực kỳ sạch và an toàn cho context
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );

              if (!mounted) return; // Kiểm tra mounted của State
              final updatedAuth = Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              if (updatedAuth.isAuthenticated) {
                await updatedAuth.claimTestResult(widget.sessionId);
                if (!mounted) return;
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              elevation: 0,
            ),
            child: const Text('Đăng Nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return _buildCard(
      title: 'Đánh Giá Độ Chính Xác Của AI',
      icon: Icons.rate_review_outlined,
      iconColor: const Color(0xFF0284C7),
      child: _feedbackSent
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cảm ơn bạn đã gửi đánh giá hài lòng!',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Đánh giá mức độ hài lòng về điểm số và phản biện của AI:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1;
                    return IconButton(
                      icon: Icon(
                        starVal <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = starVal),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Nhập ý kiến đóng góp của bạn để tinh chỉnh thuật toán AI...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSendingFeedback ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: _isSendingFeedback
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Gửi Đánh Giá',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildListItemBox({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Không có dữ liệu',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 6.0),
                      child: CircleAvatar(
                        backgroundColor: iconColor.withValues(alpha: 0.5),
                        radius: 3,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSchoolItem(dynamic school, Color themeColor) {
    if (school is! Map) return const SizedBox.shrink();
    final rawName = school['schoolName'] ?? school['name'];
    final rawOfficial = school['officialLink'] ?? school['link'];
    final rawAdmission = school['admissionLink'];
    final rawEval = school['scoreEvaluation'];

    final schoolName = (rawName is String && rawName.trim().isNotEmpty)
        ? rawName
        : 'Tên trường';
    final benchmark2025 = school['benchmark2025']?.toString();
    final benchmark2024 = school['benchmark2024']?.toString();
    final benchmark2023 = school['benchmark2023']?.toString();
    final benchmark2022 = school['benchmark2022']?.toString();
    final officialLink = (rawOfficial is String) ? rawOfficial : '';
    final admissionLink = (rawAdmission is String) ? rawAdmission : '';
    final scoreEvaluation = (rawEval is String) ? rawEval : '';

    final bool has2025 = benchmark2025 != null && benchmark2025.isNotEmpty && benchmark2025 != 'N/A';
    final String benchmarkText = has2025
        ? '2025: $benchmark2025 • 2024: ${benchmark2024 ?? "N/A"} • 2023: ${benchmark2023 ?? "N/A"}'
        : '2024: ${benchmark2024 ?? "N/A"} • 2023: ${benchmark2023 ?? "N/A"} • 2022: ${benchmark2022 ?? "N/A"}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schoolName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Điểm chuẩn: ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                benchmarkText,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          if (officialLink.isNotEmpty || admissionLink.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (officialLink.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.language_rounded, size: 14, color: themeColor),
                    label: Text(
                      'Website',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    onPressed: () async {
                      final url = officialLink.startsWith('http') ? officialLink : 'https://$officialLink';
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                if (officialLink.isNotEmpty && admissionLink.isNotEmpty)
                  const SizedBox(width: 16),
                if (admissionLink.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.campaign_outlined, size: 14, color: themeColor),
                    label: Text(
                      'Tuyển sinh',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    onPressed: () async {
                      final url = admissionLink.startsWith('http') ? admissionLink : 'https://$admissionLink';
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
              ],
            ),
          ],
          if (scoreEvaluation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assessment_rounded, size: 14, color: const Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      scoreEvaluation,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyItem(dynamic company, Color themeColor) {
    if (company is! Map) {
      return const SizedBox.shrink();
    }
    final rawName = company['companyName'] ?? company['name'];
    final rawDesc = company['companyDescription'] ?? company['description'];
    final rawSalary = company['basicSalary'] ?? company['salary'];
    final rawLink = company['careerLink'] ?? company['link'];

    final companyName = (rawName is String && rawName.trim().isNotEmpty)
        ? rawName
        : 'Tên công ty';
    final companyDescription = (rawDesc is String) ? rawDesc : '';
    final basicSalary = (rawSalary is String) ? rawSalary : '';
    final careerLink = (rawLink is String) ? rawLink : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  companyName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (basicSalary.isNotEmpty)
                Flexible(
                  flex: 2,
                  fit: FlexFit.loose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      basicSalary,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (companyDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              companyDescription,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
          if (careerLink.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.link_rounded, size: 14, color: themeColor),
              label: Text(
                'Ứng tuyển / Xem việc làm',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              onPressed: () async {
                final url = careerLink.startsWith('http') ? careerLink : 'https://$careerLink';
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ],
      ),
    );
  }
}
