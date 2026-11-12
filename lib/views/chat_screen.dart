import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/chat_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? initialContext;

  const ChatScreen({super.key, this.initialContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().initializeChat(widget.initialContext);
    });
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

  void _onSendMessage(ChatViewModel vm, String text) {
    if (text.trim().isEmpty) return;
    vm.sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.s(context, 8)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: AppColors.primaryDark,
                size: Responsive.s(context, 20),
              ),
            ),
            SizedBox(width: Responsive.s(context, 12)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cố Vấn Hướng Nghiệp AI',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Hỗ trợ 24/7',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 11),
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(Responsive.s(context, 20)),
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final msg = vm.messages[index];
                    final isLast = index == vm.messages.length - 1;
                    return _buildChatBubble(vm, msg, isLast: isLast);
                  },
                ),
              ),
              if (vm.isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.s(context, 8),
                    horizontal: Responsive.s(context, 20),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.s(context, 12)),
                      Text(
                        'AI đang phân tích câu hỏi...',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              SafeArea(
                child: Container(
                  padding: EdgeInsets.all(Responsive.s(context, 16)),
                  decoration: const BoxDecoration(color: AppColors.surface),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Nhập câu hỏi của bạn...',
                            hintStyle: TextStyle(color: AppColors.textHint),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (txt) => _onSendMessage(vm, txt),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () =>
                            _onSendMessage(vm, _textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(
    ChatViewModel vm,
    ChatMessage msg, {
    required bool isLast,
  }) {
    final isUser = msg.isUser;
    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: Responsive.s(context, 6)),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.s(context, 16),
              vertical: Responsive.s(context, 12),
            ),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isUser ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: Responsive.font(context, 13),
                height: 1.4,
              ),
            ),
          ),
        ),
        if (!isUser && isLast && msg.options != null && msg.options!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: Responsive.s(context, 4),
              bottom: Responsive.s(context, 8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.options!.map<Widget>((opt) {
                return ActionChip(
                  label: Text(
                    opt,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 12),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.primary),
                  onPressed: () => _onSendMessage(vm, opt),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
