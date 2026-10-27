import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoginMode = true;
  bool get isLoginMode => _isLoginMode;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void toggleMode() {
    _isLoginMode = !_isLoginMode;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitForm(
    AuthProvider authProvider,
    String email,
    String password,
    String fullName,
  ) async {
    _isLoading = true;
    notifyListeners();

    Map<String, dynamic> result;
    if (_isLoginMode) {
      result = await authProvider.login(email, password);
    } else {
      result = await authProvider.register(email, password, fullName);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
