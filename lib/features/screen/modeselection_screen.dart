import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models.dart'; // Đã import file models dùng chung

class ModeSelectionScreen extends StatelessWidget {
  final ValueChanged<AssessmentMode> onSelect;
  final VoidCallback onBack;

  const ModeSelectionScreen({
    super.key,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: const Text("Quay lại"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[500],
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 28,
                    height: 28,
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
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: "Career "),
                        TextSpan(
                          text: "Pathway",
                          style: TextStyle(color: Colors.amber[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Title Section
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "BƯỚC 1 / 4",
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Text(
                          "Chọn chế độ đánh giá",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Serif',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Hãy cho chúng tôi biết bạn đang ở đâu trong hành trình nghề nghiệp",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Selection Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 600;

                            final cards = [
                              // ── Card 1: Targeted Mode ──
                              Expanded(
                                flex: isDesktop ? 1 : 0,
                                child: _buildTargetedCard(context),
                              ),
                              if (isDesktop)
                                const SizedBox(width: 24)
                              else
                                const SizedBox(height: 24),

                              // ── Card 2: Discovery Mode ──
                              Expanded(
                                flex: isDesktop ? 1 : 0,
                                child: _buildDiscoveryCard(context),
                              ),
                            ];

                            return isDesktop
                                ? IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: cards,
                                    ),
                                  )
                                : Column(children: cards);
                          },
                        ),

                        const SizedBox(height: 32),
                        Text(
                          "Bạn có thể thay đổi lựa chọn bất cứ lúc nào trước khi hoàn thành",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
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

  // ── Targeted Card ──
  Widget _buildTargetedCard(BuildContext context) {
    return _HoverableCard(
      onTap: () => onSelect(AssessmentMode.targeted),
      hoverColor: Colors.amber[400]!,
      iconBgNormal: Colors.amber[100]!,
      iconBgHover: Colors.amber[500]!,
      iconColorNormal: Colors.amber[600]!,
      iconColorHover: Colors.white,
      btnColorNormal: Colors.amber[500]!,
      btnColorHover: Colors.amber[600]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "CÓ ĐỊNH HƯỚNG",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Text(
            "Targeted",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              "Dành cho bạn đã có ngành nghề cụ thể muốn theo đuổi. Hệ thống sẽ đánh giá mức độ phù hợp của bạn với ngành đó.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...[
            "Nhập ngành nghề bạn muốn theo",
            "Làm bài đánh giá phù hợp chuyên biệt",
            "Nhận điểm match + lộ trình phát triển",
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.checkCircle2,
                    size: 16,
                    color: Colors.amber[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chọn Targeted",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Discovery Card ──
  Widget _buildDiscoveryCard(BuildContext context) {
    return _HoverableCard(
      onTap: () => onSelect(AssessmentMode.discovery),
      hoverColor: Colors.grey[500]!,
      iconBgNormal: Colors.grey[100]!,
      iconBgHover: Colors.grey[700]!,
      iconColorNormal: Colors.grey[600]!,
      iconColorHover: Colors.white,
      btnColorNormal: Colors.grey[800]!,
      btnColorHover: Colors.grey[900]!,
      icon: LucideIcons.compass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "KHÁM PHÁ",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Text(
            "Discovery",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Dành cho bạn chưa xác định được hướng đi. AI sẽ phân tích tính cách và đề xuất ngành phù hợp nhất cho bạn.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LUỒNG 2 BƯỚC:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    1,
                    Colors.amber[500]!,
                    "Test tính cách (15 câu)",
                    "AI phân tích và gợi ý nghề phù hợp",
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    2,
                    Colors.grey[500]!,
                    "Đánh giá mức độ phù hợp (15 câu)",
                    "Kiểm tra chi tiết với nghề được đề xuất",
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Chọn Discovery",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step, Color color, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Widget Xử lý Hover Animation cho Card ──
class _HoverableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Color hoverColor;
  final Color iconBgNormal;
  final Color iconBgHover;
  final Color iconColorNormal;
  final Color iconColorHover;
  final Color btnColorNormal;
  final Color btnColorHover;
  final IconData icon;
  final Widget child;

  const _HoverableCard({
    required this.onTap,
    required this.hoverColor,
    required this.iconBgNormal,
    required this.iconBgHover,
    required this.iconColorNormal,
    required this.iconColorHover,
    required this.btnColorNormal,
    required this.btnColorHover,
    this.icon = LucideIcons.target,
    required this.child,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.hoverColor : Colors.grey[200]!,
              width: 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? widget.iconBgHover
                        : widget.iconBgNormal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: _isHovered
                        ? widget.iconColorHover
                        : widget.iconColorNormal,
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(child: widget.child),

                // Button "Chọn..."
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? widget.btnColorHover
                        : widget.btnColorNormal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (widget.child as Column).children.last,
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
