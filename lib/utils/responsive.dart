import 'package:flutter/material.dart';

/// Helper responsive: chuyển đổi giá trị pixel cố định sang giá trị
/// co giãn theo kích thước màn hình.
///
/// Lý do: App được thiết kế cho mobile (≈360-420dp) nhưng phải chạy
/// trên Chrome (desktop) với cửa sổ rộng vài nghìn pixel. Nếu để
/// các giá trị `fontSize: 12` hoặc `padding: 16` cố định thì khi
/// chạy trên Chrome toàn bộ UI trông nhỏ xíu. Các hàm dưới đây
/// sẽ scale theo chiều rộng màn hình một cách có kiểm soát.
///
/// Quy ước scale (dựa trên `width = 400` làm "kích thước tham chiếu"
/// - đây là chiều rộng phổ biến của điện thoại):
///   width < 600dp  : hệ số ~1.0      (điện thoại - giữ nguyên)
///   width = 900dp  : hệ số ≈ 1.25    (tablet nhỏ / Chrome cỡ trung)
///   width = 1200dp : hệ số ≈ 1.35    (Chrome rộng)
///   width ≥ 1600dp : hệ số ≈ 1.5     (màn hình rất lớn - clamp tại đây)
///
/// Với cùng công thức:
///   scale = clamp(width / 400, 1.0, 1.5)
/// → fontSize: 12 ở mobile sẽ thành 18 ở màn 1600dp (gấp 1.5 lần)
/// → padding: 16   ở mobile sẽ thành 24 ở màn 1600dp
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

  /// Scale chiều rộng (cho Container, SizedBox).
  ///
  /// Trên màn hình rộng, một số nội dung cần giới hạn maxWidth
  /// để không bị kéo dãn quá mức (vd: form đăng nhập).
  /// Mặc định max = 1200 (~kích thước tối đa của form trên desktop).
  static double width(BuildContext context, double value, {double? max}) {
    return s(context, value, max: max);
  }

  /// Phát hiện đang chạy trên màn hình "rộng" (Chrome desktop, tablet ngang...).
  /// Dùng để thay đổi layout: 1 cột vs 2 cột, padding rộng hơn...
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 900;
  }

  /// Phát hiện đang chạy trên màn hình rất lớn (TV, màn hình 4K).
  static bool isExtraWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1400;
  }

  /// Trả về maxWidth phù hợp cho nội dung.
  /// Trên mobile: full width. Trên desktop: giới hạn 1200dp để dễ đọc.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 1200;
    return width;
  }
}
