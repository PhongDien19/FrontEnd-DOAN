/// Ngành được gợi ý kèm điểm phù hợp.
class MajorScore {
  final String name;
  final double? fitScore;
  const MajorScore({required this.name, this.fitScore});
}

/// Một bài đánh giá trong lịch sử, chuẩn hóa để dùng cho chức năng so sánh.
/// Cấu trúc `result` bám theo cách assessment_flow_screen đang đọc.
/// Parse "phòng thủ": thiếu trường nào cũng không làm app crash.
class TestResult {
  final String id;
  final String flow; // 'flow_b' = đánh giá ngành mục tiêu, còn lại = khám phá
  final String audience; // 'freshman' = sinh viên năm nhất, còn lại = THPT
  final String? targetMajorId; // chỉ có ở flow_b
  final String status; // 'completed' = đã hoàn thành
  final DateTime? createdAt;

  // Điểm tổng quan (0-100)
  final double? fitScore;
  final String? fitLevel;
  final double? languageScore;
  final double? profileScore;
  final double? careerScore;

  // Tính cách & Holland
  final String? mbtiType; // vd 'INTJ'
  final Map<String, String> mbtiChoices; // vd {'E/I': 'I', ...}
  final String? hollandCode; // vd 'RIA'
  final Map<String, double> hollandScores; // normalizedScores: R, I, A, S, E, C

  final List<MajorScore> majors;
  final List<String> strengths;
  final List<String> improvementAreas;
  final Map<String, dynamic> raw;

  const TestResult({
    required this.id,
    required this.flow,
    required this.audience,
    required this.targetMajorId,
    required this.status,
    required this.createdAt,
    required this.fitScore,
    required this.fitLevel,
    required this.languageScore,
    required this.profileScore,
    required this.careerScore,
    required this.mbtiType,
    required this.mbtiChoices,
    required this.hollandCode,
    required this.hollandScores,
    required this.majors,
    required this.strengths,
    required this.improvementAreas,
    required this.raw,
  });

  bool get isCompleted => status == 'completed';
  bool get isTargetCareerFlow => flow == 'flow_b';

  String get title =>
      isTargetCareerFlow ? 'Đánh giá ngành mục tiêu' : 'Khám phá ngành phù hợp';

  /// Server chỉ tạo bản ghi kết quả khi mở màn hình kết quả lần đầu,
  /// nên bài đã hoàn thành vẫn có thể chưa có `result`.
  bool get hasResult => raw['result'] is Map;

  TestResult withResult(Map<String, dynamic> result) =>
      TestResult.fromJson({...raw, 'result': result});

  String get createdAtLabel {
    final d = createdAt?.toLocal();
    if (d == null) return '';
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}';
  }

  /// Hai bài so sánh được khi cùng đã hoàn thành, cùng loại bài;
  /// riêng flow_b phải cùng một ngành mục tiêu (khác ngành thì điểm không so được).
  bool isComparableWith(TestResult other) =>
      id != other.id &&
      isCompleted &&
      other.isCompleted &&
      flow == other.flow &&
      (!isTargetCareerFlow || targetMajorId == other.targetMajorId);

  factory TestResult.fromJson(Map<String, dynamic> json) {
    final result = _asMap(json['result']);
    final personality = _asMap(result['personalityScores']);
    final holland = _asMap(result['hollandScores']);

    final choices = <String, String>{};
    _asMap(personality['dimensions']).forEach((key, detail) {
      if (detail is Map && detail['selected'] != null) {
        choices[key] = detail['selected'].toString();
      }
    });

    return TestResult(
      id: (json['assessmentId'] ?? json['id'] ?? json['sessionId'] ?? '')
          .toString(),
      flow: json['flow']?.toString() ?? '',
      audience: json['audience']?.toString() ?? '',
      targetMajorId: (json['targetMajorId'] ?? result['targetMajorId'])
          ?.toString(),
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      fitScore: _toDouble(result['fitScore']),
      fitLevel: result['fitLevel']?.toString(),
      languageScore: _toDouble(result['languageScore']),
      profileScore: _toDouble(result['profileScore']),
      careerScore: _toDouble(result['careerScore']),
      mbtiType: personality['mbtiType']?.toString(),
      mbtiChoices: choices,
      hollandCode: holland['topCode']?.toString(),
      hollandScores: _toScores(holland['normalizedScores']),
      majors: (result['recommendedMajors'] as List? ?? [])
          .whereType<Map>()
          .map(
            (m) => MajorScore(
              name: (m['majorName'] ?? m['name'] ?? 'Ngành chưa có tên')
                  .toString(),
              fitScore: _toDouble(m['fitScore']),
            ),
          )
          .toList(),
      strengths: _toStrings(result['strengths']),
      improvementAreas: _toStrings(result['improvementAreas']),
      raw: json,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<String> _toStrings(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static Map<String, double> _toScores(dynamic v) {
    final out = <String, double>{};
    if (v is Map) {
      v.forEach((k, val) {
        final d = _toDouble(val);
        if (d != null) out[k.toString()] = d;
      });
    }
    return out;
  }
}
