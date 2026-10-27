class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<String>? options;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.time,
    this.options,
  });
}
