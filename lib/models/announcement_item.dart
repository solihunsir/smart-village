class AnnouncementItem {
  final int id;
  final String title;
  final String? location;
  final String? image;
  final String? content;
  final String? date;
  final String? author;
  final String? status;

  AnnouncementItem({
    required this.id,
    required this.title,
    this.location,
    this.image,
    this.content,
    this.date,
    this.author,
    this.status,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    String? _firstNonEmpty(List keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    String? _extractImage() {
      final direct = _firstNonEmpty(const [
        'photo_url',
        'image',
        'thumbnail',
        'image_url',
        'thumbnail_url',
        'photo',
        'cover',
        'cover_url',
        'gambar',
      ]);
      if (direct != null) return direct;
      final img = json['image'];
      if (img is Map) {
        final url = img['url'] ?? img['path'] ?? img['src'];
        if (url != null && url.toString().isNotEmpty) return url.toString();
      }
      final thumb = json['thumbnail'];
      if (thumb is Map) {
        final url = thumb['url'] ?? thumb['path'] ?? thumb['src'];
        if (url != null && url.toString().isNotEmpty) return url.toString();
      }
      return null;
    }

    String _deriveTitle() {
      final t = (json['title'] ?? json['name'] ?? json['judul'])?.toString();
      if (t != null && t.isNotEmpty) return t;
      final content = (json['content'] ??
              json['description'] ??
              json['body'] ??
              json['text'])
          ?.toString();
      if (content != null && content.isNotEmpty) {
        final trimmed = content.trim();
        return trimmed.length > 60 ? trimmed.substring(0, 60) + '…' : trimmed;
      }
      return 'Pengumuman';
    }

    return AnnouncementItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: _deriveTitle(),
      location: _firstNonEmpty(const ['location', 'lokasi']),
      image: _extractImage(),
      content: _firstNonEmpty(const ['content', 'description', 'body', 'text']),
      date: _firstNonEmpty(const [
        'activity_date',
        'date',
        'created_at',
        'published_at',
        'updated_at',
      ]),
      author: (() {
        final a = _firstNonEmpty(const [
          'author',
          'penulis',
          'created_by',
          'writer',
        ]);
        if (a != null) return a;
        final user = json['user'];
        if (user is Map) {
          final name = user['name'] ?? user['full_name'] ?? user['username'];
          if (name != null && name.toString().isNotEmpty)
            return name.toString();
        }
        final createdBy = json['created_by'];
        if (createdBy is Map) {
          final name = createdBy['name'] ?? createdBy['username'];
          if (name != null && name.toString().isNotEmpty)
            return name.toString();
        }
        return null;
      })(),
      status: _firstNonEmpty(const [
        'status',
        'state',
        'publish_status',
        'visibility',
      ]),
    );
  }

  static AnnouncementItem? tryFromJson(Map<String, dynamic> json) {
    final item = AnnouncementItem.fromJson(json);

    final status = item.status?.toLowerCase();

    if (status == 'draft' || status == 'pending' || status == 'rejected') {
      return null;
    }

    return item;
  }
}
