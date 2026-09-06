// File: api_product.dart

import 'product.dart';
import '../config/api_config.dart';

int _parseIntSafe(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}

class ProductCategory {
  final int id;
  final String name;
  final String description;
  final String createdAt;
  final String updatedAt;

  ProductCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: _parseIntSafe(json['id']),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ProductSeller {
  final int id;
  final String name;
  final String email;
  final String phone; // Nomor HP Penjual

  ProductSeller({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory ProductSeller.fromJson(Map<String, dynamic> json) {
    // Mencari kunci 'phone_number' atau 'phone' yang dikembalikan API
    final dynamic rawPhoneNumber =
        json['phone_number'] ??
        json['Phone_Number'] ??
        json['phone'] ??
        json['contact'];

    // Konversi ke string dan trim untuk membersihkan
    final String phoneNumber = rawPhoneNumber?.toString().trim() ?? '';

    return ProductSeller(
      id: _parseIntSafe(json['id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: phoneNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'phone_number': phone};
  }
}

class ProductPhoto {
  final int id;
  final int productId;
  final String photoUrl;
  final String createdAt;
  final String updatedAt;

  ProductPhoto({
    required this.id,
    required this.productId,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductPhoto.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photo_url']?.toString() ?? '';
    String normalized;
    if (rawPhoto.startsWith('http')) {
      normalized = rawPhoto;
    } else if (rawPhoto.startsWith('/')) {
      normalized = '${ApiConfig.baseUrl}$rawPhoto';
    } else if (rawPhoto.isEmpty) {
      normalized = '';
    } else {
      normalized = '${ApiConfig.baseUrl}/$rawPhoto';
    }

    return ProductPhoto(
      id: _parseIntSafe(json['id']),
      productId: _parseIntSafe(json['product_id']),
      photoUrl: normalized,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'photo_url': photoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ApiProduct {
  final int id;
  final int sellerId;
  final int categoryId;
  final String name;
  final String description;
  final String price;
  final String status;
  final String conditionProduct;
  final String location;
  final String createdAt;
  final String updatedAt;
  final ProductSeller? seller;
  final ProductCategory? category;
  final List<ProductPhoto> photos;

  ApiProduct({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.status,
    required this.conditionProduct,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
    this.category,
    this.photos = const [],
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: _parseIntSafe(json['id']),
      sellerId: _parseIntSafe(json['seller_id']),
      categoryId: _parseIntSafe(json['category_id']),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
      status: json['status'] ?? 'tersedia',
      conditionProduct: json['condition_product'] ?? 'bekas',
      location: json['location'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      seller: json['seller'] != null
          ? ProductSeller.fromJson(json['seller'])
          : null,
      category: json['category'] != null
          ? ProductCategory.fromJson(json['category'])
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List)
                .map(
                  (photo) =>
                      ProductPhoto.fromJson(Map<String, dynamic>.from(photo)),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'status': status,
      'condition_product': conditionProduct,
      'location': location,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'seller': seller?.toJson(),
      'category': category?.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }

  // Helper methods
  double get priceAsDouble {
    try {
      return double.parse(price);
    } catch (e) {
      return 0.0;
    }
  }

  String get formattedPrice {
    final priceNum = priceAsDouble;
    if (priceNum >= 1000000000) {
      return 'Rp ${(priceNum / 1000000000).toStringAsFixed(1)}M';
    } else if (priceNum >= 1000000) {
      return 'Rp ${(priceNum / 1000000).toStringAsFixed(0)} Juta';
    } else if (priceNum >= 1000) {
      return 'Rp ${(priceNum / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${priceNum.toStringAsFixed(0)}';
  }

  String get primaryImageUrl {
    if (photos.isNotEmpty) {
      return photos.first.photoUrl;
    }
    return '';
  }

  String get sellerName {
    return seller?.name ?? 'Unknown Seller';
  }

  String get categoryName {
    return category?.name ?? 'Tanpa Kategori';
  }

  bool get isAvailable {
    return status.toLowerCase() == 'tersedia';
  }

  bool get isNew {
    return conditionProduct.toLowerCase() == 'baru';
  }

  // ✅ BARU: Getter yang akan digunakan di ApiProductDetailPage
  String get sellerContactNumber {
    // Ambil nomor dari objek seller (ProductSeller.phone)
    return seller?.phone ?? '';
  }

  // Convert to legacy Product model for compatibility
  Product toLegacyProduct() {
    return Product(
      id: id.toString(),
      name: name,
      price: priceAsDouble,
      image: primaryImageUrl,
      seller: sellerName,
      description: description,
      condition: conditionProduct,
      location: location,
      contactWhatsApp:
          sellerContactNumber, // Gunakan getter yang sudah terjamin
      category: categoryName,
    );
  }
}

class ProductPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;

  ProductPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
  });

  factory ProductPagination.fromJson(Map<String, dynamic> json) {
    return ProductPagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

class ProductResponse {
  final bool success;
  final String message;
  final List<ApiProduct> data;
  final ProductPagination? pagination;
  final Map<String, dynamic>? filters;

  ProductResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
    this.filters,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List)
                .map((item) => ApiProduct.fromJson(item))
                .toList()
          : [],
      pagination: json['pagination'] != null
          ? ProductPagination.fromJson(json['pagination'])
          : null,
      filters: json['filters'],
    );
  }
}
