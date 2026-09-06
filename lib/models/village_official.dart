class VillageOfficial {
  final int id;
  final String name;
  final String position;
  final String? photoUrl;
  final String? periodStart;
  final String? periodEnd;
  final String? detailDescription;
  final String? logoDesa;
  final bool isActive;

  VillageOfficial({
    required this.id,
    required this.name,
    required this.position,
    this.photoUrl,
    this.periodStart,
    this.periodEnd,
    this.detailDescription,
    this.logoDesa,
    required this.isActive,
  });

  factory VillageOfficial.fromJson(Map<String, dynamic> json) {
    return VillageOfficial(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      periodStart: json['period_start']?.toString(),
      periodEnd: json['period_end']?.toString(),
      detailDescription: json['detail_description']?.toString(),
      logoDesa: json['logo_desa']?.toString(),
      isActive: json['is_active'] == true,
    );
  }

  String get normalizedPhotoUrl {
    final url = photoUrl ?? '';
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final clean = url.startsWith('/') ? url.substring(1) : url;
    return 'https://smart-village-web.citiasiainc.id/$clean';
  }
}
