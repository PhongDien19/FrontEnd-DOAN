import 'package:flutter/material.dart';

/// Responsive sizing helpers shared by the Flutter screens.
class Responsive {
  Responsive._();

  /// Chiều rộng cơ sở dùng để tính tỉ lệ. Mọi giá trị được thiết kế
  /// cho màn hình mobile khoảng 400dp chiều rộng.
  static const double _referenceWidth = 400.0;

  /// Hệ số scale tối đa - không bao giờ phóng to quá 1.5 lần
  /// để tránh text trở nên quá to trên màn hình TV.
  static const double _maxScale = 1.5;

  /// Hệ số scale tối thiểu - không bao giờ co lại nhỏ hơn 1.0
  /// (giữ nguyên ở mobile).
  static const double _minScale = 1.0;

  /// Trả về hệ số scale theo chiều rộng màn hình hiện tại.
  ///
  /// Ví dụ:
  ///   width = 400 → 1.0
  ///   width = 900 → 1.25
  ///   width = 1600 → 1.5 (clamped)
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final raw = width / _referenceWidth;
    return raw.clamp(_minScale, _maxScale);
  }

  /// Scale một giá trị pixel theo chiều rộng màn hình, có min/max.
  ///
  /// Dùng cho: `padding`, `SizedBox`, `width`, `height`, `radius`,
  /// `SizedBox(width: Responsive.s(16))`.
  ///
  /// [min] và [max] để chặn không cho giá trị bị quá nhỏ / quá to
  /// trong trường hợp đặc biệt.
  static double s(
    BuildContext context,
    double value, {
    double? min,
    double? max,
  }) {
    final result = value * scaleFactor(context);
    if (min != null && result < min) return min;
    if (max != null && result > max) return max;
    return result;
  }

  /// Scale font size theo chiều rộng màn hình.
  /// Đây là hàm chính bạn sẽ dùng cho `fontSize:`.
  ///
  /// Sử dụng `MediaQuery.textScalerOf(context)` để cộng dồn với
  /// cài đặt font-size của thiết bị (quan trọng cho accessibility).
  static double font(BuildContext context, double baseSize) {
    final widthScale = scaleFactor(context);
    final scaled = baseSize * widthScale;
    // Tôn trọng cài đặt textScale của user (accessibility).
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(scaled);
  }

  /// Trả về maxWidth phù hợp cho nội dung.
  /// Trên mobile: full width. Trên desktop: giới hạn 1200dp để dễ đọc.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 1200;
    return width;
  }
}
