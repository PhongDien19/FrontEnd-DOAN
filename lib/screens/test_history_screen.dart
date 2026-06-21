import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestHistoryScreen extends StatefulWidget {
  final String userId;

  const TestHistoryScreen({super.key, required this.userId});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  final bool _isLoading = false;

  // DỮ LIỆU MẪU CÓ SẴN CÂU TRẢ LỜI & ĐÁP ÁN DƯỚI CÙNG
  final List<dynamic> _history = [
    {
      'sessionId': 'AI_DISCOVERY_8892',
      'mode': 'discovery',
      'isCompleted': true,
      'createdAt': '2026-06-21T21:30:00.000Z',
      'recommendedCareer': 'Chuyên gia Trí tuệ Nhân tạo (AI)',
      'details':
          'Lộ trình: Tập trung xây dựng nền tảng Toán học, Machine Learning, Deep Learning và thành thạo các khung làm việc như TensorFlow hoặc PyTorch để phát triển các hệ thống thông minh.',
      'relevanceScore': 4.8,
      'conclusionReason':
          'Dựa trên phân tích: Bạn có tư duy logic thuật toán vượt trội, thích giải quyết bài toán lớn bằng tự động hóa và có khả năng ngồi làm việc sâu (Deep work) với dữ liệu phức tạp.',
      'questions': [
        {
          'q':
              'Khi đối mặt với một vấn đề phức tạp trong công việc, cách tiếp cận đầu tiên của bạn là gì?',
          'a':
              'Tìm kiếm các quy luật, bóc tách thành các biến số và xây dựng một quy trình giải quyết tự động.',
        },
        {
          'q':
              'Bạn cảm thấy kiệt sức và mất năng lượng nhất khi phải làm những đầu việc có tính chất nào?',
          'a':
              'Các công việc lặp đi lặp lại thủ công theo lối mòn mà không được phép tối ưu hay cải tiến.',
        },
        {
          'q':
              'Môi trường làm việc khiến bạn phát huy 200% công suất trông như thế nào?',
          'a':
              'Ít họp hành vô bổ, tôn trọng sự yên tĩnh, được trang bị công cụ phần cứng/phần mềm mạnh nhất.',
        },
        {
          'q':
              'Nếu được giao một tệp dữ liệu gồm 100.000 dòng lộn xộn, phản ứng của bạn là:',
          'a':
              'Rất hào hứng. Tôi sẽ viết ngay một đoạn script Python để làm sạch và bóc tách insight.',
        },
      ],
    },
    {
      'sessionId': 'AI_TARGET_FS_002',
      'mode': 'target',
      'title': 'Mục Tiêu (Target)',
      'subtitle': 'Mục tiêu: Kỹ sư Phần mềm Fullstack',
      'details':
          'Định hướng: Phát triển tư duy hệ thống từ Frontend (React) đến Backend (Node.js/SQL) và triển khai hạ tầng Cloud/DevOps.',
      'relevanceScore': 4.5,
      'isCompleted': true,
      'createdAt': '2026-06-22T10:30:00.000Z',
      'questions': [
        {
          'q': 'Bạn thích thiết kế giao diện hay xử lý logic backend?',
          'a':
              'Tôi thích thiết kế cơ sở dữ liệu và tối ưu hóa API xử lý hệ thống lớn.',
        },
        {
          'q': 'Bạn quản lý lỗi (bug) trong dự án như thế nào?',
          'a':
              'Tôi sử dụng TDD (Test Driven Development) và viết log chi tiết.',
        },
        {
          'q': 'Tầm nhìn nghề nghiệp 3 năm tới của bạn là gì?',
          'a':
              'Trở thành một Tech Lead có khả năng thiết kế hệ thống có tính mở rộng cao.',
        },
        {
          'q': 'Khi cần chọn công nghệ cho dự án, bạn dựa vào tiêu chí gì?',
          'a':
              'Dựa trên hiệu năng, cộng đồng hỗ trợ và khả năng bảo trì lâu dài.',
        },
      ],
      'recommendedCareer': 'Kỹ sư Backend / Fullstack',
      'conclusionReason':
          'Kỹ năng nền tảng của bạn rất sát với mục tiêu, tập trung vào Backend sẽ giúp bạn tối ưu hóa hệ thống hiệu quả hơn.',
    },
    {
      'sessionId': 'AI_DISCOVERY_1023',
      'mode': 'discovery',
      'title': 'Khám Phá (Discovery)',
      'subtitle': 'Gợi ý: Kỹ Sư Điện Tử',
      'details':
          'Lộ trình: Tập trung vào thiết kế vi mạch, hệ thống nhúng, điều khiển tự động và thực hành các dự án phần cứng ứng dụng.',
      'relevanceScore': 4.5,
      'isCompleted': true,
      'createdAt': '2026-06-22T04:30:00.000Z',
    },
    {
      'sessionId': 'AI_TARGET_1024',
      'mode': 'target',
      'title': 'Mục Tiêu (Target)',
      'subtitle': 'Mục tiêu: Bác Sĩ Y Khoa',
      'details':
          'Lộ trình: Chú trọng kiến thức giải phẫu, thực tập lâm sàng tại các bệnh viện và nghiên cứu chuyên sâu về chẩn đoán y học.', // Thêm trường này
      'relevanceScore': 4.1,
      'isCompleted': true,
      'createdAt': '2026-06-18T16:15:00.000Z',
    },
  ];

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

  // BẢNG CHI TIẾT KHI BẤM VÀO THẺ (HIỆN CÂU TRẢ LỜI + ĐÁP ÁN CHỐT)
  void _viewSessionDetails(dynamic session) {
    final isDiscovery = session['mode'] == 'discovery';
    final questions = session['questions'] as List<dynamic>? ?? [];
    final recommendedCareer = session['recommendedCareer'] ?? 'Chưa xác định';
    final reason =
        session['conclusionReason'] ??
        'Hệ thống AI đã tổng hợp các tham số từ câu trả lời của bạn.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191922),
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
                    color: const Color(0xFF5E6072),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Session ID: ${session['sessionId']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF888B9B),
                  ),
                ),
                const Divider(color: Color(0xFF2C2C3E), height: 24),

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
                          color: const Color(0xFF5E6072),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rải danh sách câu hỏi và câu trả lời
                      ...questions.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2C2C3E)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Câu $index: ${item['q']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00F5A0,
                                  ).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.subdirectory_arrow_right_rounded,
                                      color: Color(0xFF00F5A0),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['a'],
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF00F5A0),
                                          fontWeight: FontWeight.w500,
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

                      // KHỐI ĐÁP ÁN DƯỚI CÙNG (FINAL ANSWER BOX)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00F5A0).withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF00F5A0),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ĐÁP ÁN HƯỚNG NGHIỆP PHÙ HỢP NHẤT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00F5A0),
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              reason,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFC3C5E0),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
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
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Lịch Sử Phiên Hướng Nghiệp',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final session = _history[index];
            final isDiscovery = session['mode'] == 'discovery';
            final title =
                session['title'] ??
                (isDiscovery ? 'Khám Phá (Discovery)' : 'Mục Tiêu (Target)');
            final subtitle =
                session['subtitle'] ??
                (isDiscovery
                    ? 'Gợi ý: ${session['recommendedCareer']}'
                    : 'Mục tiêu: ${session['targetJob']}');
            final details = session['details'];
            final color = isDiscovery
                ? const Color(0xFF00F5A0)
                : const Color(0xFF7C4DFF);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2C2C3E)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => session['questions'] != null
                    ? _viewSessionDetails(session)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDiscovery
                                ? Icons.explore_rounded
                                : Icons.track_changes_rounded,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${session['relevanceScore']}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),

                      // Hiển thị phần details (định hướng) nếu có
                      if (details != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          details,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFF2C2C3E)),
                      Text(
                        _formatDateTime(session['createdAt']),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF5E6072),
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
