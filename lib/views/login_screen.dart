import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import '../viewmodels/login_viewmodels.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await vm.submitForm(
      authProvider,
      _emailController.text.trim(),
      _passwordController.text,
      _fullNameController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Thao tác thành công!'),
          backgroundColor: const Color(0xFF00F5A0),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!vm.isLoginMode) {
        vm.toggleMode();
        _passwordController.clear();
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đã có lỗi xảy ra!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F13),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 24),
                  vertical: Responsive.s(context, 16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.s(context, 16)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF6C63FF,
                          ).withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          size: Responsive.s(context, 48),
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 16)),
                      Text(
                        'Hướng Nghiệp AI',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 26),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 8)),
                      Text(
                        vm.isLoginMode
                            ? 'Đăng nhập để khám phá lộ trình phát triển bản thân'
                            : 'Đăng ký tài khoản mới để bắt đầu ngay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.font(context, 13),
                          color: const Color(0xFF888B9B),
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 32)),
                      Container(
                        padding: EdgeInsets.all(Responsive.s(context, 24)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191922),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                vm.isLoginMode ? 'Đăng Nhập' : 'Tạo Tài Khoản',
                                style: TextStyle(
                                  fontSize: Responsive.font(context, 18),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: Responsive.s(context, 20)),
                              if (!vm.isLoginMode) ...[
                                TextFormField(
                                  controller: _fullNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Họ và tên',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF888B9B),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF6C63FF),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0F0F13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6C63FF),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (!vm.isLoginMode &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: Responsive.s(context, 16)),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF888B9B),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF6C63FF),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F0F13),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF6C63FF),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: Responsive.s(context, 16)),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: vm.obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF888B9B),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF6C63FF),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      vm.obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF888B9B),
                                    ),
                                    onPressed: () =>
                                        vm.togglePasswordVisibility(),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F0F13),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF6C63FF),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (value.length < 6) {
                                    return 'Mật khẩu tối thiểu 6 ký tự';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: Responsive.s(context, 24)),
                              SizedBox(
                                height: Responsive.s(context, 48),
                                child: ElevatedButton(
                                  onPressed: vm.isLoading
                                      ? null
                                      : () => _submit(vm),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: vm.isLoading
                                      ? SizedBox(
                                          width: Responsive.s(context, 22),
                                          height: Responsive.s(context, 22),
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                        )
                                      : Text(
                                          vm.isLoginMode
                                              ? 'ĐĂNG NHẬP'
                                              : 'ĐĂNG KÝ TÀI KHOẢN',
                                          style: TextStyle(
                                            fontSize: Responsive.font(
                                              context,
                                              14,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vm.isLoginMode
                                ? 'Chưa có tài khoản? '
                                : 'Đã có tài khoản? ',
                            style: TextStyle(
                              fontSize: Responsive.font(context, 13),
                              color: const Color(0xFF888B9B),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _formKey.currentState?.reset();
                              vm.toggleMode();
                            },
                            child: Text(
                              vm.isLoginMode ? 'Đăng ký ngay' : 'Đăng nhập',
                              style: TextStyle(
                                fontSize: Responsive.font(context, 13),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6C63FF),
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
          ),
        );
      },
    );
  }
}
