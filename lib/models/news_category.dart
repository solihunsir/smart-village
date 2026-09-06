class NewsCategory {
  final int? id;
  final String name;
  final String? slug;

  NewsCategory({this.id, required this.name, this.slug});

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final id = _parseInt(json['id']);
    final name = (json['name'] ?? json['title'] ?? json['kategori'] ?? '')
        .toString();
    final slug = (json['slug'] ?? json['category_slug'] ?? json['kode'])
        .toString();

    return NewsCategory(
      id: id,
      name: name.isNotEmpty ? name : (slug.isNotEmpty ? slug : 'Kategori'),
      slug: slug.isNotEmpty ? slug : null,
    );
  }
}
