// lib/models/community.dart

class Community {
  final int id;
  final int channelId;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;
  final int memberCount;
  final int creatorId; // Dipakai untuk filtering Admin

  Community({
    required this.id,
    required this.channelId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    required this.memberCount,
    required this.creatorId,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int,
      channelId: json['community_channel_id'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? 'Tidak ada deskripsi.',
      imageUrl: json['profile_image_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      memberCount: json['members_count'] as int? ?? 0,
      // ASUMSI: creator_id mungkin ada di response detail, default 0 jika tidak ada di list
      creatorId: json['creator_id'] as int? ?? 0,
    );
  }

  Community copyWith({
    int? id,
    int? channelId,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
    int? memberCount,
    int? creatorId,
  }) {
    return Community(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}
