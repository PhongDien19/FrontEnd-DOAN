import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models.dart';

// ── Dữ liệu tĩnh ─────────────────────────────────────────────────────────────
final List<Map<String, String>> educationOptions = [
  {"value": "thpt", "label": "THPT (Lớp 12)"},
  {"value": "trungcap", "label": "Trung cấp / Cao đẳng"},
  {"value": "daihoc", "label": "Đại học"},
  {"value": "thacsi", "label": "Thạc sĩ"},
  {"value": "tiensi", "label": "Tiến sĩ / Sau đại học"},
];

final List<Map<String, String>> statusOptions = [
  {"value": "studying", "label": "Đang học"},
  {"value": "working", "label": "Đi làm"},
  {"value": "switching", "label": "Đang chuyển nghề"},
  {"value": "searching", "label": "Đang tìm việc"},
];

// ── UI Component ─────────────────────────────────────────────────────────────
class PersonalInfoScreen extends StatefulWidget {
  final AssessmentMode mode;
  final ValueChanged<UserData> onSubmit;
  final VoidCallback onBack;

  const PersonalInfoScreen({
    super.key,
    required this.mode,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Controllers & State
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _targetCareerCtrl = TextEditingController();

  double _age = 22.0;
  String? _education;
  String? _currentStatus;

  Map<String, String> _errors = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _skillsCtrl.dispose();
    _targetCareerCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final e = <String, String>{};

    if (_nameCtrl.text.trim().isEmpty) e['name'] = "Vui lòng nhập họ và tên";
    if (_education == null || _education!.isEmpty)
      e['education'] = "Vui lòng chọn trình độ học vấn";
    if (_currentStatus == null || _currentStatus!.isEmpty)
      e['currentStatus'] = "Vui lòng chọn tình trạng hiện tại";
    if (_locationCtrl.text.trim().isEmpty)
      e['location'] = "Vui lòng nhập khu vực sinh sống";
    if (_skillsCtrl.text.trim().isEmpty)
      e['skills'] = "Vui lòng mô tả sở thích và kỹ năng của bạn";

    if (widget.mode == AssessmentMode.targeted &&
        _targetCareerCtrl.text.trim().isEmpty) {
      e['targetCareer'] = "Vui lòng nhập ngành nghề bạn muốn theo";
    }

    setState(() => _errors = e);
    return e.isEmpty;
  }

  void _handleSubmit() {
    if (!_validate()) return;

    widget.onSubmit(
      UserData(
        name: _nameCtrl.text.trim(),
        age: _age.toInt(),
        education: _education!,
        currentStatus: _currentStatus!,
        location: _locationCtrl.text.trim(),
        skills: _skillsCtrl.text.trim(),
        targetCareer: widget.mode == AssessmentMode.targeted
            ? _targetCareerCtrl.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.mode == AssessmentMode.targeted
        ? "BƯỚC 2 / 4"
        : "BƯỚC 2 / 5";

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
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
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
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 672,
                    ), // max-w-2xl
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
                            step,
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Text(
                          "Thông tin cá nhân",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Serif',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Giúp AI hiểu rõ bối cảnh của bạn để đưa ra đánh giá chính xác hơn",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Form Card
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
                              // Name
                              _buildLabel("Họ và tên", isRequired: true),
                              _buildTextField(
                                controller: _nameCtrl,
                                icon: LucideIcons.user,
                                hint: "Nguyễn Văn An",
                                errorText: _errors['name'],
                              ),
                              const SizedBox(height: 24),

                              // Age Slider
                              Row(
                                children: [
                                  const Text(
                                    "Tuổi: ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "${_age.toInt()}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.amber[500],
                                  inactiveTrackColor: Colors.grey[200],
                                  thumbColor: Colors.amber[500],
                                  overlayColor: Colors.amber.withValues(
                                    alpha: 0.2,
                                  ),
                                  trackHeight: 6,
                                ),
                                child: Slider(
                                  min: 15,
                                  max: 60,
                                  value: _age,
                                  onChanged: (v) => setState(() => _age = v),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "15",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  Text(
                                    "60",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Education Dropdown
                              _buildLabel("Trình độ học vấn", isRequired: true),
                              DropdownButtonFormField<String>(
                                value: _education,
                                icon: const Icon(
                                  LucideIcons.chevronDown,
                                  size: 16,
                                ),
                                decoration: _inputDecoration(
                                  errorText: _errors['education'],
                                ),
                                hint: const Text(
                                  "-- Chọn trình độ --",
                                  style: TextStyle(fontSize: 14),
                                ),
                                items: educationOptions
                                    .map(
                                      (o) => DropdownMenuItem(
                                        value: o['value'],
                                        child: Text(
                                          o['label']!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _education = v),
                              ),
                              if (_errors['education'] != null)
                                _buildError(_errors['education']!),
                              const SizedBox(height: 24),

                              // Status Radio Grid
                              _buildLabel(
                                "Tình trạng hiện tại",
                                isRequired: true,
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisExtent:
                                          48, // Chiều cao cố định cho radio button card
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: statusOptions.length,
                                itemBuilder: (context, index) {
                                  final option = statusOptions[index];
                                  final isSelected =
                                      _currentStatus == option['value'];

                                  return InkWell(
                                    onTap: () => setState(
                                      () => _currentStatus = option['value'],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.amber[50]
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.amber[500]!
                                              : Colors.grey[200]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<String>(
                                            value: option['value']!,
                                            groupValue: _currentStatus,
                                            activeColor: Colors.amber[500],
                                            onChanged: (v) => setState(
                                              () => _currentStatus = v,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              option['label']!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (_errors['currentStatus'] != null)
                                _buildError(_errors['currentStatus']!),
                              const SizedBox(height: 24),

                              // Location
                              _buildLabel(
                                "Khu vực sinh sống",
                                isRequired: true,
                              ),
                              _buildTextField(
                                controller: _locationCtrl,
                                hint:
                                    "Ví dụ: Hà Nội, TP. Hồ Chí Minh, Đà Nẵng...",
                                errorText: _errors['location'],
                              ),
                              const SizedBox(height: 24),

                              // Target Career (Chỉ hiện khi Mode là Targeted)
                              if (widget.mode == AssessmentMode.targeted) ...[
                                _buildLabel(
                                  "Ngành nghề muốn theo",
                                  isRequired: true,
                                ),
                                _buildTextField(
                                  controller: _targetCareerCtrl,
                                  hint:
                                      "Ví dụ: Kỹ sư phần mềm, Bác sĩ, Luật sư, Kế toán...",
                                  errorText: _errors['targetCareer'],
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Skills Textarea
                              _buildLabel(
                                "Sở thích & Kỹ năng hiện có",
                                isRequired: true,
                              ),
                              TextField(
                                controller: _skillsCtrl,
                                maxLines: 4,
                                onChanged: (_) =>
                                    setState(() {}), // Để cập nhật đếm số ký tự
                                decoration: _inputDecoration(
                                  hint:
                                      "Mô tả chi tiết về sở thích, kỹ năng, kinh nghiệm và những điều bạn giỏi nhất. Càng chi tiết, kết quả càng chính xác...",
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_skillsCtrl.text.length} ký tự",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              if (_errors['skills'] != null)
                                _buildError(_errors['skills']!),
                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[500],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Tiếp tục",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(LucideIcons.arrowRight, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  // ── Helpers ──

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          children: [
            TextSpan(text: text),
            if (isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
        if (errorText != null) _buildError(errorText),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: Colors.grey[400])
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.amber[400]!, width: 2),
      ),
    );
  }

  Widget _buildError(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
