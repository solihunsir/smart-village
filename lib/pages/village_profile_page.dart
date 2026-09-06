// File: lib/pages/village_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lt;
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

import '../services/village_service.dart';
import '../models/village_settings.dart';
import '../models/village_official.dart';
import '../services/destination_service.dart';
import '../config/api_config.dart';

// PENTING: Import IndicatorPage dari path relatif dengan prefix 'ind_page'
import 'indicator_page.dart' as ind_page;

// Tambahkan import halaman destinasi: ASUMSIKAN file ada di direktori yang sama
import 'destinations_list_page.dart';

class GeoPoint {
  final double latitude;
  final double longitude;
  final String name;
  final List<lt.LatLng> boundaries;
  final String fullAddressQuery;

  GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.boundaries = const [],
    required this.fullAddressQuery,
  });
}

final List<lt.LatLng> _dummyPolygon = [];

// Fungsi yang dimodifikasi untuk menentukan titik tengah desa
GeoPoint _determineVillageCenter(VillageSettings settings) {
  final kelurahanName = settings.selectedKelurahanNama.isNotEmpty
      ? settings.selectedKelurahanNama
      : "Pusat Desa";
  final fullQuery =
      "${settings.alamatKantor}, ${settings.selectedKelurahanNama}, ${settings.selectedKecamatanNama}, ${settings.selectedKotaNama}, ${settings.selectedProvinsiNama}";

  // Koordinat default (jika data kantor desa tidak ada/null)
  const double defaultLat = -6.9034; // Contoh latitude: Bandung
  const double defaultLng = 107.5732; // Contoh longitude: Bandung

  // **LOGIKA PENGAMBILAN KOORDINAT:** Menggunakan koordinat dummy.
  // Ganti dengan settings.latitudeKantor dan settings.longitudeKantor jika sudah ada di model.
  final double villageLat = defaultLat;
  final double villageLng = defaultLng;

  return GeoPoint(
    latitude: villageLat,
    longitude: villageLng,
    name: kelurahanName,
    fullAddressQuery: fullQuery,
  );
}

class MapPoint {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  MapPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
  factory MapPoint.fromJson(Map<String, dynamic> json) =>
      MapPoint(id: 0, name: '', latitude: 0, longitude: 0);
}

class _MapService {
  static Future<List<MapPoint>> getMapPoints() async {
    return [];
  }
}

class VillageProfilePage extends StatefulWidget {
  const VillageProfilePage({Key? key}) : super(key: key);

  @override
  State<VillageProfilePage> createState() => _VillageProfilePageState();
}

class _VillageProfilePageState extends State<VillageProfilePage> {
  VillageSettings? _settings;
  bool _isLoading = true;
  String _errorMessage = '';
  List<VillageOfficial> _officials = [];
  List<dynamic> _destinations = [];
  GeoPoint? _centerPoint;
  bool _mapLoading = true;
  String? _mapLoadError;

  final List<String> _indicatorAssets = const [
    'assets/images/penduduk.png',
    'assets/images/pekerjaan.png',
    'assets/images/pendidikan.png',
    'assets/images/kesehatan.png',
  ];
  bool _indicatorAssetsInManifest = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDestinations();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final path in _indicatorAssets) {
        try {
          // Precache assets
          if (mounted) {
            await precacheImage(AssetImage(path), context);
          }
        } catch (_) {
          // AppLogger.log('Precache failed for asset: ' + path);
        }
      }

      // Check asset manifest
      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifest = json.decode(manifestJson);
        final allPresent = _indicatorAssets.every(
          (a) => manifest.containsKey(a),
        );
        if (!allPresent && mounted) {
          setState(() {
            _indicatorAssetsInManifest = false;
          });
        }
      } catch (_) {
        // Handle error loading manifest
      }
    });
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await VillageService.getVillageSettings();
      final officials = await VillageService.getVillageOfficials();
      if (!mounted) return;
      setState(() {
        _settings = data;
        _officials = officials;
        if (_settings == null) {
          _errorMessage = 'Gagal memuat profil desa';
        }
        _isLoading = false;
      });

      if (_settings != null) {
        _determineMapCenter(_settings!);
      } else {
        if (!mounted) return;
        setState(() {
          _mapLoadError =
              "Pengaturan desa tidak termuat untuk menentukan lokasi.";
          _mapLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan saat memuat data: $e';
      });
    }
  }

  void _determineMapCenter(VillageSettings settings) {
    if (!mounted) return;
    setState(() {
      _mapLoading = true;
      _mapLoadError = null;
    });

    try {
      final point = _determineVillageCenter(settings);

      if (!mounted) return;
      setState(() {
        _centerPoint = point;
        _mapLoading = false;
      });

      if (_centerPoint == null) {
        _mapLoadError = "Gagal memproses data lokasi.";
      } else {
        _mapLoadError = null;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mapLoadError = "Gagal memproses data lokasi: ${e.toString()}";
        _mapLoading = false;
      });
    }
  }

  Future<void> _launchMaps(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    // Menggunakan skema URI umum untuk membuka aplikasi peta (mis. Google Maps)
    // dengan query pencarian.
    final uri = Uri.parse("https://maps.google.com/?q=$encodedQuery");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi peta.')),
        );
      }
      throw 'Could not launch map.';
    }
  }

  Future<void> _loadMapPoints() async {
    // Fungsi ini dinonaktifkan
  }

  Future<void> _loadDestinations() async {
    try {
      final items = await DestinationService.list(
        perPage: 6,
        isActive: true,
        showInProfile: true,
      );
      if (!mounted) return;
      setState(() {
        _destinations = items;
      });
    } catch (e) {
      // AppLogger.log('Failed to load destinations: $e');
    }
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _formatPeriod(String? start, String? end) {
    if (start == null || end == null) {
      return '';
    }
    try {
      final startYear = DateTime.parse(start).year;
      final endYear = DateTime.parse(end).year;
      return '$startYear–$endYear';
    } catch (_) {
      return '2023–2028';
    }
  }

  // --- FUNGSI BARU: MENAMPILKAN POP-UP GAMBAR (DIALOG) ---
  void _showImagePopup(
      BuildContext context, String imageUrl, String title, Color primaryColor) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL gambar tidak tersedia.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gambar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 400, // Batasan tinggi
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain, // Agar gambar menyesuaikan dalam batas
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: primaryColor, // MENGGANTI: Warna loading
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Tombol Tutup
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor, // MENGGANTI: Warna teks
                ),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- END FUNGSI BARU ---

  // --- WIDGET MAP LEAFLET (FlutterMap) DENGAN DATA API ---
  Widget _buildLeafletMap(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    if (_mapLoading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Center(
            child: CircularProgressIndicator(
                color: primaryColor)), // MENGGANTI: Warna loading
      );
    }

    if (_centerPoint == null || _mapLoadError != null) {
      // final currentAddress = _settings?.alamatKantor ?? "Alamat Desa";

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _mapLoadError ?? 'Lokasi Peta Desa belum tersedia.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _loadSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // MENGGANTI: Warna tombol
                  foregroundColor: Colors.white,
                ),
                child: const Text("Muat Ulang Peta"),
              ),
            ],
          ),
        ),
      );
    }

    final initialCenter = lt.LatLng(
      _centerPoint!.latitude,
      _centerPoint!.longitude,
    );

    final markers = [
      Marker(
        width: 80.0,
        height: 80.0,
        point: initialCenter,
        child: Icon(
          // Mengganti GestureDetector dengan Icon saja untuk marker
          Icons.location_on,
          color: primaryColor, // MENGGANTI: Warna marker
          size: 35.0,
        ),
      ),
    ];

    // Mengganti teks 'Arahkan ke Citimun' menjadi nama desa yang sebenarnya
    final navigateText = 'Arahkan ke ${_centerPoint!.name.split(' ').first}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            // OPSI PETA: Set pusat dan zoom sesuai lokasi desa
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0, // Zoom yang lebih dekat
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Tile Layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.desaku',
              ),
              // Marker Lokasi Desa
              MarkerLayer(markers: markers),

              // Batas Desa (Jika ada data batas)
              if (_centerPoint!.boundaries.isNotEmpty)
                PolygonLayer<Object>(
                  polygons: [
                    Polygon(
                      points: _centerPoint!.boundaries,
                      // MENGGANTI: Warna Polygon hardcoded dengan primaryColor
                      color: primaryColor.withOpacity(0.25),
                      // MENGGANTI: Warna border hardcoded dengan secondaryColor
                      borderColor: secondaryColor,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
            ],
          ),

          // Action button (Arahkan) di kanan bawah
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              // NAVIGASI MENGGUNAKAN ALAMAT LENGKAP UNTUK PENCARIAN GPS
              onPressed: () {
                final query = _centerPoint!.fullAddressQuery;
                if (query.isNotEmpty) {
                  _launchMaps(query);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alamat desa tidak tersedia.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.map, size: 16),
              label: Text(navigateText),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // MENGGANTI: Warna tombol
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final secondaryColor = themeProvider.secondaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: primaryColor), // MENGGANTI: Warna ikon
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          (_settings != null && _settings!.selectedKelurahanNama.isNotEmpty)
              ? 'Profil ${_settings!.selectedKelurahanNama}'
              : 'Profil Desa',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: primaryColor)) // MENGGANTI: Warna loading
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: primaryColor), // MENGGANTI: Warna ikon
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                primaryColor, // MENGGANTI: Warna tombol
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto Desa (DIBERI GestureDetector)
                      GestureDetector(
                        onTap: () {
                          if (_settings?.photoUrl.isNotEmpty ?? false) {
                            _showImagePopup(
                              context,
                              _settings!.photoUrl,
                              'Foto Desa',
                              primaryColor, // Meneruskan primaryColor
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto Desa tidak tersedia.'),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          margin: const EdgeInsets.all(16),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: primaryColor.withOpacity(
                                0.2), // MENGGANTI: Warna background
                          ),
                          child: (_settings?.photoUrl.isNotEmpty ?? false)
                              ? Image.network(
                                  _settings!.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 48,
                                    color: primaryColor.withOpacity(
                                        0.5), // MENGGANTI: Warna ikon
                                  ),
                                ),
                        ),
                      ),

                      // Tentang Desa
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tentang Desa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _settings != null &&
                                      _settings!.villageDescription.isNotEmpty
                                  ? _stripHtmlTags(
                                      _settings!.villageDescription)
                                  : 'Deskripsi desa belum tersedia.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF616161),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Struktur Organisasi Desa
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Struktur Organisasi Desa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _officials.isEmpty
                                  ? Row(
                                      children: [
                                        _buildOrganizationMemberPlaceholder(
                                          name: 'Kepala Desa',
                                          position: _settings
                                                  ?.selectedKelurahanNama ??
                                              '',
                                          period: '',
                                        ),
                                      ],
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        final o = _officials[index];
                                        return _buildOrganizationMemberNetwork(
                                          name: o.name,
                                          position: o.position,
                                          period: _formatPeriod(
                                            o.periodStart,
                                            o.periodEnd,
                                          ),
                                          imageUrl: o.normalizedPhotoUrl,
                                          primaryColor:
                                              primaryColor, // Meneruskan primaryColor
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemCount: _officials.length,
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Peta Desa (Menggunakan FlutterMap dengan data API)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Peta Desa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Container Map
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[200],
                              ),
                              child: _buildLeafletMap(context, primaryColor,
                                  secondaryColor), // Meneruskan warna
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Destinasi Wisata
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Destinasi Wisata',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                // MODIFIKASI: Mengarahkan ke DestinationsListPage
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DestinationsListPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      color:
                                          primaryColor, // MENGGANTI: Warna teks
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: _destinations.isEmpty
                                  ? ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _buildDestinationCard(
                                          name: 'Destinasi belum tersedia',
                                          imageUrl: '',
                                        ),
                                      ],
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.only(right: 16),
                                      itemBuilder: (context, index) {
                                        final d = _destinations[index]
                                            as Map<String, dynamic>;
                                        final photo = (d['photo_url'] ??
                                            d['photoUrl'] ??
                                            d['image'] ??
                                            '') as String;
                                        return _buildDestinationCard(
                                          name: d['name'] ?? '',
                                          imageUrl: _normalizeImageUrl(photo),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemCount: _destinations.length,
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  // MODIFIKASI: Menambahkan primaryColor ke argumen
  Widget _buildOrganizationMemberNetwork({
    required String name,
    required String position,
    required String period,
    required String imageUrl,
    required Color primaryColor,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gambar diberi GestureDetector
          GestureDetector(
            onTap: () {
              if (imageUrl.isNotEmpty) {
                _showImagePopup(
                  context,
                  imageUrl,
                  'Foto ${name} (${position})',
                  primaryColor,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Foto tidak tersedia.')),
                );
              }
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: primaryColor
                    .withOpacity(0.1), // MENGGANTI: Warna background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      // 🐛 PERBAIKAN: Mengganti icons.person menjadi Icons.person
                      child: Icon(Icons.person,
                          color: primaryColor.withOpacity(0.6), size: 50),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (position.isNotEmpty)
            Text(
              position,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (period.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                period,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor, // MENGGANTI: Warna hardcoded
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // Placeholder tidak diubah karena tidak ada gambar jaringan yang bisa di-zoom
  Widget _buildOrganizationMemberPlaceholder({
    required String name,
    required String position,
    required String period,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade300,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              // 🐛 PERBAIKAN: Mengganti icons.person menjadi Icons.person
              child: Icon(Icons.person, color: Colors.grey, size: 50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (position.isNotEmpty)
            Text(
              position,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (period.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                period,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00A310),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard({
    required String name,
    required String imageUrl,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image area
            SizedBox(
              height: 140,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.white70),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.white70),
                      ),
                    ),
            ),

            // White pill label overlapping bottom of image
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi yang menggunakan ApiConfig
  String _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final clean = url.startsWith('/') ? url.substring(1) : url;
    if (clean.startsWith('storage/')) return '${ApiConfig.baseUrl}/$clean';
    return '${ApiConfig.baseUrl}/storage/$clean';
  }
}
