import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AssessmentModeScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSelectTargeted;
  final VoidCallback onSelectDiscovery;

  const AssessmentModeScreen({
    super.key,
    required this.onBack,
    required this.onSelectTargeted,
    required this.onSelectDiscovery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF7), // Màu nền đồng bộ video
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(
            LucideIcons.chevronLeft,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          label: const Text(
            "Quay lại",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "CP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                children: [
                  TextSpan(text: "Career "),
                  TextSpan(
                    text: "Pathway",
                    style: TextStyle(color: Color(0xFFFF9800)),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiến trình Bước 1/4
                  const Text(
                    "BƯỚC 1/4",
                    style: TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Chọn chế độ đánh giá",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Hãy cho chúng tôi biết bạn đang ở đâu trong hành trình nghề nghiệp",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CARD 1: TARGETED (HƯỚNG ĐÍCH)
                  _buildModeCard(
                    isHighlighted: true,
                    badgeText: "HƯỚNG ĐÍCH",
                    title: "Targeted",
                    description:
                        "Dành cho bạn đã có ngành nghề cụ thể muốn hướng tới. Hệ thống sẽ đánh giá mức độ phù hợp và các kỹ năng bạn cần bổ sung đối ứng với yêu cầu ngành đó.",
                    icon: LucideIcons.target,
                    iconBgColor: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFF9800),
                    features: [
                      "Nhập ngành nghề bạn muốn theo",
                      "Làm bài đánh giá tình huống thực tế",
                      "Nhận điểm match + lộ trình phát triển kỹ năng",
                    ],
                    buttonText: "Chọn Targeted",
                    onPressed: onSelectTargeted,
                  ),

                  const SizedBox(height: 20),

                  // CARD 2: DISCOVERY (KHÁM PHÁ)
                  _buildModeCard(
                    isHighlighted: false,
                    badgeText: "KHÁM PHÁ",
                    title: "Discovery",
                    description:
                        "Dành cho bạn chưa xác định được hướng đi cụ thể. Hệ thống AI sẽ phân tích tính cách toàn diện và đề xuất danh sách ngành nghề phù hợp nhất với bạn.",
                    icon: LucideIcons.compass,
                    iconBgColor: const Color(0xFFF3F4F6),
                    iconColor: const Color(0xFF4B5563),
                    features: [
                      "Test tính cách (15 câu tình huống động)",
                      "Đánh giá năng lực dựa trên 3 mô hình khoa học",
                      "Nhận danh sách ngành nghề tương thích nhất",
                    ],
                    buttonText: "Chọn Discovery",
                    onPressed: onSelectDiscovery,
                  ),

                  const SizedBox(height: 24),

                  // Lưu ý ở cuối màn hình giống video
                  const Center(
                    child: Text(
                      "Bạn có thể thay đổi lựa chọn bất cứ lúc nào trong quá trình làm bài.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm build Card lựa chọn chế độ mẫu chuẩn
  Widget _buildModeCard({
    required bool isHighlighted,
    required String badgeText,
    required String title,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required List<String> features,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFF9800)
              : const Color(0xFFE5E7EB),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badgeText,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isHighlighted)
                const Icon(
                  LucideIcons.checkCircle2,
                  color: Color(0xFFFF9800),
                  size: 22,
                )
              else
                const Icon(
                  LucideIcons.circle,
                  color: Color(0xFFD1D5DB),
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[100], thickness: 1),
          const SizedBox(height: 12),

          // Danh sách tính năng đi kèm dấu check vuông giống video
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      LucideIcons.check,
                      size: 12,
                      color: isHighlighted
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nút bấm hành động của Card
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted
                    ? const Color(0xFFFF9800)
                    : Colors.white,
                foregroundColor: isHighlighted
                    ? Colors.white
                    : const Color(0xFF374151),
                elevation: 0,
                side: isHighlighted
                    ? null
                    : const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
