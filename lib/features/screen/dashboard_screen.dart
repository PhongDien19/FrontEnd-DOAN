import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models.dart';

// ==========================================
// 1. LANDING PAGE SCREEN (ĐẦY ĐỦ CTA & FOOTER Ở CUỐI)
// ==========================================
class CareerPathwayLandingPage extends StatelessWidget {
  final VoidCallback onStartAssessment;
  final VoidCallback onLearnProcess;

  const CareerPathwayLandingPage({
    super.key,
    required this.onStartAssessment,
    required this.onLearnProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "CP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
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
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.menu, color: Color(0xFF333333)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.globe,
                            size: 14,
                            color: Colors.amber[800],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Hệ thống AI Chuyên gia",
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          height: 1.25,
                        ),
                        children: [
                          TextSpan(text: "Tư Vấn Hướng\nNghiệp "),
                          TextSpan(
                            text: "Khoa Học",
                            style: TextStyle(color: Color(0xFFFF9800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Đánh giá tương thích nghề nghiệp dựa trên AI và dữ liệu khoa học. Loại bỏ hoàn toàn việc chọn ngành theo cảm tính.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCheckFeature(
                      "Đánh giá đa chiều với RIASEC, Big Five & SCCT",
                    ),
                    const SizedBox(height: 12),
                    _buildCheckFeature(
                      "Khảo sát động 15 câu hỏi tình huống thực tế",
                    ),
                    const SizedBox(height: 12),
                    _buildCheckFeature("Lộ trình phát triển kỹ năng chi tiết"),
                    const SizedBox(height: 28),

                    _buildPrimaryBtn(
                      "Bắt đầu đánh giá miễn phí",
                      onStartAssessment,
                    ),
                    const SizedBox(height: 12),
                    _buildSecondaryBtn(
                      "Tìm hiểu quy trình",
                      onLearnProcess,
                      LucideIcons.compass,
                    ),
                    const SizedBox(height: 32),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=600&auto=format&fit=crop',
                        fit: BoxFit.cover,
                        height: 220,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildCounterCard("15", "Câu hỏi"),
                        const SizedBox(width: 8),
                        _buildCounterCard("3", "Mô hình khoa học"),
                        const SizedBox(width: 8),
                        _buildCounterCard("98%", "Độ chính xác"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSecondaryBtn(
                      "Tính năng nổi bật",
                      () {},
                      LucideIcons.sparkles,
                    ),
                    const SizedBox(height: 36),

                    const Text(
                      "Hệ Thống Đánh Giá Thông Minh",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kết hợp giữa AI và khoa học tâm lý nghề nghiệp để mang đến kết quả chính xác nhất.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureDetailCard(
                      LucideIcons.target,
                      "Chế độ Targeted",
                      "Đã có ngành mục tiêu? Hệ thống AI sẽ kiểm tra mức độ phù hợp và kỹ năng cần có.",
                    ),
                    _buildFeatureDetailCard(
                      LucideIcons.compass,
                      "Chế độ Discovery",
                      "Chưa biết chọn gì? Khảo sát toàn diện để gợi ý các ngành phù hợp nhất với tính cách.",
                    ),
                    _buildFeatureDetailCard(
                      LucideIcons.barChart2,
                      "Phân tích đa chiều",
                      "Đánh giá chi tiết qua 3 khía cạnh cốt lõi: Sở thích, Hành vi và Năng lực.",
                    ),
                    _buildFeatureDetailCard(
                      LucideIcons.messageSquare,
                      "Chatbot AI tư vấn",
                      "Giải đáp thắc mắc chuyên sâu về lộ trình nghề nghiệp sau khi có kết quả.",
                    ),
                    const SizedBox(height: 36),

                    const Text(
                      "3 Mô Hình Đánh Giá Khoa Học",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModelProgressCard(
                      "50%",
                      "Interest Fit",
                      "Đánh giá sở thích đam mê theo mô hình RIASEC (Holland).",
                    ),
                    const SizedBox(height: 12),
                    _buildModelProgressCard(
                      "30%",
                      "Behavioral Fit",
                      "Phân tích hành vi & phẩm chất qua Big Five Personality.",
                    ),
                    const SizedBox(height: 12),
                    _buildModelProgressCard(
                      "20%",
                      "Efficacy Fit",
                      "Đánh giá tự tin về năng lực thực hiện theo SCCT.",
                    ),
                    const SizedBox(height: 36),

                    const Text(
                      "Cách Thức Hoạt Động",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Từ khảo sát đến lộ trình hành động chi tiết.",
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    _buildStepRow(
                      "1",
                      "Bắt đầu khảo sát",
                      "Chọn chế độ Targeted hoặc Discovery thích hợp và làm bài test.",
                    ),
                    _buildStepRow(
                      "2",
                      "AI phân tích dữ liệu",
                      "Hệ thống tính toán điểm tương thích đa chiều dựa trên mô hình khoa học.",
                    ),
                    _buildStepRow(
                      "3",
                      "Đăng nhập nhận kết quả",
                      "Nhận bảng phân tích trực quan cùng các gợi ý ngành nghề.",
                    ),
                    _buildStepRow(
                      "4",
                      "Nhận lộ trình & Đồng hành",
                      "Theo dõi lộ trình phát triển kỹ năng và trò chuyện cùng Chatbot AI.",
                    ),
                    const SizedBox(height: 36),

                    // PHẦN NHẬN XÉT (Giữ nguyên vẹn theo image_1e51c2.png)
                    const Text(
                      "Người Dùng Nói Gì Về Chúng Tôi",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildReviewCard(
                      "Nguyễn Minh Châu",
                      "Học sinh lớp 12",
                      "Hệ thống phân tích rất chi tiết. Mình thích nhất phần biểu đồ RIASEC và lộ trình phát triển kỹ năng.",
                      5.0,
                    ),
                    const SizedBox(height: 12),
                    _buildReviewCard(
                      "Phạm Tuấn Anh",
                      "Sinh viên năm 2",
                      "Bài test giúp mình định vị lại bản thân, các câu hỏi tình huống cực kỳ thực tế và bổ ích.",
                      4.8,
                    ),
                    const SizedBox(height: 36),

                    // ── PHẦN CTA CHUẨN THEO ẢNH image_1e595c.png ──
                    _buildAdvancedCtaSection(),
                    const SizedBox(height: 24),

                    // ── PHẦN FOOTER CHUẨN THEO ẢNH image_1e591e.png & image_1e567b.png ──
                    _buildFooterSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // KHU VỰC THIẾT KẾ CTA KHÁM PHÁ SỰ NGHIỆP
  Widget _buildAdvancedCtaSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF161D2F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2214),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF664614), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, color: Color(0xFFFF9800), size: 14),
                SizedBox(width: 6),
                Text(
                  "Miễn phí hoàn toàn",
                  style: TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Khám Phá Con Đường\nSự Nghiệp Của Bạn",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Bắt đầu đánh giá ngay bây giờ để nhận kết quả chi tiết trong vài phút.",
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildCtaFeatureItem(
            LucideIcons.zap,
            const Color(0xFF2C2214),
            const Color(0xFFFF9800),
            "15 câu hỏi tình huống thực tế, AI tạo động",
          ),
          const SizedBox(height: 14),
          _buildCtaFeatureItem(
            LucideIcons.shield,
            const Color(0xFF232D42),
            const Color(0xFF9CA3AF),
            "Đăng nhập chỉ khi muốn xem kết quả chi tiết",
          ),
          const SizedBox(height: 14),
          _buildCtaFeatureItem(
            LucideIcons.arrowRight,
            const Color(0xFF2C2214),
            const Color(0xFFFF9800),
            "Nhận 3 tokens tư vấn AI miễn phí",
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onStartAssessment,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bắt đầu đánh giá miễn phí",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Icon(LucideIcons.arrowRight, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white24, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "Tìm hiểu thêm",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaFeatureItem(
    IconData icon,
    Color bgBox,
    Color iconColor,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgBox,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // KHU VỰC THIẾT KẾ FOOTER
  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.brain, color: Color(0xFFFF9800), size: 26),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
          const SizedBox(height: 16),
          const Text(
            "Hệ thống AI chuyên gia giúp bạn định hướng nghề nghiệp khoa học, loại bỏ việc chọn ngành theo cảm tính.",
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFooterSocialIcon(LucideIcons.facebook),
              const SizedBox(width: 12),
              _buildFooterSocialIcon(LucideIcons.instagram),
              const SizedBox(width: 12),
              _buildFooterSocialIcon(LucideIcons.linkedin),
            ],
          ),
          const SizedBox(height: 32),
          _buildFooterHeading("Liên kết nhanh"),
          const SizedBox(height: 12),
          _buildFooterLinkText("Trang chủ"),
          _buildFooterLinkText("Tính năng"),
          _buildFooterLinkText("Quy trình"),
          _buildFooterLinkText("Đánh giá"),
          const SizedBox(height: 24),
          _buildFooterHeading("Hệ thống đánh giá"),
          const SizedBox(height: 12),
          _buildFooterLinkText("Chế độ Targeted"),
          _buildFooterLinkText("Chế độ Discovery"),
          _buildFooterLinkText("Mô hình RIASEC"),
          _buildFooterLinkText("Chatbox AI"),
          const SizedBox(height: 24),
          _buildFooterHeading("Liên hệ"),
          const SizedBox(height: 16),
          _buildFooterContactRow(
            LucideIcons.mapPin,
            "Trường Cao đẳng Kỹ thuật Cao Thắng\nTP. Hồ Chí Minh",
          ),
          const SizedBox(height: 14),
          _buildFooterContactRow(LucideIcons.phone, "0123 456 789"),
          const SizedBox(height: 14),
          _buildFooterContactRow(LucideIcons.mail, "contact@careerpathway.vn"),
          const SizedBox(height: 28),
          Divider(color: Colors.grey[800], thickness: 0.8),
          const SizedBox(height: 20),
          const Text(
            "© 2026 Career Pathway. Powered by Gemini AI & O*NET Database.",
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildFooterBottomSmallLink("Chính sách bảo mật"),
              ),
              Expanded(
                child: _buildFooterBottomSmallLink("Điều khoản sử dụng"),
              ),
              Expanded(child: _buildFooterBottomSmallLink("Tài liệu API")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
    );
  }

  Widget _buildFooterHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFooterLinkText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
      ),
    );
  }

  Widget _buildFooterContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF9800), size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBottomSmallLink(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
    );
  }

  // CÁC HÀM TRỢ GIÚP KHÁC CỦA LANDING PAGE
  Widget _buildCheckFeature(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFFFF9800),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, color: Colors.white, size: 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryBtn(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.arrowRight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryBtn(
    String text,
    VoidCallback onPressed,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF374151),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4B5563)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDetailCard(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelProgressCard(String percentage, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: double.parse(percentage.replaceAll('%', '')) / 100,
              backgroundColor: Colors.grey[100],
              color: const Color(0xFFFF9800),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFFF9800),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String name,
    String role,
    String content,
    double rating,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating.floor() ? LucideIcons.star : LucideIcons.star,
                size: 14,
                color: Colors.amber[600],
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '"$content"',
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.amber[100],
                child: Text(name[0]),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. DASHBOARD SCREEN (KHÔNG ĐỔI)
// ==========================================
final List<String> dimensions = [
  "Tư duy phân tích",
  "Sáng tạo",
  "Giao tiếp",
  "Tổ chức",
  "Kỹ thuật",
  "Lãnh đạo",
];

final List<TestEntry> testHistory = [
  TestEntry(
    id: 1,
    date: "Tháng 3/2024",
    career: "Kỹ sư phần mềm",
    match: 68,
    type: "Targeted",
    scores: {
      "Tư duy phân tích": 65,
      "Sáng tạo": 55,
      "Giao tiếp": 52,
      "Tổ chức": 68,
      "Kỹ thuật": 62,
      "Lãnh đạo": 50,
    },
  ),
  TestEntry(
    id: 2,
    date: "Tháng 7/2024",
    career: "Thiết kế UX/UI",
    match: 72,
    type: "Discovery",
    scores: {
      "Tư duy phân tích": 60,
      "Sáng tạo": 78,
      "Giao tiếp": 65,
      "Tổ chức": 70,
      "Kỹ thuật": 65,
      "Lãnh đạo": 58,
    },
  ),
  TestEntry(
    id: 3,
    date: "Tháng 11/2024",
    career: "Quản lý dự án",
    match: 65,
    type: "Targeted",
    scores: {
      "Tư duy phân tích": 68,
      "Sáng tạo": 52,
      "Giao tiếp": 72,
      "Tổ chức": 82,
      "Kỹ thuật": 55,
      "Lãnh đạo": 75,
    },
  ),
  TestEntry(
    id: 4,
    date: "Tháng 1/2025",
    career: "Kỹ sư phần mềm",
    match: 84,
    type: "Discovery",
    scores: {
      "Tư duy phân tích": 84,
      "Sáng tạo": 72,
      "Giao tiếp": 68,
      "Tổ chức": 80,
      "Kỹ thuật": 82,
      "Lãnh đạo": 74,
    },
  ),
];

class DashboardScreen extends StatefulWidget {
  final AuthUser authUser;
  final String career;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const DashboardScreen({
    super.key,
    required this.authUser,
    required this.career,
    required this.onLogout,
    required this.onHome,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTab = "profile";
  bool _editMode = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _phoneController = TextEditingController(text: "0901 234 567");
  final _locationController = TextEditingController(text: "TP. Hồ Chí Minh");
  late TextEditingController _bioController;

  final List<int> _selectedIds = [];
  bool _showComparison = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.authUser.name);
    _emailController = TextEditingController(text: widget.authUser.email);
    _bioController = TextEditingController(
      text: "Đang xây dựng lộ trình trở thành ${widget.career}.",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleSelectHistory(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 2) _selectedIds.removeAt(0);
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber[500],
                      borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(width: 8),
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildMobileTabBar(),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_activeTab) {
      case "profile":
        return _buildProfileTab();
      case "history":
        return _buildHistoryTab();
      case "roadmap":
        return const Center(
          child: Text("Giao diện Lộ trình (Đang phát triển)"),
        );
      case "market":
        return const Center(
          child: Text("Giao diện Thị trường (Đang phát triển)"),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hồ sơ cá nhân",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                  ),
                ),
                Text(
                  "Thông tin và thành tích của bạn",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _editMode ? Colors.green[600] : Colors.white,
                foregroundColor: _editMode ? Colors.white : Colors.black87,
                side: BorderSide(color: Colors.grey[300]!),
                elevation: 0,
              ),
              onPressed: () => setState(() => _editMode = !_editMode),
              icon: Icon(
                _editMode ? LucideIcons.save : LucideIcons.pencil,
                size: 16,
              ),
              label: Text(_editMode ? "Lưu" : "Chỉnh sửa"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[400]!, Colors.amber[600]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _editMode
                              ? TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                )
                              : Text(
                                  _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          _editMode
                              ? TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                )
                              : Text(
                                  _emailController.text,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.career,
                                  style: TextStyle(
                                    color: Colors.amber[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "✓ Đã xác minh",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _editMode
                    ? TextField(
                        controller: _bioController,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      )
                    : Text(
                        _bioController.text,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildStatCard(
                      "Bài test đã làm",
                      "4",
                      LucideIcons.barChart2,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Điểm match hiện tại",
                      "84%",
                      LucideIcons.trendingUp,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Tuần học liên tiếp",
                      "8",
                      LucideIcons.clock,
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildProfileFields(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color[600], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFields() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      children: [
        _buildInfoField("Số điện thoại", _phoneController.text),
        _buildInfoField("Khu vực sinh sống", _locationController.text),
        _buildInfoField("Trình độ học văn", "Đại học"),
        _buildInfoField("Tình trạng", "Đi làm"),
        _buildInfoField("Ngành định hướng", widget.career),
        _buildInfoField("Lần đánh giá gần nhất", "Tháng 1/2025"),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lịch sử test",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        Text(
          "So sánh kết quả và đối chiếu ngành nghề",
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ...testHistory.map((item) {
                  final isSelected = _selectedIds.contains(item.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => _toggleSelectHistory(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber[50]!.withValues(alpha: 0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber[500]!
                                : Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.circle,
                              color: isSelected
                                  ? Colors.amber[600]
                                  : Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: item.match >= 80
                                    ? Colors.green[50]
                                    : Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${item.match}%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.match >= 80
                                      ? Colors.green[700]
                                      : Colors.amber[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.career,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${item.date} · Chế độ ${item.type}",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_selectedIds.length == 2) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _showComparison = true),
                      icon: const Icon(LucideIcons.gitCompare, size: 16),
                      label: const Text("So sánh 2 kết quả đã chọn"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_showComparison && _selectedIds.length == 2) ...[
          const SizedBox(height: 20),
          _buildComparisonPanel(),
        ],
      ],
    );
  }

  Widget _buildComparisonPanel() {
    final entry1 = testHistory.firstWhere((t) => t.id == _selectedIds[0]);
    final entry2 = testHistory.firstWhere((t) => t.id == _selectedIds[1]);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.amber[400]!, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.gitCompare, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      "So sánh nghề nghiệp",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => setState(() => _showComparison = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 300,
                height: 220,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor: Colors.amber.withValues(alpha: 0.25),
                        borderColor: Colors.amber,
                        entryRadius: 2,
                        dataEntries: dimensions
                            .map(
                              (d) => RadarEntry(
                                value: entry1.scores[d]!.toDouble(),
                              ),
                            )
                            .toList(),
                      ),
                      RadarDataSet(
                        fillColor: Colors.grey.withValues(alpha: 0.2),
                        borderColor: Colors.grey,
                        entryRadius: 2,
                        dataEntries: dimensions
                            .map(
                              (d) => RadarEntry(
                                value: entry2.scores[d]!.toDouble(),
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
                    getTitle: (index, angle) =>
                        RadarChartTitle(text: dimensions[index], angle: angle),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[500],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "CP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Career Pathway",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarNavButton(
                  "profile",
                  "Hồ sơ cá nhân",
                  LucideIcons.user,
                ),
                _buildSidebarNavButton(
                  "history",
                  "Lịch sử test",
                  LucideIcons.history,
                ),
                _buildSidebarNavButton("roadmap", "Lộ trình", LucideIcons.map),
                _buildSidebarNavButton(
                  "market",
                  "Thị trường",
                  LucideIcons.trendingUp,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.home, size: 18),
            title: const Text("Trang chủ", style: TextStyle(fontSize: 14)),
            onTap: widget.onHome,
          ),
          ListTile(
            leading: const Icon(
              LucideIcons.logOut,
              color: Colors.red,
              size: 18,
            ),
            title: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarNavButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.amber[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icon,
          color: isSelected ? Colors.amber[700] : Colors.grey[600],
          size: 18,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.amber[700] : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Colors.amber,
              )
            : null,
        onTap: () => setState(() => _activeTab = key),
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMobileTabIconButton("profile", LucideIcons.user),
        _buildMobileTabIconButton("history", LucideIcons.history),
        _buildMobileTabIconButton("roadmap", LucideIcons.map),
        _buildMobileTabIconButton("market", LucideIcons.trendingUp),
      ],
    );
  }

  Widget _buildMobileTabIconButton(String key, IconData icon) {
    final isSelected = _activeTab == key;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.amber[700] : Colors.grey[500],
      ),
      onPressed: () => setState(() => _activeTab = key),
    );
  }
}
