import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestedQuestions = [
    'Làm sao biết mình hợp ngành nào?',
    'Cần chuẩn bị gì để thi vào ngành IT?',
    'Tư vấn lộ trình học Marketing?',
    'Sự khác nhau giữa Business Analyst và Developer?'
  ];

  @override
  void initState() {
    super.initState();
    // Gửi tin chào mừng đầu tiên từ AI
    _messages.add(
      ChatMessage(
        text: 'Xin chào! Tôi là Trợ Lý Hướng Nghiệp AI. Bạn đang muốn tìm hiểu về công việc, ngành học hay lộ trình phát triển nào? Hãy chia sẻ với tôi nhé!',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          time: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();
    _textController.clear();

    final result = await ApiService.askChatbot(text);

    setState(() {
      _isLoading = false;
      if (result['success'] == true && result['reply'] != null) {
        _messages.add(
          ChatMessage(
            text: result['reply'],
            isUser: false,
            time: DateTime.now(),
          ),
        );
      } else {
        String errMsg = result['message'] ?? 'Rất tiếc, hệ thống đang gặp lỗi kết nối. Vui lòng thử lại sau.';
        if (result['success'] == false && result['tokenLimit'] == true) {
          errMsg = 'Bạn đã dùng hết lượt hỏi miễn phí hôm nay. Hãy quay lại vào ngày mai!';
        }
        _messages.add(
          ChatMessage(
            text: errMsg,
            isUser: false,
            time: DateTime.now(),
          ),
        );
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922).withValues(alpha: 0.8),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cố Vấn Hướng Nghiệp AI',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Hỗ trợ 24/7',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF00F5A0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            top: 40,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            children: [
              // Message List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg);
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF191922),
                          border: Border.all(color: const Color(0xFF2C2C3E)),
                        ),
                        child: const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI đang phân tích câu hỏi...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF888B9B),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    ],
                  ),
                ),

              // Suggestions Bar
              if (_messages.length <= 2 && !_isLoading)
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _suggestedQuestions.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _sendMessage(_suggestedQuestions[index]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191922),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2C2C3E)),
                          ),
                          child: Text(
                            _suggestedQuestions[index],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFC3C5E0),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Input Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191922),
                    border: Border.all(color: const Color(0xFF2C2C3E).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F13),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF2C2C3E)),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Nhập câu hỏi của bạn...',
                              hintStyle: TextStyle(color: Color(0xFF5E6072)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _sendMessage(_textController.text),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00F2FE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3F37C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : const Color(0xFF191922),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFF2C2C3E).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
