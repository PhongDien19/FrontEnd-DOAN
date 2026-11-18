import 'test_result.dart';

/// Một chỉ số trước/sau (điểm tổng, điểm Holland...).
class MetricDelta {
  final String label;
  final double? before;
  final double? after;
  const MetricDelta(this.label, this.before, this.after);

  /// null nếu thiếu dữ liệu ở một trong hai bài.
  double? get delta =>
      (before != null && after != null) ? after! - before! : null;
}

/// Thay đổi của một ngành được gợi ý giữa hai bài.
class MajorChange {
  final String name;
  final bool inBefore;
  final bool inAfter;
  final double? before;
  final double? after;
  const MajorChange({
    required this.name,
    required this.inBefore,
    required this.inAfter,
    this.before,
    this.after,
  });

  bool get isNew => !inBefore && inAfter;
  bool get isDropped => inBefore && !inAfter;
  double? get delta =>
      (before != null && after != null) ? after! - before! : null;
}

/// Kết quả so sánh: `before` là bài cũ hơn, `after` là bài mới hơn.
class TestComparison {
  final TestResult before;
  final TestResult after;
  final List<MetricDelta> scores;
  final List<MetricDelta> holland;
  final List<String> changedMbtiDimensions;
  final List<MajorChange> majors;

  const TestComparison({
    required this.before,
    required this.after,
    required this.scores,
    required this.holland,
    required this.changedMbtiDimensions,
    required this.majors,
  });

  bool get mbtiChanged => before.mbtiType != after.mbtiType;
  bool get hollandCodeChanged => before.hollandCode != after.hollandCode;

  factory TestComparison.between(TestResult before, TestResult after) {
    final scores = [
      MetricDelta('Mức độ phù hợp', before.fitScore, after.fitScore),
      MetricDelta('Ngoại ngữ', before.languageScore, after.languageScore),
      MetricDelta('Học tập', before.profileScore, after.profileScore),
      MetricDelta('Cơ hội nghề nghiệp', before.careerScore, after.careerScore),
    ];

    const order = ['R', 'I', 'A', 'S', 'E', 'C'];
    int rank(String k) {
      final i = order.indexOf(k);
      return i < 0 ? 99 : i;
    }

    final hollandKeys = {
      ...before.hollandScores.keys,
      ...after.hollandScores.keys,
    }.toList()..sort((a, b) => rank(a).compareTo(rank(b)));
    final holland = hollandKeys
        .map(
          (k) =>
              MetricDelta(k, before.hollandScores[k], after.hollandScores[k]),
        )
        .toList();

    final dimKeys = {...before.mbtiChoices.keys, ...after.mbtiChoices.keys};
    final changedDims = dimKeys
        .where((k) => before.mbtiChoices[k] != after.mbtiChoices[k])
        .toList();

    String key(String name) => name.trim().toLowerCase();
    final bMap = {for (final m in before.majors) key(m.name): m};
    final aMap = {for (final m in after.majors) key(m.name): m};
    final majorKeys = [
      ...aMap.keys,
      ...bMap.keys.where((k) => !aMap.containsKey(k)),
    ];
    final majors = majorKeys
        .map(
          (k) => MajorChange(
            name: (aMap[k] ?? bMap[k])!.name,
            inBefore: bMap.containsKey(k),
            inAfter: aMap.containsKey(k),
            before: bMap[k]?.fitScore,
            after: aMap[k]?.fitScore,
          ),
        )
        .toList();

    return TestComparison(
      before: before,
      after: after,
      scores: scores,
      holland: holland,
      changedMbtiDimensions: changedDims,
      majors: majors,
    );
  }
}
