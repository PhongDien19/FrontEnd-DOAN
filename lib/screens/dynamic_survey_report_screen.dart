import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'login_screen.dart';

class DynamicSurveyReportScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? initialReport;

  const DynamicSurveyReportScreen({
    super.key,
    required this.sessionId,
    this.initialReport,
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

    // Đổi màu pass/fail sang tone màu hiển thị rõ trên nền trắng
    final Color statusColor = isPassed
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);

    final summary = _report['summary'] ?? '';
    final strengths = List<String>.from(_report['strengths'] ?? []);
    final weaknesses = List<String>.from(_report['weaknesses'] ?? []);
    final advice = _report['advice'] ?? '';

    final roadmap = List<String>.from(_report['roadmap'] ?? []);
    final certificates = List<String>.from(_report['certificates'] ?? []);
    final onetMatches = List<String>.from(_report['onetMatches'] ?? []);

    final String mode = _report['mode'] ?? '';
    final compatibleCareers =
        _report['compatibleCareers'] as List<dynamic>? ?? [];
    final String basicSalary = _report['basicSalary'] ?? '';
    final String laborMarket = _report['laborMarket'] ?? '';

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
                if (!authProvider.isAuthenticated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED), // Cam nhạt
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ).then((_) async {
                              if (!context.mounted) return;
                              final updatedAuth = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              if (updatedAuth.isAuthenticated) {
                                await updatedAuth.claimTestResult(
                                  widget.sessionId,
                                );
                                if (!context.mounted) return;
                                setState(() {});
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFF97316,
                            ), // Nút màu cam nổi bật
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
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
                  ),
                  const SizedBox(height: 20),
                ],

                if (displayMode.toLowerCase() == 'discovery') ...[
                  if (compatibleCareers.isNotEmpty) ...[
                    _buildCard(
                      title: '5 Ngành Nghề Tối Tương Thích',
                      icon: Icons.work_history_rounded,
                      iconColor: const Color(0xFF059669),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: compatibleCareers.map((item) {
                          final career = item['career'] ?? '';
                          final reason = item['reason'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        career,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reason,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF4B5563),
                                    height: 1.3,
                                  ),
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
                  if (roadmap.isNotEmpty) ...[
                    _buildCard(
                      title: 'Lộ Trình Phát Triển',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF0284C7),
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
                                    backgroundColor: const Color(
                                      0xFF0284C7,
                                    ).withValues(alpha: 0.1),
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
                      title: 'Vị Trí Công Việc Tương Đồng (O*NET)',
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
                ],

                if (summary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      summary,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF4B5563),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

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

                _buildCard(
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
                                    color: const Color(
                                      0xFFF59E0B,
                                    ), // Vàng/Cam sáng hơn trên nền trắng
                                    size: 32,
                                  ),
                                  onPressed: () =>
                                      setState(() => _rating = starVal),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _commentController,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText:
                                    'Nhập ý kiến đóng góp của bạn để tinh chỉnh thuật toán AI...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isSendingFeedback
                                  ? null
                                  : _submitFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                              ),
                              child: _isSendingFeedback
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
}
