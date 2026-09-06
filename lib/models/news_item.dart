class NewsItem {
  final String slug;
  final String title;
  final String? author;
  final String? image;
  final String? content;
  final String? date;
  final String? category;

  NewsItem({
    required this.slug,
    required this.title,
    this.author,
    this.image,
    this.content,
    this.date,
    this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    String? _firstNonEmpty(List keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return null;
    }

    String? _extractAuthor() {
      final direct = _firstNonEmpty(const [
        'author',
        'author_name',
        'created_by',
        'created_by_name',
        'penulis',
      ]);
      if (direct != null) return direct;
      final authorObj = json['author'];
      if (authorObj is Map && (authorObj['name'] ?? '').toString().isNotEmpty) {
        return authorObj['name'].toString();
      }
      final userObj = json['user'];
      if (userObj is Map && (userObj['name'] ?? '').toString().isNotEmpty) {
        return userObj['name'].toString();
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
        'banner',
        'featured_image',
        'image_path',
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
      final featured = json['featured_image'];
      if (featured is Map) {
        final url = featured['url'] ?? featured['path'] ?? featured['src'];
        if (url != null && url.toString().isNotEmpty) return url.toString();
      }
      return null;
    }

    String? _extractCategory() {
      final directCat = _firstNonEmpty(const [
        'category',
        'category_name',
        'kategori',
      ]);
      if (directCat != null) return directCat;
      final catObj = json['category'];
      if (catObj is Map) {
        for (final k in ['name', 'title', 'nama', 'label']) {
          final v = catObj[k];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
        final attrs = catObj['attributes'];
        if (attrs is Map) {
          for (final k in ['name', 'title', 'nama', 'label']) {
            final v = attrs[k];
            if (v != null && v.toString().isNotEmpty) return v.toString();
          }
        }
      }
      return null;
    }

    return NewsItem(
      slug: (json['slug'] ?? json['id'] ?? json['uuid'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? json['judul'] ?? '').toString(),
      author: _extractAuthor(),
      image: _extractImage(),
      content: _firstNonEmpty(const ['content', 'body', 'text', 'description']),
      date: _firstNonEmpty(const [
        'date',
        'created_at',
        'published_at',
        'updated_at',
      ]),
      category: _extractCategory(),
    );
  }
}
