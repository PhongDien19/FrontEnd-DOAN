import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

/// Áp dụng Roboto làm font mặc định (Material Design standard font)
/// Font này hỗ trợ tiếng Việt tốt và các weight (bold, regular) luôn hoạt động đúng
TextTheme _buildTextTheme(TextTheme base) {
  const String fontFamily = 'Roboto';
  
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontFamily: fontFamily),
    displayMedium: base.displayMedium?.copyWith(fontFamily: fontFamily),
    displaySmall: base.displaySmall?.copyWith(fontFamily: fontFamily),
    headlineLarge: base.headlineLarge?.copyWith(fontFamily: fontFamily),
    headlineMedium: base.headlineMedium?.copyWith(fontFamily: fontFamily),
    headlineSmall: base.headlineSmall?.copyWith(fontFamily: fontFamily),
    titleLarge: base.titleLarge?.copyWith(fontFamily: fontFamily),
    titleMedium: base.titleMedium?.copyWith(fontFamily: fontFamily),
    titleSmall: base.titleSmall?.copyWith(fontFamily: fontFamily),
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: fontFamily),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: fontFamily),
    bodySmall: base.bodySmall?.copyWith(fontFamily: fontFamily),
    labelLarge: base.labelLarge?.copyWith(fontFamily: fontFamily),
    labelMedium: base.labelMedium?.copyWith(fontFamily: fontFamily),
    labelSmall: base.labelSmall?.copyWith(fontFamily: fontFamily),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Pathway',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00F2FE),
          surface: Color(0xFF191922),
          error: Colors.redAccent,
        ),
        textTheme: _buildTextTheme(ThemeData.dark().textTheme),
        primaryTextTheme: _buildTextTheme(ThemeData.dark().primaryTextTheme),
      ),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final TextScaler effectiveScaler =
            mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
        return MediaQuery(
          data: mq.copyWith(textScaler: effectiveScaler),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
