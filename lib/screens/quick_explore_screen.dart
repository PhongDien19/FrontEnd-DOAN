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

  // Tab 1: Tìm trường & ngành
  String? _selectedIndustry;
  String? _selectedSchool;
  String? _selectedPosition;

  // Tab 2: Thị trường việc làm
  String? _selectedJobIndustry;
  String? _selectedJobPosition;
  String? _selectedLocation;

  bool _isLoading = false;
  String? _response;
  Map<String, dynamic>? _structured;
  bool _hasError = false;
  String? _errorMessage;

  // Mock data
  final List<String> _industries = [
    'Công nghệ thông tin',
    'Marketing',
    'Tài chính - Ngân hàng',
    'Kế toán - Kiểm toán',
    'Cơ khí - Tự động hóa',
    'Điện - Điện tử',
    'Xây dựng',
    'Y tế - Dược phẩm',
    'Giáo dục',
    'Logistics',
    'Du lịch - Khách sạn',
    'Thiết kế - Sáng tạo',
    'Nhân sự',
    'Kinh doanh - Bán hàng',
    'Truyền thông',
    'Luật - Pháp lý',
  ];

  final List<String> _schools = [
    'ĐH Bách Khoa Hà Nội',
    'ĐH Quốc gia Hà Nội',
    'ĐH Quốc gia TP.HCM',
    'ĐH Kinh tế Quốc dân',
    'ĐH Ngoại thương',
    'ĐH FPT',
    'ĐH Bách Khoa TP.HCM',
    'ĐH Công nghệ - ĐHQG HN',
    'ĐH Sư phạm Kỹ thuật HCM',
    'ĐH Khoa học Tự nhiên',
    'HV Bưu chính Viễn thông',
    'ĐH Kinh tế TP.HCM (UEH)',
    'ĐH Tôn Đức Thắng',
    'ĐH RMIT Việt Nam',
  ];

  final List<String> _positions = [
    'Lập trình viên (Developer)',
    'Kỹ sư phần mềm',
    'Data Analyst / Data Scientist',
    'Chuyên viên Marketing',
    'Quản lý dự án',
    'Kế toán viên',
    'Chuyên viên nhân sự',
    'Thiết kế đồ họa',
    'Kỹ sư cơ khí',
    'Kỹ sư điện',
    'Chuyên viên kinh doanh',
    'Content Creator',
    'Biên phiên dịch',
    'Giáo viên / Giảng viên',
  ];

  final Map<String, List<String>> _positionsByIndustry = {
    'Công nghệ thông tin': [
      'Lập trình viên (Developer)',
      'Kỹ sư phần mềm',
      'Data Analyst / Data Scientist',
      'Quản lý dự án',
    ],
    'Marketing': [
      'Chuyên viên Marketing',
      'Content Creator',
      'Thiết kế đồ họa',
      'Chuyên viên kinh doanh',
    ],
    'Tài chính - Ngân hàng': [
      'Kế toán viên',
      'Data Analyst / Data Scientist',
      'Chuyên viên kinh doanh',
    ],
    'Kế toán - Kiểm toán': [
      'Kế toán viên',
      'Chuyên viên kinh doanh',
    ],
    'Cơ khí - Tự động hóa': [
      'Kỹ sư cơ khí',
      'Kỹ sư điện',
      'Quản lý dự án',
    ],
    'Điện - Điện tử': [
      'Kỹ sư điện',
      'Kỹ sư phần mềm',
      'Quản lý dự án',
    ],
    'Xây dựng': [
      'Quản lý dự án',
      'Kỹ sư cơ khí',
    ],
    'Y tế - Dược phẩm': [
      'Chuyên viên kinh doanh',
      'Quản lý dự án',
    ],
    'Giáo dục': [
      'Giáo viên / Giảng viên',
      'Chuyên viên nhân sự',
    ],
    'Logistics': [
      'Chuyên viên kinh doanh',
      'Quản lý dự án',
    ],
    'Du lịch - Khách sạn': [
      'Chuyên viên kinh doanh',
      'Biên phiên dịch',
    ],
    'Thiết kế - Sáng tạo': [
      'Thiết kế đồ họa',
      'Content Creator',
      'Chuyên viên Marketing',
    ],
    'Nhân sự': [
      'Chuyên viên nhân sự',
      'Quản lý dự án',
    ],
    'Kinh doanh - Bán hàng': [
      'Chuyên viên kinh doanh',
      'Chuyên viên Marketing',
      'Quản lý dự án',
    ],
    'Truyền thông': [
      'Content Creator',
      'Chuyên viên Marketing',
      'Thiết kế đồ họa',
      'Biên phiên dịch',
    ],
    'Luật - Pháp lý': [
      'Chuyên viên nhân sự',
      'Quản lý dự án',
    ],
  };

  List<String> get _filteredSchoolPositions {
    if (_selectedIndustry == null) return _positions;
    return _positionsByIndustry[_selectedIndustry!] ?? _positions;
  }

  List<String> get _filteredJobPositions {
    if (_selectedJobIndustry == null) return _positions;
    return _positionsByIndustry[_selectedJobIndustry!] ?? _positions;
  }

  final List<String> _locations = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Long An',
    'Bắc Ninh',
    'Thái Nguyên',
    'Quảng Ninh',
    'Khác (toàn quốc)',
  ];

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
    super.dispose();
  }

  bool get _canSubmit {
    if (_tabController.index == 0) {
      return _selectedIndustry != null ||
          _selectedSchool != null ||
          _selectedPosition != null;
    } else {
      return _selectedJobIndustry != null ||
          _selectedJobPosition != null ||
          _selectedLocation != null;
    }
  }

  Future<void> _ask() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng chọn ít nhất 1 tiêu chí để tìm hiểu!',
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

    String question;
    String mode;
    if (_tabController.index == 0) {
      mode = 'HOC';
      final parts = <String>[];
      if (_selectedIndustry != null) parts.add('ngành $_selectedIndustry');
      if (_selectedSchool != null) parts.add('trường $_selectedSchool');
      if (_selectedPosition != null) parts.add('vị trí $_selectedPosition');
      question =
          'Tư vấn cho tôi về ${parts.join(", ")}. Gợi ý các trường đào tạo phù hợp.';
    } else {
      mode = 'LAM';
      final parts = <String>[];
      if (_selectedJobIndustry != null) {
        parts.add('ngành $_selectedJobIndustry');
      }
      if (_selectedJobPosition != null) {
        parts.add('vị trí $_selectedJobPosition');
      }
      if (_selectedLocation != null) {
        parts.add('khu vực $_selectedLocation');
      }
      question =
          'Tư vấn thị trường việc làm cho ${parts.join(", ")}. Gợi ý các công ty đang tuyển dụng.';
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _response = null;
      _structured = null;
    });

    final userContext = {
      'targetJob': auth.targetJob,
      'educationLevel': auth.educationLevel,
      'age': auth.userProfile?['age'] ?? 18,
      'hobby': auth.hobby,
      'requestType': mode,
    };

    final result = await ApiService.consultCareer({
      'question': question,
      'userContext': userContext,
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
                'Chọn các tiêu chí bên dưới để AI gợi ý trường và ngành đào tạo phù hợp với bạn.',
          ),
          SizedBox(height: Responsive.s(context, 20)),
          _buildDropdownField(
            label: 'Ngành học quan tâm',
            icon: Icons.category_outlined,
            value: _selectedIndustry,
            items: _industries,
            onChanged: (v) => setState(() {
              _selectedIndustry = v;
              _selectedPosition = null;
            }),
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildDropdownField(
            label: 'Trường',
            icon: Icons.account_balance_outlined,
            value: _selectedSchool,
            items: _schools,
            onChanged: (v) => setState(() => _selectedSchool = v),
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildDropdownField(
            label: 'Vị trí công việc mong muốn',
            icon: Icons.work_outline_rounded,
            value: _selectedPosition,
            items: _filteredSchoolPositions,
            onChanged: (v) => setState(() => _selectedPosition = v),
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
                'Chọn các tiêu chí bên dưới để AI gợi ý công ty và vị trí đang tuyển dụng.',
          ),
          SizedBox(height: Responsive.s(context, 20)),
          _buildDropdownField(
            label: 'Chọn ngành nghề',
            icon: Icons.category_outlined,
            value: _selectedJobIndustry,
            items: _industries,
            onChanged: (v) => setState(() {
              _selectedJobIndustry = v;
              _selectedJobPosition = null;
            }),
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildDropdownField(
            label: 'Vị trí công việc',
            icon: Icons.work_outline_rounded,
            value: _selectedJobPosition,
            items: _filteredJobPositions,
            onChanged: (v) => setState(() => _selectedJobPosition = v),
          ),
          SizedBox(height: Responsive.s(context, 14)),
          _buildDropdownField(
            label: 'Địa điểm/Khu vực',
            icon: Icons.location_on_outlined,
            value: _selectedLocation,
            items: _locations,
            onChanged: (v) => setState(() => _selectedLocation = v),
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 12),
            ),
            onTap: () => _showPickerSheet(
              label: label,
              icon: icon,
              items: items,
              selectedValue: value,
              onSelected: onChanged,
            ),
            child: Container(
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
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 14),
                vertical: Responsive.s(context, 14),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: Responsive.s(context, 18),
                    color: value != null
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF9CA3AF),
                  ),
                  SizedBox(width: Responsive.s(context, 10)),
                  Expanded(
                    child: Text(
                      value ?? '-- Chọn --',
                      style: GoogleFonts.inter(
                        fontSize: Responsive.font(context, 14),
                        color: value != null
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF9CA3AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6B7280),
                    size: Responsive.s(context, 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPickerSheet({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    String query = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.s(context, 20)),
        ),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final lowerQuery = query.trim().toLowerCase();
                final filtered = lowerQuery.isEmpty
                    ? items
                    : items
                        .where(
                          (i) => i.toLowerCase().contains(lowerQuery),
                        )
                        .toList();

                return Column(
                  children: [
                    Container(
                      margin:
                          EdgeInsets.only(top: Responsive.s(context, 12)),
                      width: Responsive.s(context, 40),
                      height: Responsive.s(context, 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.s(context, 20),
                        Responsive.s(context, 16),
                        Responsive.s(context, 20),
                        Responsive.s(context, 8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              Responsive.s(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                Responsive.s(context, 10),
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFFF59E0B),
                              size: Responsive.s(context, 18),
                            ),
                          ),
                          SizedBox(width: Responsive.s(context, 12)),
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.outfit(
                                fontSize: Responsive.font(context, 16),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 20),
                        vertical: Responsive.s(context, 4),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 12),
                          ),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: TextField(
                          autofocus: false,
                          textInputAction: TextInputAction.search,
                          onChanged: (v) =>
                              setSheetState(() => query = v),
                          style: GoogleFonts.inter(
                            fontSize: Responsive.font(context, 14),
                            color: const Color(0xFF1F2937),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập để tìm kiếm...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: Responsive.font(context, 13),
                              color: const Color(0xFF9CA3AF),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: const Color(0xFF6B7280),
                              size: Responsive.s(context, 20),
                            ),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: const Color(0xFF6B7280),
                                      size: Responsive.s(context, 18),
                                    ),
                                    onPressed: () =>
                                        setSheetState(() => query = ''),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Responsive.s(context, 12),
                              vertical: Responsive.s(context, 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.s(context, 8)),
                    Divider(
                      color: const Color(0xFFE5E7EB),
                      height: Responsive.s(context, 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 20),
                        vertical: Responsive.s(context, 8),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} kết quả',
                            style: GoogleFonts.inter(
                              fontSize:
                                  Responsive.font(context, 12),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (selectedValue != null)
                            TextButton.icon(
                              onPressed: () {
                                onSelected(null);
                                Navigator.pop(sheetContext);
                              },
                              icon: Icon(
                                Icons.clear_all_rounded,
                                size: Responsive.s(context, 14),
                                color: const Color(0xFFDC2626),
                              ),
                              label: Text(
                                'Bỏ chọn',
                                style: GoogleFonts.inter(
                                  fontSize:
                                      Responsive.font(context, 12),
                                  color: const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: Responsive.s(context, 48),
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                  SizedBox(
                                    height:
                                        Responsive.s(context, 8),
                                  ),
                                  Text(
                                    'Không tìm thấy kết quả',
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.font(
                                        context,
                                        13,
                                      ),
                                      color:
                                          const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.only(
                                bottom: Responsive.s(context, 20),
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final item = filtered[index];
                                final isSelected =
                                    item == selectedValue;
                                return InkWell(
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(sheetContext);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.s(
                                        context,
                                        20,
                                      ),
                                      vertical: Responsive.s(
                                        context,
                                        14,
                                      ),
                                    ),
                                    color: isSelected
                                        ? const Color(0xFFFFF7ED)
                                        : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item,
                                            style:
                                                GoogleFonts.inter(
                                              fontSize:
                                                  Responsive.font(
                                                context,
                                                14,
                                              ),
                                              color: isSelected
                                                  ? const Color(
                                                      0xFFF59E0B,
                                                    )
                                                  : const Color(
                                                      0xFF1F2937,
                                                    ),
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight
                                                          .w600
                                                      : FontWeight
                                                          .w400,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_rounded,
                                            color: const Color(
                                              0xFFF59E0B,
                                            ),
                                            size: Responsive.s(
                                              context,
                                              20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
                        'Điểm chuẩn 2 năm gần nhất',
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

    if (raw is Map) {
      final entries = <_BenchmarkEntry>[];
      final keys = raw.keys.toList();
      final values = raw.values.toList();
      for (int i = 0; i < keys.length && i < 2; i++) {
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
          .take(2)
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