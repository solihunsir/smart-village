class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataFromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && dataFromJson != null
          ? dataFromJson(json['data'])
          : json['data'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
}
