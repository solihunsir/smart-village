// lib/models/comment.dart

import 'post.dart';

/// Model untuk merepresentasikan gambar yang dilampirkan pada Komentar.
class CommentImageModel {
  final int id;
  final String imageUrl;
  final int order;

  CommentImageModel({
    required this.id,
    required this.imageUrl,
    required this.order,
  });

  factory CommentImageModel.fromJson(Map<String, dynamic> json) {
    return CommentImageModel(
      id: json['id'] as int? ?? 0, // Tambahkan null check
      imageUrl: json['image_url'] as String? ?? '',
      order: json['order'] as int? ?? 0, // Tambahkan null check
    );
  }
}

class Comment {
  final int id;
  final String commentText;
  final User user;
  final String createdAt;
  final List<CommentImageModel> images;
  // 🛠️ PERBAIKAN: Tambahkan field Like
  final int likesCount;
  final bool hasLiked;

  Comment({
    required this.id,
    required this.commentText,
    required this.user,
    required this.createdAt,
    required this.images,
    required this.likesCount, // Tambahkan
    required this.hasLiked, // Tambahkan
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map<String, dynamic> ? json['user'] : null;

    final List<CommentImageModel> parsedImages =
        (json['images'] as List?)
            ?.map((i) => CommentImageModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return Comment(
      id: json['id'] as int? ?? 0, // Tambahkan null check
      commentText: json['comment_text'] as String? ?? '',
      user: userData != null
          ? User.fromJson(userData)
          : User(id: json['user_id'] ?? 0, name: 'Tidak diketahui'),
      createdAt: json['created_at'] as String? ?? '',
      images: parsedImages,
      // 🛠️ PERBAIKAN: Ambil data Like dari JSON (asumsi fieldnya ada di response API)
      likesCount: json['likes_count'] as int? ?? 0,
      hasLiked: json['has_liked'] as bool? ?? false,
    );
  }

  // 🛠️ PERBAIKAN: Tambahkan copyWith untuk Optimistic Update
  Comment copyWith({int? likesCount, bool? hasLiked}) {
    return Comment(
      id: id,
      commentText: commentText,
      user: user,
      createdAt: createdAt,
      images: images,
      likesCount: likesCount ?? this.likesCount,
      hasLiked: hasLiked ?? this.hasLiked,
    );
  }
}
