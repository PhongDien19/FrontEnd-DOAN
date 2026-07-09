import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser; // Chứa id, email, role
  Map<String, dynamic>? _userProfile; // Chứa fullName, targetJob, educationLevel, v.v.
  bool _isLoading = false;

  // Temporary models for storing data before login
  TempProfile? _tempProfile;
  TempScores? _tempScores;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  TempProfile? get tempProfile => _tempProfile;
  TempScores? get tempScores => _tempScores;

  String? get userId => _currentUser?['id']?.toString();
  String get fullName => _userProfile?['fullName'] ?? '';
  String get targetJob => _userProfile?['targetJob'] ?? '';
  String get educationLevel => _userProfile?['educationLevel'] ?? '';
  String get hobby => _userProfile?['hobby'] ?? '';

  // Khởi tạo, tự động kiểm tra đăng nhập cũ
  AuthProvider() {
    tryAutoLogin();
  }

  // Tự động đăng nhập bằng SharedPreferences
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

      final userData = jsonDecode(prefs.getString('userData')!) as Map<String, dynamic>;
      _currentUser = userData['user'];
      _userProfile = userData['profile'];
      _isAuthenticated = true;

      // Cập nhật userId cho ApiService
      ApiService.currentUserId = userId;

      // Đồng bộ profile mới nhất từ server
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

  // Làm mới thông tin Profile từ server
  Future<void> refreshProfile() async {
    if (userId == null) {
      return;
    }
    final res = await ApiService.getProfile(userId!);
    if (res['success'] == true && res['profile'] != null) {
      _userProfile = res['profile'];
      await _saveToPrefs();
      notifyListeners();
    }
  }

  // Đăng nhập
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

        // Auto-sync temp profile and scores if exists
        if (_tempProfile != null || _tempScores != null) {
          await _syncTempDataToServer();
        }
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

  // Đăng ký
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

  // Auto-sync temp data lên server sau khi đăng nhập
  Future<void> _syncTempDataToServer() async {
    if (userId == null) return;

    try {
      // Sync temp profile (chỉ gọi nếu có dữ liệu)
      if (_tempProfile != null) {
        final profileData = _tempProfile!.toJson();
        await updateProfile(
          fullName: profileData['fullName'] ?? '',
          targetJob: profileData['targetJob'] ?? '',
          educationLevel: profileData['educationLevel'] ?? '',
          hobby: profileData['hobby'] ?? '',
          age: profileData['age'],
          location: profileData['location'],
        );
      }

      // Sync temp scores
      if (_tempScores != null) {
        await ApiService.saveScores(userId!, _tempScores!.toJson());
      }

      // Clear temp data after sync
      _tempProfile = null;
      _tempScores = null;
      await _clearTempData();

      // Refresh profile
      await refreshProfile();
    } catch (e) {
      debugPrint('Lỗi sync temp data: $e');
    }
  }

  // Lưu temp data vào SharedPreferences
  Future<void> _saveTempToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_tempProfile != null) {
      await prefs.setString('tempProfile', jsonEncode(_tempProfile!.toJson()));
    }
    if (_tempScores != null) {
      await prefs.setString('tempScores', jsonEncode(_tempScores!.toJson()));
    }
  }

  // Xóa temp data khỏi SharedPreferences
  Future<void> _clearTempData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tempProfile');
    await prefs.remove('tempScores');
  }

  // Lưu temp profile
  void setTempProfile(TempProfile profile) {
    _tempProfile = profile;
    _saveTempToPrefs();
    notifyListeners();
  }

  // Lưu temp scores
  void setTempScores(TempScores scores) {
    _tempScores = scores;
    _saveTempToPrefs();
    notifyListeners();
  }

  // Đăng xuất
  Future<void> logout() async {
    _currentUser = null;
    _userProfile = null;
    _isAuthenticated = false;
    ApiService.currentUserId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    
    notifyListeners();
  }

  // Cập nhật thông tin Profile (Học vấn, công việc mục tiêu, sở thích)
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String targetJob,
    required String educationLevel,
    required String hobby,
    int? age,
    String? location,
    Map<String, dynamic>? studentScores,
    Map<String, dynamic>? workerScores,
  }) async {
    if (userId == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    _isLoading = true;
    notifyListeners();

    final updateData = {
      'fullName': fullName,
      'targetJob': targetJob,
      'educationLevel': educationLevel,
      'hobby': hobby,
      'age': age,
      'location': location,
      'studentScores': studentScores,
      'workerScores': workerScores,
    };

    final res = await ApiService.updateProfile(userId!, updateData);
    if (res['success'] == true) {
      // Cập nhật local state
      if (_userProfile == null) {
        _userProfile = updateData;
      } else {
        _userProfile!['fullName'] = fullName;
        _userProfile!['targetJob'] = targetJob;
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

  // Nhận quyền kết quả bài trắc nghiệm làm trước khi login
  Future<Map<String, dynamic>> claimTestResult(String sessionId) async {
    if (userId == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    final res = await ApiService.claimAssessment(sessionId, userId!);
    if (res['success'] == true) {
      await refreshProfile(); // Tải lại điểm mới vào profile
    }
    return res;
  }

  // Helper lưu dữ liệu phiên vào SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode({
      'user': _currentUser,
      'profile': _userProfile,
    });
    await prefs.setString('userData', userData);
  }
}
