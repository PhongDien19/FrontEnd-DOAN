import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models.dart';

// ── Dữ liệu tĩnh ─────────────────────────────────────────────────────────────
final List<Question> personalityQuestions = [
  Question(
    id: 1,
    text: "Khi gặp một vấn đề phức tạp, bạn thường làm gì đầu tiên?",
    options: [
      Option(value: "A", label: "Phân tích từng bước theo logic và dữ liệu"),
      Option(
        value: "B",
        label: "Tìm kiếm giải pháp sáng tạo, không theo lối mòn",
      ),
      Option(value: "C", label: "Tham khảo ý kiến và lắng nghe người khác"),
      Option(value: "D", label: "Lập kế hoạch chi tiết và phân bổ nguồn lực"),
    ],
  ),
  Question(
    id: 2,
    text: "Môi trường làm việc lý tưởng của bạn là?",
    options: [
      Option(value: "A", label: "Yên tĩnh, tập trung, ít bị gián đoạn"),
      Option(value: "B", label: "Năng động, đầy thách thức và cơ hội mới"),
      Option(value: "C", label: "Hợp tác nhóm, giao tiếp và kết nối nhiều"),
      Option(
        value: "D",
        label: "Có cấu trúc rõ ràng, quy trình và mục tiêu cụ thể",
      ),
    ],
  ),
  Question(
    id: 3,
    text: "Điều gì mang lại sự thỏa mãn nhất cho bạn trong công việc?",
    options: [
      Option(value: "A", label: "Tìm ra giải pháp tối ưu cho bài toán khó"),
      Option(value: "B", label: "Tạo ra điều gì đó mới mẻ và có ý nghĩa"),
      Option(value: "C", label: "Giúp người khác phát triển và đạt mục tiêu"),
      Option(value: "D", label: "Hoàn thành dự án đúng hạn và vượt kỳ vọng"),
    ],
  ),
  Question(
    id: 4,
    text: "Bạn học hiệu quả nhất bằng cách nào?",
    options: [
      Option(
        value: "A",
        label: "Đọc tài liệu và nghiên cứu độc lập, chuyên sâu",
      ),
      Option(value: "B", label: "Thực hành và thử nghiệm trực tiếp"),
      Option(value: "C", label: "Học qua thảo luận, trao đổi với người khác"),
      Option(value: "D", label: "Theo dõi hướng dẫn từng bước, có cấu trúc"),
    ],
  ),
  Question(
    id: 5,
    text: "Trong công việc, bạn coi trọng nhất điều gì?",
    options: [
      Option(value: "A", label: "Độ chính xác và chất lượng cao"),
      Option(value: "B", label: "Sự sáng tạo và tự do biểu đạt"),
      Option(value: "C", label: "Mối quan hệ và tinh thần đồng đội"),
      Option(value: "D", label: "Hiệu quả và kết quả đo lường được"),
    ],
  ),
  Question(
    id: 6,
    text: "Khi phải ra quyết định quan trọng, bạn thường?",
    options: [
      Option(value: "A", label: "Thu thập và phân tích dữ liệu kỹ lưỡng"),
      Option(value: "B", label: "Tin vào trực giác và cảm nhận sáng tạo"),
      Option(value: "C", label: "Tham khảo ý kiến nhiều người liên quan"),
      Option(value: "D", label: "Cân nhắc rủi ro, lợi ích và tính thực tế"),
    ],
  ),
  Question(
    id: 7,
    text: "Bạn cảm thấy thế nào khi làm việc với số liệu và dữ liệu?",
    options: [
      Option(value: "A", label: "Rất thoải mái — đây là điểm mạnh của tôi"),
      Option(value: "B", label: "Bình thường, tôi thích phần sáng tạo hơn"),
      Option(
        value: "C",
        label: "Không phải thế mạnh, tôi giỏi làm việc với người",
      ),
      Option(value: "D", label: "Ổn nếu có mục đích và quy trình rõ ràng"),
    ],
  ),
  Question(
    id: 8,
    text: "Khi dự án gặp trở ngại bất ngờ, bạn phản ứng như thế nào?",
    options: [
      Option(
        value: "A",
        label: "Phân tích nguyên nhân và tìm giải pháp hệ thống",
      ),
      Option(
        value: "B",
        label: "Nghĩ ra hướng tiếp cận hoàn toàn mới và sáng tạo",
      ),
      Option(value: "C", label: "Huy động nhóm cùng nhau giải quyết"),
      Option(value: "D", label: "Điều chỉnh kế hoạch và quản lý rủi ro"),
    ],
  ),
  Question(
    id: 9,
    text: "Bạn muốn đóng góp vào xã hội bằng cách nào?",
    options: [
      Option(
        value: "A",
        label: "Phát triển công nghệ và giải pháp kỹ thuật tiên tiến",
      ),
      Option(
        value: "B",
        label: "Tạo ra nghệ thuật, thiết kế và trải nghiệm đặc sắc",
      ),
      Option(
        value: "C",
        label: "Hỗ trợ và giúp đỡ con người phát triển toàn diện",
      ),
      Option(value: "D", label: "Tổ chức và quản lý nguồn lực xã hội hiệu quả"),
    ],
  ),
  Question(
    id: 10,
    text: "Khi được giao một dự án mới, điều đầu tiên bạn làm là?",
    options: [
      Option(
        value: "A",
        label: "Nghiên cứu tài liệu và tìm hiểu giải pháp hiện có",
      ),
      Option(value: "B", label: "Brainstorm ý tưởng sáng tạo và độc đáo"),
      Option(
        value: "C",
        label: "Liên hệ với các bên liên quan để hiểu kỳ vọng",
      ),
      Option(
        value: "D",
        label: "Lập kế hoạch chi tiết với timeline và milestone",
      ),
    ],
  ),
  Question(
    id: 11,
    text: "Bạn thích công việc có đặc điểm gì?",
    options: [
      Option(
        value: "A",
        label: "Nhiều thách thức trí tuệ và bài toán phức tạp",
      ),
      Option(
        value: "B",
        label: "Không gian sáng tạo tự do và đổi mới liên tục",
      ),
      Option(value: "C", label: "Tương tác với con người thường xuyên"),
      Option(value: "D", label: "Mục tiêu rõ ràng và đo lường kết quả được"),
    ],
  ),
  Question(
    id: 12,
    text: "Nhìn về tương lai 10 năm, bạn muốn trở thành?",
    options: [
      Option(
        value: "A",
        label: "Chuyên gia hàng đầu trong lĩnh vực kỹ thuật/nghiên cứu",
      ),
      Option(
        value: "B",
        label: "Người sáng tạo với thương hiệu cá nhân nổi bật",
      ),
      Option(
        value: "C",
        label: "Nhà lãnh đạo truyền cảm hứng, phát triển đội ngũ",
      ),
      Option(
        value: "D",
        label: "Giám đốc điều hành tổ chức hoặc doanh nghiệp thành công",
      ),
    ],
  ),
  Question(
    id: 13,
    text: "Phong cách làm việc bạn ưa thích là?",
    options: [
      Option(
        value: "A",
        label: "Độc lập — tự mình nghiên cứu và giải quyết vấn đề",
      ),
      Option(
        value: "B",
        label: "Tự do — ít ràng buộc, tự quyết định cách thực hiện",
      ),
      Option(
        value: "C",
        label: "Cộng tác — luôn làm việc cùng nhóm, hỗ trợ lẫn nhau",
      ),
      Option(
        value: "D",
        label: "Có cấu trúc — quy trình rõ ràng, phân công cụ thể",
      ),
    ],
  ),
  Question(
    id: 14,
    text: "Người khác thường nhận xét bạn là người như thế nào?",
    options: [
      Option(value: "A", label: "Thông minh, có óc phân tích và tư duy logic"),
      Option(value: "B", label: "Sáng tạo, độc đáo và có tư duy khác biệt"),
      Option(value: "C", label: "Thân thiện, đồng cảm và giỏi kết nối"),
      Option(value: "D", label: "Có tổ chức, đáng tin cậy và thực tế"),
    ],
  ),
  Question(
    id: 15,
    text: "Điều bạn lo ngại nhất khi bước vào nghề nghiệp là?",
    options: [
      Option(
        value: "A",
        label: "Làm việc thiếu chính xác hoặc mắc lỗi kỹ thuật",
      ),
      Option(
        value: "B",
        label: "Công việc nhàm chán, lặp đi lặp lại, không có sáng tạo",
      ),
      Option(
        value: "C",
        label: "Phải làm việc hoàn toàn một mình, không có đồng nghiệp",
      ),
      Option(value: "D", label: "Thiếu định hướng, mục tiêu không rõ ràng"),
    ],
  ),
];

List<Question> getCareerQuestions(String career) {
  final careerName = career.isNotEmpty ? career : "này";
  return [
    Question(
      id: 1,
      text:
          "Bạn đánh giá kiến thức nền tảng của mình về lĩnh vực $careerName ở mức nào?",
      options: [
        Option(value: "A", label: "Rất vững — tôi đã học và thực hành nhiều"),
        Option(
          value: "B",
          label: "Khá tốt — có kiến thức cơ bản, cần bổ sung thêm",
        ),
        Option(value: "C", label: "Mới bắt đầu — đang tìm hiểu"),
        Option(value: "D", label: "Chưa có — hoàn toàn mới với lĩnh vực này"),
      ],
    ),
    Question(
      id: 2,
      text:
          "Bạn đã có kinh nghiệm thực tế liên quan đến ngành $careerName chưa?",
      options: [
        Option(value: "A", label: "Có — đã đi làm hoặc thực tập trong ngành"),
        Option(
          value: "B",
          label: "Một chút — đã làm dự án cá nhân hoặc học thuật",
        ),
        Option(
          value: "C",
          label: "Chưa nhiều — chỉ tìm hiểu qua sách/khóa học",
        ),
        Option(value: "D", label: "Chưa có — đây là lần đầu tôi khám phá"),
      ],
    ),
    Question(
      id: 3,
      text:
          "Bạn sẵn sàng đầu tư bao nhiêu thời gian/tuần để học kỹ năng cho ngành $careerName?",
      options: [
        Option(
          value: "A",
          label: "20+ giờ/tuần — tôi rất nghiêm túc với mục tiêu này",
        ),
        Option(value: "B", label: "10–20 giờ/tuần — sẵn sàng đầu tư đáng kể"),
        Option(
          value: "C",
          label: "5–10 giờ/tuần — học song song với công việc/học chính",
        ),
        Option(value: "D", label: "Dưới 5 giờ/tuần — thời gian có hạn"),
      ],
    ),
    Question(
      id: 4,
      text:
          "Môi trường làm việc điển hình của ngành $careerName có phù hợp với bạn không?",
      options: [
        Option(
          value: "A",
          label: "Rất phù hợp — đúng với sở thích làm việc của tôi",
        ),
        Option(value: "B", label: "Khá phù hợp — có thể thích nghi dễ dàng"),
        Option(value: "C", label: "Chấp nhận được — cần thời gian làm quen"),
        Option(value: "D", label: "Không chắc — chưa hiểu rõ môi trường này"),
      ],
    ),
    Question(
      id: 5,
      text: "Kỳ vọng thu nhập của bạn trong 2 năm đầu là?",
      options: [
        Option(
          value: "A",
          label: "Ưu tiên học hỏi và kinh nghiệm hơn là thu nhập",
        ),
        Option(value: "B", label: "Thu nhập ở mức trung bình thị trường là đủ"),
        Option(value: "C", label: "Cần thu nhập ổn định từ tháng đầu tiên"),
        Option(value: "D", label: "Mức thu nhập cao là điều kiện tiên quyết"),
      ],
    ),
    Question(
      id: 6,
      text: "Bạn tự đánh giá kỹ năng giao tiếp và thuyết trình của mình?",
      options: [
        Option(
          value: "A",
          label: "Rất tốt — thuyết trình và giao tiếp là thế mạnh",
        ),
        Option(value: "B", label: "Khá tốt — có thể làm tốt khi chuẩn bị kỹ"),
        Option(value: "C", label: "Trung bình — đang cải thiện dần"),
        Option(value: "D", label: "Cần phát triển nhiều hơn"),
      ],
    ),
    Question(
      id: 7,
      text: "Bạn có mạng lưới kết nối trong ngành này không?",
      options: [
        Option(value: "A", label: "Có — quen biết nhiều người trong ngành"),
        Option(
          value: "B",
          label: "Một chút — có vài người quen làm trong ngành",
        ),
        Option(value: "C", label: "Ít — mới bắt đầu xây dựng network"),
        Option(value: "D", label: "Chưa có — hoàn toàn chưa có kết nối"),
      ],
    ),
    Question(
      id: 8,
      text:
          "Cơ hội phát triển và thăng tiến trong ngành $careerName có hấp dẫn bạn không?",
      options: [
        Option(
          value: "A",
          label: "Rất hấp dẫn — đây là một trong lý do tôi chọn ngành này",
        ),
        Option(value: "B", label: "Khá hấp dẫn — có nhiều cơ hội tốt"),
        Option(value: "C", label: "Bình thường — quan trọng hơn là ổn định"),
        Option(value: "D", label: "Chưa rõ — cần tìm hiểu thêm"),
      ],
    ),
    Question(
      id: 9,
      text: "Khả năng chịu áp lực và deadline gấp của bạn?",
      options: [
        Option(
          value: "A",
          label: "Rất tốt — tôi làm việc hiệu quả nhất dưới áp lực",
        ),
        Option(
          value: "B",
          label: "Tốt — có thể chịu được áp lực ở mức độ vừa phải",
        ),
        Option(value: "C", label: "Trung bình — cần cân bằng áp lực hợp lý"),
        Option(
          value: "D",
          label: "Yếu — áp lực cao ảnh hưởng nhiều đến hiệu quả",
        ),
      ],
    ),
    Question(
      id: 10,
      text: "Bạn sẵn sàng làm thêm giờ hoặc linh hoạt thời gian khi cần không?",
      options: [
        Option(
          value: "A",
          label: "Hoàn toàn sẵn sàng — công việc là ưu tiên hàng đầu",
        ),
        Option(value: "B", label: "Được, trong những giai đoạn quan trọng"),
        Option(value: "C", label: "Chấp nhận nhưng không muốn thường xuyên"),
        Option(
          value: "D",
          label: "Cần cân bằng rõ ràng giữa công việc và cuộc sống",
        ),
      ],
    ),
    Question(
      id: 11,
      text:
          "Bạn có sẵn sàng lấy thêm bằng cấp hoặc chứng chỉ chuyên môn không?",
      options: [
        Option(
          value: "A",
          label: "Rất sẵn sàng — coi đây là khoản đầu tư giá trị",
        ),
        Option(value: "B", label: "Được nếu thực sự cần thiết cho công việc"),
        Option(value: "C", label: "Cân nhắc tùy theo chi phí và thời gian"),
        Option(value: "D", label: "Ưu tiên kinh nghiệm thực tế hơn bằng cấp"),
      ],
    ),
    Question(
      id: 12,
      text: "Bạn có thể làm việc hiệu quả trong môi trường đa văn hóa không?",
      options: [
        Option(
          value: "A",
          label: "Rất tốt — thích làm việc với người từ nhiều nền văn hóa",
        ),
        Option(value: "B", label: "Được — có thể thích nghi tốt"),
        Option(value: "C", label: "Cần thời gian — đang cải thiện kỹ năng này"),
        Option(value: "D", label: "Thích môi trường thuần Việt hơn"),
      ],
    ),
    Question(
      id: 13,
      text: "Bạn tự đánh giá bản thân phù hợp với ngành $careerName ở mức nào?",
      options: [
        Option(
          value: "A",
          label: "Rất phù hợp — cảm giác đây là đam mê thực sự",
        ),
        Option(
          value: "B",
          label: "Khá phù hợp — nhiều điểm trùng với sở thích",
        ),
        Option(value: "C", label: "Tương đối — cần khám phá thêm"),
        Option(value: "D", label: "Chưa chắc — vẫn đang tìm hiểu bản thân"),
      ],
    ),
    Question(
      id: 14,
      text:
          "Xu hướng phát triển của ngành $careerName trong 10 năm tới có làm bạn hứng thú không?",
      options: [
        Option(
          value: "A",
          label: "Rất hứng thú — đây là ngành có tương lai rõ ràng",
        ),
        Option(value: "B", label: "Hứng thú — có nhiều tiềm năng phát triển"),
        Option(
          value: "C",
          label: "Bình thường — quan trọng là phù hợp với mình",
        ),
        Option(value: "D", label: "Chưa rõ — cần nghiên cứu thêm về xu hướng"),
      ],
    ),
    Question(
      id: 15,
      text:
          "Bạn có thể hình dung rõ bản thân trong vai trò $careerName 5 năm tới không?",
      options: [
        Option(
          value: "A",
          label: "Rất rõ — tôi đã có vision cụ thể cho hành trình này",
        ),
        Option(value: "B", label: "Khá rõ — có hướng đi nhưng cần điều chỉnh"),
        Option(value: "C", label: "Mờ — mường tượng được nhưng chưa chắc chắn"),
        Option(value: "D", label: "Chưa rõ — vẫn đang khám phá các lựa chọn"),
      ],
    ),
  ];
}

// ── UI Component ─────────────────────────────────────────────────────────────
class AssessmentScreen extends StatefulWidget {
  final AssessmentType type;
  final String career;
  final ValueChanged<Map<int, String>> onComplete;
  final VoidCallback onBack;

  const AssessmentScreen({
    super.key,
    required this.type,
    this.career = "",
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _current = 0;
  final Map<int, String> _answers = {};
  late List<Question> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.type == AssessmentType.personality
        ? personalityQuestions
        : getCareerQuestions(widget.career);
  }

  void _handleNext() {
    final currentQuestion = _questions[_current];
    if (!_answers.containsKey(currentQuestion.id)) return;

    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
      });
    } else {
      widget.onComplete(_answers);
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
    final total = _questions.length;
    final progress = (_current + 1) / total;
    final q = _questions[_current];
    final selected = _answers[q.id];

    final title = widget.type == AssessmentType.personality
        ? "Bài test tính cách"
        : "Đánh giá: ${widget.career}";

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
                                title,
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
