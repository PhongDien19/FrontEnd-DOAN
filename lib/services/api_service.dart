import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Android emulator maps 10.0.2.2 to the development host's localhost.
  static const String baseUrl =
      'http://localhost:5000/api';

  // Lưu trữ userId của người dùng hiện tại để tự động đính kèm vào header
  static String? currentUserId;

  // Helper để sinh sessionId ngẫu nhiên cho các bài test
  static String generateSessionId(String prefix) {
    final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${prefix}_$rand';
  }

  static const Duration _defaultTimeout = Duration(seconds: 35);
  static const Duration _aiTimeout = Duration(seconds: 120);

  // Header cơ bản có kèm userId nếu đã đăng nhập
  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (currentUserId != null) {
      headers['x-user-id'] = currentUserId!;
    }
    return headers;
  }

  // Parse JSON an toàn
  static Map<String, dynamic> _safeParseResponse(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        if (parsed['success'] == false && response.statusCode >= 400) {
          return {
            ...parsed,
            'statusCode': response.statusCode,
            'errorMessage':
                parsed['errorMessage'] ??
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
        'errorMessage':
            'Phản hồi từ máy chủ không hợp lệ (HTTP ${response.statusCode})',
        'raw': response.body,
        'statusCode': response.statusCode,
      };
    }
  }

  // --- 1. AUTHENTICATION ---

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_defaultTimeout);

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

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'fullName': fullName,
            }),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối tới máy chủ: $e'};
    }
  }

  // --- 2. USER PROFILE & HISTORY ---

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/profile/$userId'), headers: _headers)
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy thông tin cá nhân: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/profile/$userId'),
            headers: _headers,
            body: jsonEncode(profileData),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi cập nhật thông tin cá nhân: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getHistory(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/assessment/history/$userId'),
            headers: _headers,
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy lịch sử: $e'};
    }
  }

  static Future<Map<String, dynamic>> startAssessment({
    required String flow,
    required String audience,
    String? userId,
    String? targetMajorId,
    int? certaintyLevel,
    String? targetReason,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/assessment/start'),
            headers: _headers,
            body: jsonEncode({
              'flow': flow,
              'audience': audience,
              'userId': ?userId,
              'targetMajorId': ?targetMajorId,
              'certaintyLevel': ?certaintyLevel,
              if (targetReason != null && targetReason.isNotEmpty)
                'targetReason': targetReason,
            }),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể tạo phiên đánh giá: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAssessmentQuestions(
    String assessmentId,
    String section,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/assessment/$assessmentId/section/$section'),
            headers: _headers,
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể tải câu hỏi: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitAssessmentSection({
    required String assessmentId,
    required String sectionType,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/assessment/$assessmentId/submit-section'),
            headers: _headers,
            body: jsonEncode({'sectionType': sectionType, 'answers': answers}),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể gửi câu trả lời: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAssessmentResult(
    String assessmentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/assessment/$assessmentId/result'),
            headers: _headers,
          )
          .timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể tải kết quả: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitAssessmentTrustCheck({
    required String assessmentId,
    required int trustScore,
    required String feedbackText,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/assessment/$assessmentId/trust-check'),
            headers: _headers,
            body: jsonEncode({
              'trustScore': trustScore,
              'isTrusted': trustScore >= 3,
              'section': 'overall',
              'disagreeReasons': <String>[],
              'feedbackText': feedbackText,
            }),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể gửi phản hồi: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMajors() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/majors'), headers: _headers)
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Không thể tải danh sách ngành: $e'};
    }
  }

  // --- 3. AI CHAT & CONSULT ---

  static Future<Map<String, dynamic>> askChatbot(String question) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/ask'),
            headers: _headers,
            body: jsonEncode({'question': question}),
          )
          .timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối chat: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    return askChatbot(message);
  }

  static Future<Map<String, dynamic>> searchCareer(
    Map<String, dynamic> info,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/search/career'),
            headers: _headers,
            body: jsonEncode(info),
          )
          .timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tìm kiếm: $e'};
    }
  }

  // --- 6. COMPREHENSIVE ASSESSMENT ---

  static Future<Map<String, dynamic>> getComprehensiveAssessment(
    String userId,
    Map<String, dynamic> context,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/assessment/comprehensive/$userId'),
            headers: _headers,
            body: jsonEncode(context),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi lấy báo cáo tổng hợp: $e'};
    }
  }

  // --- 7. DYNAMIC SURVEY ---

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
      final response = await http
          .post(
            Uri.parse('$baseUrl/survey/init'),
            headers: _headers,
            body: jsonEncode({
              'mode': mode,
              if (targetCareer != null && targetCareer.isNotEmpty)
                'target_career': targetCareer,
              'age': age,
              if (education != null && education.isNotEmpty)
                'education': education,
              if (location != null && location.isNotEmpty) 'location': location,
              if (hobby != null && hobby.isNotEmpty) 'hobby': hobby,
              'academicData': academicData,
            }),
          )
          .timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi khởi tạo khảo sát động: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitSurvey(
    String sessionId,
    List<int> answers,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/survey/submit'),
            headers: _headers,
            body: jsonEncode({'sessionId': sessionId, 'answers': answers}),
          )
          .timeout(_aiTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi nộp kết quả khảo sát: $e'};
    }
  }

  static Future<Map<String, dynamic>> feedbackSurvey(
    String surveyId,
    int ratingScore,
    String comment,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/survey/feedback'),
            headers: _headers,
            body: jsonEncode({
              'survey_id': surveyId,
              'rating_score': ratingScore,
              'comment': comment,
            }),
          )
          .timeout(_defaultTimeout);
      return _safeParseResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi gửi phản hồi: $e'};
    }
  }
}
