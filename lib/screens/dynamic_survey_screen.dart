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

  // THỐNG NHẤT MÀU THƯƠNG HIỆU THEO IMAGE_E945CF.PNG
  static const Color brandColor = Color(0xFFF1A416);

  // Cấu hình chế độ (Mặc định khởi tạo là Discovery, sẽ tự động thay đổi khi bấm nút bắt đầu)
  String _mode = 'Discovery';
  final _targetCareerController = TextEditingController();
  final _ageController = TextEditingController();
  String _educationLevel = 'Đại học';
  final _formKey = GlobalKey<FormState>();

  // Filter khu vực
  final List<String> _locationOptions = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Quảng Ninh',
    'Thừa Thiên Huế',
    'Du học Mỹ',
    'Du học Úc',
    'Du học Nhật Bản',
    'Du học Hàn Quốc',
  ];
  List<String> _selectedLocations = [];

  // Quản lý điểm số học tập
  final List<String> _subjectNames = [
    'Văn',
    'Toán',
    'Anh Văn',
    'Lý',
    'Hoá',
    'Sinh',
    'Địa',
    'Sử',
    'GDCD',
  ];
  final Map<String, TextEditingController> _subjectControllers = {};
  final _gpaController = TextEditingController();

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
    // Khởi tạo controller cho 9 môn học
    for (var subject in _subjectNames) {
      _subjectControllers[subject] = TextEditingController();
    }
    _loadUserProfileContext();
  }

  void _loadUserProfileContext() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated && auth.userProfile != null) {
      final p = auth.userProfile!;
      _targetCareerController.text = p['targetJob'] ?? '';
      _ageController.text = (p['age'] ?? '').toString();
      _educationLevel = p['educationLevel'] ?? 'Đại học';

      // Xử lý nạp dữ liệu khu vực từ profile (nếu có dạng "Hà Nội, TP.HCM")
      String locs = p['location'] ?? '';
      if (locs.isNotEmpty) {
        _selectedLocations = locs
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _targetCareerController.dispose();
    _ageController.dispose();
    for (var controller in _subjectControllers.values) {
      controller.dispose();
    }
    _gpaController.dispose();
    super.dispose();
  }

  // Khởi tạo câu hỏi khảo sát từ API
  void _initializeSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 khu vực học tập/làm việc!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // --- LOGIC TỰ ĐỘNG NHẬN DIỆN CHẾ ĐỘ ---
    final targetInput = _targetCareerController.text.trim();
    if (targetInput.isEmpty) {
      _mode = 'Discovery'; // Người dùng để trống => Chế độ Khám phá
    } else {
      _mode = 'Targeted'; // Người dùng điền ngành nghề => Chế độ Mục tiêu
    }

    // Đọc và xử lý dữ liệu điểm số (Ô không nhập tự động mặc định bằng 0.0)
    Map<String, dynamic> academicData = {};
    if (_educationLevel == 'Học sinh THCS' ||
        _educationLevel == 'Học sinh THPT') {
      Map<String, double> scores = {};
      for (var subject in _subjectNames) {
        String textVal = _subjectControllers[subject]!.text.trim();
        scores[subject] = double.tryParse(textVal) ?? 0.0;
      }
      academicData = {'type': 'high_school', 'scores': scores};
    } else if (_educationLevel == 'Cao đẳng' || _educationLevel == 'Đại học') {
      String gpaText = _gpaController.text.trim();
      double gpa = double.tryParse(gpaText) ?? 0.0;
      academicData = {'type': 'university', 'gpa': gpa};
    }

    setState(() {
      _step = 1;
    });

    final targetCareer = _mode == 'Targeted' ? targetInput : null;
    final ageVal = int.tryParse(_ageController.text);
    final locationVal = _selectedLocations.join(', ');

    final result = await ApiService.initSurvey(
      _mode,
      targetCareer,
      age: ageVal,
      education: _educationLevel,
      location: locationVal,
      hobby: null,
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

    final List<int> orderedAnswers = [];
    for (int i = 0; i < _questions.length; i++) {
      orderedAnswers.add(_answers[i] ?? 3);
    }

    final result = await ApiService.submitSurvey(_sessionId, orderedAnswers);

    if (result['success'] == true) {
      if (!mounted) {
        return;
      }
      final evaluation = result['evaluation'] ?? {};
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.isAuthenticated) {
        await auth.claimTestResult(_sessionId);
      }

      if (!mounted) {
        return;
      }

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
        _step = 2;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _testName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF334155)),
          onPressed: () {
            if (_step == 2) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
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
                          color: brandColor,
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
          // Background Gradient circles đồng bộ theo tone Vàng Cam nhạt
          Positioned(
            top: 80,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandColor.withValues(alpha: 0.04),
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
                color: brandColor.withValues(alpha: 0.03),
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
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 48,
                    color: brandColor,
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
                  // 1. Ô ĐỘ TUỔI
                  TextFormField(
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
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: brandColor),
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
                        return 'Nhập tuổi';
                      }
                      final age = int.tryParse(val);
                      if (age == null || age < 5 || age > 100) {
                        return 'Từ 5-100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Ô KHU VỰC MONG MUỐN
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return _locationOptions.where((String option) {
                            final matchesSearch = option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                            final notSelectedYet = !_selectedLocations.contains(
                              option,
                            );
                            return matchesSearch && notSelectedYet;
                          });
                        },
                        onSelected: (String selection) {
                          setState(() {
                            _selectedLocations.add(selection);
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_selectedLocations.contains(
                                  textEditingController.text,
                                )) {
                                  textEditingController.clear();
                                }
                              });

                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Khu vực học tập/làm việc mong muốn',
                                  labelStyle: GoogleFonts.inter(
                                    color: const Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                  hintText:
                                      'Gõ để tìm kiếm (Ví dụ: Hà Nội, TP. Hồ Chí Minh...)',
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
                                    borderSide: const BorderSide(
                                      color: brandColor,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                              );
                            },
                      ),

                      if (_selectedLocations.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedLocations.map((loc) {
                            return Chip(
                              label: Text(
                                loc,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: brandColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.cancel,
                                size: 16,
                                color: brandColor,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedLocations.remove(loc);
                                });
                              },
                              backgroundColor: brandColor.withValues(
                                alpha: 0.1,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. TRÌNH ĐỘ HỌC VẤN
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
                        borderSide: const BorderSide(color: brandColor),
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
                          'Cao đẳng',
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

                  // Khối nhập điểm học tập động dựa trên Trình độ học vấn
                  _buildAcademicScoreFields(brandColor),

                  const SizedBox(height: 16),

                  // 4. NGHỀ NGHIỆP MONG MUỐN (ĐỒNG BỘ THEO TONE VÀNG CAM)
                  TextFormField(
                    controller: _targetCareerController,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'Nghề nghiệp mong muốn (Để trống nếu chưa xác định)',
                      labelStyle: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                      hintText:
                          'Ví dụ: Lập trình viên AI, Marketing Manager, Thiết kế đồ họa...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.business_center_outlined,
                        color: brandColor,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: brandColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _initializeSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    brandColor, // Màu vàng cam thương hiệu từ ảnh gốc
                foregroundColor: Colors.white,
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
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị ô nhập điểm tùy theo Trình độ học vấn
  Widget _buildAcademicScoreFields(Color themeColor) {
    if (_educationLevel == 'Học sinh THCS' ||
        _educationLevel == 'Học sinh THPT') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'ĐIỂM SỐ (CHỈ ĐIỀN CÁC MÔN BẠN HỌC/XÉT TUYỂN)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _subjectNames.length; i += 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  for (
                    int j = i;
                    j < i + 3 && j < _subjectNames.length;
                    j++
                  ) ...[
                    if (j > i) const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _subjectControllers[_subjectNames[j]],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          labelText: _subjectNames[j],
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                          ),
                          hintText: '0',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: themeColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    } else if (_educationLevel == 'Cao đẳng' || _educationLevel == 'Đại học') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _gpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              labelText: 'Điểm GPA hiện tại / Tốt nghiệp',
              labelStyle: GoogleFonts.inter(
                color: const Color(0xFF475569),
                fontSize: 12,
              ),
              hintText: 'Ví dụ: 3.2 (hệ 4) hoặc 8.0 (hệ 10)',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

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
              valueColor: const AlwaysStoppedAnimation<Color>(brandColor),
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

  Widget _buildSurveyView() {
    if (_questions.isEmpty) {
      return const SizedBox.shrink();
    }

    final question = _questions[_currentQuestionIndex];
    final questionText = question['questionText'] ?? '';
    final category = question['category'] ?? 'Tình Huống';
    final options = List<dynamic>.from(question['options'] ?? []);

    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toString().toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: brandColor,
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

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(brandColor),
          ),
        ),
        const SizedBox(height: 28),

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
                              ? brandColor.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? brandColor
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
                                      ? brandColor
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
                                          color: brandColor,
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

        Row(
          children: [
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
                      ? brandColor
                      : const Color(0xFFE2E8F0),
                  foregroundColor: _answers.containsKey(_currentQuestionIndex)
                      ? Colors.white
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
                        ? Colors.white
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
}
