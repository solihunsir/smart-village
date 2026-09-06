// lib/models/user.dart

class UserRole {
  final int id;
  final String name;
  UserRole({required this.id, required this.name});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final UserRole? role;
  final String status;
  final String verificationStatus;
  final String? emailVerifiedAt;
  final String? avatarUrl;
  final String? photo;
  final String? photoUrl; // 🎯 PERBAIKAN: Tambahkan properti photoUrl
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.role,
    required this.status,
    required this.verificationStatus,
    this.emailVerifiedAt,
    this.avatarUrl,
    this.photo,
    this.photoUrl, // Tambahkan ke constructor
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Pengguna Anonim',
      email: json['email'] as String? ?? 'anonim@example.com',
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
      status: json['status'] as String? ?? 'active',
      verificationStatus:
          json['verification_status'] as String? ?? 'unverified',
      emailVerifiedAt: json['email_verified_at'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      photo: json['photo'] as String?,
      photoUrl:
          json['photo_url']
              as String?, // 🎯 PERBAIKAN: Ambil photo_url dari JSON
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'role': role?.toJson(),
      'status': status,
      'verification_status': verificationStatus,
      'email_verified_at': emailVerifiedAt,
      'avatar_url': avatarUrl,
      'photo': photo,
      'photo_url': photoUrl, // Tambahkan ke toJson
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
