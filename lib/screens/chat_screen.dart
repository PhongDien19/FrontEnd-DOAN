import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<String>? options;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.options,
  });
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? initialContext;

  const ChatScreen({super.key, this.initialContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _defaultSuggestedQuestions = [
    'Làm sao biết mình hợp ngành nào?',
    'Cần chuẩn bị gì để thi vào ngành IT?',
    'Tư vấn lộ trình học Marketing?',
    'Sự khác nhau giữa Business Analyst và Developer?',
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    final careerContext = widget.initialContext;

    // Construct the initialization prompt
    String initPrompt = 'Chào bạn! Tôi muốn bắt đầu cuộc trò chuyện tư vấn hướng nghiệp. ';
    if (careerContext != null && careerContext.isNotEmpty) {
      if (careerContext.containsKey('targetCareer') && careerContext['targetCareer'] != null && careerContext['targetCareer'].toString().isNotEmpty) {
        initPrompt += 'Tôi vừa xem kết quả khảo sát ngành mục tiêu là: ${careerContext['targetCareer']}. ';
      } else if (careerContext.containsKey('recommendedCareers') && careerContext['recommendedCareers'] is List) {
        final List careers = careerContext['recommendedCareers'];
        if (careers.isNotEmpty) {
          initPrompt += 'Tôi vừa hoàn thành khảo sát và phù hợp với các ngành: ${careers.join(", ")}. ';
        }
      }
    }
    initPrompt += 'Hãy đưa ra lời chào đón cá nhân hóa ngắn gọn dựa trên thông tin này và gợi ý 3-4 câu hỏi tiếp theo để tôi nhấp chọn.';

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.askChatbot(initPrompt);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true && result['reply'] != null) {
            final List<String> options = (result['options'] != null && result['options'] is List)
                ? List<String>.from(result['options'])
                : [];
            _messages.add(
              ChatMessage(
                text: result['reply'],
                isUser: false,
                time: DateTime.now(),
                options: options,
              ),
            );
          } else {
            _useFallbackGreeting();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _useFallbackGreeting();
        });
      }
    }
  }

  void _useFallbackGreeting() {
    final careerContext = widget.initialContext;
    String introText =
        'Xin chào! Tôi là Trợ Lý Hướng Nghiệp AI. Dựa trên kết quả khảo sát của bạn, tôi có thể tư vấn thêm cho bạn.';

    if (careerContext != null && careerContext.isNotEmpty) {
      final careers = careerContext['recommendedCareers'] as List?;
      final strengths = careerContext['strengths'] as List?;
      final analysis = careerContext['overallAnalysis'] as String?;

      if (careers != null && careers.isNotEmpty) {
        final careerList = careers.take(3).join(', ');
        introText += '\n\nBạn có vẻ phù hợp với các ngành: $careerList.';
      }
      if (strengths != null && strengths.isNotEmpty) {
        final strengthList = strengths.take(3).join(', ');
        introText += '\n\nĐiểm mạnh của bạn: $strengthList.';
      }
      if (analysis != null && analysis.isNotEmpty) {
        introText += '\n\n$analysis';
      }
    } else {
      introText =
          'Xin chào! Tôi là Trợ Lý Hướng Nghiệp AI. Bạn đang muốn tìm hiểu về công việc, ngành học hay lộ trình phát triển nào? Hãy chia sẻ với tôi nhé!';
    }

    _messages.add(
      ChatMessage(
        text: introText,
        isUser: false,
        time: DateTime.now(),
        options: _defaultSuggestedQuestions,
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
    if (text.trim().isEmpty) {
      return;
    }

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
        final List<String> options = (result['options'] != null && result['options'] is List)
            ? List<String>.from(result['options'])
            : [];
        _messages.add(
          ChatMessage(
            text: result['reply'],
            isUser: false,
            time: DateTime.now(),
            options: options,
          ),
        );
      } else {
        String errMsg = result['message'] ??
            'Rất tiếc, hệ thống đang gặp lỗi kết nối. Vui lòng thử lại sau.';
        if (result['success'] == false && result['tokenLimit'] == true) {
          errMsg =
              'Bạn đã dùng hết lượt hỏi miễn phí hôm nay. Hãy quay lại vào ngày mai!';
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
              padding: EdgeInsets.all(Responsive.s(context, 8)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: const Color(0xFF6C63FF),
                size: Responsive.s(context, 20),
              ),
            ),
            SizedBox(width: Responsive.s(context, 12)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cố Vấn Hướng Nghiệp AI',
                  style: GoogleFonts.outfit(
                    fontSize: Responsive.font(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Hỗ trợ 24/7',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.font(context, 11),
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
          Positioned(
            top: Responsive.s(context, 40),
            right: -Responsive.s(context, 100),
            child: Container(
              width: Responsive.s(context, 250),
              height: Responsive.s(context, 250),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(Responsive.s(context, 20)),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg, isLast: index == _messages.length - 1);
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.s(context, 8),
                    horizontal: Responsive.s(context, 20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.s(context, 8)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF191922),
                          border: Border.all(color: const Color(0xFF2C2C3E)),
                        ),
                        child: SizedBox(
                          width: Responsive.s(context, 14),
                          height: Responsive.s(context, 14),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.s(context, 12)),
                      Text(
                        'AI đang phân tích câu hỏi...',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.font(context, 12),
                          color: const Color(0xFF888B9B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),



              SafeArea(
                child: Container(
                  padding: EdgeInsets.all(Responsive.s(context, 16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191922),
                    border: Border.all(
                      color: const Color(0xFF2C2C3E).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.s(context, 16),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F13),
                            borderRadius: BorderRadius.circular(
                              Responsive.s(context, 24),
                            ),
                            border: Border.all(
                              color: const Color(0xFF2C2C3E),
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.font(context, 14),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập câu hỏi của bạn...',
                              hintStyle: TextStyle(
                                color: const Color(0xFF5E6072),
                                fontSize: Responsive.font(context, 14),
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.s(context, 12)),
                      GestureDetector(
                        onTap: () => _sendMessage(_textController.text),
                        child: Container(
                          padding: EdgeInsets.all(Responsive.s(context, 12)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00F2FE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: Responsive.s(context, 20),
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

  Widget _buildChatBubble(ChatMessage msg, {required bool isLast}) {
    final isUser = msg.isUser;
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: Responsive.s(context, 8)),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.s(context, 18),
              vertical: Responsive.s(context, 14),
            ),
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
                topLeft: Radius.circular(Responsive.s(context, 20)),
                topRight: Radius.circular(Responsive.s(context, 20)),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: const Color(0xFF2C2C3E).withValues(alpha: 0.5),
                    ),
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
                fontSize: Responsive.font(context, 14),
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (!isUser && isLast && msg.options != null && msg.options!.isNotEmpty && !_isLoading)
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.s(context, 8),
              top: Responsive.s(context, 4),
              bottom: Responsive.s(context, 12),
            ),
            child: Wrap(
              spacing: Responsive.s(context, 8),
              runSpacing: Responsive.s(context, 8),
              children: msg.options!.map((opt) {
                return GestureDetector(
                  onTap: () => _sendMessage(opt),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.s(context, 16),
                      vertical: Responsive.s(context, 10),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191922),
                      borderRadius: BorderRadius.circular(
                        Responsive.s(context, 20),
                      ),
                      border: Border.all(
                        color: const Color(0xFF2C2C3E),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: Responsive.font(context, 12),
                        color: const Color(0xFFC3C5E0),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
