enum MessageSender { user, ai }

class Message {
  final String content;
  final MessageSender sender;
  final bool isLoading;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.sender,
    this.isLoading = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
