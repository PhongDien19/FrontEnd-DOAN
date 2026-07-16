import 'dart:convert';
import 'package:flutter/material.dart';
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

  final TextEditingController _jobIndustryController = TextEditingController();
  final TextEditingController _jobPositionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  static final Map<String, _QuickExploreCache> _cacheMap = {};

  bool _isLoadingSchool = false;
  String? _responseSchool;
  Map<String, dynamic>? _structuredSchool;
  bool _hasErrorSchool = false;
  String? _errorMessageSchool;

  bool _isLoadingJob = false;
  String? _responseJob;
  Map<String, dynamic>? _structuredJob;
  bool _hasErrorJob = false;
  String? _errorMessageJob;
  bool get _isLoading => _isLoadingSchool || _isLoadingJob;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final cache = _cacheMap[widget.topic] ??= _QuickExploreCache();

    // Restore text inputs
    _industryController.text = cache.industryText;
    _schoolController.text = cache.schoolText;
    _jobIndustryController.text = cache.jobIndustryText;
    _jobPositionController.text = cache.jobPositionText;
    _locationController.text = cache.locationText;

    // Restore active tab
    _tabController.index = cache.tabIndex;

    // Restore results
    _isLoadingSchool = cache.isLoadingSchool;
    _responseSchool = cache.responseSchool;
    _structuredSchool = cache.structuredSchool;
    _hasErrorSchool = cache.hasErrorSchool;
    _errorMessageSchool = cache.errorMessageSchool;

    _isLoadingJob = cache.isLoadingJob;
    _responseJob = cache.responseJob;
    _structuredJob = cache.structuredJob;
    _hasErrorJob = cache.hasErrorJob;
    _errorMessageJob = cache.errorMessageJob;

    _tabController.addListener(_onTabChanged);

    // Save inputs to cache instantly on changes
    _industryController.addListener(() => cache.industryText = _industryController.text);
    _schoolController.addListener(() => cache.schoolText = _schoolController.text);
    _jobIndustryController.addListener(() => cache.jobIndustryText = _jobIndustryController.text);
    _jobPositionController.addListener(() => cache.jobPositionText = _jobPositionController.text);
    _locationController.addListener(() => cache.locationText = _locationController.text);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final cache = _cacheMap[widget.topic];
    if (cache != null) {
      cache.tabIndex = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _industryController.dispose();
    _schoolController.dispose();
    _jobIndustryController.dispose();
    _jobPositionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    // Validate: at least one field must have content
    final hasText = _tabController.index == 0
        ? (_schoolController.text.trim().isNotEmpty ||
              _industryController.text.trim().isNotEmpty)
        : (_jobIndustryController.text.trim().isNotEmpty ||
              _jobPositionController.text.trim().isNotEmpty ||
              _locationController.text.trim().isNotEmpty);

    if (!hasText) {
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
    final cache = _cacheMap[widget.topic];

    if (mode == 'HOC') {
      setState(() {
        _isLoadingSchool = true;
        _hasErrorSchool = false;
        _errorMessageSchool = null;
        _responseSchool = null;
        _structuredSchool = null;
      });
      if (cache != null) {
        cache.isLoadingSchool = true;
        cache.hasErrorSchool = false;
        cache.errorMessageSchool = null;
        cache.responseSchool = null;
        cache.structuredSchool = null;
      }
    } else {
      setState(() {
        _isLoadingJob = true;
        _hasErrorJob = false;
        _errorMessageJob = null;
        _responseJob = null;
        _structuredJob = null;
      });
      if (cache != null) {
        cache.isLoadingJob = true;
        cache.hasErrorJob = false;
        cache.errorMessageJob = null;
        cache.responseJob = null;
        cache.structuredJob = null;
      }
    }

    final result = await ApiService.searchCareer({
      'mode': mode,
      'industry': _tabController.index == 0
          ? _industryController.text.trim()
          : _jobIndustryController.text.trim(),
      'school': _tabController.index == 0 ? _schoolController.text.trim() : '',
      'position': _tabController.index == 0
          ? ''
          : _jobPositionController.text.trim(),
      'location': _tabController.index == 0
          ? ''
          : _locationController.text.trim(),
      'age': auth.userProfile?['age'] ?? 18,
      'academicData': auth.userProfile?['studentScores'],
    });

    if (!mounted) return;

    final aiSuccess = result['success'] == true;
    final dynamic advice = result['advice'] ?? result['data'];

    String? response;
    Map<String, dynamic>? structured;
    bool hasError = false;
    String? errorMessage;

    if (aiSuccess && advice != null) {
      if (advice is Map) {
        final parsedAdvice = Map<String, dynamic>.from(advice);
        structured = parsedAdvice;
        response = parsedAdvice['summary']?.toString();
      } else if (advice is String && advice.trim().isNotEmpty) {
        final decoded = _decodeJsonMap(advice);
        if (decoded != null) {
          structured = decoded;
          response = decoded['summary']?.toString();
        } else {
          response = advice;
        }
      }
    }

    if (response == null && structured == null) {
      hasError = true;
      errorMessage = result['message']?.toString() ??
          'Máy chủ không trả về dữ liệu hiển thị.';
    }

    setState(() {
      if (mode == 'HOC') {
        _isLoadingSchool = false;
        _responseSchool = response;
        _structuredSchool = structured;
        _hasErrorSchool = hasError;
        _errorMessageSchool = errorMessage;

        if (cache != null) {
          cache.isLoadingSchool = false;
          cache.responseSchool = response;
          cache.structuredSchool = structured;
          cache.hasErrorSchool = hasError;
          cache.errorMessageSchool = errorMessage;
        }
      } else {
        _isLoadingJob = false;
        _responseJob = response;
        _structuredJob = structured;
        _hasErrorJob = hasError;
        _errorMessageJob = errorMessage;

        if (cache != null) {
          cache.isLoadingJob = false;
          cache.responseJob = response;
          cache.structuredJob = structured;
          cache.hasErrorJob = hasError;
          cache.errorMessageJob = errorMessage;
        }
      }
    });
  }

  Map<String, dynamic>? _decodeJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
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
          style: TextStyle(
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
              labelStyle: TextStyle(
                fontSize: Responsive.font(context, 13),
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: Responsive.font(context, 13),
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'TRƯỜNG & NGÀNH'),
                Tab(text: 'VIỆC LÀM'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            KeepAliveWrapper(child: _buildSchoolTab()),
            KeepAliveWrapper(child: _buildJobMarketTab()),
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
            activeIconColor: const Color(0xFF3B82F6),
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildInputField(
            label: 'Trường',
            icon: Icons.account_balance_outlined,
            controller: _schoolController,
            hint: 'Nhập tên trường (ví dụ: Đại học Bách Khoa)',
            activeIconColor: const Color(0xFF3B82F6),
          ),
          SizedBox(height: Responsive.s(context, 24)),
          _buildSubmitButton(
            color: const Color(0xFF3B82F6),
            label: 'Tìm hiểu',
            icon: Icons.search_rounded,
          ),
          SizedBox(height: Responsive.s(context, 24)),
          if (_isLoadingSchool)
            _buildLoadingBox(const Color(0xFF3B82F6))
          else if (_hasErrorSchool)
            _buildErrorBox(_errorMessageSchool)
          else if (_responseSchool != null || _structuredSchool != null)
            _buildAnswerBox(
              color: const Color(0xFF3B82F6),
              icon: Icons.school_rounded,
              title: 'Trường & ngành phù hợp',
              response: _responseSchool,
              structured: _structuredSchool,
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
          if (_isLoadingJob)
            _buildLoadingBox(const Color(0xFF10B981))
          else if (_hasErrorJob)
            _buildErrorBox(_errorMessageJob)
          else if (_responseJob != null || _structuredJob != null)
            _buildAnswerBox(
              color: const Color(0xFF10B981),
              icon: Icons.work_rounded,
              title: 'Công ty & cơ hội việc làm',
              response: _responseJob,
              structured: _structuredJob,
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
              borderRadius: BorderRadius.circular(Responsive.s(context, 12)),
            ),
            child: Icon(icon, color: color, size: Responsive.s(context, 22)),
          ),
          SizedBox(width: Responsive.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 4)),
                Text(
                  subtitle,
                  style: TextStyle(
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
            style: TextStyle(
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
            borderRadius: BorderRadius.circular(Responsive.s(context, 12)),
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
            style: TextStyle(
              fontSize: Responsive.font(context, 14),
              color: const Color(0xFF1F2937),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
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
          padding: EdgeInsets.symmetric(vertical: Responsive.s(context, 14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.s(context, 12)),
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
                    style: TextStyle(
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
            style: TextStyle(
              fontSize: Responsive.font(context, 13),
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String? errorMessage) {
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
              errorMessage ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
              style: TextStyle(
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
    required String? response,
    required Map<String, dynamic>? structured,
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.font(context, 14),
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 12)),
          if (response != null && response.isNotEmpty)
            Text(
              response,
              style: TextStyle(
                fontSize: Responsive.font(context, 13),
                color: const Color(0xFF1F2937),
                height: 1.5,
              ),
            ),
          if (structured != null) ...[
            if (structured['officialLink'] != null) ...[
              SizedBox(height: Responsive.s(context, 10)),
              _buildSchoolOfficialLinkButton(
                structured['officialLink'],
                color,
              ),
            ],
            // CASE 1: server trả về topMajors[] (chỉ có tên trường)
            if (structured['topMajors'] != null &&
                structured['topMajors'] is List)
              ...(structured['topMajors'] as List).map((m) {
                final raw = (m is Map<String, dynamic>)
                    ? m
                    : (m is Map)
                    ? Map<String, dynamic>.from(m)
                    : <String, dynamic>{};
                return _buildTopMajorCard(raw, color);
              }),
            // CASE 1: mô tả trường + website (schoolDescription, schoolWebsite)
            if (structured['schoolDescription'] != null &&
                structured['schoolDescription'].toString().isNotEmpty)
              _buildSchoolInfoBlock(color, structured),
            // CASE 2: server trả về schools[] (chỉ có tên ngành)
            if (structured['schools'] != null &&
                structured['schools'] is List)
              ...(structured['schools'] as List).map((s) {
                final m = (s is Map<String, dynamic>)
                    ? s
                    : (s is Map)
                    ? Map<String, dynamic>.from(s)
                    : <String, dynamic>{};
                return _buildSchoolCard(m, color);
              }),
            // CASE 3: server trả về majorInfo (có cả trường + ngành)
            if (structured['majorInfo'] is Map)
              _buildMajorInfoCard(
                Map<String, dynamic>.from(structured['majorInfo'] as Map),
                color,
              ),
            // MODE 'LAM': server trả về companies[]
            if (structured['companies'] != null &&
                structured['companies'] is List)
              ...(structured['companies'] as List).map((c) {
                final m = (c is Map<String, dynamic>)
                    ? c
                    : (c is Map)
                    ? Map<String, dynamic>.from(c)
                    : <String, dynamic>{};
                return _buildCompanyCard(m, color);
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildSchoolOfficialLinkButton(dynamic officialLinkRaw, Color accent) {
    String? url;
    String? title;
    if (officialLinkRaw is Map) {
      url = officialLinkRaw['url']?.toString();
      title = officialLinkRaw['title']?.toString();
    } else if (officialLinkRaw is String) {
      url = officialLinkRaw;
    }
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    title ??= 'Truy cập website chính thức của trường';

    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url!.startsWith('http') ? url : 'https://$url');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(Responsive.s(context, 10)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.s(context, 14),
          vertical: Responsive.s(context, 12),
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Responsive.s(context, 10)),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language_rounded,
              size: Responsive.s(context, 18),
              color: accent,
            ),
            SizedBox(width: Responsive.s(context, 8)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.font(context, 13),
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: Responsive.s(context, 12),
              color: accent,
            ),
          ],
        ),
      ),
    );
  }

  // CASE 1: Card hiển thị thông tin từng ngành hot trong topMajors[]
  // (khi người dùng chỉ nhập tên trường).
  Widget _buildTopMajorCard(Map<String, dynamic> m, Color accent) {
    final name = (m['majorName'] ?? m['name'] ?? 'Ngành').toString();

    // Điểm chuẩn KHÔNG còn hiển thị ở đây
    // Thay vào đó hiển thị admission link qua _buildAdmissionLinkButton(m, accent)

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              borderRadius: BorderRadius.circular(Responsive.s(context, 12)),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: Responsive.s(context, 22),
            ),
          ),
          SizedBox(width: Responsive.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 4)),
                // THAY ĐIỂM BẰNG LINK: Hiển thị link trang tuyển sinh
                _buildAdmissionLinkButton(m, accent),
                // XÓA phần "Nguồn: benchmarkScores.json" vì không còn đúng
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CASE 1: Khối hiển thị mô tả + website của trường (schoolDescription + schoolWebsite).
  Widget _buildSchoolInfoBlock(Color accent, Map<String, dynamic>? structured) {
    final description = structured?['schoolDescription']?.toString() ?? '';
    final website = structured?['schoolWebsite']?.toString();
    final schoolName = structured?['schoolName']?.toString() ?? 'trường này';

    return Container(
      margin: EdgeInsets.only(top: Responsive.s(context, 10)),
      padding: EdgeInsets.all(Responsive.s(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.s(context, 14)),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: Responsive.s(context, 16),
                color: accent,
              ),
              SizedBox(width: Responsive.s(context, 6)),
              Expanded(
                child: Text(
                  'Giới thiệu về $schoolName',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 13),
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 8)),
            Text(
              description,
              style: TextStyle(
                fontSize: Responsive.font(context, 12),
                color: const Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ],
          if (website != null && website.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 10)),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(website);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 10),
                  vertical: Responsive.s(context, 6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
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
                    Text(
                      'Trang web trường',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 11),
                        color: accent,
                        fontWeight: FontWeight.w600,
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

  // CASE 3: Card hiển thị thông tin điểm chuẩn của 1 ngành cụ thể tại 1 trường cụ thể.
  Widget _buildMajorInfoCard(Map<String, dynamic> m, Color accent) {
    final majorName = (m['majorName'] ?? _structuredSchool?['majorName'] ?? 'Ngành')
        .toString();
    final benchmarkVal =
        m['benchmark'] ??
        m['benchmark2025'] ??
        m['benchmark2024'] ??
        m['benchmark2023'];
    final year =
        m['benchmarkYear'] ??
        (m['benchmark2025'] != null
            ? 2025
            : m['benchmark2024'] != null
            ? 2024
            : m['benchmark2023'] != null
            ? 2023
            : null);
    final source = m['benchmarkSource']?.toString();
    final tier = m['benchmarkTier']?.toString();
    final estimated = m['benchmarkEstimated'] == true;
    final verified = m['benchmarkVerified'] == true;
    final reason = m['estimatedReason']?.toString();

    // LỌC NULL: Chỉ hiển thị điểm nếu là số hợp lệ (> 0 và <= 30)
    String? scoreStr;
    if (benchmarkVal != null) {
      double? scoreNum;
      if (benchmarkVal is num) {
        scoreNum = benchmarkVal.toDouble();
      } else {
        scoreNum = double.tryParse(benchmarkVal.toString());
      }
      // LỌC: Chỉ chấp nhận số > 0 và <= 30
      if (scoreNum != null && scoreNum > 0 && scoreNum <= 30) {
        scoreStr = _formatScore(scoreNum);
      }
    }

    return Container(
      margin: EdgeInsets.only(top: Responsive.s(context, 10)),
      padding: EdgeInsets.all(Responsive.s(context, 14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF0F9FF)],
        ),
        borderRadius: BorderRadius.circular(Responsive.s(context, 14)),
        border: Border.all(color: const Color(0xFFBAE6FD)),
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
            children: [
              Container(
                width: Responsive.s(context, 40),
                height: Responsive.s(context, 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1),
                  borderRadius: BorderRadius.circular(
                    Responsive.s(context, 10),
                  ),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: Responsive.s(context, 20),
                ),
              ),
              SizedBox(width: Responsive.s(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      majorName,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: Responsive.s(context, 2)),
                    Text(
                      _structuredSchool?['schoolName']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 11),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 12)),
          if (m['duration'] != null && m['duration'].toString().isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: Responsive.s(context, 16),
                  color: const Color(0xFF0369A1),
                ),
                SizedBox(width: Responsive.s(context, 8)),
                Text(
                  'Thời gian đào tạo: ',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  m['duration'].toString(),
                  style: TextStyle(
                    fontSize: Responsive.font(context, 12),
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.s(context, 8)),
          ],
          if (m['combinations'] != null &&
              m['combinations'] is List &&
              (m['combinations'] as List).isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: Responsive.s(context, 16),
                  color: const Color(0xFF0369A1),
                ),
                SizedBox(width: Responsive.s(context, 8)),
                Text(
                  'Tổ hợp xét tuyển: ',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                Expanded(
                  child: Text(
                    (m['combinations'] as List).join(', '),
                    style: TextStyle(
                      fontSize: Responsive.font(context, 12),
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.s(context, 8)),
          ],
          if (m['officialLink'] != null) ...[
            _buildSchoolOfficialLinkButton(
              m['officialLink'],
              const Color(0xFF0369A1),
            ),
            SizedBox(height: Responsive.s(context, 10)),
          ],
          if (scoreStr != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 12),
                vertical: Responsive.s(context, 10),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.s(context, 10)),
                border: Border.all(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: Responsive.s(context, 18),
                    color: const Color(0xFF0369A1),
                  ),
                  SizedBox(width: Responsive.s(context, 8)),
                  Text(
                    'Điểm chuẩn: ',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 12),
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    scoreStr,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                  if (year != null) ...[
                    SizedBox(width: Responsive.s(context, 4)),
                    Text(
                      '(Năm $year)',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 11),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (estimated)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 6),
                        vertical: Responsive.s(context, 2),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 4),
                        ),
                      ),
                      child: Text(
                        'Ước lượng',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 9),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    )
                  else if (verified)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 6),
                        vertical: Responsive.s(context, 2),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 4),
                        ),
                      ),
                      child: Text(
                        'Đã xác minh',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 9),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 12),
                vertical: Responsive.s(context, 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(Responsive.s(context, 10)),
              ),
              child: Text(
                'Chưa có dữ liệu điểm chuẩn chính xác cho ngành này.',
                style: TextStyle(
                  fontSize: Responsive.font(context, 12),
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if ((tier != null && tier.isNotEmpty) ||
              (source != null && source.isNotEmpty) ||
              (reason != null && reason.isNotEmpty)) ...[
            SizedBox(height: Responsive.s(context, 8)),
            if (tier != null && tier.isNotEmpty)
              Text(
                '• Mức: $tier',
                style: TextStyle(
                  fontSize: Responsive.font(context, 11),
                  color: const Color(0xFF4B5563),
                ),
              ),
            if (source != null && source.isNotEmpty)
              Text(
                '• Nguồn: $source',
                style: TextStyle(
                  fontSize: Responsive.font(context, 11),
                  color: const Color(0xFF4B5563),
                ),
              ),
            if (reason != null && reason.isNotEmpty)
              Text(
                '• $reason',
                style: TextStyle(
                  fontSize: Responsive.font(context, 11),
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
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
          await launchUrl(
            Uri.parse(effectiveUrl),
            mode: LaunchMode.externalApplication,
          );
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

  Widget _buildSchoolCard(Map<String, dynamic> m, Color accent) {
    final name = (m['schoolName'] ?? m['name'] ?? 'Trường').toString();
    final majors = (m['majors'] ?? m['specializations'] ?? m['nganh']) is List
        ? List<String>.from(m['majors'] ?? m['specializations'] ?? m['nganh'])
        : <String>[];
    final reason = m['reason'] ?? m['lyDo'] ?? m['note'];

    String? officialLink;
    String? admissionLink;

    final officialLinkRaw = m['officialLink'];
    if (officialLinkRaw != null) {
      if (officialLinkRaw is Map) {
        officialLink = officialLinkRaw['url']?.toString();
      } else if (officialLinkRaw is String) {
        officialLink = officialLinkRaw;
      }
    }

    final admissionLinkRaw = m['admissionLink'];
    if (admissionLinkRaw != null) {
      if (admissionLinkRaw is Map) {
        admissionLink = admissionLinkRaw['url']?.toString();
      } else if (admissionLinkRaw is String) {
        admissionLink = admissionLinkRaw;
      }
    }

    if ((officialLink == null || officialLink.isEmpty) &&
        (admissionLink == null || admissionLink.isEmpty)) {
      officialLink = (m['website'] ?? m['url'] ?? m['link'])?.toString();
    }

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
                    style: TextStyle(
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
                      style: TextStyle(
                        fontSize: Responsive.font(context, 15),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (location != null && location.toString().isNotEmpty) ...[
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
                              style: TextStyle(
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
                borderRadius: BorderRadius.circular(Responsive.s(context, 10)),
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
                        'Điểm chuẩn năm gần nhất',
                        style: TextStyle(
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
                        style: TextStyle(
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
              style: TextStyle(
                fontSize: Responsive.font(context, 12),
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
          if ((officialLink != null && officialLink.isNotEmpty) ||
              (admissionLink != null && admissionLink.isNotEmpty)) ...[
            SizedBox(height: Responsive.s(context, 10)),
            Row(
              children: [
                if (officialLink != null && officialLink.isNotEmpty)
                  _buildLinkChip(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    color: accent,
                    url: officialLink,
                  ),
                if (officialLink != null &&
                    officialLink.isNotEmpty &&
                    admissionLink != null &&
                    admissionLink.isNotEmpty)
                  SizedBox(width: Responsive.s(context, 12)),
                if (admissionLink != null && admissionLink.isNotEmpty)
                  _buildLinkChip(
                    icon: Icons.campaign_outlined,
                    label: 'Tuyển sinh',
                    color: accent,
                    url: admissionLink,
                  ),
              ],
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
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            'Năm $year',
            style: TextStyle(
              fontSize: Responsive.font(context, 10),
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Responsive.s(context, 2)),
          Text(
            score,
            style: TextStyle(
              fontSize: Responsive.font(context, 16),
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          if (major != null && major.isNotEmpty) ...[
            SizedBox(height: Responsive.s(context, 2)),
            Text(
              major,
              style: TextStyle(
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
    // LỌC NULL: Không hiển thị gì nếu không có điểm hợp lệ
    // Chỉ chấp nhận số > 0 và <= 30

    // Ưu tiên 1: server trả về field 'benchmark' (chuỗi kiểu "24.5" hoặc số)
    // kèm 'benchmarkYear' và 'benchmarkTier' riêng.
    final dynamic directBenchmark = m['benchmark'];
    final dynamic directYear = m['benchmarkYear'];
    if (directBenchmark != null && directBenchmark.toString().isNotEmpty) {
      final entries = <_BenchmarkEntry>[];
      // Trường hợp benchmark là chuỗi JSON dạng map {"2025": 24.5, "2024": 25.0}
      if (directBenchmark is String && directBenchmark.startsWith('{')) {
        try {
          final decoded = jsonDecode(directBenchmark);
          if (decoded is Map) {
            final keys = decoded.keys.toList();
            final values = decoded.values.toList();
            for (int i = 0; i < keys.length && i < 3; i++) {
              final dynamic v = values[i];
              if (v is num && v > 0 && v <= 30) {
                entries.add(
                  _BenchmarkEntry(
                    year: keys[i].toString(),
                    score: _formatScore(v.toDouble()),
                  ),
                );
              }
            }
            if (entries.isNotEmpty) return entries;
          }
        } catch (_) {}
      }
      // Trường hợp benchmark đơn lẻ (điểm năm hiện tại)
      if (directBenchmark is num) {
        // LỌC: Chỉ chấp nhận số > 0 và <= 30
        if (directBenchmark > 0 && directBenchmark <= 30) {
          final scoreStr = _formatScore(directBenchmark.toDouble());
          final String yearStr = directYear != null
              ? directYear.toString()
              : DateTime.now().year.toString();
          entries.add(_BenchmarkEntry(year: yearStr, score: scoreStr));
        }
      } else if (directBenchmark is String) {
        final parsed = double.tryParse(directBenchmark);
        if (parsed != null && parsed > 0 && parsed <= 30) {
          final scoreStr = _formatScore(parsed);
          final String yearStr = directYear != null
              ? directYear.toString()
              : DateTime.now().year.toString();
          entries.add(_BenchmarkEntry(year: yearStr, score: scoreStr));
        }
      }
      if (entries.isNotEmpty) return entries;
    }

    // Chỉ in điểm 1 năm gần nhất (2025). Nếu không có, thử 2024, rồi 2023.
    // Nhưng chỉ hiển thị 1 năm duy nhất trên UI.
    final yearlyBenchmarks = <String, dynamic>{
      '2025': m['benchmark2025'],
      '2024': m['benchmark2024'],
      '2023': m['benchmark2023'],
    };
    final yearlyEntries = <_BenchmarkEntry>[];
    yearlyBenchmarks.forEach((year, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        double? scoreNum;
        if (value is num) {
          scoreNum = value.toDouble();
        } else {
          scoreNum = double.tryParse(value.toString());
        }
        // LỌC: Chỉ chấp nhận số > 0 và <= 30
        if (scoreNum != null && scoreNum > 0 && scoreNum <= 30) {
          final score = _formatScore(scoreNum);
          yearlyEntries.add(_BenchmarkEntry(year: year, score: score));
        }
      }
    });
    if (yearlyEntries.isNotEmpty) {
      // CHỈ LẤY NĂM GẦN NHẤT (phần tử đầu tiên - 2025)
      return [yearlyEntries.first];
    }

    // Ưu tiên 2: các key phổ biến khác (cấu trúc cũ từ API khác)
    final dynamic raw =
        m['benchmarkScores'] ?? m['diemChuan'] ?? m['cutoffScores'];

    if (raw is String) {
      final entries = <_BenchmarkEntry>[];
      final regExp = RegExp(r'(\d{4})\s*[:\-]\s*(\d+(?:\.\d+)?)');
      final matches = regExp.allMatches(raw);
      for (final match in matches.take(3)) {
        entries.add(
          _BenchmarkEntry(year: match.group(1)!, score: match.group(2)!),
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
          entries.add(_BenchmarkEntry(year: keys[i].toString(), score: v));
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

  /// Widget hiển thị nút link trang tuyển sinh
  Widget _buildAdmissionLinkButton(Map<String, dynamic> m, Color accent) {
    final link = _extractAdmissionLink(m);

    if (link == null) {
      // Không có link -> hiển thị text gợi ý
      return Text(
        'Vui lòng truy cập trang tuyển sinh để xem điểm chuẩn',
        style: TextStyle(
          fontSize: Responsive.font(context, 11),
          color: const Color(0xFF9CA3AF),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return InkWell(
      onTap: () async {
        final url = link['url']!;
        final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(Responsive.s(context, 6)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.s(context, 10),
          vertical: Responsive.s(context, 6),
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Responsive.s(context, 6)),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
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
                link['title']!,
                style: TextStyle(
                  fontSize: Responsive.font(context, 12),
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trích xuất admission link từ data
  /// Trả về {url, title} hoặc null
  Map<String, String>? _extractAdmissionLink(Map<String, dynamic> m) {
    // Ưu tiên: officialLink (từ backend mới)
    final dynamic officialLinkRaw = m['officialLink'];
    if (officialLinkRaw != null) {
      if (officialLinkRaw is Map) {
        final url = officialLinkRaw['url']?.toString();
        final title = officialLinkRaw['title']?.toString();
        if (url != null && url.isNotEmpty) {
          return {'url': url, 'title': title ?? 'Xem điểm chuẩn'};
        }
      } else if (officialLinkRaw is String && officialLinkRaw.isNotEmpty) {
        return {'url': officialLinkRaw, 'title': 'Xem điểm chuẩn'};
      }
    }

    // Fallback: admissionLink
    final dynamic admissionLinkRaw = m['admissionLink'];
    if (admissionLinkRaw != null) {
      if (admissionLinkRaw is Map) {
        final url = admissionLinkRaw['url']?.toString();
        final title = admissionLinkRaw['title']?.toString();
        if (url != null && url.isNotEmpty) {
          return {'url': url, 'title': title ?? 'Xem điểm chuẩn'};
        }
      } else if (admissionLinkRaw is String && admissionLinkRaw.isNotEmpty) {
        return {'url': admissionLinkRaw, 'title': 'Xem điểm chuẩn'};
      }
    }

    // Fallback: benchmarkUrl (legacy)
    final benchmarkUrl = m['benchmarkUrl']?.toString();
    if (benchmarkUrl != null &&
        benchmarkUrl.isNotEmpty &&
        benchmarkUrl.startsWith('http')) {
      return {'url': benchmarkUrl, 'title': 'Xem điểm chuẩn'};
    }

    return null;
  }

  Widget _buildCompanyCard(Map<String, dynamic> m, Color accent) {
    final name = (m['companyName'] ?? m['name'] ?? 'Công ty').toString();
    final positions = (m['positions'] ?? m['jobs'] ?? m['viTri']) is List
        ? List<String>.from(m['positions'] ?? m['jobs'] ?? m['viTri'])
        : <String>[];
    final reason = m['reason'] ?? m['description'] ?? m['lyDo'] ?? m['note'];
    final link = m['website'] ?? m['url'] ?? m['link'] ?? m['careerLink'];
    final location = m['location'] ?? m['diaDiem'];
    final salary = m['salary'] ?? m['basicSalary'] ?? m['luong'];

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
                    style: TextStyle(
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
                      style: TextStyle(
                        fontSize: Responsive.font(context, 15),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (location != null && location.toString().isNotEmpty) ...[
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
                              style: TextStyle(
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
                        style: TextStyle(
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
                  style: TextStyle(
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
              style: TextStyle(
                fontSize: Responsive.font(context, 12),
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
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
              borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 10),
                  vertical: Responsive.s(context, 6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Responsive.s(context, 8)),
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
                        style: TextStyle(
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

  const _BenchmarkEntry({required this.year, required this.score, this.major});
}

class _QuickExploreCache {
  int tabIndex = 0;
  String industryText = '';
  String schoolText = '';
  String jobIndustryText = '';
  String jobPositionText = '';
  String locationText = '';

  bool isLoadingSchool = false;
  String? responseSchool;
  Map<String, dynamic>? structuredSchool;
  bool hasErrorSchool = false;
  String? errorMessageSchool;

  bool isLoadingJob = false;
  String? responseJob;
  Map<String, dynamic>? structuredJob;
  bool hasErrorJob = false;
  String? errorMessageJob;
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
