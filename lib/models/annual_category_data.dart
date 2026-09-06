double _safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

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

// Model Indikator Yak
class AnnualCategoryData {
  final int id;
  final int categoryId;
  final int variableCategoryId;
  final String periodStart;
  final String periodEnd;
  final double value;
  final int year;
  final String unit;
  final VariableCategory? variableCategory;

  AnnualCategoryData({
    required this.id,
    required this.categoryId,
    required this.variableCategoryId,
    required this.periodStart,
    required this.periodEnd,
    required this.value,
    required this.year,
    required this.unit,
    this.variableCategory,
  });

  factory AnnualCategoryData.fromJson(Map<String, dynamic> json) {
    final parsedId = _safeToInt(json['id']);
    final parsedCategoryId = _safeToInt(
      json.containsKey('category_id')
          ? json['category_id']
          : (json['variableCategory']?['category']?['id']),
    );
    final parsedVariableId = _safeToInt(json['variable_category_id']);

    final parsedValue = _safeToDouble(json['value']);
    final parsedYear = _safeToInt(json['year']);

    return AnnualCategoryData(
      id: parsedId,
      categoryId: parsedCategoryId,
      variableCategoryId: parsedVariableId,
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      value: parsedValue,
      year: parsedYear,
      unit: json['unit'] as String? ?? '',
      variableCategory: json['variableCategory'] != null
          ? VariableCategory.fromJson(json['variableCategory'])
          : null,
    );
  }
}

// Variabel Kategori Yak
class VariableCategory {
  final int id;
  final String name;

  VariableCategory({required this.id, required this.name});

  factory VariableCategory.fromJson(Map<String, dynamic> json) {
    return VariableCategory(
      id: _safeToInt(json['id']),
      name: json['name'] as String? ?? 'N/A',
    );
  }
}

// Kategori Tahun yak
class AnnualCategoryDataResponse {
  final List<AnnualCategoryData> data;
  final bool success;
  final String message;

  AnnualCategoryDataResponse({
    required this.data,
    required this.success,
    required this.message,
  });

  factory AnnualCategoryDataResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    List<AnnualCategoryData> data = dataList
        .map((i) => AnnualCategoryData.fromJson(i))
        .toList();

    return AnnualCategoryDataResponse(
      data: data,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
