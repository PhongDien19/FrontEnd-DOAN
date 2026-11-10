import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get userId => _currentUser?['id']?.toString();
  String get fullName => _userProfile?['fullName'] ?? '';
  String get targetJob => _userProfile?['targetJob'] ?? '';
  String get educationLevel => _userProfile?['educationLevel'] ?? '';
  String get hobby => _userProfile?['hobby'] ?? '';

  AuthProvider() {
    tryAutoLogin();
  }

  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userData')) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userData =
          jsonDecode(prefs.getString('userData')!) as Map<String, dynamic>;
      _currentUser = userData['user'];
      _userProfile = userData['profile'];
      _isAuthenticated = true;

      ApiService.currentUserId = userId;

      if (userId != null) {
        await refreshProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (userId == null) return;
    final res = await ApiService.getProfile(userId!);
    if (res['success'] == true && res['profile'] != null) {
      _userProfile = res['profile'];
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.login(email, password);

      if (res['success'] == true) {
        _currentUser = res['user'];
        _userProfile = res['profile'];
        _isAuthenticated = true;
        ApiService.currentUserId = userId;

        await _saveToPrefs();
      }

      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message':
            'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.register(email, password, fullName);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e, st) {
      debugPrint('Register error: $e\n$st');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message':
            'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.',
      };
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _userProfile = null;
    _isAuthenticated = false;
    ApiService.currentUserId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');

    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String educationLevel,
    required String hobby,
    int? age,
    String? location,
  }) async {
    if (userId == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    _isLoading = true;
    notifyListeners();

    final updateData = {
      'fullName': fullName,
      'educationLevel': educationLevel,
      'hobby': hobby,
      'age': age,
      'location': location,
    };

    final res = await ApiService.updateProfile(userId!, updateData);
    if (res['success'] == true) {
      if (_userProfile == null) {
        _userProfile = updateData;
      } else {
        _userProfile!['fullName'] = fullName;
        _userProfile!['educationLevel'] = educationLevel;
        _userProfile!['hobby'] = hobby;
        if (age != null) _userProfile!['age'] = age;
        if (location != null) _userProfile!['location'] = location;
      }
      await _saveToPrefs();
    }

    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode({
      'user': _currentUser,
      'profile': _userProfile,
    });
    await prefs.setString('userData', userData);
  }
}
