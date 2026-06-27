import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestHistoryScreen extends StatefulWidget {
  final String userId;

  const TestHistoryScreen({super.key, required this.userId});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  // DANH SÁCH DỮ LIỆU ĐÃ ĐƯỢC CHUẨN HÓA (KHÔNG BỊ LẶP, TÍCH HỢP ROADMAP 2 NGÀNH)
  final List<dynamic> _history = [
    {
      'sessionId': 'AI_DISCOVERY_8892',
      'mode': 'discovery',
      'title': 'Khám Phá (Discovery)',
      'subtitle': 'Gợi ý: Chuyên gia Trí tuệ Nhân tạo (AI)',
      'isCompleted': true,
      'createdAt': '2026-06-21T21:30:00.000Z',
      'recommendedCareer': 'Chuyên gia Trí tuệ Nhân tạo (AI)',
      'relevanceScore': 4.8,
      'details':
          'Định hướng: Tập trung vào Machine Learning, Deep Learning và tối ưu thuật toán hệ thống thông minh.',
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
      // LỘ TRÌNH THĂNG TIẾN: CHUYÊN GIA AI
      'roadmap': [
        {
          'stage': 'Giai đoạn 1: AI Intern / Fresher',
          'desc':
              'Làm chủ ngôn ngữ Python, nắm vững Toán cao cấp (Đại số tuyến tính, Xác suất thống kê) và sử dụng thành thạo NumPy, Pandas, Sklearn.',
        },
        {
          'stage': 'Giai đoạn 2: Junior AI Engineer',
          'desc':
              'Xây dựng và tinh chỉnh các mô hình Học máy (Machine Learning) truyền thống, tiếp cận Học sâu (Deep Learning) và xử lý dữ liệu lớn Big Data.',
        },
        {
          'stage': 'Giai đoạn 3: Senior AI Engineer / Data Scientist',
          'desc':
              'Thiết kế các kiến trúc mạng phức tạp (Transformer, LLMs, Computer Vision), tối ưu hóa hiệu năng phần cứng và triển khai mô hình lên Production (MLOps).',
        },
        {
          'stage': 'Giai đoạn 4: AI Tech Lead / Architect',
          'desc':
              'Dẫn dắt đội ngũ kỹ thuật, định hình kiến trúc hệ thống AI tổng thể cho doanh nghiệp và kết nối bài toán kinh doanh thực tế với giải pháp AI.',
        },
        {
          'stage': 'Giai đoạn 5: Head of AI / Chief Data Officer (CDO)',
          'desc':
              'Hoạch định chiến lược công nghệ AI toàn diện cho tổ chức, nghiên cứu và phát triển các giải pháp đón đầu xu hướng toàn cầu.',
        },
      ],
    },
    {
      'sessionId': 'AI_TARGET_1024',
      'mode': 'target',
      'title': 'Mục Tiêu (Target)',
      'subtitle': 'Mục tiêu: Kỹ sư Phần mềm (Fullstack)',
      'isCompleted': true,
      'createdAt': '2026-06-18T09:15:00.000Z',
      'recommendedCareer': 'Kỹ sư Phần mềm (Fullstack)',
      'relevanceScore': 4.4,
      'details':
          'Lộ trình: Học chuyên sâu kiến trúc hệ thống từ Frontend đến Backend, tối ưu hóa Database và triển khai hạ tầng Cloud/DevOps.',
      'conclusionReason':
          'Kỹ năng nền tảng của bạn rất sát với mục tiêu. Định hướng Fullstack giúp bạn làm chủ toàn bộ vòng đời sản phẩm từ giao diện tương tác đến hệ thống lõi chịu tải cao.',
      'questions': [
        {
          'q':
              'Bạn thích thiết kế giao diện hiển thị cho người dùng xem, hay thích thiết kế cơ sở dữ liệu chạy ngầm bên dưới?',
          'a':
              'Tôi thích thiết kế cơ sở dữ liệu, tối ưu hóa các đầu API để hệ thống xử lý mượt mà và chịu tải tốt.',
        },
        {
          'q': 'Tầm nhìn nghề nghiệp trong 3 năm tới của bạn là gì?',
          'a':
              'Trở thành một Fullstack Senior cứng có khả năng độc lập thiết kế, triển khai giải pháp phần mềm hoàn chỉnh.',
        },
        {
          'q':
              'Khi lựa chọn một framework/công nghệ mới cho dự án, tiêu chí nào là quan trọng nhất với bạn?',
          'a':
              'Sự phù hợp với bài toán, hiệu năng vận hành, độ chín của cộng đồng hỗ trợ và khả năng bảo trì lâu dài.',
        },
      ],
      // LỘ TRÌNH THĂNG TIẾN MỚI: KỸ SƯ PHẦN MỀM FULLSTACK
      'roadmap': [
        {
          'stage': 'Giai đoạn 1: Fullstack Intern / Fresher',
          'desc':
              'Làm chủ HTML5, CSS3, JavaScript vững vàng. Học một framework Frontend (React/Next.js) song song với Node.js (Express) và cơ sở dữ liệu SQL cơ bản.',
        },
        {
          'stage': 'Giai đoạn 2: Junior Fullstack Developer',
          'desc':
              'Phát triển độc lập các tính năng từ giao diện đến API. Làm việc thuần thục với cơ sở dữ liệu NoSQL (MongoDB), thiết kế chuẩn RESTful API và quản lý mã nguồn qua Git.',
        },
        {
          'stage': 'Giai đoạn 3: Senior Fullstack Developer',
          'desc':
              'Tối ưu hóa hiệu năng ứng dụng (Caching với Redis, Tải bất đồng bộ). Làm chủ quy trình đóng gói container với Docker, cấu hình CI/CD và quản lý hạ tầng đám mây (AWS/GCP).',
        },
        {
          'stage': 'Giai đoạn 4: Fullstack Tech Lead / Solution Architect',
          'desc':
              'Chịu trách nhiệm thiết kế toàn bộ kiến trúc hệ thống (Microservices, distributed system), lựa chọn stack công nghệ, giải quyết bài toán bảo mật và chịu tải lớn (High Availability).',
        },
        {
          'stage':
              'Giai đoạn 5: Chief Technology Officer (CTO) / Technical Director',
          'desc':
              'Quản lý và định hướng chiến lược công nghệ dài hạn cho doanh nghiệp, tối ưu hóa quy trình kỹ thuật phần mềm và đồng bộ năng lực công nghệ với mục tiêu kinh doanh.',
        },
      ],
    },
  ];

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) {
      return 'Gần đây';
    }
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) {
      return 'Gần đây';
    }
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$hour:$minute - $day/$month/$year';
  }

  // BẢNG CHI TIẾT KHI BẤM VÀO THẺ (HIỆN CÂU TRẢ LỜI + ĐÁP ÁN CHỐT + LỘ TRÌNH THĂNG TIẾN)
  void _viewSessionDetails(dynamic session) {
    final isDiscovery = session['mode'] == 'discovery';
    final questions = session['questions'] as List<dynamic>? ?? [];
    final recommendedCareer = session['recommendedCareer'] ?? 'Chưa xác định';
    final reason =
        session['conclusionReason'] ??
        'Hệ thống AI đã tổng hợp các tham số từ câu trả lời của bạn.';
    final roadmap = session['roadmap'] as List<dynamic>?;
    final color = isDiscovery
        ? const Color(0xFF00F5A0)
        : const Color(0xFF7C4DFF);

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
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
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

                      // KHỐI LỘ TRÌNH THĂNG TIẾN (ROADMAP) DÙNG CHUNG CHO CẢ 2 PHÂN HỆ
                      if (roadmap != null) ...[
                        const SizedBox(height: 28),
                        Text(
                          'LỘ TRÌNH THĂNG TIẾN KHUYẾN NGHỊ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5E6072),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...roadmap.map((step) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F13),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF2C2C3E),
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        step['desc'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFC3C5E0),
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
                onTap: () => _viewSessionDetails(
                  session,
                ), // Mở modal chi tiết mượt mà cho mọi thẻ
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
