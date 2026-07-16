import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Map<String, dynamic> result;

    if (_isLoginMode) {
      result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      result = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
      );
    }

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Thao tác thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!_isLoginMode) {
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
        } else {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Đã xảy ra lỗi, vui lòng thử lại!',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final isWide = Responsive.isWideScreen(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          if (Navigator.canPop(context))
            Positioned(
              top: Responsive.s(context, 16),
              left: Responsive.s(context, 16),
              child: SafeArea(
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: const Color(0xFF1F2937),
                    size: Responsive.s(context, 24),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.2,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 28),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(Responsive.s(context, 20)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF59E0B).withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          size: Responsive.s(context, 48),
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.s(context, 24)),

                    Text(
                      'CAREER PATHWAY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 32),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: Responsive.s(context, 8)),
                    Text(
                      'Hệ Thống Tư Vấn Hướng Nghiệp AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.font(context, 15),
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: Responsive.s(context, 40)),

                    Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 500 : double.infinity,
                        ),
                        padding: EdgeInsets.all(Responsive.s(context, 28)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 24),
                          ),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _isLoginMode = true,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Đăng Nhập',
                                            style: TextStyle(
                                              fontSize: Responsive.font(
                                                context,
                                                18,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              color: _isLoginMode
                                                  ? const Color(0xFF1F2937)
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                          SizedBox(
                                            height: Responsive.s(
                                              context,
                                              8,
                                            ),
                                          ),
                                          Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              color: _isLoginMode
                                                  ? const Color(0xFFF59E0B)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _isLoginMode = false,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Đăng Ký',
                                            style: TextStyle(
                                              fontSize: Responsive.font(
                                                context,
                                                18,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              color: !_isLoginMode
                                                  ? const Color(0xFF1F2937)
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                          SizedBox(
                                            height: Responsive.s(
                                              context,
                                              8,
                                            ),
                                          ),
                                          Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              color: !_isLoginMode
                                                  ? const Color(0xFFF59E0B)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.s(context, 32)),

                              if (!_isLoginMode) ...[
                                TextFormField(
                                  controller: _fullNameController,
                                  style: TextStyle(
                                    color: const Color(0xFF1F2937),
                                    fontSize: Responsive.font(context, 14),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Họ và tên',
                                    labelStyle: TextStyle(
                                      color: const Color(0xFF6B7280),
                                      fontSize: Responsive.font(context, 14),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: const Color(0xFF9CA3AF),
                                      size: Responsive.s(context, 22),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF3F4F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        Responsive.s(context, 16),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        Responsive.s(context, 16),
                                      ),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        Responsive.s(context, 16),
                                      ),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF59E0B),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    if (val.trim().length < 2) {
                                      return 'Tên phải có ít nhất 2 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: Responsive.s(context, 20)),
                              ],

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: const Color(0xFF1F2937),
                                  fontSize: Responsive.font(context, 14),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                    color: const Color(0xFF6B7280),
                                    fontSize: Responsive.font(context, 14),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: const Color(0xFF9CA3AF),
                                    size: Responsive.s(context, 22),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF59E0B),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Vui lòng nhập Email';
                                  }
                                  if (val.contains(' ')) {
                                    return 'Email không được chứa khoảng trắng';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*@[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+$',
                                  ).hasMatch(val.trim())) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: Responsive.s(context, 20)),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  color: const Color(0xFF1F2937),
                                  fontSize: Responsive.font(context, 14),
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  labelStyle: TextStyle(
                                    color: const Color(0xFF6B7280),
                                    fontSize: Responsive.font(context, 14),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outlined,
                                    color: const Color(0xFF9CA3AF),
                                    size: Responsive.s(context, 22),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF9CA3AF),
                                      size: Responsive.s(context, 22),
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF59E0B),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (val.contains(' ')) {
                                    return 'Mật khẩu không được chứa khoảng trắng';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9]+$',
                                  ).hasMatch(val)) {
                                    return 'Mật khẩu chỉ được chứa chữ cái và số';
                                  }
                                  if (val.length < 6) {
                                    return 'Mật khẩu phải dài ít nhất 6 ký tự';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: Responsive.s(context, 32)),

                              ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: Responsive.s(context, 16),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.s(context, 16),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFF59E0B),
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  constraints: const BoxConstraints(
                                    minHeight: 20,
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: Responsive.s(context, 24),
                                          height: Responsive.s(context, 24),
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
                                          _isLoginMode
                                              ? 'Đăng Nhập'
                                              : 'Tạo Tài Khoản',
                                          style: TextStyle(
                                            fontSize: Responsive.font(
                                              context,
                                              16,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
