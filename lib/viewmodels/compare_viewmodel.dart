import 'package:flutter/material.dart';
import '../models/test_comparison.dart';
import '../models/test_result.dart';
import '../services/api_service.dart';

/// Quản lý việc chọn 2 bài test, tải kết quả còn thiếu và tạo bản so sánh.
class CompareViewModel extends ChangeNotifier {
  final List<TestResult> _selected = [];
  List<TestResult> get selected => List.unmodifiable(_selected);

  bool _isPreparing = false;
  bool get isPreparing => _isPreparing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool isSelected(TestResult t) => _selected.any((e) => e.id == t.id);

  /// Chọn / bỏ chọn một bài.
  /// Trả về lý do không chọn được, hoặc null nếu thành công.
  String? toggle(TestResult t) {
    if (t.id.isEmpty) return 'Bài này thiếu mã định danh nên chưa thể so sánh.';

    if (isSelected(t)) {
      _selected.removeWhere((e) => e.id == t.id);
      _errorMessage = null;
      notifyListeners();
      return null;
    }
    if (!t.isCompleted) return 'Chỉ so sánh được các bài đã hoàn thành.';
    if (_selected.length >= 2) {
      return 'Chỉ chọn tối đa 2 bài. Hãy bỏ chọn một bài trước.';
    }
    if (_selected.isNotEmpty) {
      final first = _selected.first;
      if (t.flow != first.flow) {
        return 'Chỉ so sánh được hai bài cùng loại đánh giá.';
      }
      if (!t.isComparableWith(first)) {
        return 'Hai bài đánh giá ngành mục tiêu phải cùng một ngành.';
      }
    }

    _selected.add(t);
    _errorMessage = null;
    notifyListeners();
    return null;
  }

  bool get canCompare =>
      _selected.length == 2 && _selected[0].isComparableWith(_selected[1]);

  bool get isReady => canCompare && _selected.every((t) => t.hasResult);

  /// Tải kết quả cho bài nào chưa có (server sẽ tự tạo nếu cần).
  Future<void> prepare() async {
    if (!canCompare) {
      _errorMessage = 'Cần chọn đủ 2 bài hợp lệ để so sánh.';
      notifyListeners();
      return;
    }

    _isPreparing = true;
    _errorMessage = null;
    notifyListeners();

    for (var i = 0; i < _selected.length; i++) {
      final t = _selected[i];
      if (t.hasResult) continue;

      final res = await ApiService.getAssessmentResult(t.id);
      final r = res['result'];
      if (res['success'] == true && r is Map) {
        _selected[i] = t.withResult(Map<String, dynamic>.from(r));
      } else {
        _errorMessage =
            res['message']?.toString() ??
            'Không thể tải kết quả của bài ${i + 1}.';
        break;
      }
    }

    _isPreparing = false;
    notifyListeners();
  }

  /// Bài cũ hơn là "trước", bài mới hơn là "sau".
  TestComparison? get comparison {
    if (!isReady) return null;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = [..._selected]
      ..sort((a, b) => (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch));
    return TestComparison.between(sorted[0], sorted[1]);
  }

  void clear() {
    if (_selected.isEmpty && _errorMessage == null) return;
    _selected.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
