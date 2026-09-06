// lib/models/post.dart
import 'dart:convert';

// Model User yang Sederhana (sesuai file post.dart Anda)
class User {
  final int id;
  final String name;
  // Field ini tetap, namun inisialisasi dari JSON akan diubah.
  final String? profilePhotoUrl;

  User({required this.id, required this.name, this.profilePhotoUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    // 🚨 PERBAIKAN UTAMA: Ambil nilai dari 'photo_url' atau 'profile_photo_url'
    final String? photoPath =
        json['photo_url'] as String? ?? json['profile_photo_url'] as String?;

    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Pengguna',
      // Gunakan path yang sudah ditemukan
      profilePhotoUrl: photoPath,
    );
  }
}

class Post {
  // ... (SISA KODE POST TETAP SAMA) ...
  final int id;
  final String content;
  final User user;
  final String createdAt;
  final int commentsCount;
  final int likesCount;
  final bool hasLiked;
  final bool hasBookmarked;
  final List<String> imageUrls;

  Post({
    required this.id,
    required this.content,
    required this.user,
    required this.createdAt,
    required this.commentsCount,
    required this.likesCount,
    required this.hasLiked,
    required this.hasBookmarked,
    this.imageUrls = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map<String, dynamic> ? json['user'] : null;

    final List<dynamic> imagesJson = json['images'] ?? [];
    final imageUrls = imagesJson
        .map((img) => img['image_url'] as String)
        .where((url) => url.isNotEmpty)
        .toList();

    return Post(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      user: userData != null
          ? User.fromJson(userData)
          : User(id: json['user_id'] as int? ?? 0, name: 'Tidak diketahui'),
      createdAt: json['created_at'] as String? ?? '',
      commentsCount: json['comments_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      hasLiked: json['has_liked'] as bool? ?? false,
      hasBookmarked: json['has_bookmarked'] as bool? ?? false,
      imageUrls: imageUrls,
    );
  }

  Post copyWith({
    int? commentsCount,
    int? likesCount,
    bool? hasLiked,
    bool? hasBookmarked,
  }) {
    return Post(
      id: id,
      content: content,
      user: user,
      createdAt: createdAt,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      hasLiked: hasLiked ?? this.hasLiked,
      hasBookmarked: hasBookmarked ?? this.hasBookmarked,
      imageUrls: imageUrls,
    );
  }
}
