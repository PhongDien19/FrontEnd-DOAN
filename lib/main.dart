import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Auth Provider
import 'services/auth_provider.dart';

// ViewModels
import 'viewmodels/assessment_flow_viewmodels.dart';
import 'viewmodels/chat_viewmodels.dart';
import 'viewmodels/comprehensive_report_viewmodels.dart';
import 'viewmodels/dynamic_survey_report_viewmodels.dart';
import 'viewmodels/dynamic_survey_viewmodels.dart';
import 'viewmodels/home_viewmodels.dart';
import 'viewmodels/login_viewmodels.dart';
import 'viewmodels/profile_viewmodels.dart';
import 'viewmodels/quick_explore_viewmodels.dart';
import 'viewmodels/test_history_viewmodels.dart';

// Screens / Views
import 'view/home_screen.dart';

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
        ChangeNotifierProvider(create: (_) => AssessmentFlowViewModel()),
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
