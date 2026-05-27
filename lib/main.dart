import 'package:flutter/material.dart';

// Import các màn hình của bạn
import 'features/screen/modeselection_screen.dart';
import 'features/screen/personalinfo_screen.dart';
import 'features/screen/assessment_screen.dart';
import 'features/screen/careerrecommendation_screen.dart';
import 'features/screen/authgate_screen.dart';
import 'features/screen/result_screen.dart';
import 'features/screen/dashboard_screen.dart';

// ĐÃ THÊM: Import file models.dart để fix lỗi Undefined class
import 'features/screen/models.dart';

void main() {
  runApp(const CareerPathwayApp());
}

class CareerPathwayApp extends StatelessWidget {
  const CareerPathwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Pathway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Sans', // Thay bằng font bạn dùng
      ),
      home: const MainAppFlow(),
    );
  }
}

// ── Các bước của ứng dụng ──
enum AppStep {
  home,
  modeSelection,
  personalInfo,
  personalityTest,
  recommendation,
  careerTest,
  authGate,
  results,
  dashboard,
}

class MainAppFlow extends StatefulWidget {
  const MainAppFlow({super.key});

  @override
  State<MainAppFlow> createState() => _MainAppFlowState();
}

class _MainAppFlowState extends State<MainAppFlow> {
  // --- STATE CỦA TOÀN BỘ LUỒNG ---
  AppStep _currentStep = AppStep.home;

  AssessmentMode? _mode;
  UserData? _userData;
  Map<int, String>? _personalityAnswers;
  Map<int, String>? _careerAnswers;
  String _targetCareer = "";
  AuthUser? _authUser;

  // --- HÀM RESET DATA KHI VỀ TRANG CHỦ ---
  void _resetFlow() {
    setState(() {
      _currentStep = AppStep.home;
      _mode = null;
      _userData = null;
      _personalityAnswers = null;
      _careerAnswers = null;
      _targetCareer = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    // Điều hướng hiển thị UI dựa trên _currentStep
    switch (_currentStep) {
      case AppStep.home:
        return _buildMockHomeScreen();

      case AppStep.modeSelection:
        return ModeSelectionScreen(
          onSelect: (mode) {
            setState(() {
              _mode = mode;
              _currentStep = AppStep.personalInfo;
            });
          },
          onBack: () => setState(() => _currentStep = AppStep.home),
        );

      case AppStep.personalInfo:
        return PersonalInfoScreen(
          mode: _mode!,
          onSubmit: (data) {
            setState(() {
              _userData = data;
              if (_mode == AssessmentMode.targeted) {
                // Luồng Targeted: Có định hướng -> Test chuyên môn luôn
                _targetCareer = data.targetCareer ?? "Chưa xác định";
                _currentStep = AppStep.careerTest;
              } else {
                // Luồng Discovery: Khám phá -> Test tính cách trước
                _currentStep = AppStep.personalityTest;
              }
            });
          },
          onBack: () => setState(() => _currentStep = AppStep.modeSelection),
        );

      case AppStep.personalityTest:
        return AssessmentScreen(
          type: AssessmentType.personality,
          onComplete: (answers) {
            setState(() {
              _personalityAnswers = answers;
              // Giả lập AI đề xuất ngành dựa trên tính cách
              _targetCareer = "Kỹ sư phần mềm";
              _currentStep = AppStep.recommendation;
            });
          },
          onBack: () => setState(() => _currentStep = AppStep.personalInfo),
        );

      case AppStep.recommendation:
        return CareerRecommendationScreen(
          career: _targetCareer,
          onContinue: () => setState(() => _currentStep = AppStep.careerTest),
          onBack: () => setState(() => _currentStep = AppStep.personalityTest),
        );

      case AppStep.careerTest:
        return AssessmentScreen(
          type: AssessmentType.career,
          career: _targetCareer,
          onComplete: (answers) {
            setState(() {
              _careerAnswers = answers;
              _currentStep = _authUser == null
                  ? AppStep.authGate
                  : AppStep.results;
            });
          },
          onBack: () => setState(() {
            _currentStep = _mode == AssessmentMode.targeted
                ? AppStep.personalInfo
                : AppStep.recommendation;
          }),
        );

      case AppStep.authGate:
        return AuthGateScreen(
          onLogin: (user) {
            setState(() {
              _authUser = user;
              _currentStep = AppStep.results;
            });
          },
          onBack: () => setState(() => _currentStep = AppStep.careerTest),
        );

      case AppStep.results:
        return ResultsScreen(
          mode: _mode!,
          userData: _userData!,
          // ĐÃ FIX LỖI Answers TYPE: Chuyển key từ int sang String bằng .map()
          personalityAnswers:
              _personalityAnswers?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              {},
          careerAnswers:
              _careerAnswers?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              {},
          career: _targetCareer,
          authUser: _authUser!,
          onDashboard: () => setState(() => _currentStep = AppStep.dashboard),
          onHome: _resetFlow,
        );

      case AppStep.dashboard:
        return DashboardScreen(
          authUser: _authUser!,
          career: _targetCareer,
          onLogout: () {
            setState(() {
              _authUser = null;
              _resetFlow();
            });
          },
          onHome: () => setState(() => _currentStep = AppStep.home),
        );
    }
  }

  // --- MÀN HÌNH TRANG CHỦ MÔ PHỎNG THEO FIGMA ---
  Widget _buildMockHomeScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // Thêm hình nền vào đây
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover, // Căn chỉnh ảnh phủ kín màn hình
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Tư Vấn Hướng Nghiệp Khoa Học",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  // Thêm màu nền cho chữ để dễ đọc nếu hình nền tối
                  backgroundColor: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    setState(() => _currentStep = AppStep.modeSelection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Bắt đầu đánh giá miễn phí"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
