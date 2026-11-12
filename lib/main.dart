import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/assessment_flow_controller.dart';
// Services & Auth Provider
import 'services/auth_provider.dart';
import 'utils/app_colors.dart';

// ViewModels
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
        ChangeNotifierProvider(create: (_) => ComprehensiveReportViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => DynamicSurveyViewModel()),
        ChangeNotifierProvider(create: (_) => DynamicSurveyReportViewModel()),
        ChangeNotifierProvider(create: (_) => QuickExploreViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => TestHistoryViewModel()),
        ChangeNotifierProvider(create: (_) => AssessmentFlowController()),
      ],
      child: MaterialApp(
        title: 'Hướng Nghiệp AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: AppColors.background,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: const TextStyle(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 1.5,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
