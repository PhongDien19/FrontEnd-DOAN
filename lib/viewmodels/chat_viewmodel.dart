import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? options;

  ChatMessage({required this.text, required this.isUser, this.options});
}

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void initializeChat(Map<String, dynamic>? initialContext) {
    if (_messages.isNotEmpty) return;

    String welcomeMsg =
        'Xin chào! Tôi là Cố Vấn Hướng Nghiệp AI. Tôi có thể giúp gì cho bạn hôm nay?';
    List<String> suggestions = [
      'Gợi ý lộ trình phát triển kỹ năng',
      'Phân tích chi tiết báo cáo của tôi',
      'Các ngành nghề phổ biến hiện nay',
    ];

    if (initialContext != null) {
      final careers = initialContext['recommendedCareers'] as List<String>?;
      if (careers != null && careers.isNotEmpty) {
        welcomeMsg =
            'Dựa trên báo cáo hướng nghiệp của bạn, tôi thấy bạn rất phù hợp với các ngành: ${careers.join(", ")}. Bạn muốn tìm hiểu sâu hơn về ngành nào?';
        suggestions = careers.map((c) => 'Tìm hiểu thêm về $c').toList();
      }
    }

    _messages.add(
      ChatMessage(text: welcomeMsg, isUser: false, options: suggestions),
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    _messages.add(ChatMessage(text: trimmedText, isUser: true));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.sendChatMessage(trimmedText);

      final replyText =
          response['message'] ??
          response['reply'] ??
          'Rất tiếc, AI chưa thể phản hồi lúc này. Bạn vui lòng thử lại nhé!';
      final rawOptions = response['options'] as List?;
      final List<String>? options = rawOptions
          ?.map((e) => e.toString())
          .toList();

      _messages.add(
        ChatMessage(text: replyText, isUser: false, options: options),
      );
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Đã có lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền!',
          isUser: false,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
