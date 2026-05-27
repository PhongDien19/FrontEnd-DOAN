import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui'; // Dùng cho ImageFilter nếu cần làm mờ sâu
import 'models.dart';

// ── UI Component ─────────────────────────────────────────────────────────────
class AuthGateScreen extends StatefulWidget {
  final ValueChanged<AuthUser> onLogin;
  final VoidCallback onBack;

  const AuthGateScreen({
    super.key,
    required this.onLogin,
    required this.onBack,
  });

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _isLoginTab = true;
  bool _showPw = false;

  // Controllers cho Login
  final _loginEmailCtrl = TextEditingController();
  final _loginPwCtrl = TextEditingController();
  String _loginError = "";

  // Controllers cho Register
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPwCtrl = TextEditingController();
  final _regPw2Ctrl = TextEditingController();
  String _regError = "";

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPwCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPwCtrl.dispose();
    _regPw2Ctrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _loginEmailCtrl.text.trim();
    final pw = _loginPwCtrl.text;

    if (email.isEmpty || pw.isEmpty) {
      setState(() => _loginError = "Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (!email.contains("@")) {
      setState(() => _loginError = "Email không hợp lệ");
      return;
    }

    setState(() => _loginError = "");
    // Tạo tên giả lập từ email giống logic React
    String rawName = email.split("@")[0].replaceAll(RegExp(r'[._]'), ' ');
    String name = rawName.isNotEmpty
        ? rawName[0].toUpperCase() + rawName.substring(1)
        : "User";

    widget.onLogin(AuthUser(name: name, email: email));
  }

  void _handleRegister() {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pw = _regPwCtrl.text;
    final pw2 = _regPw2Ctrl.text;

    if (name.isEmpty || email.isEmpty || pw.isEmpty || pw2.isEmpty) {
      setState(() => _regError = "Vui lòng điền đầy đủ thông tin");
      return;
    }
    if (!email.contains("@")) {
      setState(() => _regError = "Email không hợp lệ");
      return;
    }
    if (pw.length < 6) {
      setState(() => _regError = "Mật khẩu cần ít nhất 6 ký tự");
      return;
    }
    if (pw != pw2) {
      setState(() => _regError = "Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() => _regError = "");
    widget.onLogin(AuthUser(name: name, email: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient nền tối
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF111827), // gray-900
              Color(0xFF1F2937), // gray-800
              Color(0xFF111827), // gray-900
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative Glow Elements ──
            Positioned(
              top: 80,
              left: 80,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: 80,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber[600]!.withValues(alpha: 0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // ── Main Content ──
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(LucideIcons.arrowLeft, size: 16),
                          label: const Text("Quay lại"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[400],
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
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: "Career "),
                              TextSpan(
                                text: "Pathway",
                                style: TextStyle(color: Colors.amber[400]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Container
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 448,
                          ), // max-w-md
                          child: Column(
                            children: [
                              // Announcement
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.amber[500]!.withValues(
                                    alpha: 0.2,
                                  ),
                                  border: Border.all(
                                    color: Colors.amber[500]!.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 14,
                                      color: Colors.amber[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Bài đánh giá đã hoàn thành!",
                                      style: TextStyle(
                                        color: Colors.amber[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                "Đăng nhập để xem kết quả",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Serif',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Kết quả phân tích chi tiết của bạn đang chờ. Đăng nhập hoặc tạo tài khoản để xem ngay.",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Auth Card
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Tabs
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTabButton(
                                            "Đăng nhập",
                                            true,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildTabButton(
                                            "Tạo tài khoản",
                                            false,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Forms
                                    Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: _isLoginTab
                                          ? _buildLoginForm()
                                          : _buildRegisterForm(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Thông tin của bạn được bảo mật tuyệt đối theo PDPA",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  // ── Sub-Widgets & Helpers ──

  Widget _buildTabButton(String title, bool isLoginAction) {
    final isActive = _isLoginTab == isLoginAction;
    return InkWell(
      onTap: () {
        setState(() {
          _isLoginTab = isLoginAction;
          _loginError = "";
          _regError = "";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.amber[50] : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.amber[500]! : Colors.grey[200]!,
              width: isActive ? 2 : 1,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.amber[700] : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: "Email",
          controller: _loginEmailCtrl,
          icon: LucideIcons.mail,
          hint: "yourname@email.com",
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Mật khẩu",
          controller: _loginPwCtrl,
          icon: LucideIcons.lock,
          hint: "••••••••",
          isPassword: true,
          onSubmitted: (_) => _handleLogin(),
        ),
        if (_loginError.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildErrorText(_loginError),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[500],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Đăng nhập & xem kết quả",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[200])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "hoặc",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[200])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.g_mobiledata,
                  color: Colors.blue,
                  size: 24,
                ), // Tạm dùng icon mặc định thay cho SVG
                label: const Text(
                  "Google",
                  style: TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.facebook, color: Colors.blue, size: 20),
                label: const Text(
                  "Facebook",
                  style: TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: "Họ và tên",
          controller: _regNameCtrl,
          icon: LucideIcons.user,
          hint: "Nguyễn Văn An",
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Email",
          controller: _regEmailCtrl,
          icon: LucideIcons.mail,
          hint: "yourname@email.com",
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Mật khẩu",
          controller: _regPwCtrl,
          icon: LucideIcons.lock,
          hint: "Tối thiểu 6 ký tự",
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: "Xác nhận mật khẩu",
          controller: _regPw2Ctrl,
          icon: LucideIcons.lock,
          hint: "Nhập lại mật khẩu",
          isPassword: true,
          onSubmitted: (_) => _handleRegister(),
        ),
        if (_regError.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildErrorText(_regError),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[500],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Tạo tài khoản & xem kết quả",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            children: [
              const TextSpan(text: "Bằng cách đăng ký, bạn đồng ý với\n"),
              TextSpan(
                text: "Điều khoản sử dụng",
                style: TextStyle(
                  color: Colors.amber[600],
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: " và "),
              TextSpan(
                text: "Chính sách bảo mật",
                style: TextStyle(
                  color: Colors.amber[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && !_showPw,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _showPw ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _showPw = !_showPw),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildErrorText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
