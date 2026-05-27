import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models.dart';

// Giả lập kiểu Answers tương đương Record<string, string> trong TS
typedef Answers = Map<String, String>;

// ── UI Component ─────────────────────────────────────────────────────────────
class ResultsScreen extends StatefulWidget {
  final AssessmentMode mode;
  final UserData userData;
  final Answers personalityAnswers;
  final Answers careerAnswers;
  final String career;
  final AuthUser authUser;
  final VoidCallback onDashboard;
  final VoidCallback onHome;

  const ResultsScreen({
    super.key,
    required this.mode,
    required this.userData,
    required this.personalityAnswers,
    required this.careerAnswers,
    required this.career,
    required this.authUser,
    required this.onDashboard,
    required this.onHome,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _deepScan = false;
  bool _scanning = false;

  late Scores _scores;
  late int _match;
  late List<RadarDataPoint> _radarData;
  late List<String> _strengths;
  late List<String> _gaps;

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  void _calculateResults() {
    final pAnswers = widget.personalityAnswers.isNotEmpty
        ? widget.personalityAnswers
        : {"1": "A", "2": "A", "3": "A", "4": "A", "5": "A"};
    final cAnswers = widget.careerAnswers.isNotEmpty
        ? widget.careerAnswers
        : {"1": "A", "2": "A", "3": "A", "4": "A", "5": "A"};

    _scores = _computeScores(pAnswers, cAnswers);
    _match = _scores.matchScore.clamp(60, 95);

    _radarData = [
      RadarDataPoint("Tư duy phân tích", _scores.analytical, 100),
      RadarDataPoint("Sáng tạo", _scores.creative, 100),
      RadarDataPoint("Giao tiếp", _scores.communication, 100),
      RadarDataPoint("Tổ chức", _scores.organization, 100),
      RadarDataPoint("Kỹ thuật", _scores.technical, 100),
      RadarDataPoint("Lãnh đạo", _scores.leadership, 100),
    ];

    _strengths = _radarData
        .where((d) => d.value >= 65)
        .map((d) => d.dimension)
        .toList();
    _gaps = _radarData
        .where((d) => d.value < 50)
        .map((d) => d.dimension)
        .toList();
  }

  Scores _computeScores(Answers pAnswers, Answers cAnswers) {
    final pCounts = {"A": 0, "B": 0, "C": 0, "D": 0};
    for (var v in pAnswers.values) {
      if (pCounts.containsKey(v)) pCounts[v] = pCounts[v]! + 1;
    }

    final cCounts = {"A": 0, "B": 0, "C": 0, "D": 0};
    for (var v in cAnswers.values) {
      if (cCounts.containsKey(v)) cCounts[v] = cCounts[v]! + 1;
    }

    int total(Map<String, int> obj) => obj.values.fold(0, (a, b) => a + b);
    final pTotal = total(pCounts) == 0 ? 1 : total(pCounts);
    final cTotal = total(cCounts) == 0 ? 1 : total(cCounts);

    int pct(int n, int t) => ((n / t) * 100).round();

    return Scores(
      analytical: (pct(pCounts["A"]!, pTotal) * 4 + 20).clamp(0, 95),
      creative: (pct(pCounts["B"]!, pTotal) * 4 + 20).clamp(0, 95),
      communication: (pct(pCounts["C"]!, pTotal) * 4 + 20).clamp(0, 95),
      organization: (pct(pCounts["D"]!, pTotal) * 4 + 20).clamp(0, 95),
      technical: (pct(cCounts["A"]! + cCounts["B"]!, cTotal) * 3 + 25).clamp(
        0,
        95,
      ),
      leadership: (pct(pCounts["A"]! + pCounts["D"]!, pTotal) * 2 + 30).clamp(
        0,
        95,
      ),
      matchScore:
          ((pct(pCounts["A"]!, pTotal) +
                          pct(cCounts["A"]! + cCounts["B"]!, cTotal)) /
                      2 +
                  50)
              .round(),
    );
  }

  void _handleDeepScan() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _scanning = false;
        _deepScan = true;
      });
    }
  }

  void _handleExportPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Tính năng xuất PDF đang được phát triển. Báo cáo sẽ được gửi qua email của bạn sớm!",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchColor = _match >= 80
        ? Colors.green[600]!
        : _match >= 65
        ? Colors.amber[600]!
        : Colors.red[500]!;
    final matchBg = _match >= 80
        ? Colors.green[50]!
        : _match >= 65
        ? Colors.amber[50]!
        : Colors.red[50]!;
    final matchBorder = _match >= 80
        ? Colors.green[200]!
        : _match >= 65
        ? Colors.amber[200]!
        : Colors.red[200]!;
    final matchLabel = _match >= 80
        ? "Rất phù hợp"
        : _match >= 65
        ? "Khá phù hợp"
        : "Cần cân nhắc";
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.amber[500],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "CP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Kết quả đánh giá",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "${widget.authUser.name} • ${widget.career}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            if (isDesktop)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _handleExportPDF,
                    icon: const Icon(LucideIcons.download, size: 14),
                    label: const Text("Xuất PDF"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey[300]!),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onDashboard,
                    icon: const Icon(LucideIcons.layoutDashboard, size: 14),
                    label: const Text("Dashboard"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024), // max-w-5xl
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Match Score Hero ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: matchBg,
                    border: Border.all(color: matchBorder, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: isDesktop
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: isDesktop ? 150 : double.infinity,
                        margin: EdgeInsets.only(bottom: isDesktop ? 0 : 24),
                        child: Column(
                          children: [
                            Text(
                              "$_match%",
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: matchColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              matchLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: matchColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Serif',
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Mức độ phù hợp với ngành ",
                                  ),
                                  TextSpan(
                                    text: widget.career,
                                    style: TextStyle(color: Colors.amber[700]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Dựa trên ${widget.mode == AssessmentMode.discovery ? "bài test tính cách và " : ""}bài đánh giá chuyên sâu, AI phân tích ${_radarData.length} chiều năng lực của bạn với yêu cầu của ngành ${widget.career}.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _match / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _match >= 80
                                        ? Colors.green[500]
                                        : _match >= 65
                                        ? Colors.amber[500]
                                        : Colors.red[400],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Main Grid (Chart & Scores) ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final children = [
                      // Radar Chart
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Biểu đồ phân tích năng lực",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: RadarChart(
                                  RadarChartData(
                                    dataSets: [
                                      RadarDataSet(
                                        fillColor: Colors.amber.withValues(
                                          alpha: 0.25,
                                        ),
                                        borderColor: Colors.amber[500],
                                        entryRadius: 2,
                                        borderWidth: 2,
                                        dataEntries: _radarData
                                            .map(
                                              (d) => RadarEntry(
                                                value: d.value.toDouble(),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                    radarBackgroundColor: Colors.transparent,
                                    borderData: FlBorderData(show: false),
                                    radarBorderData: const BorderSide(
                                      color: Colors.grey,
                                      width: 0.5,
                                    ),
                                    titlePositionPercentageOffset: 0.2,
                                    getTitle: (index, angle) => RadarChartTitle(
                                      text: _radarData[index].dimension,
                                      angle: angle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isWide)
                        const SizedBox(width: 24)
                      else
                        const SizedBox(height: 24),

                      // Scores Breakdown
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Chi tiết từng chiều",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._radarData.map((d) {
                                final color = d.value >= 70
                                    ? Colors.green[500]!
                                    : d.value >= 50
                                    ? Colors.amber[500]!
                                    : Colors.red[400]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            d.dimension,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            "${d.value}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: d.value / 100,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ];
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: children,
                          )
                        : Column(children: children);
                  },
                ),
                const SizedBox(height: 24),

                // ── Strengths & Gaps ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final children = [
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      LucideIcons.checkCircle2,
                                      size: 16,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Điểm mạnh nổi bật",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _strengths.isNotEmpty
                                  ? Column(
                                      children: _strengths
                                          .map(
                                            (s) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[500],
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      s,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  : Text(
                                      "Tiếp tục phát triển đều các chiều năng lực",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      if (isWide)
                        const SizedBox(width: 24)
                      else
                        const SizedBox(height: 24),
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      LucideIcons.alertCircle,
                                      size: 16,
                                      color: Colors.amber[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Cần phát triển thêm",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _gaps.isNotEmpty
                                  ? Column(
                                      children: _gaps
                                          .map(
                                            (g) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber[500],
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      g,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  : Text(
                                      "Hồ sơ năng lực của bạn khá cân bằng và vững chắc",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ];
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: children,
                          )
                        : Column(children: children);
                  },
                ),
                const SizedBox(height: 24),

                // ── AI Analysis ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LucideIcons.sparkles,
                                  size: 16,
                                  color: Colors.amber[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Phân tích AI",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (!_deepScan)
                            OutlinedButton.icon(
                              onPressed: _scanning ? null : _handleDeepScan,
                              icon: Icon(
                                LucideIcons.zoomIn,
                                size: 14,
                                color: Colors.amber[700],
                              ),
                              label: Text(
                                _scanning
                                    ? "Đang phân tích..."
                                    : "Deep-scan AI",
                                style: TextStyle(color: Colors.amber[700]),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.amber[300]!),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: "Dựa trên kết quả đánh giá, "),
                            TextSpan(
                              text: widget.authUser.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const TextSpan(text: " thể hiện "),
                            TextSpan(
                              text: _strengths.isNotEmpty
                                  ? "năng lực nổi bật về ${_strengths.take(2).join(" và ")}"
                                  : "tiềm năng phát triển đa chiều",
                            ),
                            const TextSpan(
                              text:
                                  " — những yếu tố cốt lõi để thành công trong ngành ",
                            ),
                            TextSpan(
                              text: widget.career,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                            const TextSpan(text: ".\n\n"),
                            const TextSpan(text: "Điểm match "),
                            TextSpan(
                              text: "$_match%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                            TextSpan(
                              text:
                                  " cho thấy bạn có nền tảng ${_match >= 80 ? "rất tốt" : "khá tốt"} để phát triển trong lĩnh vực này. Với ",
                            ),
                            TextSpan(text: widget.userData.location),
                            TextSpan(
                              text:
                                  ", thị trường lao động đang có nhu cầu cao về nhân sự ngành ${widget.career}.",
                            ),
                          ],
                        ),
                      ),
                      if (_deepScan) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ), // Animate pulse
                            const SizedBox(width: 8),
                            const Text(
                              "KẾT QUẢ DEEP-SCAN AI",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            border: Border.all(color: Colors.amber[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Phân tích chuyên sâu: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "Hồ sơ tính cách của bạn phù hợp với nhóm chuyên gia ${_scores.analytical > _scores.creative ? "thiên về phân tích và kỹ thuật" : "thiên về sáng tạo và đổi mới"}. Trong ngành ${widget.career}, nhóm này thường thăng tiến nhanh ở các vị trí ${widget.career == "Kỹ sư phần mềm"
                                              ? "Senior Engineer, Tech Lead, Architect"
                                              : widget.career == "Thiết kế UX/UI"
                                              ? "Senior Designer, Design Lead, Creative Director"
                                              : "Senior Manager, Director, C-level"}.",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Pivot logic: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "Nếu sau 2 năm bạn muốn chuyển hướng, các ngành liền kề phù hợp nhất là: ${widget.career == "Kỹ sư phần mềm"
                                              ? "Data Science, Product Management, CTO startup"
                                              : widget.career == "Thiết kế UX/UI"
                                              ? "Product Design, Brand Strategy, Creative Consulting"
                                              : "Organizational Development, Executive Coaching, Business Consulting"}.",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Lời khuyên ưu tiên: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "Tập trung ${_gaps.isNotEmpty ? "nâng cao ${_gaps.first} trong 6 tháng tới — đây là khoảng trống lớn nhất so với yêu cầu ngành" : "duy trì và đào sâu các thế mạnh hiện có, đồng thời xây dựng portfolio thực tế"}.",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Recommendations ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.trendingUp,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Bước tiếp theo được đề xuất",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600;
                          final items = [
                            {
                              "step": "01",
                              "title": "Xây dựng portfolio",
                              "desc":
                                  "Tạo 2–3 dự án thực tế trong lĩnh vực ${widget.career}",
                              "time": "1–3 tháng",
                            },
                            {
                              "step": "02",
                              "title": "Học chứng chỉ cơ bản",
                              "desc":
                                  "Hoàn thành 1 khóa học chuyên sâu được công nhận trong ngành",
                              "time": "3–6 tháng",
                            },
                            {
                              "step": "03",
                              "title": "Tìm mentor & network",
                              "desc":
                                  "Kết nối với ít nhất 5 chuyên gia trong ngành qua LinkedIn",
                              "time": "Ngay bây giờ",
                            },
                          ];

                          final children = items
                              .map(
                                (item) => Expanded(
                                  flex: isWide ? 1 : 0,
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: isWide ? 0 : 16,
                                      right: isWide ? 16 : 0,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["step"]!,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[500],
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item["title"]!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item["desc"]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            item["time"]!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.amber[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList();

                          return isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: children,
                                )
                              : Column(children: children);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── CTA Buttons ──
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onHome,
                      icon: const Icon(LucideIcons.home, size: 16),
                      label: const Text("Về trang chủ"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onDashboard,
                      icon: const Icon(LucideIcons.layoutDashboard, size: 16),
                      label: const Text("Xem Dashboard cá nhân"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[500],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _handleExportPDF,
                      icon: const Icon(LucideIcons.download, size: 16),
                      label: const Text("Xuất báo cáo PDF"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber[700],
                        side: BorderSide(color: Colors.amber[300]!),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
