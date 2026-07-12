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

/// Áp dụng font "Roboto" cho toàn bộ TextTheme
/// — Roboto là font mặc định của Material Design, hỗ trợ tiếng Việt tốt.
TextTheme _buildTextTheme(TextTheme base) {
  return GoogleFonts.robotoTextTheme(base).copyWith(
    // Đảm bảo các style cụ thể cũng dùng Roboto
    displayLarge: GoogleFonts.roboto(textStyle: base.displayLarge),
    displayMedium: GoogleFonts.roboto(textStyle: base.displayMedium),
    displaySmall: GoogleFonts.roboto(textStyle: base.displaySmall),
    headlineLarge: GoogleFonts.roboto(textStyle: base.headlineLarge),
    headlineMedium: GoogleFonts.roboto(textStyle: base.headlineMedium),
    headlineSmall: GoogleFonts.roboto(textStyle: base.headlineSmall),
    titleLarge: GoogleFonts.roboto(textStyle: base.titleLarge),
    titleMedium: GoogleFonts.roboto(textStyle: base.titleMedium),
    titleSmall: GoogleFonts.roboto(textStyle: base.titleSmall),
    bodyLarge: GoogleFonts.roboto(textStyle: base.bodyLarge),
    bodyMedium: GoogleFonts.roboto(textStyle: base.bodyMedium),
    bodySmall: GoogleFonts.roboto(textStyle: base.bodySmall),
    labelLarge: GoogleFonts.roboto(textStyle: base.labelLarge),
    labelMedium: GoogleFonts.roboto(textStyle: base.labelMedium),
    labelSmall: GoogleFonts.roboto(textStyle: base.labelSmall),
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
        // Clamp text scaling for better IME compatibility (especially Vietnamese input),
        // while still respecting the user's preferred system text size.
        final TextScaler? effectiveScaler =
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
