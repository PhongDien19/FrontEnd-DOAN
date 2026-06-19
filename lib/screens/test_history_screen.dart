import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class TestHistoryScreen extends StatefulWidget {
  final String userId;

  const TestHistoryScreen({super.key, required this.userId});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.getHistory(widget.userId);

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _history = res['history'] ?? [];
        // Sắp xếp theo ngày gần nhất (createdAt) giảm dần
        _history.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      } else {
        _errorMessage = res['message'] ?? 'Không thể tải lịch sử làm bài. Vui lòng thử lại sau.';
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Gần đây';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return 'Gần đây';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day/$month/$year';
  }

  String _getTestType(dynamic session) {
    if (session['testType'] != null) {
      return session['testType'].toString().toLowerCase();
    }
    final questions = session['questions'] as List<dynamic>? ?? [];
    if (questions.isNotEmpty && questions[0]['testType'] != null) {
      return questions[0]['testType'].toString().toLowerCase();
    }
    // Thử đoán từ testName
    final testName = (session['testName'] ?? '').toString().toLowerCase();
    if (testName.contains('holland')) return 'holland';
    if (testName.contains('personality') || testName.contains('tính cách') || testName.contains('mbti')) return 'personality';
    if (testName.contains('cognitive') || testName.contains('năng lực')) return 'cognitive';
    if (testName.contains('values') || testName.contains('giá trị')) return 'values';
    if (testName.contains('khảo sát động') || testName.contains('dynamic')) return 'dynamic_survey';
    return 'career';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'holland':
        return Icons.palette_outlined;
      case 'personality':
        return Icons.psychology_outlined;
      case 'cognitive':
        return Icons.lightbulb_outline_rounded;
      case 'values':
        return Icons.star_border_rounded;
      case 'dynamic_survey':
        return Icons.psychology_alt_rounded;
      default:
        return Icons.assessment_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'holland':
        return const Color(0xFFFF5252);
      case 'personality':
        return const Color(0xFF7C4DFF);
      case 'cognitive':
        return const Color(0xFF00E676);
      case 'values':
        return const Color(0xFFFFD600);
      case 'dynamic_survey':
        return const Color(0xFF00F2FE);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  void _viewTestDetails(dynamic session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final questions = session['questions'] as List<dynamic>? ?? [];
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E6072),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    session['testName'] ?? 'Chi tiết bài trắc nghiệm',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã phiên: ${session['sessionId']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF888B9B),
                  ),
                ),
                const Divider(color: Color(0xFF2C2C3E), height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F13),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2C2C3E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu ${index + 1}: ${q['questionText']}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Đã trả lời: ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF888B9B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    q['userAnswer'] ?? 'Chưa trả lời',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Lịch Sử Làm Bài',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: 20,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF888B9B), fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFF5E6072)),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử làm bài',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF888B9B)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Text(
            '${_history.length} bài đã làm',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF888B9B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final session = _history[index];
              final testName = session['testName'] ?? 'Bài test hướng nghiệp';
              final isCompleted = session['isCompleted'] ?? true;
              final questions = session['questions'] as List<dynamic>? ?? [];
              final questionsCount = questions.length;
              final dateStr = _formatDate(session['createdAt']);
              
              final type = _getTestType(session);
              final pillarIcon = _getIconForType(type);
              final pillarColor = _getColorForType(type);
              
              final score = session['score'] != null ? double.tryParse(session['score'].toString()) : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF191922),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2C2C3E)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: pillarColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        pillarIcon,
                        color: pillarColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      testName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(
                            '$questionsCount câu hỏi',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF888B9B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: const Color(0xFF5E6072), fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompleted ? 'Hoàn thành' : 'Chưa xong',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isCompleted ? Colors.green : Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: const Color(0xFF5E6072), fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF5E6072),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (score != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (score > 3 ? const Color(0xFF00F5A0) : const Color(0xFFFFB74D)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              score.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: score > 3 ? const Color(0xFF00F5A0) : const Color(0xFFFFB74D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF888B9B)),
                      ],
                    ),
                    onTap: () => _viewTestDetails(session),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
