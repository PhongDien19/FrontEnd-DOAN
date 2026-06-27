import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL cấu hình tự động.
  // Android emulator cần dùng 10.0.2.2 thay vì localhost.
  // Bật/tắt kết nối Local (true) hoặc Production Render (false)
  // static const bool useLocal = true;

  static String get baseUrl {
    // if (!useLocal) {
    return 'https://server-ai-doan-1.onrender.com/api';
    // }
    // return defaultTargetPlatform == TargetPlatform.android
    //     ? 'http://10.0.2.2:5000/api'
    //     : 'http://localhost:5000/api';
  }

  // Lưu trữ userId của người dùng hiện tại để tự động đính kèm vào header
  static String? currentUserId;

  // Helper để sinh sessionId ngẫu nhiên cho các bài test
  static String generateSessionId(String prefix) {
    final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${prefix}_$rand';
  }

  // Header cơ bản có kèm userId nếu đã đăng nhập
  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (currentUserId != null) {
      headers['x-user-id'] = currentUserId!;
    }
    return headers;
  }

  // --- 1. AUTHENTICATION ENDPOINTS ---

  // Đăng nhập thường
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        currentUserId = data['user']['id']?.toString();
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối tới máy chủ: $e'};
    }
  }

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối tới máy chủ: $e'};
    }
  }

  // --- 2. USER PROFILE & HISTORY ---

  // Lấy thông tin Profile
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy thông tin cá nhân: $e'};
    }
  }

  // Cập nhật Profile
  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: _headers,
        body: jsonEncode(profileData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi cập nhật thông tin cá nhân: $e',
      };
    }
  }

  // Lấy lịch sử làm bài test
  static Future<Map<String, dynamic>> getHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/$userId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy lịch sử: $e'};
    }
  }

  // --- 3. AI CHAT & CONSULT ---

  // Hỏi AI Chatbot
  static Future<Map<String, dynamic>> askChatbot(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/ask'),
        headers: _headers,
        body: jsonEncode({'question': question}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối chat: $e'};
    }
  }

  // Tư vấn nghề nghiệp tổng quát
  static Future<Map<String, dynamic>> consultCareer(
    Map<String, dynamic> info,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/consult'),
        headers: _headers,
        body: jsonEncode({'info': info}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tư vấn: $e'};
    }
  }

  // --- 4. TRẮC NGHIỆM CHI TIẾT (4 TRỤ CỘT) ---

  // A. HOLLAND TEST (Sở thích nghề nghiệp)
  static Future<Map<String, dynamic>> generateTest(
    String testType,
    Map<String, dynamic> context,
  ) async {
    try {
      final body = Map<String, dynamic>.from(context);
      body['testType'] = testType;

      final response = await http.post(
        Uri.parse('$baseUrl/test/generate'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi tạo bài test: $e'};
    }
  }

  static Future<Map<String, dynamic>> evaluateTest(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/test/evaluate/$sessionId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đánh giá bài test: $e'};
    }
  }

  // --- 5. TEST DATA MANAGEMENT ---

  // Lưu câu hỏi & câu trả lời (sau khi người dùng làm xong từng câu hoặc chọn xong)
  static Future<Map<String, dynamic>> saveQuestions({
    required String sessionId,
    String? userId,
    required String testName,
    required List<Map<String, dynamic>> questions,
    required Map<String, dynamic> userContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/test/questions'),
        headers: _headers,
        body: jsonEncode({
          'sessionId': sessionId,
          'userId': userId,
          'testName': testName,
          'questions': questions,
          'userContext': userContext,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lưu câu hỏi: $e'};
    }
  }

  // Nhận lại câu hỏi của 1 session
  static Future<Map<String, dynamic>> getQuestions(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test/questions/$sessionId'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi tải danh sách câu hỏi: $e'};
    }
  }

  // Yêu cầu liên kết kết quả bài test (sau khi người dùng đăng nhập)
  static Future<Map<String, dynamic>> claimAssessment(
    String sessionId,
    String userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assessment/claim'),
        headers: _headers,
        body: jsonEncode({'sessionId': sessionId, 'userId': userId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi đồng bộ kết quả test: $e'};
    }
  }

  // --- 6. COMPREHENSIVE ASSESSMENT ---

  // Tổng hợp đánh giá từ 4 trụ cột
  static Future<Map<String, dynamic>> getComprehensiveAssessment(
    String userId,
    Map<String, dynamic> context,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assessment/comprehensive/$userId'),
        headers: _headers,
        body: jsonEncode(context),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy báo cáo tổng hợp: $e'};
    }
  }

  // --- 7. KHẢO SÁT HƯỚNG NGHIỆP ĐỘNG (DYNAMIC SURVEY) ---

  // Khởi tạo khảo sát động
  static Future<Map<String, dynamic>> initSurvey(
    String mode,
    String? targetCareer,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/survey/init'),
        headers: _headers,
        body: jsonEncode({
          'mode': mode,
          if (targetCareer != null && targetCareer.isNotEmpty)
            'target_career': targetCareer,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi khởi tạo khảo sát động: $e'};
    }
  }

  // Nộp bài khảo sát động
  static Future<Map<String, dynamic>> submitSurvey(
    String sessionId,
    List<int> answers,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/survey/submit'),
        headers: _headers,
        body: jsonEncode({'sessionId': sessionId, 'answers': answers}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi nộp kết quả khảo sát: $e'};
    }
  }

  // Gửi feedback đánh giá hài lòng cho khảo sát động
  static Future<Map<String, dynamic>> feedbackSurvey(
    String surveyId,
    int ratingScore,
    String comment,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/survey/feedback'),
        headers: _headers,
        body: jsonEncode({
          'survey_id': surveyId,
          'rating_score': ratingScore,
          'comment': comment,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi gửi phản hồi: $e'};
    }
  }
}
