class FeaturedProduct {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final String? productCategory;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  FeaturedProduct({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.productCategory,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory FeaturedProduct.fromJson(Map<String, dynamic> json) {
    return FeaturedProduct(
      id: _parseId(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      image:
          (json['photo_url'] ??
                  json['photoUrl'] ??
                  json['image'] ??
                  json['photo'])
              ?.toString(),
      productCategory: json['product_category']?.toString(),
      isActive: _parseBool(json['is_active']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'product_category': productCategory,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
