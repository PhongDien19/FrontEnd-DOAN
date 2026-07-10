import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Áp dụng font "Inter" (hỗ trợ đầy đủ tiếng Việt) cho toàn bộ TextTheme
/// — fix lỗi chữ có dấu bị to/dày hơn chữ không dấu do fallback font hệ thống.
TextTheme _buildTextTheme(TextTheme base) {
  return GoogleFonts.interTextTheme(base).copyWith(
    // Đảm bảo các style cụ thể cũng dùng Inter
    displayLarge: GoogleFonts.inter(textStyle: base.displayLarge),
    displayMedium: GoogleFonts.inter(textStyle: base.displayMedium),
    displaySmall: GoogleFonts.inter(textStyle: base.displaySmall),
    headlineLarge: GoogleFonts.inter(textStyle: base.headlineLarge),
    headlineMedium: GoogleFonts.inter(textStyle: base.headlineMedium),
    headlineSmall: GoogleFonts.inter(textStyle: base.headlineSmall),
    titleLarge: GoogleFonts.inter(textStyle: base.titleLarge),
    titleMedium: GoogleFonts.inter(textStyle: base.titleMedium),
    titleSmall: GoogleFonts.inter(textStyle: base.titleSmall),
    bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge),
    bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium),
    bodySmall: GoogleFonts.inter(textStyle: base.bodySmall),
    labelLarge: GoogleFonts.inter(textStyle: base.labelLarge),
    labelMedium: GoogleFonts.inter(textStyle: base.labelMedium),
    labelSmall: GoogleFonts.inter(textStyle: base.labelSmall),
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
      home: const HomeScreen(),
    );
  }
}
