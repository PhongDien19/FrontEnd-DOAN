import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Auth Provider
import 'services/auth_provider.dart';

// Controllers & ViewModels
import 'controllers/assessment_flow_controller.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/comprehensive_report_viewmodel.dart';
import 'viewmodels/dynamic_survey_report_viewmodel.dart';
import 'viewmodels/dynamic_survey_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/quick_explore_viewmodel.dart';
import 'viewmodels/test_history_viewmodel.dart';

// Screens / Views
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => AssessmentFlowController()),
        ChangeNotifierProvider(create: (_) => ComprehensiveReportViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => DynamicSurveyViewModel()),
        ChangeNotifierProvider(create: (_) => DynamicSurveyReportViewModel()),
        ChangeNotifierProvider(create: (_) => QuickExploreViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => TestHistoryViewModel()),
      ],
      child: MaterialApp(
        title: 'Hướng Nghiệp AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F13),
          primaryColor: const Color(0xFF6C63FF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF00F5A0),
            surface: Color(0xFF191922),
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
