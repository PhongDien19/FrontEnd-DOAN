import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class ComprehensiveReportScreen extends StatefulWidget {
  const ComprehensiveReportScreen({super.key});

  @override
  State<ComprehensiveReportScreen> createState() => _ComprehensiveReportScreenState();
}

class _ComprehensiveReportScreenState extends State<ComprehensiveReportScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bạn cần đăng nhập để xem báo cáo hướng nghiệp toàn diện.';
      });
      return;
    }

    final profile = auth.userProfile;
    // Kiểm tra xem đã hoàn thành ít nhất 1 bài test chưa
    final hasHolland = profile != null && profile['hollandScores'] != null;
    final hasPersonality = profile != null && profile['personalityScores'] != null;
    final hasCognitive = profile != null && profile['cognitiveScores'] != null;
    final hasValues = profile != null && profile['valuesScores'] != null;

    if (!hasHolland && !hasPersonality && !hasCognitive && !hasValues) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bạn chưa hoàn thành bất kỳ bài trắc nghiệm nào. Vui lòng làm ít nhất một bài trắc nghiệm ở màn hình chính trước khi xem báo cáo.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final contextData = {
      'targetJob': auth.targetJob,
      'age': profile['age'] ?? 18,
      'educationLevel': auth.educationLevel,
      'hobby': auth.hobby,
    };

    final result = await ApiService.getComprehensiveAssessment(auth.userId!, contextData);

    setState(() {
      _isLoading = false;
      if (result['success'] == true && result['comprehensiveAssessment'] != null) {
        _report = result['comprehensiveAssessment'];
      } else {
        _errorMessage = result['message'] ?? 'Không thể tải báo cáo từ AI. Vui lòng thử lại sau.';
      }
    });
  }

  Color _getZoneColor(String zone) {
    switch (zone.toLowerCase()) {
      case 'tối ưu':
        return Colors.green;
      case 'tiềm năng':
        return const Color(0xFFFFB74D); // Orange
      case 'rủi ro':
        return Colors.redAccent;
      default:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Báo Cáo Hướng Nghiệp AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            bottom: 10,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withValues(alpha: 0.04),
              ),
            ),
          ),

          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 20),
            Text(
              'AI đang phân tích và tổng hợp dữ liệu...',
              style: GoogleFonts.outfit(color: const Color(0xFF888B9B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 64, color: Color(0xFF5E6072)),
              const SizedBox(height: 20),
              Text(
                'Chưa Sẵn Sàng',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF888B9B), height: 1.5),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Quay lại trang chủ', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_report == null) return const SizedBox.shrink();

    final overall = _report!['overallCompatibility'] ?? 0;
    final zone = _report!['compatibilityZone'] ?? 'Chưa xác định';
    final zoneColor = _getZoneColor(zone);
    final summary = _report!['comprehensiveSummary'] ?? '';
    final strengths = List<String>.from(_report!['strengths'] ?? []);
    final weaknesses = List<String>.from(_report!['weaknesses'] ?? []);
    final careers = List<String>.from(_report!['recommendedCareers'] ?? []);
    final skills = List<String>.from(_report!['skillDevelopment'] ?? []);
    final environment = _report!['workEnvironment'] ?? '';
    final advice = _report!['careerAdvice'] ?? '';

    // Pillar scores logic
    final pillarScores = _report!['pillarScores'] as Map<String, dynamic>? ?? {};
    final double scoreInterest = double.tryParse(pillarScores['interest']?.toString() ?? '0') ?? 0.0;
    final double scorePersonality = double.tryParse(pillarScores['personality']?.toString() ?? '0') ?? 0.0;
    final double scoreAbility = double.tryParse(pillarScores['ability']?.toString() ?? '0') ?? 0.0;
    final double scoreValues = double.tryParse(pillarScores['values']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compatibility Circle Meter
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2C2C3E)),
            ),
            child: Column(
              children: [
                Text(
                  'Độ Phù Hợp Nghề Nghiệp',
                  style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF888B9B), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: overall / 100.0,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$overall%',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: zoneColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                zone,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: zoneColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC3C5E0), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4-Pillars Chart
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2C2C3E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điểm Số Theo Trụ Cột',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 5,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String label = '';
                              switch (value.toInt()) {
                                case 0:
                                  label = 'Sở thích';
                                  break;
                                case 1:
                                  label = 'Tính cách';
                                  break;
                                case 2:
                                  label = 'Năng lực';
                                  break;
                                case 3:
                                  label = 'Giá trị';
                                  break;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  label,
                                  style: GoogleFonts.inter(color: const Color(0xFF888B9B), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _buildBarGroup(0, scoreInterest, const Color(0xFFFF5252)),
                        _buildBarGroup(1, scorePersonality, const Color(0xFF7C4DFF)),
                        _buildBarGroup(2, scoreAbility, const Color(0xFF00E676)),
                        _buildBarGroup(3, scoreValues, const Color(0xFFFFD600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Strengths & Weaknesses Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildListItemBox(
                  title: 'Điểm Mạnh',
                  items: strengths,
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildListItemBox(
                  title: 'Điểm Cần Cải Thiện',
                  items: weaknesses,
                  icon: Icons.remove_circle_outline_rounded,
                  iconColor: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recommended Careers
          _buildInfoCard(
            title: 'Gợi Ý Nghề Nghiệp Phù Hợp',
            icon: Icons.work_outline_rounded,
            iconColor: const Color(0xFF00F2FE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: careers.map((job) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Skill development
          _buildInfoCard(
            title: 'Lộ Trình Phát Triển Kỹ Năng',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFFF7A00),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: skills.map((skill) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right_rounded, color: Color(0xFFFF7A00)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          skill,
                          style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Environment and Advice
          _buildInfoCard(
            title: 'Môi Trường Làm Việc Phù Hợp',
            icon: Icons.business_rounded,
            iconColor: const Color(0xFFE040FB),
            child: Text(
              environment,
              style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),

          _buildInfoCard(
            title: 'Lời Khuyên Sự Nghiệp',
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFF00F5A0),
            child: Text(
              advice,
              style: GoogleFonts.inter(color: const Color(0xFFC3C5E0), fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 5,
            color: const Color(0xFF1F1F2C),
          ),
        ),
      ],
    );
  }

  Widget _buildListItemBox({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  '• $item',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF888B9B), height: 1.3),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
