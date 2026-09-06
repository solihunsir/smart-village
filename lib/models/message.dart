class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> comments;
  final String? attachmentUrl;
  final MessageAttachmentType? attachmentType;
  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.content,
    required this.timestamp,
    this.likes = const [],
    this.comments = const [],
    this.attachmentUrl,
    this.attachmentType,
  });
}

enum MessageAttachmentType { image, document, video, audio }

class MessageComment {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String content;
  final DateTime timestamp;
  MessageComment({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.content,
    required this.timestamp,
  });
}
