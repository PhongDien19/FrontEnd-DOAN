import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/pdf_export_service.dart';
import '../utils/responsive.dart';

class TestHistoryScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final String? educationLevel;
  final String? initialSessionId;

  const TestHistoryScreen({
    super.key,
    required this.userId,
    this.userRole = 'worker',
    this.educationLevel,
    this.initialSessionId,
  });

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  void _exportPdf(BuildContext context) async {
    final historyItems = _history.map((item) {
      return {
        'date': _formatDateTime(item['createdAt'] ?? ''),
        'type': _safeString(item['testType'] ?? 'Khảo sát'),
        'score': _safeString(item['score'] ?? item['matchScore'] ?? 'N/A'),
        'status': (item['score'] != null || item['matchScore'] != null)
            ? 'Hoàn thành'
            : 'Đang xử lý',
      };
    }).toList();

    await PdfExportService.exportTestHistory(
      context: context,
      userName: widget.userId,
      historyItems: historyItems,
    );
  }

  String _safeString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    if (v is num) return v.toString();
    if (v is bool) return v.toString();
    return v.toString();
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() async {
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.getHistory(widget.userId);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _history = res['history'] ?? [];
        _isLoading = false;
      });

      if (widget.initialSessionId != null && _history.isNotEmpty) {
        final targetSession = _history.firstWhere(
          (s) => s['sessionId']?.toString() == widget.initialSessionId,
          orElse: () => null,
        );
        if (targetSession != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _viewSessionDetails(targetSession);
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ?? 'Lỗi tải lịch sử hướng nghiệp',
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Gần đây';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return 'Gần đây';

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$hour:$minute - $day/$month/$year';
  }

  void _viewSessionDetails(dynamic session) {
    final isDiscovery = session['mode'] == 'discovery';
    final questions = session['questions'] as List<dynamic>? ?? [];
    final roadmap = session['roadmap'] as List<dynamic>? ?? [];

    final matchingSchools =
        session['matchingSchools'] as List<dynamic>? ?? [];
    final marketSalaries =
        session['marketSalaries'] as List<dynamic>? ?? [];
    final hiringCompanies =
        session['hiringCompanies'] as List<dynamic>? ?? [];

    final color = isDiscovery
        ? const Color(0xFF059669)
        : const Color(0xFF6C63FF);

    final isStudent = session['isStudent'] == true ||
        widget.userRole == 'student' ||
        (session['educationLevel'] != null &&
            (session['educationLevel']
                    .toString()
                    .toLowerCase()
                    .contains('học sinh') ||
                session['educationLevel']
                    .toString()
                    .toLowerCase()
                    .contains('thpt') ||
                session['educationLevel']
                    .toString()
                    .toLowerCase()
                    .contains('thcs')));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.s(context, 24)),
        ),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.6,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  SizedBox(height: Responsive.s(context, 12)),
                  Container(
                    width: Responsive.s(context, 40),
                    height: Responsive.s(context, 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(
                        Responsive.s(context, 2),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 16)),
                  Text(
                    isDiscovery
                        ? 'Chi Tiết Phiên Khám Phá AI'
                        : 'Chi Tiết Kiểm Tra Mục Tiêu',
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 4)),
                  Text(
                    'Session ID: ${session['sessionId']}',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.font(context, 12),
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 12)),

                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: color,
                    indicatorWeight: 3,
                    labelColor: color,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 14),
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      const Tab(text: 'Câu hỏi'),
                      const Tab(text: 'Đánh giá'),
                      const Tab(text: 'Lộ trình'),
                      Tab(
                        text: isStudent
                            ? 'Trường phù hợp'
                            : 'Thị trường & Công ty',
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildQuestionsTab(questions, color, scrollController),
                        _buildEvaluationTab(
                          session,
                          color,
                          scrollController,
                        ),
                        _buildRoadmapTab(roadmap, color, scrollController),
                        isStudent
                            ? _buildStudentTab(
                                matchingSchools,
                                color,
                                scrollController,
                              )
                            : _buildWorkerTab(
                                marketSalaries,
                                hiringCompanies,
                                color,
                                scrollController,
                              ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab(
    List<dynamic> questions,
    Color color,
    ScrollController controller,
  ) {
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu câu hỏi',
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontSize: Responsive.font(context, 14),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final item = questions[index];
        return Container(
          margin: EdgeInsets.only(bottom: Responsive.s(context, 14)),
          padding: EdgeInsets.all(Responsive.s(context, 16)),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 16),
            ),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Câu ${index + 1}: ${item['q']}',
                style: GoogleFonts.outfit(
                  fontSize: Responsive.font(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: Responsive.s(context, 10)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.s(context, 12)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 10),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      color: color,
                      size: Responsive.s(context, 16),
                    ),
                    SizedBox(width: Responsive.s(context, 8)),
                    Expanded(
                      child: Text(
                        item['a'],
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 13),
                          color: color,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
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
    );
  }

  Widget _buildEvaluationTab(
    dynamic session,
    Color color,
    ScrollController controller,
  ) {
    final recommendedCareer = session['recommendedCareer'] ?? 'Chưa xác định';
    final reason =
        session['conclusionReason'] ??
        'Hệ thống AI đã tổng hợp các tham số từ câu trả lời của bạn.';

    final strengths = session['strengths'] as List<dynamic>? ?? [];
    final weaknesses = session['weaknesses'] as List<dynamic>? ?? [];
    final summary = session['summary'] ?? '';
    final advice = session['advice'] ?? '';

    return ListView(
      controller: controller,
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.s(context, 20)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 20),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: color,
                    size: Responsive.s(context, 20),
                  ),
                  SizedBox(width: Responsive.s(context, 8)),
                  Expanded(
                    child: Text(
                      'ĐÁP ÁN HƯỚNG NGHIỆP PHÙ HỢP NHẤT',
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.font(context, 12),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.s(context, 12)),
              Text(
                recommendedCareer,
                style: GoogleFonts.outfit(
                  fontSize: Responsive.font(context, 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: Responsive.s(context, 8)),
              Text(
                reason,
                style: GoogleFonts.inter(
                  fontSize: Responsive.font(context, 13),
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (summary.toString().isNotEmpty) ...[
          SizedBox(height: Responsive.s(context, 16)),
          Text(
            'TÓM TẮT ĐÁNH GIÁ',
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 11),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: Responsive.s(context, 8)),
          Text(
            summary.toString(),
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 13),
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
        if (strengths.isNotEmpty || weaknesses.isNotEmpty) ...[
          SizedBox(height: Responsive.s(context, 20)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (strengths.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐIỂM MẠNH',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 8)),
                      ...strengths.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    color: const Color(0xFF059669), size: Responsive.s(context, 14)),
                                SizedBox(width: Responsive.s(context, 6)),
                                Expanded(
                                  child: Text(
                                    item.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.font(context, 12),
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              if (strengths.isNotEmpty && weaknesses.isNotEmpty)
                SizedBox(width: Responsive.s(context, 16)),
              if (weaknesses.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CẦN CẢI THIỆN',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 8)),
                      ...weaknesses.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: const Color(0xFFDC2626), size: Responsive.s(context, 14)),
                                SizedBox(width: Responsive.s(context, 6)),
                                Expanded(
                                  child: Text(
                                    item.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.font(context, 12),
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ],
        if (advice.toString().isNotEmpty) ...[
          SizedBox(height: Responsive.s(context, 20)),
          Text(
            'LỜI KHUYÊN HƯỚNG NGHIỆP',
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 11),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD97706),
            ),
          ),
          SizedBox(height: Responsive.s(context, 8)),
          Text(
            advice.toString(),
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 13),
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoadmapTab(
    List<dynamic> roadmap,
    Color color,
    ScrollController controller,
  ) {
    if (roadmap.isEmpty) {
      return Center(
        child: Text(
          'Chưa có thông tin lộ trình',
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontSize: Responsive.font(context, 14),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      itemCount: roadmap.length,
      itemBuilder: (context, index) {
        final step = roadmap[index];
        final certs = step['certs'] as List<dynamic>? ?? [];

        return Container(
          margin: EdgeInsets.only(bottom: Responsive.s(context, 14)),
          padding: EdgeInsets.all(Responsive.s(context, 16)),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 16),
            ),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.s(context, 6)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: color,
                  size: Responsive.s(context, 16),
                ),
              ),
              SizedBox(width: Responsive.s(context, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['stage'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: Responsive.font(context, 14),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: Responsive.s(context, 6)),
                    Text(
                      step['desc'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: Responsive.font(context, 12),
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                    if (certs.isNotEmpty) ...[
                      SizedBox(height: Responsive.s(context, 10)),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: certs.map<Widget>((cert) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.s(context, 8),
                              vertical: Responsive.s(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.s(context, 6),
                              ),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  size: Responsive.s(context, 12),
                                  color: color,
                                ),
                                SizedBox(width: Responsive.s(context, 4)),
                                Text(
                                  cert.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: Responsive.font(context, 10),
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentTab(
    List<dynamic> schools,
    Color color,
    ScrollController controller,
  ) {
    if (schools.isEmpty) {
      return Center(
        child: Text(
          'Chưa có thông tin trường học phù hợp từ hệ thống',
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontSize: Responsive.font(context, 14),
          ),
        ),
      );
    }
    return ListView(
      controller: controller,
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      children: [
        Text(
          'DANH SÁCH TRƯỜNG ĐÀO TẠO ĐỢT KHẢO SÁT',
          style: GoogleFonts.inter(
            fontSize: Responsive.font(context, 11),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: Responsive.s(context, 12)),
        ...schools.map(
          (sch) => Container(
            margin: EdgeInsets.only(bottom: Responsive.s(context, 12)),
            padding: EdgeInsets.all(Responsive.s(context, 16)),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(
                Responsive.s(context, 16),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sch['name'] ?? 'Tên trường',
                            style: GoogleFonts.outfit(
                              fontSize: Responsive.font(context, 15),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: Responsive.s(context, 4)),
                          Text(
                            'Ngành: ${sch['major'] ?? ''}',
                            style: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 13),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          SizedBox(height: Responsive.s(context, 2)),
                          Text(
                            '📍 ${sch['location'] ?? ''}',
                            style: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 12),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 10),
                        vertical: Responsive.s(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 8),
                        ),
                      ),
                      child: Text(
                        sch['score'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: Responsive.font(context, 13),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((sch['officialLink'] != null &&
                        sch['officialLink'].toString().isNotEmpty) ||
                    (sch['admissionLink'] != null &&
                        sch['admissionLink'].toString().isNotEmpty)) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.s(context, 8),
                    ),
                    child: const Divider(
                      height: 1,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                  Row(
                    children: [
                      if (sch['officialLink'] != null &&
                          sch['officialLink'].toString().isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(
                              Responsive.s(context, 50),
                              Responsive.s(context, 30),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.language_rounded,
                            size: Responsive.s(context, 14),
                            color: color,
                          ),
                          label: Text(
                            'Website',
                            style: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 11),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          onPressed: () async {
                            final urlString = sch['officialLink'].toString();
                            final url = urlString.startsWith('http')
                                ? urlString
                                : 'https://$urlString';
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                      if (sch['officialLink'] != null &&
                          sch['officialLink'].toString().isNotEmpty &&
                          sch['admissionLink'] != null &&
                          sch['admissionLink'].toString().isNotEmpty)
                        SizedBox(width: Responsive.s(context, 16)),
                      if (sch['admissionLink'] != null &&
                          sch['admissionLink'].toString().isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(
                              Responsive.s(context, 50),
                              Responsive.s(context, 30),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.campaign_outlined,
                            size: Responsive.s(context, 14),
                            color: color,
                          ),
                          label: Text(
                            'Tuyển sinh',
                            style: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 11),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          onPressed: () async {
                            final urlString = sch['admissionLink'].toString();
                            final url = urlString.startsWith('http')
                                ? urlString
                                : 'https://$urlString';
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerTab(
    List<dynamic> salaries,
    List<dynamic> companies,
    Color color,
    ScrollController controller,
  ) {
    if (salaries.isEmpty && companies.isEmpty) {
      return Center(
        child: Text(
          'Chưa có thông tin thị trường tuyển dụng lúc này',
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontSize: Responsive.font(context, 14),
          ),
        ),
      );
    }
    return ListView(
      controller: controller,
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      children: [
        if (salaries.isNotEmpty) ...[
          Text(
            'MỨC LƯƠNG THEO CẤP ĐỘ (THÁNG 5/2025)',
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 11),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: Responsive.s(context, 12)),
          Container(
            padding: EdgeInsets.all(Responsive.s(context, 16)),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(
                Responsive.s(context, 16),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: salaries.map((sal) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.s(context, 8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: Responsive.s(
                          context,
                          110,
                          max: 200,
                        ),
                        child: Text(
                          sal['level'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: Responsive.font(context, 12),
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 4),
                          ),
                          child: LinearProgressIndicator(
                            value: 0.65,
                            backgroundColor: const Color(0xFFE5E7EB),
                            color: Colors.orange,
                            minHeight: Responsive.s(context, 6),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.s(context, 14)),
                      Text(
                        sal['range'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: Responsive.font(context, 12),
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: Responsive.s(context, 24)),
        ],

        if (companies.isNotEmpty) ...[
          Text(
            'CƠ HỘI VIỆC LÀM NỔI BẬT',
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 11),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: Responsive.s(context, 12)),
          ...companies.map(
            (comp) => Container(
              margin: EdgeInsets.only(bottom: Responsive.s(context, 12)),
              padding: EdgeInsets.all(Responsive.s(context, 16)),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 16),
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comp['role'] ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: Responsive.font(context, 14),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: Responsive.s(context, 4)),
                            Text(
                              '${comp['company'] ?? ''} • ${comp['loc'] ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: Responsive.font(context, 12),
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.s(context, 10),
                              vertical: Responsive.s(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(
                                Responsive.s(context, 6),
                              ),
                            ),
                            child: Text(
                              comp['type'] ?? 'Toàn thời gian',
                              style: GoogleFonts.inter(
                                fontSize: Responsive.font(context, 11),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          if (comp['salary'] != null &&
                              comp['salary'].toString().isNotEmpty) ...[
                            SizedBox(height: Responsive.s(context, 4)),
                            Text(
                              comp['salary'].toString(),
                              style: GoogleFonts.outfit(
                                fontSize: Responsive.font(context, 11),
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (comp['description'] != null &&
                      comp['description'].toString().isNotEmpty) ...[
                    SizedBox(height: Responsive.s(context, 8)),
                    Text(
                      comp['description'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: Responsive.font(context, 12),
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (comp['careerLink'] != null &&
                      comp['careerLink'].toString().isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.s(context, 6),
                      ),
                      child: const Divider(
                        height: 1,
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(
                          Responsive.s(context, 50),
                          Responsive.s(context, 30),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        Icons.link_rounded,
                        size: Responsive.s(context, 14),
                        color: color,
                      ),
                      label: Text(
                        'Ứng tuyển / Xem việc làm',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      onPressed: () async {
                        final urlString = comp['careerLink'].toString();
                        final url = urlString.startsWith('http')
                            ? urlString
                            : 'https://$urlString';
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Lịch Sử Phiên Hướng Nghiệp',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.font(context, 18),
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.black87,
            size: Responsive.s(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.black87,
              size: Responsive.s(context, 24),
            ),
            tooltip: 'Xuất PDF',
            onPressed: _history.isNotEmpty
                ? () => _exportPdf(context)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              )
            : _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: Responsive.s(context, 64),
                          color: const Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: Responsive.s(context, 16)),
                        Text(
                          'Bạn chưa thực hiện bài đánh giá nào.',
                          style: GoogleFonts.outfit(
                            fontSize: Responsive.font(context, 16),
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.s(context, 20),
                      vertical: Responsive.s(context, 16),
                    ),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final session = _history[index];
                      final isDiscovery = session['mode'] == 'discovery';
                      final title = session['title'] ??
                          (isDiscovery
                              ? 'Khám Phá (Discovery)'
                              : 'Mục Tiêu (Target)');
                      final subtitle = session['subtitle'] ??
                          (isDiscovery
                              ? 'Gợi ý: ${session['recommendedCareer']}'
                              : 'Mục tiêu: ${session['targetJob']}');
                      final details = session['details'];
                      final color = isDiscovery
                          ? const Color(0xFF059669)
                          : const Color(0xFF6C63FF);

                      return Container(
                        margin: EdgeInsets.only(
                          bottom: Responsive.s(context, 16),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 20),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 20),
                          ),
                          onTap: () => _viewSessionDetails(session),
                          child: Padding(
                            padding: EdgeInsets.all(
                              Responsive.s(context, 20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        Responsive.s(context, 8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDiscovery
                                            ? Icons.explore_rounded
                                            : Icons.track_changes_rounded,
                                        color: color,
                                        size: Responsive.s(context, 18),
                                      ),
                                    ),
                                    SizedBox(width: Responsive.s(context, 14)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.outfit(
                                              fontSize: Responsive.font(
                                                context,
                                                15,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(
                                            height: Responsive.s(
                                              context,
                                              2,
                                            ),
                                          ),
                                          Text(
                                            subtitle,
                                            style: GoogleFonts.inter(
                                              fontSize: Responsive.font(
                                                context,
                                                13,
                                              ),
                                              color: color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (session['relevanceScore'] != null)
                                      Text(
                                        '${session['relevanceScore']}',
                                        style: GoogleFonts.outfit(
                                          fontSize: Responsive.font(
                                            context,
                                            16,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                  ],
                                ),
                                if (details != null) ...[
                                  SizedBox(
                                    height: Responsive.s(context, 12),
                                  ),
                                  Text(
                                    details,
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.font(
                                        context,
                                        13,
                                      ),
                                      color: const Color(0xFF4B5563),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                SizedBox(height: Responsive.s(context, 14)),
                                const Divider(color: Color(0xFFF3F4F6)),
                                SizedBox(height: Responsive.s(context, 4)),
                                Text(
                                  _formatDateTime(session['createdAt']),
                                  style: GoogleFonts.inter(
                                    fontSize: Responsive.font(context, 11),
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
