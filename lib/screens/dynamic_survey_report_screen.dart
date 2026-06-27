import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DynamicSurveyReportScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? initialReport;

  const DynamicSurveyReportScreen({
    super.key,
    required this.sessionId,
    this.initialReport,
  });

  @override
  State<DynamicSurveyReportScreen> createState() => _DynamicSurveyReportScreenState();
}

class _DynamicSurveyReportScreenState extends State<DynamicSurveyReportScreen> {
  late Map<String, dynamic> _report;
  bool _feedbackSent = false;
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSendingFeedback = false;

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

  // Gửi feedback hài lòng
  void _submitFeedback() async {
    setState(() {
      _isSendingFeedback = true;
    });

    final res = await ApiService.feedbackSurvey(
      widget.sessionId,
      _rating,
      _commentController.text.trim(),
    );

    setState(() {
      _isSendingFeedback = false;
      if (res['success'] == true) {
        _feedbackSent = true;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true ? 'Cảm ơn phản hồi của bạn!' : (res['message'] ?? 'Lỗi gửi phản hồi.')),
          backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_report.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F13),
        appBar: AppBar(
          backgroundColor: const Color(0xFF191922),
          title: Text('Báo Cáo AI', style: GoogleFonts.outfit()),
        ),
        body: const Center(
          child: Text('Không tìm thấy dữ liệu báo cáo.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final double rawScore = double.tryParse(_report['score']?.toString() ?? '0') ?? 0.0;
    final int percentageScore = (rawScore * 20).toInt().clamp(0, 100);
    final String status = _report['status'] ?? 'Failed';
    final bool isPassed = status.toLowerCase() == 'passed' || rawScore > 3.0;

    final Color statusColor = isPassed ? const Color(0xFF00F5A0) : const Color(0xFFFF5252);
    final String statusText = isPassed ? 'PHÙ HỢP NGHỀ NGHIỆP' : 'CÓ ĐIỂM CHƯA TƯƠNG THÍCH';

    final summary = _report['summary'] ?? '';
    final strengths = List<String>.from(_report['strengths'] ?? []);
    final weaknesses = List<String>.from(_report['weaknesses'] ?? []);
    final advice = _report['advice'] ?? '';

    // Passed variables
    final roadmap = List<String>.from(_report['roadmap'] ?? []);
    final certificates = List<String>.from(_report['certificates'] ?? []);
    final onetMatches = List<String>.from(_report['onetMatches'] ?? []);

    // Failed variables
    final deepScan = _report['deepScanAnalysis'] ?? '';
    final pivotSuggestions = _report['pivotSuggestions'] as List<dynamic>? ?? [];

    // New variables for Discovery and Targeted modes
    final String mode = _report['mode'] ?? '';
    final String targetCareer = _report['targetCareer'] ?? '';
    final compatibleCareers = _report['compatibleCareers'] as List<dynamic>? ?? [];
    final String basicSalary = _report['basicSalary'] ?? '';
    final String laborMarket = _report['laborMarket'] ?? '';

    // Determine display mode with intelligent fallback
    String displayMode = mode;
    if (displayMode.isEmpty) {
      if (compatibleCareers.isNotEmpty) {
        displayMode = 'Discovery';
      } else if (roadmap.isNotEmpty || basicSalary.isNotEmpty || laborMarket.isNotEmpty) {
        displayMode = 'Targeted';
      } else {
        displayMode = 'Discovery';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Báo Cáo Khảo Sát Động AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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
                color: statusColor.withValues(alpha: 0.04),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score compatibility ring
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191922),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2C2C3E)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Độ Tương Thích Với Ngành',
                        style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFF888B9B), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          children: [
                            Center(
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: CircularProgressIndicator(
                                  value: percentageScore / 100.0,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                ),
                              ),
                            ),
                             Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${rawScore.toStringAsFixed(1)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Thang điểm 5',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF888B9B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        summary,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC3C5E0), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Strengths and Weaknesses
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildListItemBox(
                        title: 'Điểm Mạnh',
                        items: strengths,
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF00F5A0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildListItemBox(
                        title: 'Tố Chất Cần Rèn',
                        items: weaknesses,
                        icon: Icons.error_outline_rounded,
                        iconColor: const Color(0xFFFF5252),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Advice
                _buildCard(
                  title: 'Lời Khuyên Hướng Nghiệp',
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: const Color(0xFFFFD600),
                  child: Text(
                    advice,
                    style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),

                // Mode-based Views: Discovery vs Targeted
                if (displayMode.toLowerCase() == 'discovery') ...[
                  if (compatibleCareers.isNotEmpty) ...[
                    _buildCard(
                      title: '5 Ngành Nghề Tối Tương Thích',
                      icon: Icons.work_history_rounded,
                      iconColor: const Color(0xFF00F5A0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: compatibleCareers.map((item) {
                          final career = item['career'] ?? '';
                          final reason = item['reason'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2C2C3E)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFF00F5A0)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        career,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reason,
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888B9B), height: 1.3),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ] else ...[
                  // Targeted Mode
                  if (roadmap.isNotEmpty) ...[
                    // Roadmap timeline
                    _buildCard(
                      title: 'Lộ Trình Phát Triển',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF00F2FE),
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
                                    backgroundColor: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (idx < roadmap.length - 1)
                                    Container(
                                      width: 1.5,
                                      height: 35,
                                      color: const Color(0xFF2C2C3E),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    roadmap[idx],
                                    style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13, height: 1.3),
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

                  if (certificates.isNotEmpty) ...[
                    _buildCard(
                      title: 'Chứng Chỉ Cần Thiết',
                      icon: Icons.school_outlined,
                      iconColor: const Color(0xFFE040FB),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: certificates.map((cert) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFFE040FB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(cert, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (onetMatches.isNotEmpty) ...[
                    _buildCard(
                      title: 'Vị Trí Công Việc Tương Đồng (O*NET)',
                      icon: Icons.work_history_outlined,
                      iconColor: const Color(0xFFFF7A00),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: onetMatches.map((job) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              const Icon(Icons.star_border_rounded, size: 14, color: Color(0xFFFF7A00)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(job, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (basicSalary.isNotEmpty) ...[
                    _buildCard(
                      title: 'Mức Lương Cơ Bản tại Việt Nam',
                      icon: Icons.monetization_on_outlined,
                      iconColor: const Color(0xFF00F5A0),
                      child: Text(
                        basicSalary,
                        style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (laborMarket.isNotEmpty) ...[
                    _buildCard(
                      title: 'Thị Trường Lao Động tại Việt Nam',
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFFFF7A00),
                      child: Text(
                        laborMarket,
                        style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],

                // Feedback Loop Card
                _buildCard(
                  title: 'Đánh Giá Độ Chính Xác Của AI',
                  icon: Icons.rate_review_outlined,
                  iconColor: const Color(0xFF00F2FE),
                  child: _feedbackSent
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Cảm ơn bạn đã gửi đánh giá hài lòng!',
                                  style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold),
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
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888B9B)),
                            ),
                            const SizedBox(height: 12),
                            // Stars selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final starVal = index + 1;
                                return IconButton(
                                  icon: Icon(
                                    starVal <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: const Color(0xFFFFD600),
                                    size: 32,
                                  ),
                                  onPressed: () => setState(() => _rating = starVal),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Nhập ý kiến đóng góp của bạn để tinh chỉnh thuật toán AI...',
                                hintStyle: const TextStyle(color: Color(0xFF5E6072)),
                                filled: true,
                                fillColor: const Color(0xFF0F0F13),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2C2C3E)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isSendingFeedback
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    )
                                  : Text('Gửi Đánh Giá', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 36),
              ],
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
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Không có dữ liệu',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5E6072)),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    '• $item',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF888B9B), height: 1.3),
                  ),
                )),
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
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C3E)),
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
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
}
