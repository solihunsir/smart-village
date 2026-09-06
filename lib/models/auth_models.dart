import 'dart:io';

class Role {
  final int id;
  final String name;
  Role({required this.id, required this.name});
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'], name: json['name']);
  }
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class User {
  final int id;
  String name;
  final String email;
  String? phoneNumber;
  final Role? role;
  final String status;
  final String verificationStatus;
  final String? emailVerifiedAt;
  String? avatarUrl;
  String? photo;
  final String createdAt;
  final String updatedAt;
  File? imageFile;
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
    required this.createdAt,
    required this.updatedAt,
    this.imageFile,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      status: json['status'],
      verificationStatus: json['verification_status'],
      emailVerifiedAt: json['email_verified_at'],
      avatarUrl: json['avatar_url'],
      // Model menerima apapun yang diberikan AuthService (seharusnya full URL)
      photo: json['photo'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      imageFile: null,
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
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phoneNumber;
  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phoneNumber,
  });
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }
}

class AuthResponse {
  final User user;
  final String? token;
  AuthResponse({required this.user, this.token});
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : User.fromJson({
              'id': 0,
              'name': json['user'] ?? 'Unknown',
              'email': json['email'] ?? '',
              'status': 'active',
              'verification_status': 'unverified',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }),
      token: json['token'],
    );
  }
}
