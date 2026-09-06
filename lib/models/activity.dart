// lib/models/activity.dart

import 'package:intl/intl.dart';

enum ActivityType { like, comment }

class ActivityItem {
  final ActivityType type;
  final int userId;
  final String userName;
  final String? userPhoto;
  final String? commentText; // Hanya ada jika type == comment
  final DateTime createdAt;

  ActivityItem({
    required this.type,
    required this.userId,
    required this.userName,
    this.userPhoto,
    this.commentText,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    ActivityType type;
    if (json['type'] == 'like') {
      type = ActivityType.like;
    } else {
      type = ActivityType.comment;
    }

    return ActivityItem(
      type: type,
      userId: json['user_id'] as int? ?? 0,
      userName: json['user_name'] as String? ?? 'Pengguna Anonim',
      userPhoto: json['user_photo'] as String?,
      commentText: json['comment_text'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get timeAgo {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inHours < 24) {
      final hours = duration.inHours;
      if (hours > 0) return '$hours Jam yang lalu';
      final minutes = duration.inMinutes;
      if (minutes > 0) return '$minutes Menit yang lalu';
      return 'Baru saja';
    }
    return DateFormat('d MMM y').format(createdAt);
  }
}
