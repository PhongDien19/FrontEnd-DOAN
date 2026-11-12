import 'package:flutter/material.dart';

/// Bảng màu: AppBar vàng, nền trắng, chữ đen.
class AppColors {
  // Nền
  static const background = Colors.white;
  static const surface = Color(0xFFF7F7F7); // card, ô nhập
  static const chip = Color(0xFFEFEFEF);
  static const border = Color(0xFFE5E5E5);

  // Vàng
  static const primary = Color(0xFFFFC107); // AppBar, nút chính
  static const primaryDark = Color(0xFFE09A00); // icon/viền nhấn trên nền trắng
  static const primaryLight = Color(0xFFFFF4CC);

  // Chữ
  static const textPrimary = Color(0xFF111111);
  static const textBody = Color(0xFF333333);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textHint = Color(0xFF9E9E9E);
  static const onPrimary = Color(0xFF111111); // chữ trên nền vàng

  // Trạng thái
  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFE08A00);
  static const error = Color(0xFFD93025);
}
