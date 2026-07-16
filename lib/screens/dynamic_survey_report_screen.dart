import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/clickable_url_text.dart';
import '../utils/pdf_export_service.dart';
import 'chat_screen.dart';

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

  void _openChatWithContext(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          initialContext: _report.isNotEmpty
              ? {
                  'summary': _report['summary'] ?? '',
                  'strengths': _report['strengths'] ?? [],
                  'weaknesses': _report['weaknesses'] ?? [],
                  'advice': _report['advice'] ?? '',
                  'targetCareer': _report['targetCareer'] ?? _report['careerName'] ?? _report['career'] ?? '',
                }
              : null,
        ),
      ),
    );
  }

  void _exportPdf(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.fullName.isNotEmpty ? authProvider.fullName : 'Người dùng';
    final date = _safeString(_report['date'] ?? DateTime.now().toIso8601String());
    final displayMode = _safeString(_report['displayMode'] ?? 'discovery');

    // Build scores map
    final scores = <String, dynamic>{};
    if (_report['matchScore'] != null) {
      scores['Điểm Phù Hợp'] = _report['matchScore'];
    }
    if (_report['matchPercentage'] != null) {
      scores['Tỷ Lệ Phù Hợp'] = '${_report['matchPercentage']}%';
    }

    // Build interpretations
    final interpretations = <String, dynamic>{};

    final strengths = _safeStringList(_report['strengths']);
    if (strengths.isNotEmpty) {
      interpretations['Điểm Mạnh'] = strengths.join('\n');
    }

    final weaknesses = _safeStringList(_report['weaknesses']);
    if (weaknesses.isNotEmpty) {
      interpretations['Tố Chất Cần Rèn'] = weaknesses.join('\n');
    }

    final summary = _safeString(_report['summary']);
    if (summary.isNotEmpty) {
      interpretations['Lời Nói Ngắn'] = summary;
    }

    final roadmap = _safeStringList(_report['roadmap']);
    if (roadmap.isNotEmpty) {
      interpretations['Lộ Trình Phát Triển'] = roadmap.join('\n');
    }

    final advice = _safeString(_report['advice']);
    if (advice.isNotEmpty) {
      interpretations['Lời Khuyên Hướng Nghiệp'] = advice;
    }

    final compatibleCareers =
        (_report['compatibleCareers'] is List) ? (_report['compatibleCareers'] as List) : <dynamic>[];
    final String targetCareer = _safeString(_report['targetCareer'] ?? _report['careerName'] ?? _report['career'] ?? '');
    final trainingInstitutions =
        (_report['trainingInstitutions'] is List || _report['schools'] is List)
            ? (_report['trainingInstitutions'] ?? _report['schools']) as List
            : <dynamic>[];
    final targetCompanies =
        (_report['companies'] is List || _report['companyDetails'] is List)
            ? (_report['companies'] ?? _report['companyDetails']) as List
            : <dynamic>[];

    String? careerRec;
    final buffer = StringBuffer();

    if (displayMode.toLowerCase() == 'discovery') {
      if (compatibleCareers.isNotEmpty) {
        buffer.writeln('CÁC NGÀNH NGHỀ PHÙ HỢP GỢI Ý:');
        for (final item in compatibleCareers) {
          if (item is! Map) continue;
          final cName = _safeString(item['careerName'] ?? item['name']);
          final cReason = _safeString(item['reason'] ?? item['interpretation']);
          buffer.writeln('\n• Ngành nghề: $cName');
          if (cReason.isNotEmpty) {
            buffer.writeln('  Phân tích: $cReason');
          }

          if (_selectedPath == CareerPath.study) {
            final schList = item['trainingInstitutions'];
            if (schList is List && schList.isNotEmpty) {
              buffer.writeln('  🏛️ Trường đào tạo đề xuất:');
              for (final sch in schList) {
                if (sch is! Map) continue;
                final sName = _safeString(sch['schoolName'] ?? sch['name']);
                final benchmark2024 = sch['benchmark2024']?.toString();
                final benchmark2023 = sch['benchmark2023']?.toString();
                buffer.write('    - $sName');
                if (benchmark2024 != null || benchmark2023 != null) {
                  buffer.write(' (Điểm chuẩn: 2024: ${benchmark2024 ?? "N/A"} • 2023: ${benchmark2023 ?? "N/A"})');
                }
                buffer.writeln();
              }
            }
          } else {
            final compList = item['companyDetails'];
            if (compList is List && compList.isNotEmpty) {
              buffer.writeln('  🏢 Cơ hội việc làm & Doanh nghiệp gợi ý:');
              for (final comp in compList) {
                if (comp is! Map) continue;
                final compName = _safeString(comp['companyName'] ?? comp['name']);
                final pos = _safeString(comp['position'] ?? comp['jobOpportunities']);
                buffer.write('    - $compName');
                if (pos.isNotEmpty) {
                  buffer.write(' ($pos)');
                }
                buffer.writeln();
              }
            }
          }
        }
      }
    } else {
      // Targeted Mode
      buffer.writeln('NGÀNH NGHỀ MỤC TIÊU: $targetCareer\n');
      if (_selectedPath == CareerPath.study) {
        if (trainingInstitutions.isNotEmpty) {
          buffer.writeln('🏛️ Trường đào tạo đề xuất:');
          for (final sch in trainingInstitutions) {
            if (sch is! Map) continue;
            final sName = _safeString(sch['schoolName'] ?? sch['name']);
            final benchmark2024 = sch['benchmark2024']?.toString();
            final benchmark2023 = sch['benchmark2023']?.toString();
            buffer.write('  - $sName');
            if (benchmark2024 != null || benchmark2023 != null) {
              buffer.write(' (Điểm chuẩn: 2024: ${benchmark2024 ?? "N/A"} • 2023: ${benchmark2023 ?? "N/A"})');
            }
            buffer.writeln();
          }
        }
      } else {
        if (targetCompanies.isNotEmpty) {
          buffer.writeln('🏢 Doanh nghiệp tuyển dụng tiêu biểu:');
          for (final comp in targetCompanies) {
            if (comp is! Map) continue;
            final compName = _safeString(comp['companyName'] ?? comp['name']);
            final pos = _safeString(comp['position'] ?? comp['jobOpportunities']);
            buffer.write('  - $compName');
            if (pos.isNotEmpty) {
              buffer.write(' ($pos)');
            }
            buffer.writeln();
          }
        }
      }
    }

    if (buffer.isNotEmpty) {
      careerRec = buffer.toString().trim();
    }

    await PdfExportService.exportSurveyReport(
      context: context,
      title: displayMode == 'discovery'
          ? 'Báo Cáo Khảo Sát Động - Discovery'
          : 'Báo Cáo Khảo Sát Động - Targeted',
      userName: userName,
      testType: displayMode == 'discovery' ? 'Discovery' : 'Targeted',
      date: date,
      scores: scores,
      interpretations: interpretations,
      careerRecommendations: careerRec,
    );
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
            style: TextStyle(color: Colors.black87),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.font(context, 18),
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: Colors.black87,
            size: Responsive.s(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.black87,
              size: Responsive.s(context, 24),
            ),
            tooltip: 'Trao đổi thêm với AI',
            onPressed: () => _openChatWithContext(context),
          ),
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.black87,
              size: Responsive.s(context, 24),
            ),
            tooltip: 'Xuất PDF',
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -Responsive.s(context, 50),
            right: -Responsive.s(context, 50),
            child: Container(
              width: Responsive.s(context, 250),
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.s(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner nhắc đăng nhập
                if (!authProvider.isAuthenticated) ...[
                  _buildLoginBanner(),
                  SizedBox(height: Responsive.s(context, 20)),
                ],

                // ========== ĐIỂM PHÙ HỢP TỔNG QUAN ==========
                if (displayMode.toLowerCase() != 'discovery') ...[
                  _buildMatchScoreCard(
                    rawScore,
                    status,
                    isPassed,
                    statusColor,
                    targetCareer,
                  ),
                  SizedBox(height: Responsive.s(context, 20)),
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
                  style: TextStyle(
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
                        style: TextStyle(
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
                        style: TextStyle(
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
        style: TextStyle(
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
        style: TextStyle(
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
    style: TextStyle(
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kết quả đánh giá từ thuật toán AI',
                      style: TextStyle(
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
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  height: 1,
                ),
              ),
              Text(
                score <= 5 ? ' / 5' : '%',
                style: TextStyle(
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
              style: TextStyle(
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      subTitle,
                      style: TextStyle(
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
            style: TextStyle(
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
                              style: TextStyle(
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
                        style: TextStyle(
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
                  style: TextStyle(
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
                      style: TextStyle(
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
                      style: TextStyle(
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
                            style: TextStyle(
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
                  // 1. Lộ trình phát triển nghề nghiệp
                  if (item['careerRoadmap'] != null && item['careerRoadmap'] is List && (item['careerRoadmap'] as List).isNotEmpty) ...[
                    Text(
                      '📈 Lộ trình phát triển nghề nghiệp:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...(item['careerRoadmap'] as List).map((step) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              step.toString(),
                              style: TextStyle(fontSize: 12, color: const Color(0xFF374151)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 10),
                  ],

                  // 2. Chứng chỉ nghề nghiệp cần có
                  if (item['requiredCertificates'] != null && item['requiredCertificates'] is List && (item['requiredCertificates'] as List).isNotEmpty) ...[
                    Text(
                      '🎓 Chứng chỉ nghề nghiệp khuyên có:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (item['requiredCertificates'] as List).map((cert) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            cert.toString(),
                            style: TextStyle(fontSize: 11, color: const Color(0xFF047857), fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 3. Cơ hội việc làm nổi bật (nếu có)
                  if (item['companyDetails'] != null && (item['companyDetails'] as List).isNotEmpty) ...[
                    Text(
                      '🏢 Cơ hội việc làm nổi bật:',
                      style: TextStyle(
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
                      '🏢 Công ty & Tập đoàn tuyển dụng tiêu biểu:',
                      style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD1FAE5)),
                          ),
                          child: Text(
                            company,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF047857)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 4. Thị trường tuyển dụng (Luôn hiển thị)
                  const SizedBox(height: 10),
                  Text(
                    '🔥 Thị trường: $marketDemand',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đăng nhập để lưu kết quả này vào lịch sử hướng nghiệp cá nhân của bạn.',
                  style: TextStyle(
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
              textStyle: TextStyle(
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
                      style: TextStyle(
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
                  style: TextStyle(
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
                          style: TextStyle(
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
                  style: TextStyle(
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
              style: TextStyle(
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
                        style: TextStyle(
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
                  style: TextStyle(
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

  Widget _buildLinkChip({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () async {
        try {
          final effectiveUrl = url.startsWith('http') ? url : 'https://$url';
          await launchUrl(Uri.parse(effectiveUrl), mode: LaunchMode.externalApplication);
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
          borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.s(context, 13), color: color),
            SizedBox(width: Responsive.s(context, 4)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.font(context, 11),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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
    
    // Lấy benchmark từ nhiều nguồn (ưu tiên field benchmark trước)
    final benchmarkField = school['benchmark'];
    
    // Parse benchmark values để kiểm tra tính hợp lệ
    double? parseScore(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) {
        final parsed = double.tryParse(val);
        return parsed;
      }
      return null;
    }
    
    final score2025 = parseScore(benchmarkField ?? school['benchmark2025']);
    final score2024 = parseScore(school['benchmark2024']);
    final score2023 = parseScore(school['benchmark2023']);
    final score2022 = parseScore(school['benchmark2022']);
    
    // LỌC NULL: Chỉ hiển thị điểm hợp lệ (> 0 và <= 30)
    String? benchmarkText;
    int? benchmarkYear;
    
    if (score2025 != null && score2025 > 0 && score2025 <= 30) {
      benchmarkText = score2025.toStringAsFixed(1);
      benchmarkYear = 2025;
    } else if (score2024 != null && score2024 > 0 && score2024 <= 30) {
      benchmarkText = score2024.toStringAsFixed(1);
      benchmarkYear = 2024;
    } else if (score2023 != null && score2023 > 0 && score2023 <= 30) {
      benchmarkText = score2023.toStringAsFixed(1);
      benchmarkYear = 2023;
    } else if (score2022 != null && score2022 > 0 && score2022 <= 30) {
      benchmarkText = score2022.toStringAsFixed(1);
      benchmarkYear = 2022;
    }
    // Nếu không có benchmark hợp lệ -> KHÔNG hiển thị gì (ẩn hẳn phần điểm)
    
    final officialLink = (rawOfficial is String) ? rawOfficial : '';
    final admissionLink = (rawAdmission is String) ? rawAdmission : '';
    final scoreEvaluation = (rawEval is String) ? rawEval : '';
    
    // Lấy benchmarkNote từ backend nếu có
    final benchmarkNote = school['benchmarkNote']?.toString();

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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF1F2937),
            ),
          ),
          
          // Chỉ hiển thị benchmark NẾU CÓ giá trị hợp lệ
          if (benchmarkText != null && benchmarkYear != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Điểm chuẩn: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$benchmarkYear: $benchmarkText',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (benchmarkNote != null) ...[
            // Hiển thị ghi chú nếu không có điểm
            const SizedBox(height: 6),
            Text(
              benchmarkNote,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
          
          // Hiển thị đường link nếu có
          if (officialLink.isNotEmpty || admissionLink.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (officialLink.isNotEmpty)
                  _buildLinkChip(
                    icon: Icons.language_rounded,
                    label: 'Trang web trường',
                    color: themeColor,
                    url: officialLink,
                  ),
                if (officialLink.isNotEmpty && admissionLink.isNotEmpty)
                  const SizedBox(width: 16),
                if (admissionLink.isNotEmpty)
                  _buildLinkChip(
                    icon: Icons.campaign_outlined,
                    label: 'Tuyển sinh',
                    color: themeColor,
                    url: admissionLink,
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
                    child: ClickableUrlText(
                      text: scoreEvaluation,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
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
                  style: TextStyle(
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
                      style: TextStyle(
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
            ClickableUrlText(
              text: companyDescription,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
          if (careerLink.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLinkChip(
              icon: Icons.link_rounded,
              label: 'Ứng tuyển / Xem việc làm',
              color: themeColor,
              url: careerLink,
            ),
          ],
        ],
      ),
    );
  }
}
