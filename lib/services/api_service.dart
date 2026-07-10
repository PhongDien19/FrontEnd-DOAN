import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ========== TEMPORARY MODELS FOR FRONTEND ==========

/// Temporary Profile model - lưu tạm ở Frontend khi chưa đăng nhập
class TempProfile {
  final String? fullName;
  final String? targetJob;
  final String? educationLevel;
  final String? hobby;
  final int? age;
  final String? location;

  TempProfile({
    this.fullName,
    this.targetJob,
    this.educationLevel,
    this.hobby,
    this.age,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'targetJob': targetJob,
        'educationLevel': educationLevel,
        'hobby': hobby,
        'age': age,
        'location': location,
      };

  factory TempProfile.fromJson(Map<String, dynamic> json) => TempProfile(
        fullName: json['fullName'],
        targetJob: json['targetJob'],
        educationLevel: json['educationLevel'],
        hobby: json['hobby'],
        age: json['age'],
        location: json['location'],
      );
}

/// Temporary Scores model - lưu tạm ở Frontend khi chưa đăng nhập
class TempScores {
  final String type; // 'high_school' hoặc 'university_worker'
  final Map<String, dynamic> scores;

  TempScores({
    required this.type,
    required this.scores,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'scores': scores,
      };

  factory TempScores.fromJson(Map<String, dynamic> json) => TempScores(
        type: json['type'] ?? 'high_school',
        scores: json['scores'] ?? {},
      );
}

// ========== API SERVICE ==========

class ApiService {
  // Cấu hình môi trường backend:
  //   useLocal = true        → trỏ về server Node.js đang chạy trên máy dev
  //   useLocal = false       → trỏ về server Production trên Render
  static const bool useLocal = true;

  // Khi useLocal = true trên Android, chọn 1 trong 2 chế độ sau:
  //   useAndroidEmulatorAlias = true  → dùng 10.0.2.2 (chỉ chạy được trên Android Emulator)
  //   useAndroidEmulatorAlias = false → dùng IP LAN của máy dev (chạy được trên thiết bị thật
  //                                     cùng mạng WiFi với máy dev)
  //
  // ⚠️ Khi test trên điện thoại thật: BẬT useAndroidEmulatorAlias = false
  //                                    và đảm bảo IP LAN bên dưới đúng với máy của bạn.
  static const bool useAndroidEmulatorAlias = false;

  /// IP LAN của máy chạy server Node.js (đổi nếu máy dev có IP khác).
  /// Kiểm tra bằng lệnh: `ipconfig` (Windows) hoặc `ifconfig` (macOS/Linux).
  static const String devLanIp = '192.168.137.1';

  /// Xác định base URL tuỳ theo nền tảng đang chạy:
  ///  - Flutter Web (Chrome/Edge/Safari): dùng `http://localhost:5000/api`
  ///  - Android Emulator: dùng `http://10.0.2.2:5000/api` (alias đặc biệt của AVD)
  ///  - Android thiết bị thật: dùng `http://<devLanIp>:5000/api` (cùng WiFi với máy dev)
  ///  - iOS simulator / Windows / macOS / Linux desktop: `http://localhost:5000/api`
  static String get baseUrl {
    if (!useLocal) {
      return 'https://server-ai-doan-1.onrender.com/api';
    }

    // kIsWeb = true khi đang chạy trên trình duyệt (Chrome, Edge, Safari, Firefox...)
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return useAndroidEmulatorAlias
          ? 'http://10.0.2.2:5000/api'
          : 'http://$devLanIp:5000/api';
    }

    // iOS simulator, Windows, macOS, Linux... đều trỏ về localhost
    return 'http://localhost:5000/api';
  }

  // Lưu trữ userId của người dùng hiện tại để tự động đính kèm vào header
  static String? currentUserId;

  // Helper để sinh sessionId ngẫu nhiên cho các bài test
  static String generateSessionId(String prefix) {
    final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${prefix}_$rand';
  }

  /// Timeout mặc định cho các request tới backend.
  /// Tránh trường hợp app bị "treo" vĩnh viễn nếu server không phản hồi
  /// (vd: mất kết nối, sai IP, server chưa bật) — lúc đó loading spinner sẽ
  /// quay vĩnh viễn và nút bấm biến mất.
  static const Duration _defaultTimeout = Duration(seconds: 35);

  /// Timeout dài hơn cho các endpoint AI (consult, chat, generate-test, evaluate).
  /// Gemini thường phản hồi trong 15-25 giây cho prompt dài — nếu dùng
  /// `_defaultTimeout` (8s) sẽ bị TimeoutException dù server vẫn đang xử lý.
  static const Duration _aiTimeout = Duration(seconds: 45);

  // Header cơ bản có kèm userId nếu đã đăng nhập
  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (currentUserId != null) {
      headers['x-user-id'] = currentUserId!;
    }
    return headers;
  }

  // Safe JSON parse: returns a Map when possible, otherwise returns
  // a map with success=false and raw body for diagnostics.
  static Map<String, dynamic> _safeParseResponse(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        // Nếu server trả về lỗi (success=false, HTTP 4xx/5xx),
        // gắn statusCode vào payload để FE có thể hiển thị đúng thông điệp.
        if (parsed['success'] == false && response.statusCode >= 400) {
          return {
            ...parsed,
            'statusCode': response.statusCode,
            // Tạo thông điệp hiển thị: ưu tiên errorMessage, sau đó tới message
            'errorMessage': parsed['errorMessage'] ??
                parsed['message'] ??
                'Máy chủ trả về lỗi (${response.statusCode})',
          };
        }
        return parsed;
      }
      return {'success': true, 'data': parsed};
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid JSON from server',
        'errorMessage': 'Phản hồi từ máy chủ không hợp lệ (HTTP ${response.statusCode})',
        'raw': response.body,
        'statusCode': response.statusCode,
      };
    }
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
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_defaultTimeout);

      final data = _safeParseResponse(response);
      if (response.statusCode == 200 && data['success'] == true) {
        currentUserId = (data['user'] != null
            ? data['user']['id']?.toString()
            : null);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối chat: $e'};
    }
  }

  // Tư vấn nghề nghiệp tổng quát — dùng cho cả tư vấn AI chung lẫn "Học ở đâu?" / "Làm ở đâu?".
  // Server trả về:
  //   - Nếu requestType = 'HOC' / 'LAM' : advice là object JSON { summary, schools[] } hoặc { summary, companies[] }
  //   - Ngược lại                         : advice là chuỗi văn bản tư vấn
  static Future<Map<String, dynamic>> consultCareer(
    Map<String, dynamic> info,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/consult'),
        headers: _headers,
        body: jsonEncode(info),
      ).timeout(_aiTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi tạo bài test: $e'};
    }
  }

  static Future<Map<String, dynamic>> evaluateTest(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/test/evaluate/$sessionId'),
        headers: _headers,
      ).timeout(_aiTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy báo cáo tổng hợp: $e'};
    }
  }

  // --- 7. KHẢO SÁT HƯỚNG NGHIỆP ĐỘNG (DYNAMIC SURVEY) ---

  // Khởi tạo khảo sát động
  static Future<Map<String, dynamic>> initSurvey(
    String mode,
    String? targetCareer, {
    int? age,
    String? education,
    String? location,
    String? hobby,
    Map<String, dynamic>? academicData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/survey/init'),
        headers: _headers,
        body: jsonEncode({
          'mode': mode,
          if (targetCareer != null && targetCareer.isNotEmpty)
            'target_career': targetCareer,
          'age': age,
          if (education != null && education.isNotEmpty) 'education': education,
          if (location != null && location.isNotEmpty) 'location': location,
          if (hobby != null && hobby.isNotEmpty) 'hobby': hobby,
          'academicData': academicData,
        }),
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
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
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi gửi phản hồi: $e'};
    }
  }

  // --- 7.1 SCORES ENDPOINTS ---

  // Lấy điểm số của người dùng
  static Future<Map<String, dynamic>> getScores(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId/scores'),
        headers: _headers,
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy điểm số: $e'};
    }
  }

  // Lưu/cập nhật điểm số
  static Future<Map<String, dynamic>> saveScores(
    String userId,
    Map<String, dynamic> scoreData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/$userId/scores'),
        headers: _headers,
        body: jsonEncode(scoreData),
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lưu điểm số: $e'};
    }
  }

  // Xóa điểm số
  static Future<Map<String, dynamic>> deleteScores(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/$userId/scores'),
        headers: _headers,
      ).timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi xóa điểm số: $e'};
    }
  }
}
