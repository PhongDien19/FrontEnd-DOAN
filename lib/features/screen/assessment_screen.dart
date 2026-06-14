import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models.dart'; // Vẫn cần models.dart để nhận diện class Question, Option

class AssessmentScreen extends StatefulWidget {
  final String
  title; // Tiêu đề của bài test (VD: "Bài test tính cách", "Đánh giá chuyên môn")
  final List<Question>
  questions; // Dữ liệu thực được truyền từ bên ngoài vào đây
  final ValueChanged<Map<int, String>> onComplete;
  final VoidCallback onBack;

  const AssessmentScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _current = 0;
  final Map<int, String> _answers = {};

  void _handleNext() {
    final currentQuestion = widget.questions[_current];
    if (!_answers.containsKey(currentQuestion.id)) return;

    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
      });
    } else {
      widget.onComplete(_answers); // Hoàn thành test thì trả kết quả ra ngoài
    }
  }

  void _handleBack() {
    if (_current == 0) {
      widget.onBack();
    } else {
      setState(() {
        _current--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu danh sách câu hỏi rỗng (chưa load kịp dữ liệu)
    if (widget.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final total = widget.questions.length;
    final progress = (_current + 1) / total;
    final q = widget.questions[_current];
    final selected = _answers[q.id];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[50]!, Colors.amber[50]!],
          ),
        ),
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.amber[500],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.brain,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${_current + 1} / $total",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber[500]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question Title
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "CÂU ${_current + 1}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                q.text,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Options List
                              ...q.options.map((opt) {
                                final isSelected = selected == opt.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _answers[q.id] = opt.value;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.amber[50]
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.amber[500]!
                                              : Colors.grey[200]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.amber[500]
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.amber[500]!
                                                    : Colors.grey[300]!,
                                                width: 2,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              opt.value,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              opt.label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? Colors.black87
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 32),
                              const Divider(height: 1),
                              const SizedBox(height: 24),

                              // ── Footer Buttons ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: _handleBack,
                                    icon: const Icon(
                                      LucideIcons.arrowLeft,
                                      size: 16,
                                    ),
                                    label: const Text("Trước"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: selected != null
                                        ? _handleNext
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selected != null
                                          ? Colors.amber[500]
                                          : Colors.grey[100],
                                      foregroundColor: selected != null
                                          ? Colors.white
                                          : Colors.grey[400],
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _current == total - 1
                                              ? "Hoàn thành"
                                              : "Tiếp theo",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          LucideIcons.arrowRight,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không có câu trả lời đúng hay sai — hãy chọn điều phù hợp nhất với bạn",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
