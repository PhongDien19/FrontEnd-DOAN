import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> updateProfile(
    AuthProvider auth, {
    required String fullName,
    required String targetJob,
    required String educationLevel,
    required String hobby,
    int? age,
    String? location,
    Function(String)? onError,
  }) async {
    _isSaving = true;
    notifyListeners();

    final res = await auth.updateProfile(
      fullName: fullName,
      targetJob: targetJob,
      educationLevel: educationLevel,
      hobby: hobby,
      age: age,
      location: location,
    );

    _isSaving = false;
    notifyListeners();

    if (res['success'] == true) {
      return true;
    } else {
      onError?.call(res['message'] ?? 'Cập nhật thất bại.');
      return false;
    }
  }
}
