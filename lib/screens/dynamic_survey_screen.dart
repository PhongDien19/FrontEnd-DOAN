import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import 'dynamic_survey_report_screen.dart';
import 'login_screen.dart';

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

  // Hướng đi (dùng cho Discovery mode): 'study' = Đi học, 'work' = Đi làm.
  // Giá trị này luôn được đồng bộ từ _pathFromEducation mỗi khi user đổi
  // Trình độ học vấn, khi load profile hoặc trước khi submit.
  // Mặc định = 'work' để khớp với _educationLevel mặc định là 'Đại học'.
  String _selectedPath = 'work';

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

  // Quản lý điểm số học tập — danh sách môn thay đổi theo Trình độ học vấn
  // THCS: 9 môn (theo chương trình GDPT 2018)
  static const List<String> _thcsSubjects = [
    'Toán',
    'Văn',
    'Anh',
    'Tin học',
    'Lịch sử',
    'Địa lý',
    'Công nghệ',
    'GDCD',
    'Khoa học tự nhiên',
  ];

  // THPT: 9 môn (giữ nguyên như trước)
  static const List<String> _thptSubjects = [
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

  /// Danh sách môn học đang active dựa trên _educationLevel
  List<String> get _activeSubjects {
    switch (_educationLevel) {
      case 'Học sinh THCS':
        return _thcsSubjects;
      case 'Học sinh THPT':
        return _thptSubjects;
      default:
        return const [];
    }
  }

  /// Hướng đi tự động suy ra từ Trình độ học vấn:
  /// - Học sinh THCS / THPT   → 'study' (Đi học)
  /// - Cao đẳng / Đại học / Khác → 'work'  (Thị trường lao động)
  String get _pathFromEducation {
    if (_educationLevel == 'Học sinh THCS' ||
        _educationLevel == 'Học sinh THPT') {
      return 'study';
    }
    return 'work';
  }

  /// Khoảng tuổi hợp lệ đối với từng trình độ học vấn.
  /// Mọi trình độ đều có ràng buộc tuổi tối thiểu/tối đa hợp lý
  /// (kể cả "Cao đẳng" và "Khác" — trước đây bị bỏ qua, gây ra lỗi
  /// nhập tuổi 9 vẫn chọn được "Cao đẳng").
  ({int min, int max})? _ageRangeForEducation() {
    switch (_educationLevel) {
      case 'Học sinh THCS':
        return (min: 11, max: 14);
      case 'Học sinh THPT':
        return (min: 15, max: 18);
      case 'Đại học':
        return (min: 18, max: 25);
      case 'Cao đẳng':
        return (min: 18, max: 25);
      default:
        return (min: 16, max: 100);
    }
  }

  final Map<String, TextEditingController> _subjectControllers = {};
  final _gpaController = TextEditingController();

  // Sở thích cá nhân (phục vụ cá nhân hóa khảo sát & tư vấn)
  final _hobbyController = TextEditingController();

  // Dữ liệu khảo sát từ API
  String _sessionId = '';
  String _testName = 'Khảo Sát Hướng Nghiệp';
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;

  // Câu trả lời của người dùng: câu hỏi index -> lựa chọn index (0-4)
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller cho tất cả các môn có thể xuất hiện
    // (cả THCS + THPT) để giữ giá trị khi người dùng chuyển đổi trình độ học vấn
    for (var subject in [..._thcsSubjects, ..._thptSubjects]) {
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
      // Đồng bộ hướng đi theo trình độ học vấn vừa load (giống cơ chế Targeted
      // với nghề nghiệp: hướng đi cũng được quyết định ngầm, không cần UI).
      _selectedPath = _pathFromEducation;
      _hobbyController.text = p['hobby'] ?? '';

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
    _hobbyController.dispose();
    super.dispose();
  }

  // Khởi tạo câu hỏi khảo sát từ API
  void _initializeSurvey() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng chọn ít nhất 1 khu vực học tập/làm việc!',
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
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

    // Đồng bộ _selectedPath theo Trình độ học vấn ngay trước khi gọi API
    // (phòng trường hợp user đổi trình độ học vấn mà chưa đóng dropdown
    // hoặc _selectedPath bị lệch sau khi load profile).
    _selectedPath = _pathFromEducation;

    final ageVal = int.tryParse(_ageController.text);
    final locationVal = _selectedLocations.join(', ');
    final hobbyVal = _hobbyController.text.trim();

    // 1. Tạo model tạm Profile
    final tempProfile = TempProfile(
      fullName: auth.userProfile?['fullName'] ?? 'Người dùng',
      targetJob: targetInput,
      educationLevel: _educationLevel,
      hobby: hobbyVal,
      age: ageVal,
      location: locationVal,
    );

    // 2. Đọc và xử lý dữ liệu điểm số
    Map<String, dynamic>? academicData;
    TempScores? tempScores;
    if (_educationLevel == 'Học sinh THCS' ||
        _educationLevel == 'Học sinh THPT') {
      Map<String, double> scores = {};
      int enteredCount = 0;
      for (var subject in _activeSubjects) {
        String textVal = _subjectControllers[subject]!.text.trim();
        final parsed = double.tryParse(textVal);
        // Chỉ tính là "đã nhập điểm" khi ô không rỗng VÀ parse được số hợp lệ
        if (textVal.isNotEmpty && parsed != null) {
          scores[subject] = parsed;
          enteredCount++;
        }
      }

      // Bắt buộc tối thiểu 6 môn (THCS/THPT) mới cho phép khảo sát.
      if (enteredCount < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vui lòng nhập điểm ít nhất 6 môn (hiện tại mới nhập $enteredCount môn).',
              style: TextStyle(fontSize: Responsive.font(context, 14)),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Chỉ gửi các môn đã nhập điểm (không kèm môn bỏ trống / giá trị 0 mặc định)
      academicData = {
        'type': 'high_school',
        'scores': scores,
        'enteredSubjectCount': enteredCount,
      };
      tempScores = TempScores(type: 'high_school', scores: scores);
    } else if (_educationLevel == 'Cao đẳng' || _educationLevel == 'Đại học') {
      String gpaText = _gpaController.text.trim();
      double gpa = double.tryParse(gpaText) ?? 0.0;
      academicData = {'type': 'university_worker', 'gpa': gpa};
      tempScores = TempScores(type: 'university_worker', scores: {'gpa': gpa});
    }

    // 3. Thực hiện lưu tạm hoặc lưu vào DB
    if (!auth.isAuthenticated) {
      auth.setTempProfile(tempProfile);
      if (tempScores != null) {
        auth.setTempScores(tempScores);
      }
    } else {
      await auth.updateProfile(
        fullName: tempProfile.fullName ?? 'Người dùng',
        targetJob: tempProfile.targetJob ?? '',
        educationLevel: tempProfile.educationLevel ?? '',
        hobby: tempProfile.hobby ?? '',
        age: tempProfile.age,
        location: tempProfile.location,
        studentScores: tempScores?.type == 'high_school'
            ? tempScores?.scores
            : null,
        workerScores: tempScores?.type == 'university_worker'
            ? tempScores?.scores
            : null,
      );
    }

    setState(() {
      _step = 1;
    });

    final targetCareer = _mode == 'Targeted' ? targetInput : null;

    final result = await ApiService.initSurvey(
      _mode,
      targetCareer,
      age: ageVal,
      education: _educationLevel,
      location: locationVal,
      hobby: hobbyVal.isEmpty ? null : hobbyVal,
      academicData: academicData,
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
            style: TextStyle(fontSize: Responsive.font(context, 14)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Chọn câu trả lời cho câu hỏi hiện tại
  void _selectAnswer(int optionIndex) {
    setState(() {
      _answers[_currentQuestionIndex] = optionIndex;
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
      final selectedOptIndex = _answers[i];
      int weight = 3;
      if (selectedOptIndex != null) {
        final q = _questions[i];
        final options = List<dynamic>.from(q['options'] ?? []);
        if (selectedOptIndex >= 0 && selectedOptIndex < options.length) {
          weight = options[selectedOptIndex]['weight'] as int? ?? 3;
        }
      }
      orderedAnswers.add(weight);
    }

    final result = await ApiService.submitSurvey(_sessionId, orderedAnswers);

    if (result['success'] == true) {
      if (!mounted) {
        return;
      }
      final evaluation = result['evaluation'] ?? {};
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Nếu chưa đăng nhập → bắt buộc đăng nhập trước khi xem kết quả.
      // Lưu kết quả tạm vào state để có thể navigate sau khi đăng nhập xong.
      if (!auth.isAuthenticated) {
        await _showLoginRequiredDialog(
          evaluation: evaluation,
          sessionId: _sessionId,
        );
        return;
      }

      await auth.claimTestResult(_sessionId);

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DynamicSurveyReportScreen(
            sessionId: _sessionId,
            initialReport: evaluation,
            selectedPath: _selectedPath,
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

  // Hiển thị dialog yêu cầu đăng nhập trước khi xem kết quả khảo sát.
  // Sau khi đăng nhập thành công, navigate thẳng tới Report screen.
  Future<void> _showLoginRequiredDialog({
    required Map<String, dynamic> evaluation,
    required String sessionId,
  }) async {
    if (!mounted) return;
    setState(() {
      _step = 2; // Cho phép user làm lại hoặc đăng nhập
    });

    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: brandColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yêu cầu đăng nhập',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn đã hoàn thành 15 câu hỏi. Vui lòng đăng nhập để xem kết quả phân tích hướng nghiệp của mình.',
          style: TextStyle(
            color: const Color(0xFF475569),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Để sau',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Đăng nhập',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !mounted) {
      return;
    }

    // Mở màn hình đăng nhập
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (!mounted) return;

    // Sau khi quay lại, kiểm tra trạng thái đăng nhập
    final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
    if (updatedAuth.isAuthenticated) {
      // Đồng bộ kết quả khảo sát với user vừa đăng nhập
      await updatedAuth.claimTestResult(sessionId);
      if (!mounted) return;
      // Navigate tới Report screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DynamicSurveyReportScreen(
            sessionId: sessionId,
            initialReport: evaluation,
            selectedPath: _selectedPath,
          ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.font(context, 18),
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF334155),
            size: Responsive.s(context, 24),
          ),
          onPressed: () {
            if (_step == 2) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.s(context, 20),
                    ),
                  ),
                  title: Text(
                    'Hủy bỏ khảo sát?',
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(context, 18),
                    ),
                  ),
                  content: Text(
                    'Mọi câu trả lời của bạn trong phiên này sẽ không được lưu lại.',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: Responsive.font(context, 14),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'Tiếp tục khảo sát',
                        style: TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.font(context, 14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text(
                        'Thoát',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.font(context, 14),
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
            top: Responsive.s(context, 80),
            left: -Responsive.s(context, 120),
            child: Container(
              width: Responsive.s(context, 320),
              height: Responsive.s(context, 320),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandColor.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: Responsive.s(context, 80),
            right: -Responsive.s(context, 120),
            child: Container(
              width: Responsive.s(context, 320),
              height: Responsive.s(context, 320),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandColor.withValues(alpha: 0.03),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(Responsive.s(context, 24)),
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
              padding: EdgeInsets.all(Responsive.s(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.s(context, 24)),
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
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: Responsive.s(context, 48),
                    color: brandColor,
                  ),
                  SizedBox(height: Responsive.s(context, 14)),
                  Text(
                    'Cấu Hình Khảo Sát Động AI',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 8)),
                  Text(
                    'Hệ thống AI sẽ tự động sinh câu hỏi thực tế dựa trên thông tin cá nhân của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 13),
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.s(context, 24)),

            Text(
              'THÔNG TIN CÁ NHÂN (CÁ NHÂN HÓA ĐÁNH GIÁ)',
              style: TextStyle(
                fontSize: Responsive.font(context, 11),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: Responsive.s(context, 12)),

            Container(
              padding: EdgeInsets.all(Responsive.s(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.s(context, 20)),
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
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: Responsive.font(context, 13),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Độ tuổi',
                      labelStyle: TextStyle(
                        color: const Color(0xFF475569),
                        fontSize: Responsive.font(context, 12),
                      ),
                      hintText: 'Ví dụ: 18',
                      hintStyle: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: Responsive.font(context, 12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 12),
                        ),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 12),
                        ),
                        borderSide: const BorderSide(color: brandColor),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 12),
                        ),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.s(context, 12),
                        ),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Responsive.s(context, 12),
                        vertical: Responsive.s(context, 14),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nhập tuổi';
                      }
                      final age = int.tryParse(val);
                      if (age == null || age < 5 || age > 100) {
                        return 'độ tuổi từ 10 - 25';
                      }

                      // Cảnh báo khi tuổi không khớp với Trình độ học vấn đã chọn.
                      // - THCS (11-14) và THPT (15-18) gắn chặt với tuổi nên vẫn
                      //   gợi ý cụ thể khi sai.
                      // - Từ 18 tuổi trở lên: Cao đẳng / Đại học / Khác đều hợp lệ,
                      //   KHÔNG có 1 đáp án đúng duy nhất, nên không ép gợi ý
                      //   "Đại học" nữa — chỉ cảnh báo nếu vẫn đang chọn THCS/THPT.
                      // Tuy nhiên KHÔNG tự ý đổi Trình độ — chỉ cảnh báo để user biết.
                      final range = _ageRangeForEducation();
                      if (range != null &&
                          (age < range.min || age > range.max)) {
                        final isSchoolLevel =
                            _educationLevel == 'Học sinh THCS' ||
                            _educationLevel == 'Học sinh THPT';

                        if (age >= 11 && age <= 14 && _educationLevel != 'Học sinh THCS') {
                          return 'Tuổi $age thường là "Học sinh THCS", không phải "$_educationLevel"';
                        }
                        if (age >= 15 && age <= 18 && _educationLevel != 'Học sinh THPT') {
                          return 'Tuổi $age thường là "Học sinh THPT", không phải "$_educationLevel"';
                        }
                        if (age > 18 && isSchoolLevel) {
                          // Tuổi đã lớn nhưng vẫn đang chọn THCS/THPT — không rõ
                          // là Cao đẳng, Đại học hay Khác nên chỉ gợi ý chung.
                          return 'Tuổi $age không còn phù hợp với "$_educationLevel" (thường là Cao đẳng/Đại học/Sau Đại học)';
                        }
                        return 'Tuổi $age ngoài khoảng ${range.min}-${range.max} của "$_educationLevel"';
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
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Khu vực học tập/làm việc mong muốn',
                                  labelStyle: TextStyle(
                                    color: const Color(0xFF475569),
                                    fontSize: 12,
                                  ),
                                  hintText:
                                      'Gõ để tìm kiếm (Ví dụ: Hà Nội, TP. Hồ Chí Minh...)',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
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
                                ),
                                validator: (val) {
                                  if (_selectedLocations.isEmpty) {
                                    return 'Chọn ít nhất 1 khu vực';
                                  }
                                  return null;
                                },
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
                                style: TextStyle(
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
                    initialValue: _educationLevel,
                    dropdownColor: Colors.white,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Trình độ học vấn',
                      labelStyle: TextStyle(
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
                          'Sau Đại học',
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
                          // Đồng bộ hướng đi theo trình độ học vấn mới
                          _selectedPath = _pathFromEducation;
                        });
                        // Kiểm tra lại ngay ô Độ tuổi với Trình độ học vấn vừa chọn,
                        // để hiện lỗi kịp thời (không phải đợi tới lúc bấm Submit).
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _formKey.currentState?.validate();
                        });
                      }
                    },
                  ),

                  // Khối nhập điểm học tập động dựa trên Trình độ học vấn
                  _buildAcademicScoreFields(brandColor),

                  const SizedBox(height: 16),

                  // 3b. Ô SỞ THÍCH CÁ NHÂN (giúp AI cá nhân hóa khảo sát tốt hơn)
                  TextFormField(
                    controller: _hobbyController,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Sở thích cá nhân',
                      labelStyle: TextStyle(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                      hintText:
                          'Ví dụ: Đọc sách, chơi game, vẽ, du lịch, lập trình...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.favorite_outline_rounded,
                        color: brandColor,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập sở thích cá nhân';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 4. NGHỀ NGHIỆP MONG MUỐN (ĐỒNG BỘ THEO TONE VÀNG CAM)
                  TextFormField(
                    controller: _targetCareerController,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'Nghề nghiệp mong muốn (Để trống nếu chưa xác định)',
                      labelStyle: TextStyle(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                      hintText:
                          'Ví dụ: Lập trình viên AI, Marketing Manager, Thiết kế đồ họa...',
                      hintStyle: TextStyle(
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
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
                    ),
                  ),

                  // 5. KHÔNG hiển thị UI chọn hướng đi.
                  //    Hướng đi (Đi Học / Đi Làm) được quyết định NGẦM theo Trình độ học vấn
                  //    và truyền thẳng vào Report screen (giống cơ chế Targeted):
                  //      • Học sinh THCS / THPT      → 'study' (Đi Học - Top trường)
                  //      • Cao đẳng / Đại học / Khác → 'work'  (Đi Làm - Thị trường lao động)
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          ..._buildSubjectScoreGrid(themeColor),
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
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(color: const Color(0xFF0F172A), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Điểm GPA hiện tại / Tốt nghiệp',
              labelStyle: TextStyle(
                color: const Color(0xFF475569),
                fontSize: 12,
              ),
              hintText: 'Ví dụ: 3.2 (hệ 4) hoặc 8.0 (hệ 10)',
              hintStyle: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập điểm GPA';
              }
              final gpa = double.tryParse(val.trim());
              if (gpa == null) {
                return 'Điểm phải là số';
              }
              if (gpa < 0 || gpa > 10) {
                return 'Điểm từ 0 đến 10';
              }
              return null;
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// Số cột hiển thị ô nhập điểm — phụ thuộc vào trình độ học vấn.
  /// THCS: 2 cột (vì có môn "Khoa học tự nhiên" tên dài).
  /// THPT: 3 cột (tên môn ngắn, hiển thị gọn hơn).
  int _subjectColumnsForCurrentLevel() {
    return _educationLevel == 'Học sinh THCS' ? 2 : 3;
  }

  /// Render grid các ô nhập điểm theo số cột được cấu hình.
  List<Widget> _buildSubjectScoreGrid(Color themeColor) {
    final int columns = _subjectColumnsForCurrentLevel();
    final List<Widget> rows = [];

    for (int i = 0; i < _activeSubjects.length; i += columns) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              for (
                int j = i;
                j < i + columns && j < _activeSubjects.length;
                j++
              ) ...[
                if (j > i) const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _subjectControllers[_activeSubjects[j]],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: _activeSubjects[j],
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '—',
                      hintStyle: TextStyle(
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
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: themeColor),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (val) {
                      // Cho phép bỏ trống từng ô — kiểm tra số lượng môn nhập
                      // được thực hiện ở _initializeSurvey (tối thiểu 6 môn).
                      // Validator ở đây chỉ chặn nếu user nhập SAI định dạng.
                      if (val == null || val.trim().isEmpty) {
                        return null;
                      }
                      final score = double.tryParse(val.trim());
                      if (score == null) {
                        return 'Phải là số';
                      }
                      if (score < 0 || score > 10) {
                        return '0-10';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return rows;
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
              style: TextStyle(
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: brandColor,
                ),
              ),
            ),
            Text(
              'Câu ${_currentQuestionIndex + 1} / ${_questions.length}',
              style: TextStyle(
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ...options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  final text = opt['text'] ?? '';
                  final isSelected = _answers[_currentQuestionIndex] == idx;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(idx),
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
                                style: TextStyle(
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
                    style: TextStyle(
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
                  style: TextStyle(
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