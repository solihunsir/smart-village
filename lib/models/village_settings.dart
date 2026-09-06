import 'package:desaku/utils/app_logger.dart';

class VillageSettings {
  final String villageDescription;
  final String visi;
  final String misi;
  final String? photo;
  final String? photoKepalaDesa;
  final String? logoDesa;
  final String selectedProvinsiKode;
  final String selectedProvinsiNama;
  final String selectedKotaKode;
  final String selectedKotaNama;
  final String selectedKecamatanKode;
  final String selectedKecamatanNama;
  final String selectedKelurahanKode;
  final String selectedKelurahanNama;
  final String? emailVillage;
  final String? phoneVillage;
  final String? alamatKantor;
  final String? websiteDesa;
  final String? jamOperasional;

  VillageSettings({
    required this.villageDescription,
    required this.visi,
    required this.misi,
    this.photo,
    this.photoKepalaDesa,
    this.logoDesa,
    required this.selectedProvinsiKode,
    required this.selectedProvinsiNama,
    required this.selectedKotaKode,
    required this.selectedKotaNama,
    required this.selectedKecamatanKode,
    required this.selectedKecamatanNama,
    required this.selectedKelurahanKode,
    required this.selectedKelurahanNama,
    this.emailVillage,
    this.phoneVillage,
    this.alamatKantor,
    this.websiteDesa,
    this.jamOperasional,
  });

  factory VillageSettings.fromJson(Map<String, dynamic> json) {
    AppLogger.log('Creating VillageSettings from JSON: ${json.keys.toList()}');
    AppLogger.log('Village name: ${json['selected_kelurahan_nama']}');
    AppLogger.log('Village photo: ${json['photo']}');
    AppLogger.log('Kepala desa photo: ${json['photo_kepala_desa']}');

    return VillageSettings(
      villageDescription: json['village_description']?.toString() ?? '',
      visi: json['visi']?.toString() ?? '',
      misi: json['misi']?.toString() ?? '',
      photo: json['photo']?.toString(),
      photoKepalaDesa: json['photo_kepala_desa']?.toString(),
      logoDesa: json['logo_desa']?.toString(),
      selectedProvinsiKode: json['selected_provinsi_kode']?.toString() ?? '',
      selectedProvinsiNama: json['selected_provinsi_nama']?.toString() ?? '',
      selectedKotaKode: json['selected_kota_kode']?.toString() ?? '',
      selectedKotaNama: json['selected_kota_nama']?.toString() ?? '',
      selectedKecamatanKode: json['selected_kecamatan_kode']?.toString() ?? '',
      selectedKecamatanNama: json['selected_kecamatan_nama']?.toString() ?? '',
      selectedKelurahanKode: json['selected_kelurahan_kode']?.toString() ?? '',
      selectedKelurahanNama: json['selected_kelurahan_nama']?.toString() ?? '',
      emailVillage: json['email_village']?.toString(),
      phoneVillage: json['phone_village']?.toString(),
      alamatKantor: json['alamat_kantor']?.toString(),
      websiteDesa: json['website_desa']?.toString(),
      jamOperasional: json['jam_operasional']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'village_description': villageDescription,
      'visi': visi,
      'misi': misi,
      'photo': photo,
      'photo_kepala_desa': photoKepalaDesa,
      'logo_desa': logoDesa,
      'selected_provinsi_kode': selectedProvinsiKode,
      'selected_provinsi_nama': selectedProvinsiNama,
      'selected_kota_kode': selectedKotaKode,
      'selected_kota_nama': selectedKotaNama,
      'selected_kecamatan_kode': selectedKecamatanKode,
      'selected_kecamatan_nama': selectedKecamatanNama,
      'selected_kelurahan_kode': selectedKelurahanKode,
      'selected_kelurahan_nama': selectedKelurahanNama,
      'email_village': emailVillage,
      'phone_village': phoneVillage,
      'alamat_kantor': alamatKantor,
      'website_desa': websiteDesa,
      'jam_operasional': jamOperasional,
    };
  }

  String get fullAddress {
    List<String> addressParts = [
      selectedKelurahanNama,
      selectedKecamatanNama,
      selectedKotaNama,
      selectedProvinsiNama,
    ].where((part) => part.isNotEmpty).toList();

    return addressParts.join(', ');
  }

  String get photoUrl {
    if (photo == null || photo!.isEmpty) {
      AppLogger.log('No village photo available');
      return '';
    }

    if (photo!.startsWith('http')) {
      AppLogger.log('Village photo URL (full): $photo');
      return photo!;
    }

    String cleanPath = photo!.startsWith('/') ? photo!.substring(1) : photo!;
    String fullUrl =
        'https://smart-village-web.citiasiainc.id/storage/$cleanPath';
    AppLogger.log('Village photo URL (constructed): $fullUrl');
    return fullUrl;
  }

  String get photoKepalaDesaUrl {
    if (photoKepalaDesa == null || photoKepalaDesa!.isEmpty) {
      AppLogger.log('No kepala desa photo available');
      return '';
    }

    if (photoKepalaDesa!.startsWith('http')) {
      AppLogger.log('Kepala desa photo URL (full): $photoKepalaDesa');
      return photoKepalaDesa!;
    }

    String cleanPath = photoKepalaDesa!.startsWith('/')
        ? photoKepalaDesa!.substring(1)
        : photoKepalaDesa!;
    String fullUrl =
        'https://smart-village-web.citiasiainc.id/storage/$cleanPath';
    AppLogger.log(' Kepala desa photo URL (constructed): $fullUrl');
    return fullUrl;
  }
}
