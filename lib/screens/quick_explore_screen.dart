import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import 'login_screen.dart';

class QuickExploreScreen extends StatefulWidget {
  final String topic;

  const QuickExploreScreen({super.key, required this.topic});

  @override
  State<QuickExploreScreen> createState() => _QuickExploreScreenState();
}

class _QuickExploreScreenState extends State<QuickExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for TextFields
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  final TextEditingController _jobIndustryController = TextEditingController();
  final TextEditingController _jobPositionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  String? _response;
  Map<String, dynamic>? _structured;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _response = null;
      _structured = null;
      _hasError = false;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _industryController.dispose();
    _schoolController.dispose();
    _positionController.dispose();
    _jobIndustryController.dispose();
    _jobPositionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_tabController.index == 0) {
      return _industryController.text.trim().isNotEmpty ||
          _schoolController.text.trim().isNotEmpty ||
          _positionController.text.trim().isNotEmpty;
    } else {
      return _jobIndustryController.text.trim().isNotEmpty ||
          _jobPositionController.text.trim().isNotEmpty ||
          _locationController.text.trim().isNotEmpty;
    }
  }

  Future<void> _ask() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập ít nhất 1 tiêu chí để tìm hiểu!',
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
      if (!auth.isAuthenticated) return;
    }

    final mode = _tabController.index == 0 ? 'HOC' : 'LAM';

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _response = null;
      _structured = null;
    });

    final result = await ApiService.searchCareer({
      'mode': mode,
      'industry': _tabController.index == 0 ? _industryController.text.trim() : _jobIndustryController.text.trim(),
      'school': _tabController.index == 0 ? _schoolController.text.trim() : '',
      'position': _tabController.index == 0 ? _positionController.text.trim() : _jobPositionController.text.trim(),
      'location': _tabController.index == 0 ? '' : _locationController.text.trim(),
      'age': auth.userProfile?['age'] ?? 18,
    });

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      final aiSuccess = result['success'] == true;
      final hasAdvice = result['advice'] != null;
      final advice = result['advice'];

      if (aiSuccess && hasAdvice) {
        if (advice is Map<String, dynamic>) {
          _structured = advice;
          _response = (advice['summary'] is String)
              ? advice['summary'] as String
              : null;
        } else if (advice is String) {
          _response = advice;
        }
      } else {
        _hasError = true;
        _errorMessage =
            result['message'] ?? 'Không thể kết nối dịch vụ tư vấn AI.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tư Vấn Nhanh Hướng Nghiệp',
          style: GoogleFonts.outfit(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Responsive.s(context, 48)),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: GoogleFonts.outfit(
                fontSize: Responsive.font(context, 13),
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.outfit(
                fontSize: Responsive.font(context, 13),
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'TÌM TRƯỜNG & NGÀNH'),
                Tab(text: 'THỊ TRƯỜNG VIỆC LÀM'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSchoolTab(),
            _buildJobMarketTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHintCard(
            icon: Icons.school_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Tìm trường & ngành phù hợp',
            subtitle:
                'Nhập các tiêu chí bên dưới để AI gợi ý trường và ngành đào tạo phù hợp với bạn.',
          ),
          SizedBox(height: Responsive.s(context, 20)),
          _buildInputField(
            label: 'Ngành học quan tâm',
            icon: Icons.category_outlined,
            controller: _industryController,
            hint: 'Nhập ngành học (ví dụ: Công nghệ thông tin)',
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildInputField(
            label: 'Trường',
            icon: Icons.account_balance_outlined,
            controller: _schoolController,
            hint: 'Nhập tên trường (ví dụ: Đại học Bách Khoa)',
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildInputField(
            label: 'Vị trí công việc mong muốn',
            icon: Icons.work_outline_rounded,
            controller: _positionController,
            hint: 'Nhập vị trí công việc (ví dụ: Lập trình viên)',
          ),
          SizedBox(height: Responsive.s(context, 24)),
          _buildSubmitButton(
            color: const Color(0xFF3B82F6),
            label: 'Tìm hiểu',
            icon: Icons.search_rounded,
          ),
          SizedBox(height: Responsive.s(context, 24)),
          if (_isLoading) _buildLoadingBox(const Color(0xFF3B82F6))
          else if (_hasError)
            _buildErrorBox()
          else if (_response != null || _structured != null)
            _buildAnswerBox(
              color: const Color(0xFF3B82F6),
              icon: Icons.school_rounded,
              title: 'Trường & ngành phù hợp',
            ),
        ],
      ),
    );
  }

  Widget _buildJobMarketTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHintCard(
            icon: Icons.work_rounded,
            color: const Color(0xFF10B981),
            title: 'Khám phá thị trường việc làm',
            subtitle:
                'Nhập các tiêu chí bên dưới để AI gợi ý công ty và vị trí đang tuyển dụng.',
          ),
          SizedBox(height: Responsive.s(context, 20)),
          _buildInputField(
            label: 'Chọn ngành nghề',
            icon: Icons.category_outlined,
            controller: _jobIndustryController,
            hint: 'Nhập ngành nghề (ví dụ: Thiết kế đồ họa)',
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildInputField(
            label: 'Vị trí công việc',
            icon: Icons.work_outline_rounded,
            controller: _jobPositionController,
            hint: 'Nhập vị trí công việc (ví dụ: UI/UX Designer)',
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildInputField(
            label: 'Địa điểm/Khu vực',
            icon: Icons.location_on_outlined,
            controller: _locationController,
            hint: 'Nhập tỉnh/thành phố (ví dụ: TP. Hồ Chí Minh)',
          ),
          SizedBox(height: Responsive.s(context, 24)),
          _buildSubmitButton(
            color: const Color(0xFF10B981),
            label: 'Tìm hiểu',
            icon: Icons.search_rounded,
          ),
          SizedBox(height: Responsive.s(context, 24)),
          if (_isLoading) _buildLoadingBox(const Color(0xFF10B981))
          else if (_hasError)
            _buildErrorBox()
          else if (_response != null || _structured != null)
            _buildAnswerBox(
              color: const Color(0xFF10B981),
              icon: Icons.work_rounded,
              title: 'Công ty & cơ hội việc làm',
            ),
        ],
      ),
    );
  }

  Widget _buildHintCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Responsive.s(context, 14)),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.s(context, 10)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(
                Responsive.s(context, 12),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: Responsive.s(context, 22),
            ),
          ),
          SizedBox(width: Responsive.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 4)),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 12),
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    Color activeIconColor = const Color(0xFFF59E0B),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: Responsive.s(context, 4)),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 12),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
        ),
        SizedBox(height: Responsive.s(context, 6)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 12),
            ),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 14),
              color: const Color(0xFF1F2937),
            ),
            onChanged: (text) {
              setState(() {}); // Trigger rebuild to update _canSubmit button state
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: Responsive.font(context, 14),
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                icon,
                size: Responsive.s(context, 18),
                color: controller.text.isNotEmpty
                    ? activeIconColor
                    : const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 14),
                vertical: Responsive.s(context, 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _ask,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: Responsive.s(context, 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 12),
            ),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: Responsive.s(context, 18),
                height: Responsive.s(context, 18),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: Responsive.s(context, 18)),
                  SizedBox(width: Responsive.s(context, 8)),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: Responsive.font(context, 15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingBox(Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.s(context, 16)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: Responsive.s(context, 24),
            height: Responsive.s(context, 24),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(height: Responsive.s(context, 12)),
          Text(
            'AI đang phân tích câu hỏi của bạn...',
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 13),
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(Responsive.s(context, 14)),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFDC2626),
            size: Responsive.s(context, 20),
          ),
          SizedBox(width: Responsive.s(context, 12)),
          Expanded(
            child: Text(
              _errorMessage ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
              style: GoogleFonts.inter(
                fontSize: Responsive.font(context, 13),
                color: const Color(0xFF991B1B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBox({
    required Color color,
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.s(context, 16)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Icon(icon, size: Responsive.s(context, 18), color: color),
              SizedBox(width: Responsive.s(context, 8)),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.font(context, 15),
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 12)),
          if (_response != null && _response!.isNotEmpty)
            Text(
              _response!,
              style: GoogleFonts.inter(
                fontSize: Responsive.font(context, 13),
                color: const Color(0xFF1F2937),
                height: 1.5,
              ),
            ),
          if (_structured != null) ...[
            if (_structured!['schools'] != null && _structured!['schools'] is List)
              ...(_structured!['schools'] as List).map((s) {
                final m = (s is Map<String, dynamic>)
                    ? s
                    : (s is Map) ? Map<String, dynamic>.from(s) : <String, dynamic>{};
                return _buildSchoolCard(m, color);
              }),
            if (_structured!['companies'] != null &&
                _structured!['companies'] is List)
              ...(_structured!['companies'] as List).map((c) {
                final m = (c is Map<String, dynamic>)
                    ? c
                    : (c is Map) ? Map<String, dynamic>.from(c) : <String, dynamic>{};
                return _buildCompanyCard(m, color);
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> m, Color accent) {
    final name = (m['schoolName'] ?? m['name'] ?? 'Trường').toString();
    final majors = (m['majors'] ?? m['specializations'] ?? m['nganh'])
            is List
        ? List<String>.from(m['majors'] ?? m['specializations'] ?? m['nganh'])
        : <String>[];
    final reason = m['reason'] ?? m['lyDo'] ?? m['note'];
    final link = (m['website'] ?? m['url'] ?? m['link'])?.toString();
    final location = m['location'] ?? m['diaDiem'];

    final benchmark = _extractBenchmarkScores(m);
    final hasBenchmark = benchmark.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(top: Responsive.s(context, 10)),
      padding: EdgeInsets.all(Responsive.s(context, 14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, accent.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(Responsive.s(context, 14)),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                width: Responsive.s(context, 44),
                height: Responsive.s(context, 44),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 12),
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.characters.first.toUpperCase() : 'T',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(context, 18),
                    ),
                  ),
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
                        fontSize: Responsive.font(context, 15),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (location != null &&
                        location.toString().isNotEmpty) ...[
                      SizedBox(height: Responsive.s(context, 2)),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: Responsive.s(context, 13),
                            color: const Color(0xFF6B7280),
                          ),
                          SizedBox(width: Responsive.s(context, 3)),
                          Expanded(
                            child: Text(
                              location.toString(),
                              style: GoogleFonts.inter(
                                fontSize: Responsive.font(context, 12),
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasBenchmark) ...[
            SizedBox(height: Responsive.s(context, 12)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 12),
                vertical: Responsive.s(context, 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 10),
                ),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: Responsive.s(context, 14),
                        color: const Color(0xFF0369A1),
                      ),
                      SizedBox(width: Responsive.s(context, 6)),
                      Text(
                        'Điểm chuẩn 3 năm gần nhất',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 12),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.s(context, 8)),
                  Row(
                    children: benchmark.map((entry) {
                      return Expanded(
                        child: _buildBenchmarkCell(
                          year: entry.year,
                          score: entry.score,
                          major: entry.major,
                          accent: accent,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          if (majors.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 10)),
            Wrap(
              spacing: Responsive.s(context, 6),
              runSpacing: Responsive.s(context, 6),
              children: majors
                  .take(4)
                  .map(
                    (m) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 10),
                        vertical: Responsive.s(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 8),
                        ),
                      ),
                      child: Text(
                        m,
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (reason != null && reason.toString().isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 8)),
            Text(
              reason.toString(),
              style: GoogleFonts.inter(
                fontSize: Responsive.font(context, 12),
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (link != null && link.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 10)),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(link);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(
                Responsive.s(context, 8),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 10),
                  vertical: Responsive.s(context, 6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 8),
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: Responsive.s(context, 14),
                      color: accent,
                    ),
                    SizedBox(width: Responsive.s(context, 4)),
                    Flexible(
                      child: Text(
                        'Mở trang trường: ${link.replaceFirst(RegExp(r'^https?://'), '')}',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenchmarkCell({
    required String year,
    required String score,
    String? major,
    required Color accent,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.s(context, 3)),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.s(context, 10),
        vertical: Responsive.s(context, 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Năm $year',
            style: GoogleFonts.inter(
              fontSize: Responsive.font(context, 10),
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Responsive.s(context, 2)),
          Text(
            score,
            style: GoogleFonts.outfit(
              fontSize: Responsive.font(context, 16),
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          if (major != null && major.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 2)),
            Text(
              major,
              style: GoogleFonts.inter(
                fontSize: Responsive.font(context, 9),
                color: const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  List<_BenchmarkEntry> _extractBenchmarkScores(Map<String, dynamic> m) {
    final dynamic raw =
        m['benchmarkScores'] ?? m['diemChuan'] ?? m['cutoffScores'];

    if (raw is String) {
      final entries = <_BenchmarkEntry>[];
      final regExp = RegExp(r'(\d{4})\s*[:\-]\s*(\d+(?:\.\d+)?)');
      final matches = regExp.allMatches(raw);
      for (final match in matches.take(3)) {
        entries.add(
          _BenchmarkEntry(
            year: match.group(1)!,
            score: match.group(2)!,
          ),
        );
      }
      if (entries.isNotEmpty) return entries;
    }

    if (raw is Map) {
      final entries = <_BenchmarkEntry>[];
      final keys = raw.keys.toList();
      final values = raw.values.toList();
      for (int i = 0; i < keys.length && i < 3; i++) {
        final dynamic v = values[i];
        if (v is num) {
          entries.add(
            _BenchmarkEntry(
              year: keys[i].toString(),
              score: _formatScore(v.toDouble()),
            ),
          );
        } else if (v is String) {
          entries.add(
            _BenchmarkEntry(year: keys[i].toString(), score: v),
          );
        } else if (v is Map) {
          entries.add(
            _BenchmarkEntry(
              year: (v['year'] ?? keys[i]).toString(),
              score: v['score']?.toString() ?? '',
              major: v['major']?.toString(),
            ),
          );
        }
      }
      return entries;
    }

    if (raw is List) {
      return raw
          .take(3)
          .map((e) {
            if (e is Map) {
              return _BenchmarkEntry(
                year: (e['year'] ?? e['nam'] ?? '').toString(),
                score: (e['score'] ?? e['diem'] ?? '').toString(),
                major: (e['major'] ?? e['nganh'])?.toString(),
              );
            }
            if (e is String) return _BenchmarkEntry(year: '', score: e);
            return null;
          })
          .whereType<_BenchmarkEntry>()
          .where((e) => e.score.isNotEmpty)
          .toList();
    }

    return <_BenchmarkEntry>[];
  }

  String _formatScore(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Widget _buildCompanyCard(Map<String, dynamic> m, Color accent) {
    final name = (m['companyName'] ?? m['name'] ?? 'Công ty').toString();
    final positions =
        (m['positions'] ?? m['jobs'] ?? m['viTri']) is List
            ? List<String>.from(m['positions'] ?? m['jobs'] ?? m['viTri'])
            : <String>[];
    final reason = m['reason'] ?? m['lyDo'] ?? m['note'];
    final link = m['website'] ?? m['url'] ?? m['link'];
    final location = m['location'] ?? m['diaDiem'];
    final salary = m['salary'] ?? m['luong'];

    return Container(
      margin: EdgeInsets.only(top: Responsive.s(context, 10)),
      padding: EdgeInsets.all(Responsive.s(context, 14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, accent.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(Responsive.s(context, 14)),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                width: Responsive.s(context, 44),
                height: Responsive.s(context, 44),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 12),
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.characters.first.toUpperCase() : 'C',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(context, 18),
                    ),
                  ),
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
                        fontSize: Responsive.font(context, 15),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (location != null &&
                        location.toString().isNotEmpty) ...[
                      SizedBox(height: Responsive.s(context, 2)),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: Responsive.s(context, 13),
                            color: const Color(0xFF6B7280),
                          ),
                          SizedBox(width: Responsive.s(context, 3)),
                          Expanded(
                            child: Text(
                              location.toString(),
                              style: GoogleFonts.inter(
                                fontSize: Responsive.font(context, 12),
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (positions.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 10)),
            Wrap(
              spacing: Responsive.s(context, 6),
              runSpacing: Responsive.s(context, 6),
              children: positions
                  .take(4)
                  .map(
                    (p) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 10),
                        vertical: Responsive.s(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 8),
                        ),
                      ),
                      child: Text(
                        p,
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (salary != null && salary.toString().isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 8)),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: Responsive.s(context, 14),
                  color: const Color(0xFF059669),
                ),
                SizedBox(width: Responsive.s(context, 4)),
                Text(
                  salary.toString(),
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ],
          if (reason != null && reason.toString().isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 8)),
            Text(
              reason.toString(),
              style: GoogleFonts.inter(
                fontSize: Responsive.font(context, 12),
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (link != null && link.toString().isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 10)),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(link.toString());
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(
                Responsive.s(context, 8),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 10),
                  vertical: Responsive.s(context, 6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 8),
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: Responsive.s(context, 14),
                      color: accent,
                    ),
                    SizedBox(width: Responsive.s(context, 4)),
                    Flexible(
                      child: Text(
                        link.toString().replaceFirst(RegExp(r'^https?://'), ''),
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 11),
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenchmarkEntry {
  final String year;
  final String score;
  final String? major;

  const _BenchmarkEntry({
    required this.year,
    required this.score,
    this.major,
  });
}