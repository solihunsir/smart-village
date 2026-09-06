int _safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt(); 
  if (value is String) {
    if (value.contains('.')) {
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt() ?? 0;
    }
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
 
class CategoryModel {
  final int id;
  final String name; 

  CategoryModel({
    required this.id, 
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _safeToInt(json['id']),
      name: json['name'] as String? ?? 'Kategori Tak Dikenal',
    );
  }
}

// Model Respons API Kategori
class CategoryResponse {
  final List<CategoryModel> data;
  final bool success;
  final String message;

  CategoryResponse({
    required this.data,
    required this.success,
    required this.message,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    List<CategoryModel> data = dataList.map((i) => CategoryModel.fromJson(i)).toList();

    return CategoryResponse(
      data: data,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}