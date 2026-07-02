import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'dynamic_survey_report_screen.dart';

class DynamicSurveyScreen extends StatefulWidget {
  const DynamicSurveyScreen({super.key});

  @override
  State<DynamicSurveyScreen> createState() => _DynamicSurveyScreenState();
}

class _DynamicSurveyScreenState extends State<DynamicSurveyScreen> {
  // Trạng thái màn hình:
  // 0: Thiết lập chế độ (Setup)
  // 1: Đang khởi tạo câu hỏi (Loading questions)
  // 2: Trả lời câu hỏi (Survey flow)
  // 3: Đang chấm điểm và phân tích (Evaluating)
  int _step = 0;

  // Cấu hình chế độ
  String _mode = 'Discovery'; // 'Discovery' hoặc 'Targeted'
  final _targetCareerController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _hobbyController = TextEditingController();
  String _educationLevel = 'Đại học';
  final _formKey = GlobalKey<FormState>();

  // Dữ liệu khảo sát từ API
  String _sessionId = '';
  String _testName = 'Khảo Sát Hướng Nghiệp Động AI';
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;

  // Câu trả lời của người dùng: index -> weight
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfileContext();
  }

  void _loadUserProfileContext() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated && auth.userProfile != null) {
      final p = auth.userProfile!;
      _targetCareerController.text = p['targetJob'] ?? '';
      _ageController.text = (p['age'] ?? '').toString();
      _educationLevel = p['educationLevel'] ?? 'Đại học';
      _locationController.text = p['location'] ?? '';
      _hobbyController.text = p['interests'] ?? p['hobby'] ?? '';
    }
  }

  @override
  void dispose() {
    _targetCareerController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _hobbyController.dispose();
    super.dispose();
  }

  // Khởi tạo câu hỏi khảo sát từ API
  void _initializeSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _step = 1;
    });

    final targetCareer = _mode == 'Targeted'
        ? _targetCareerController.text.trim()
        : null;
    final ageVal = int.tryParse(_ageController.text);
    final locationVal = _locationController.text.trim();
    final hobbyVal = _hobbyController.text.trim();

    final result = await ApiService.initSurvey(
      _mode,
      targetCareer,
      age: ageVal,
      education: _educationLevel,
      location: locationVal,
      hobby: hobbyVal,
    );

    if (result['success'] == true) {
      final surveyData = result['survey'] ?? {};
      setState(() {
        _sessionId = result['sessionId'] ?? '';
        _testName = surveyData['testName'] ?? 'Khảo Sát Hướng Nghiệp Động AI';
        _questions = surveyData['questions'] ?? [];
        _currentQuestionIndex = 0;
        _answers.clear();
        _step = 2;
      });
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _step = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Lỗi khởi tạo khảo sát. Vui lòng thử lại!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Chọn câu trả lời cho câu hỏi hiện tại
  void _selectAnswer(int weight) {
    setState(() {
      _answers[_currentQuestionIndex] = weight;
    });
  }

  // Nộp kết quả khảo sát
  void _submitSurvey() async {
    // Đảm bảo tất cả câu hỏi đã được trả lời
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng trả lời đầy đủ các câu hỏi trước khi nộp!'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _step = 3;
    });

    // Tạo danh sách câu trả lời theo đúng thứ tự câu hỏi
    final List<int> orderedAnswers = [];
    for (int i = 0; i < _questions.length; i++) {
      orderedAnswers.add(_answers[i] ?? 3); // Mặc định là 3 nếu thiếu sót
    }

    final result = await ApiService.submitSurvey(_sessionId, orderedAnswers);

    if (result['success'] == true) {
      if (!mounted) {
        return;
      }
      final evaluation = result['evaluation'] ?? {};
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.isAuthenticated) {
        // Tự động claim kết quả và cập nhật profile nếu đã đăng nhập
        await auth.claimTestResult(_sessionId);
      }

      if (!mounted) {
        return;
      }

      // Chuyển hướng sang màn hình báo cáo chi tiết
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DynamicSurveyReportScreen(
            sessionId: _sessionId,
            initialReport: evaluation,
          ),
        ),
      );
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _step = 2; // Quay lại làm tiếp/thử lại
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Lỗi nộp bài. Vui lòng thử lại!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Light Mode: Nền xám nhạt mịn màng
      appBar: AppBar(
        backgroundColor:
            Colors.white, // Light Mode: Thanh điều hướng trắng tinh tế
        elevation: 0,
        title: Text(
          _testName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF0F172A), // Chữ tiêu đề tối sắc nét
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF334155),
          ), // Icon tối dễ nhìn
          onPressed: () {
            if (_step == 2) {
              // Yêu cầu xác nhận thoát khi đang làm bài
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white, // Dialog nền trắng nền nã
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Hủy bỏ khảo sát?',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Mọi câu trả lời của bạn trong phiên này sẽ không được lưu lại.',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'Tiếp tục khảo sát',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text(
                        'Thoát',
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Glows nhẹ dịu cho Light mode
          Positioned(
            top: 80,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildSetupView();
      case 1:
        return _buildLoadingView(
          'AI đang thiết kế các câu hỏi kịch bản tình huống thời gian thực...',
        );
      case 2:
        return _buildSurveyView();
      case 3:
        return _buildLoadingView(
          'AI đang chấm điểm và lập báo cáo năng lực hướng nghiệp...',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSetupView() {
    // Để hài hòa trong Light Mode, đổi màu neon xanh lá chói thành Emerald dịu mắt hơn
    final themeColor = _mode == 'Discovery'
        ? const Color(0xFF10B981)
        : const Color(0xFF6C63FF);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ), // Viền xám sáng mịn
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Cấu Hình Khảo Sát Động AI',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hệ thống AI sẽ tự động sinh câu hỏi thực tế dựa trên thông tin cá nhân của bạn.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lựa chọn chế độ (Discovery / Targeted)
            Text(
              'CHỌN CHẾ ĐỘ KHẢO SÁT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Mode Cards
            Row(
              children: [
                // Discovery Mode
                Expanded(
                  child: _buildModeCard(
                    title: 'Khám Phá',
                    subtitle: 'Tìm việc phù hợp',
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    modeValue: 'Discovery',
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 14),
                // Targeted Mode
                Expanded(
                  child: _buildModeCard(
                    title: 'Mục Tiêu',
                    subtitle: 'Đánh giá độ hợp',
                    icon: Icons.track_changes_outlined,
                    activeIcon: Icons.track_changes_rounded,
                    modeValue: 'Targeted',
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Thẻ Thông tin cá nhân
            Text(
              'THÔNG TIN CÁ NHÂN (CÁ NHÂN HÓA ĐÁNH GIÁ)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tuổi & Khu vực sinh sống side-by-side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tuổi
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Độ tuổi',
                            labelStyle: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontSize: 12,
                            ),
                            hintText: 'Ví dụ: 18',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: themeColor),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nhập tuổi';
                            }
                            final age = int.tryParse(val);
                            if (age == null || age < 5 || age > 100) {
                              return 'Từ 5-100';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Khu vực sinh sống
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _locationController,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Khu vực học tập/làm việc',
                            labelStyle: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontSize: 12,
                            ),
                            hintText: 'Ví dụ: Hà Nội, Tp.HCM',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: themeColor),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nhập khu vực';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Học vấn Dropdown
                  DropdownButtonFormField<String>(
                    value: _educationLevel,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Trình độ học vấn',
                      labelStyle: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items:
                        <String>[
                          'Học sinh THCS',
                          'Học sinh THPT',
                          'Sinh viên',
                          'Đại học',
                          'Sau đại học',
                          'Đã đi làm',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _educationLevel = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sở thích cá nhân
                  TextFormField(
                    controller: _hobbyController,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Sở thích cá nhân',
                      labelStyle: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                      hintText:
                          'Ví dụ: Đọc sách, công nghệ thông tin, thiết kế đồ họa, ngoại ngữ...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập sở thích của bạn';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form nhập ngành nghề mục tiêu (chỉ hiện khi chọn Targeted Mode)
            if (_mode == 'Targeted') ...[
              Text(
                'NGÀNH NGHỀ MỤC TIÊU',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetCareerController,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0F172A),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Ví dụ: Lập trình viên AI, Marketing Manager, Thiết kế...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.business_center_rounded,
                    color: themeColor,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: themeColor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập ngành nghề mục tiêu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
            ],

            // Nút bấm Bắt đầu
            ElevatedButton(
              onPressed: _initializeSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: isColorDark(themeColor)
                    ? Colors.white
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bắt Đầu Khảo Sát',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isColorDark(themeColor)
                        ? Colors.white
                        : Colors.black87,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required IconData activeIcon,
    required String modeValue,
    required Color color,
  }) {
    final isSelected = _mode == modeValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = modeValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 32,
              color: isSelected ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BƯỚC 1 & 3: HIỂN THỊ TRẠNG THÁI LOADING ---
  Widget _buildLoadingView(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                _mode == 'Discovery'
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6C63FF),
              ),
              backgroundColor: Colors.black.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BƯỚC 2: TRÌNH BÀY CÂU HỎI & CHỌN ĐÁP ÁN ---
  Widget _buildSurveyView() {
    if (_questions.isEmpty) {
      return const SizedBox.shrink();
    }

    final question = _questions[_currentQuestionIndex];
    final questionText = question['questionText'] ?? '';
    final category = question['category'] ?? 'Tình Huống';
    final options = List<dynamic>.from(question['options'] ?? []);

    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final themeColor = _mode == 'Discovery'
        ? const Color(0xFF10B981)
        : const Color(0xFF6C63FF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar + Số thứ tự câu hỏi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toString().toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
            Text(
              'Câu ${_currentQuestionIndex + 1} / ${_questions.length}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Thanh tiến trình
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
        ),
        const SizedBox(height: 28),

        // Thẻ câu hỏi
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    questionText,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Danh sách options
                ...options.map((opt) {
                  final text = opt['text'] ?? '';
                  final weight = opt['weight'] as int? ?? 3;
                  final isSelected = _answers[_currentQuestionIndex] == weight;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(weight),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? themeColor
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                text,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isSelected
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF334155),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor
                                      : const Color(0xFF94A3B8),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: themeColor,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Hàng nút Quay lại / Tiếp theo / Nộp bài
        Row(
          children: [
            // Nút Quay lại
            if (_currentQuestionIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Quay Lại',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),

            const SizedBox(width: 12),

            // Nút Tiếp theo hoặc Nộp bài
            Expanded(
              child: ElevatedButton(
                onPressed: _answers.containsKey(_currentQuestionIndex)
                    ? (_currentQuestionIndex == _questions.length - 1
                          ? _submitSurvey
                          : () {
                              setState(() {
                                _currentQuestionIndex++;
                              });
                            })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _answers.containsKey(_currentQuestionIndex)
                      ? themeColor
                      : const Color(0xFFE2E8F0),
                  foregroundColor: _answers.containsKey(_currentQuestionIndex)
                      ? (isColorDark(themeColor)
                            ? Colors.white
                            : Colors.black87)
                      : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentQuestionIndex == _questions.length - 1
                      ? 'Nộp & Phân Tích'
                      : 'Tiếp Theo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _answers.containsKey(_currentQuestionIndex)
                        ? (isColorDark(themeColor)
                              ? Colors.white
                              : Colors.black87)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool isColorDark(Color color) {
    return color.computeLuminance() < 0.5;
  }
}
