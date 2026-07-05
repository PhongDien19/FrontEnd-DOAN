import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class TestHistoryScreen extends StatefulWidget {
  final String userId;
  // Thêm vai trò người dùng: 'student' (học sinh) hoặc 'worker' (người đi làm/sinh viên sắp tốt nghiệp)
  final String userRole;

  const TestHistoryScreen({
    super.key,
    required this.userId,
    this.userRole =
        'worker', // Mặc định là 'worker', bạn có thể truyền 'student' từ màn hình trước vào
  });

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

  // BẢNG CHI TIẾT VỚI 4 TABS ĐIỀU HƯỚNG THEO THIẾT KẾ CỦA BẠN
  void _viewSessionDetails(dynamic session) {
    final isDiscovery = session['mode'] == 'discovery';
    final questions = session['questions'] as List<dynamic>? ?? [];
    final roadmap = session['roadmap'] as List<dynamic>? ?? [];

    // Dữ liệu mở rộng từ API cho Tab 4
    final matchingSchools = session['matchingSchools'] as List<dynamic>? ?? [];
    final marketSalaries = session['marketSalaries'] as List<dynamic>? ?? [];
    final hiringCompanies = session['hiringCompanies'] as List<dynamic>? ?? [];

    final color = isDiscovery
        ? const Color(0xFF059669) // Xanh lục cho Khám phá
        : const Color(0xFF6C63FF); // Tím cho Mục tiêu

    final isStudent = widget.userRole == 'student';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Sử dụng DefaultTabController gồm 4 Tabs
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
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
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
                  const SizedBox(height: 12),

                  // THANH TAB BAR 4 MỤC
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: color,
                    indicatorWeight: 3,
                    labelColor: color,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      const Tab(text: 'Câu hỏi'),
                      const Tab(text: 'Đánh giá'),
                      const Tab(text: 'Ngành nghề phù hợp'),
                      // Tab 4 tự động đổi tên theo vai trò người dùng
                      Tab(
                        text: isStudent
                            ? 'Trường phù hợp'
                            : 'Thị trường & Công ty',
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),

                  // NỘI DUNG 4 TABS
                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1: DANH SÁCH CÂU HỎI
                        _buildQuestionsTab(questions, color, scrollController),

                        // TAB 2: ĐÁNH GIÁ HƯỚNG NGHIỆP
                        _buildEvaluationTab(session, color, scrollController),

                        // TAB 3: LỘ TRÌNH & CHỨNG CHỈ CẦN THIẾT
                        _buildRoadmapTab(roadmap, color, scrollController),

                        // TAB 4: TRƯỜNG HỌC (STUDENT) HOẶC THỊ TRƯỜNG LAO ĐỘNG (WORKER)
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

  // --- CÁC COMPONENT GIAO DIỆN CON VẼ THEO LIGHT THEME ---

  Widget _buildQuestionsTab(
    List<dynamic> questions,
    Color color,
    ScrollController controller,
  ) {
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu câu hỏi',
          style: GoogleFonts.inter(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final item = questions[index];
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
                'Câu ${index + 1}: ${item['q']}',
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

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: color, size: 20),
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
          style: GoogleFonts.inter(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(20),
      itemCount: roadmap.length,
      itemBuilder: (context, index) {
        final step = roadmap[index];
        final certs =
            step['certs'] as List<dynamic>? ??
            []; // Nhận danh sách chứng chỉ nếu có

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                child: Icon(Icons.trending_up_rounded, color: color, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['stage'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step['desc'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                    // HIỂN THỊ CHỨNG CHỈ CẦN THIẾT (NẾU CÓ)
                    if (certs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: certs.map<Widget>((cert) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cert.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
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

  // TAB 4 CHO HỌC SINH: TRƯỜNG HỌC PHÙ HỢP
  Widget _buildStudentTab(
    List<dynamic> schools,
    Color color,
    ScrollController controller,
  ) {
    if (schools.isEmpty) {
      return Center(
        child: Text(
          'Chưa có thông tin trường học phù hợp từ hệ thống',
          style: GoogleFonts.inter(color: Colors.black54),
        ),
      );
    }
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'DANH SÁCH TRƯỜNG ĐÀO TẠO ĐỢT KHẢO SÁT',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        ...schools.map(
          (sch) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sch['name'] ?? 'Tên trường',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngành: ${sch['major'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${sch['location'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sch['score'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 4 CHO NGƯỜI ĐI LÀM: THỊ TRƯỜNG LAO ĐỘNG & VIỆC LÀM
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
          style: GoogleFonts.inter(color: Colors.black54),
        ),
      );
    }
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        if (salaries.isNotEmpty) ...[
          Text(
            'MỨC LƯƠNG THEO CẤP ĐỘ (THÁNG 5/2025)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: salaries.map((sal) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          sal['level'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.65, // Tạo thanh bar trực quan
                            backgroundColor: const Color(0xFFE5E7EB),
                            color: Colors.orange,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        sal['range'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
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
          const SizedBox(height: 24),
        ],

        if (companies.isNotEmpty) ...[
          Text(
            'CƠ HỘI VIỆC LÀM NỔI BẬT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          ...companies.map(
            (comp) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comp['role'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${comp['company'] ?? ''} • ${comp['loc'] ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      comp['type'] ?? 'Toàn thời gian',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
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
