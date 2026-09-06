// lib/models/community_channel.dart

class CommunityChannel {
  final int id;
  final String name;
  final String imageUrl; // img_community dari API
  final int communitiesCount; // communities_count dari API

  CommunityChannel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.communitiesCount,
  });

  factory CommunityChannel.fromJson(Map<String, dynamic> json) {
    return CommunityChannel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['img_community'] as String? ?? '',
      communitiesCount: json['communities_count'] as int? ?? 0,
    );
  }
}
