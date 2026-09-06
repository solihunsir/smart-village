// lib/models/notification.dart

import 'post.dart';
import 'user.dart' as model;

enum NotificationType { like, comment, commentReply }

class Notification {
  final String id;
  final NotificationType type;
  final Post? post;
  // KOREKSI UTAMA: Mengubah sender menjadi nullable
  final model.User? sender;
  final String content;
  final DateTime createdAt;

  final List<model.User>? likers;
  final int? totalLikes;

  final model.User? replyToUser;
  final List<model.User>? mentionedUsers;

  Notification({
    required this.id,
    required this.type,
    this.post,
    // KOREKSI: Properti sender tidak lagi required
    this.sender,
    required this.content,
    required this.createdAt,
    this.likers,
    this.totalLikes,
    this.replyToUser,
    this.mentionedUsers,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    final typeString = json['type'].toString().toLowerCase();

    if (typeString.contains('like')) {
      type = NotificationType.like;
    } else if (typeString.contains('comment_reply')) {
      type = NotificationType.commentReply;
    } else if (typeString.contains('comment')) {
      type = NotificationType.comment;
    } else {
      type = NotificationType.comment;
    }

    final postJson = json['post'];
    final senderJson = json['notifier'] ?? json['sender'];

    return Notification(
      id: json['id']?.toString() ?? '',
      type: type,
      post: postJson != null ? Post.fromJson(postJson) : null,

      // KOREKSI: Hanya parse User jika data pengirim TIDAK null
      sender: senderJson != null && senderJson is Map<String, dynamic>
          ? model.User.fromJson(senderJson)
          : null,

      content:
          json['message'] as String? ??
          json['content'] as String? ??
          'Konten tidak tersedia.',
      createdAt: DateTime.parse(json['created_at']),

      likers: (json['likers'] as List<dynamic>?)
          ?.map((userJson) => model.User.fromJson(userJson))
          .toList(),
      totalLikes: json['total_likes'] as int?,

      replyToUser:
          json['reply_to_user'] != null &&
              json['reply_to_user'] is Map<String, dynamic>
          ? model.User.fromJson(json['reply_to_user'])
          : null,
      mentionedUsers: (json['mentioned_users'] as List<dynamic>?)
          ?.map((userJson) => model.User.fromJson(userJson))
          .toList(),
    );
  }
}
