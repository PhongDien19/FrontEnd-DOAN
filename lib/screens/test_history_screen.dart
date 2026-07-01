import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class TestHistoryScreen extends StatefulWidget {
  final String userId;

  const TestHistoryScreen({super.key, required this.userId});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

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
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Lỗi tải lịch sử hướng nghiệp'),
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
    final recommendedCareer = session['recommendedCareer'] ?? 'Chưa xác định';
    final reason =
        session['conclusionReason'] ??
        'Hệ thống AI đã tổng hợp các tham số từ câu trả lời của bạn.';
    final roadmap = session['roadmap'] as List<dynamic>?;
    // Đổi màu accent cho phù hợp nền sáng
    final color = isDiscovery
        ? const Color(0xFF059669)
        : const Color(0xFF6C63FF);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB), // Handle color sáng
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isDiscovery
                      ? 'Chi Tiết Phiên Khám Phá AI'
                      : 'Chi Tiết Kiểm Tra Mục Tiêu',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Session ID: ${session['sessionId']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const Divider(
                  color: Color(0xFFF3F4F6),
                  height: 24,
                  thickness: 1.5,
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Text(
                        'CÂU TRẢ LỜI CỦA BẠN (${questions.length})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...questions.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Câu $index: ${item['q']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.subdirectory_arrow_right_rounded,
                                      color: color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['a'],
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
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
                      }),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
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
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ĐÁP ÁN HƯỚNG NGHIỆP PHÙ HỢP NHẤT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              recommendedCareer,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              reason,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF4B5563),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (roadmap != null) ...[
                        const SizedBox(height: 28),
                        Text(
                          'LỘ TRÌNH THĂNG TIẾN KHUYẾN NGHỊ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...roadmap.map((step) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.trending_up_rounded,
                                    color: color,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['stage'],
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        step['desc'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF4B5563),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền sáng
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Lịch Sử Phiên Hướng Nghiệp',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
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
                    const Icon(
                      Icons.history_toggle_off_rounded,
                      size: 64,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bạn chưa thực hiện bài đánh giá nào.',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final session = _history[index];
                  final isDiscovery = session['mode'] == 'discovery';
                  final title =
                      session['title'] ??
                      (isDiscovery
                          ? 'Khám Phá (Discovery)'
                          : 'Mục Tiêu (Target)');
                  final subtitle =
                      session['subtitle'] ??
                      (isDiscovery
                          ? 'Gợi ý: ${session['recommendedCareer']}'
                          : 'Mục tiêu: ${session['targetJob']}');
                  final details = session['details'];
                  // Màu hiển thị trong list
                  final color = isDiscovery
                      ? const Color(0xFF059669)
                      : const Color(0xFF6C63FF);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _viewSessionDetails(session),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDiscovery
                                        ? Icons.explore_rounded
                                        : Icons.track_changes_rounded,
                                    color: color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                              ],
                            ),
                            if (details != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                details,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF4B5563),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            const Divider(color: Color(0xFFF3F4F6)),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(session['createdAt']),
                              style: GoogleFonts.inter(
                                fontSize: 11,
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
