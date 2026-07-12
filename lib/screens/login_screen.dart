import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final size = MediaQuery.of(context).size;
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
                      style: GoogleFonts.outfit(
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
                      style: GoogleFonts.inter(
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
                                            style: GoogleFonts.outfit(
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
                                            style: GoogleFonts.outfit(
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
                                  style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1F2937),
                                  fontSize: Responsive.font(context, 14),
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                inputFormatters: [
                                  TelexTextInputFormatter(),
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
                                          style: GoogleFonts.outfit(
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

class TelexTextInputFormatter extends TextInputFormatter {
  static const Map<String, List<String>> _vietnameseMap = {
    // Lowercase d
    'đ': ['dd', ''],

    // Lowercase a
    'á': ['a', 's'], 'à': ['a', 'f'], 'ả': ['a', 'r'], 'ã': ['a', 'x'], 'ạ': ['a', 'j'],
    'â': ['aa', ''], 'ấ': ['aa', 's'], 'ầ': ['aa', 'f'], 'ẩ': ['aa', 'r'], 'ẫ': ['aa', 'x'], 'ậ': ['aa', 'j'],
    'ă': ['aw', ''], 'ắ': ['aw', 's'], 'ằ': ['aw', 'f'], 'ẳ': ['aw', 'r'], 'ẵ': ['aw', 'x'], 'ặ': ['aw', 'j'],

    // Lowercase e
    'é': ['e', 's'], 'è': ['e', 'f'], 'ẻ': ['e', 'r'], 'ẽ': ['e', 'x'], 'ẹ': ['e', 'j'],
    'ê': ['ee', ''], 'ế': ['ee', 's'], 'ề': ['ee', 'f'], 'ể': ['ee', 'r'], 'ễ': ['ee', 'x'], 'ệ': ['ee', 'j'],

    // Lowercase i
    'í': ['i', 's'], 'ì': ['i', 'f'], 'ỉ': ['i', 'r'], 'ĩ': ['i', 'x'], 'ị': ['i', 'j'],

    // Lowercase o
    'ó': ['o', 's'], 'ò': ['o', 'f'], 'ỏ': ['o', 'r'], 'õ': ['o', 'x'], 'ọ': ['o', 'j'],
    'ô': ['oo', ''], 'ố': ['oo', 's'], 'ồ': ['oo', 'f'], 'ổ': ['oo', 'r'], 'ỗ': ['oo', 'x'], 'ộ': ['oo', 'j'],
    'ơ': ['ow', ''], 'ớ': ['ow', 's'], 'ờ': ['ow', 'f'], 'ở': ['ow', 'r'], 'ỡ': ['ow', 'x'], 'ợ': ['ow', 'j'],

    // Lowercase u
    'ú': ['u', 's'], 'ù': ['u', 'f'], 'ủ': ['u', 'r'], 'ũ': ['u', 'x'], 'ụ': ['u', 'j'],
    'ư': ['uw', ''], 'ứ': ['uw', 's'], 'ừ': ['uw', 'f'], 'ử': ['uw', 'r'], 'ữ': ['uw', 'x'], 'ự': ['uw', 'j'],

    // Lowercase y
    'ý': ['y', 's'], 'ỳ': ['y', 'f'], 'ỷ': ['y', 'r'], 'ỹ': ['y', 'x'], 'ỵ': ['y', 'j'],

    // Uppercase D
    'Đ': ['DD', ''],

    // Uppercase A
    'Á': ['A', 'S'], 'À': ['A', 'F'], 'Ả': ['A', 'R'], 'Ã': ['A', 'X'], 'Ạ': ['A', 'J'],
    'Â': ['AA', ''], 'Ấ': ['AA', 'S'], 'Ầ': ['AA', 'F'], 'Ẩ': ['AA', 'R'], 'Ẫ': ['AA', 'X'], 'Ậ': ['AA', 'J'],
    'Ă': ['AW', ''], 'Ắ': ['AW', 'S'], 'Ằ': ['AW', 'F'], 'Ẳ': ['AW', 'R'], 'Ẵ': ['AW', 'X'], 'Ặ': ['AW', 'J'],

    // Uppercase E
    'É': ['E', 'S'], 'È': ['E', 'F'], 'Ẻ': ['E', 'R'], 'Ẽ': ['E', 'X'], 'Ẹ': ['E', 'J'],
    'Ê': ['EE', ''], 'Ế': ['EE', 'S'], 'Ề': ['EE', 'F'], 'Ể': ['EE', 'R'], 'Ễ': ['EE', 'X'], 'Ệ': ['EE', 'J'],

    // Uppercase I
    'Í': ['I', 'S'], 'Ì': ['I', 'F'], 'Ỉ': ['I', 'R'], 'Ĩ': ['I', 'X'], 'Ị': ['I', 'J'],

    // Uppercase O
    'Ó': ['O', 'S'], 'Ò': ['O', 'F'], 'Ỏ': ['O', 'R'], 'Õ': ['O', 'X'], 'Ọ': ['O', 'J'],
    'Ô': ['OO', ''], 'Ố': ['OO', 'S'], 'Ồ': ['OO', 'F'], 'Ổ': ['OO', 'R'], 'Ỗ': ['OO', 'X'], 'Ộ': ['OO', 'J'],
    'Ơ': ['OW', ''], 'Ớ': ['OW', 'S'], 'Ờ': ['OW', 'F'], 'Ở': ['OW', 'R'], 'Ỡ': ['OW', 'X'], 'Ợ': ['OW', 'J'],

    // Uppercase U
    'Ú': ['U', 'S'], 'Ù': ['U', 'F'], 'Ủ': ['U', 'R'], 'Ũ': ['U', 'X'], 'Ụ': ['U', 'J'],
    'Ư': ['UW', ''], 'Ứ': ['UW', 'S'], 'Ừ': ['UW', 'F'], 'Ử': ['UW', 'R'], 'Ữ': ['UW', 'X'], 'Ự': ['UW', 'J'],

    // Uppercase Y
    'Ý': ['Y', 'S'], 'Ỳ': ['Y', 'F'], 'Ỷ': ['Y', 'R'], 'Ỹ': ['Y', 'X'], 'Ỵ': ['Y', 'J'],
  };

  static String convertVietnameseToTelex(String input) {
    final RegExp wordRegex = RegExp(
      r'([a-zA-ZÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐa-zàáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]+)'
    );

    return input.replaceAllMapped(wordRegex, (match) {
      final word = match.group(0)!;
      String resultWord = '';
      String toneKey = '';

      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        if (_vietnameseMap.containsKey(char)) {
          final mapping = _vietnameseMap[char]!;
          resultWord += mapping[0];
          if (mapping[1].isNotEmpty) {
            toneKey = mapping[1].toLowerCase();
          }
        } else {
          resultWord += char;
        }
      }
      return resultWord + toneKey;
    });
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String newText = newValue.text;
    final String convertedText = convertVietnameseToTelex(newText);

    if (newText == convertedText) {
      return newValue;
    }

    final int selectionIndex = newValue.selection.end + (convertedText.length - newText.length);

    return TextEditingValue(
      text: convertedText,
      selection: TextSelection.collapsed(
        offset: selectionIndex.clamp(0, convertedText.length),
      ),
    );
  }
}
