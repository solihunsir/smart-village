import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../models/village_settings.dart';
import '../services/village_service.dart';
import 'complaint_form_page.dart';
import 'complaint_detail_page.dart';
import 'package:desaku/utils/app_logger.dart';

// --- BASE URL API ---
const String _apiBaseUrl = 'https://smart-village-web.citiasiainc.id';

// --- Definisi Warna Status BARU (TETAP SEMANTIK, TIDAK MENGGUNAKAN WARNA TEMA) ---
const Color _colorSent = Color(0xFF007F99); // Biru-Hijau Tua
const Color _colorProcessed = Color(0xFFFFA000); // Amber/Orange
const Color _colorRejected = Color(0xFFD32F2F); // Merah Tua
const Color _colorDone = Color(0xFF388E3C); // Hijau Tua
const Color _colorDefault = Colors.grey;

// Fungsi pembantu untuk menentukan warna status (Duplikasi dari detail page agar konsisten)
Color _getStatusColor(String status) {
  final statusKey = status.toLowerCase();
  if (statusKey.contains('terkirim') || statusKey.contains('kirim'))
    return _colorSent;
  if (statusKey.contains('diproses') || statusKey.contains('proses'))
    return _colorProcessed;
  if (statusKey.contains('selesai')) return _colorDone;
  if (statusKey.contains('tolak') || statusKey.contains('reject'))
    return _colorRejected;
  return _colorDefault;
}

// --- MODEL DATA LAPORAN ---
class ReportModel {
  final String id;
  final String encryptedId;
  final String title;
  final String description;
  final List<String> photos;
  final String location;
  final String createdAt;
  final String category;
  final String latestStatus;
  final String reporterName;
  final String reporterPhone;

  ReportModel({
    required this.id,
    required this.encryptedId,
    required this.title,
    required this.description,
    required this.photos,
    required this.location,
    required this.createdAt,
    required this.category,
    required this.latestStatus,
    required this.reporterName,
    required this.reporterPhone,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final latestLog = json['latestLog'] ?? {};
    final category = json['category'] ?? {};
    final user = json['user'] ?? {};

    final String rawStatus =
        (latestLog['status']?.toString().trim() ?? 'Terkirim');

    // --- Normalisasi URL gambar ---
    final List<String> rawPhotos = List<String>.from(json['photos'] ?? []);
    final normalizedPhotos = rawPhotos.map((p) {
      if (p is! String) return p.toString();
      if (p.startsWith('http')) return p;
      String cleanedPath = p.startsWith('/') ? p.substring(1) : p;
      if (!cleanedPath.toLowerCase().startsWith('storage/')) {
        return '$_apiBaseUrl/storage/$cleanedPath';
      }
      return '$_apiBaseUrl/$cleanedPath';
    }).toList();

    return ReportModel(
      id: json['id']?.toString() ?? 'N/A',
      encryptedId: json['encrypted_id'] ?? json['encryptedId'] ?? '',
      title: json['title'] ?? 'Laporan Tanpa Judul',
      description: json['description'] ?? 'Tidak ada deskripsi',
      photos: normalizedPhotos,
      location: json['location'] ?? 'Lokasi tidak diketahui',
      createdAt: json['created_at'] != null
          ? (json['created_at'] as String).substring(0, 10)
          : (json['submissionDate'] ?? 'N/A'),
      category: category['category'] ?? 'Umum',
      latestStatus: rawStatus,
      reporterName: user['name'] ?? 'Pelapor Anonim',
      reporterPhone: user['phone'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'encryptedId': encryptedId,
      'category': category,
      'title': title,
      'description': description,
      'location': location,
      'submissionDate': createdAt,
      'photos': photos,
      'status': latestStatus,
      'submitterName': reporterName,
      'submitterPhone': reporterPhone,
    };
  }
}

// --- SERVICE LAPORAN KHUSUS USER ---
class ReportService {
  /// Ambil daftar laporan milik user
  static Future<List<ReportModel>> fetchMyReports() async {
    final token = await TokenService.getToken();

    if (token == null) {
      throw Exception('Sesi pengguna berakhir. Silakan login ulang.');
    }

    final uri = Uri.parse('$_apiBaseUrl/api/my-reports');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> reportListJson = jsonResponse['data'] ?? [];
      return reportListJson.map((json) => ReportModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Anda belum login.');
    } else {
      throw Exception('Gagal memuat laporan. Status: ${response.statusCode}');
    }
  }

  /// Ambil detail laporan satu per satu (digunakan untuk sinkronisasi status)
  static Future<Map<String, dynamic>> fetchReportDetail(
    String encryptedId,
  ) async {
    final uri = Uri.parse('$_apiBaseUrl/api/reports/$encryptedId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final Map<String, dynamic> latestData =
          (jsonResponse['data'] is Map) ? jsonResponse['data'] : {};
      return latestData;
    } else {
      throw Exception(
        'Gagal memuat detail laporan. Status: ${response.statusCode}',
      );
    }
  }
}

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({super.key});
  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  VillageSettings? _villageSettings;
  bool _isLoadingSettings = true;

  List<ReportModel> _myReports = [];
  bool _isLoadingReports = true;
  String? _reportsError;

  @override
  void initState() {
    super.initState();
    _loadVillageSettings();
    _fetchReportsAndSync();
  }

  Future<void> _loadVillageSettings() async {
    try {
      final settings = await VillageService.getVillageSettings();
      if (mounted) {
        setState(() {
          _villageSettings = settings;
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      AppLogger.log('Error loading village settings for logo: $e');
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
          _villageSettings = null;
        });
      }
    }
  }

  /// Ambil daftar laporan, lalu sinkron tiap laporan dengan endpoint detail
  Future<void> _fetchReportsAndSync() async {
    if (!mounted) return; // Menambahkan cek mounted

    setState(() {
      _isLoadingReports = true;
      _reportsError = null;
    });

    try {
      final baseReports = await ReportService.fetchMyReports();

      // Jika tidak ada data, langsung set dan return
      if (baseReports.isEmpty) {
        if (mounted) {
          setState(() {
            _myReports = [];
            _isLoadingReports = false;
          });
        }
        return;
      }

      // Untuk setiap laporan, ambil detailnya untuk mendapatkan logs terakhir/ latestLog
      final futures = baseReports.map((r) async {
        try {
          if (r.encryptedId.isEmpty) {
            return r; // tidak bisa sinkron tanpa encryptedId
          }
          final detailData = await ReportService.fetchReportDetail(
            r.encryptedId,
          );

          // Tentukan latestLog (mengikuti logika di complaint_detail_page.dart)
          final logs = detailData['logs'];
          Map<String, dynamic> latestLogObj = {};
          if (logs is List && logs.isNotEmpty) {
            latestLogObj = logs.last as Map<String, dynamic>;
          } else if (detailData['latestLog'] is Map) {
            latestLogObj = detailData['latestLog'] as Map<String, dynamic>;
          }

          // Ambil status terbaru dari log atau status utama
          final String statusFromDetail =
              (latestLogObj['status']?.toString().trim() ??
                  detailData['status'] ??
                  r.latestStatus);

          // Normalisasi photos seperti di detail
          final List<String> rawPhotos = List<String>.from(
            detailData['photos'] ?? r.photos,
          );
          final normalizedPhotos = rawPhotos.map((p) {
            if (p is! String) return p.toString();
            if (p.startsWith('http')) return p;
            String cleanedPath = p.startsWith('/') ? p.substring(1) : p;
            if (!cleanedPath.toLowerCase().startsWith('storage/')) {
              return '$_apiBaseUrl/storage/$cleanedPath';
            }
            return '$_apiBaseUrl/$cleanedPath';
          }).toList();

          // Buat instance baru ReportModel (salin field dari r, tetapi perbarui status & photos)
          return ReportModel(
            id: r.id,
            encryptedId: r.encryptedId,
            title: detailData['title'] ?? r.title,
            description: detailData['description'] ?? r.description,
            photos: normalizedPhotos,
            location: detailData['location'] ?? r.location,
            createdAt: detailData['created_at'] != null
                ? (detailData['created_at'] as String).substring(0, 10)
                : r.createdAt,
            category: (detailData['category'] is Map)
                ? (detailData['category']['category'] ?? r.category)
                : (detailData['category'] ?? r.category),
            latestStatus: statusFromDetail,
            reporterName: (detailData['user']?['name'] ?? r.reporterName),
            reporterPhone: (detailData['user']?['phone'] ?? r.reporterPhone),
          );
        } catch (e) {
          // Jika fetch detail gagal, kembalikan object original (tapi jangan crash)
          AppLogger.log('Warning: gagal sinkron detail untuk ${r.id}: $e');
          return r;
        }
      }).toList();

      final List<ReportModel> syncedReports = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _myReports = syncedReports;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      AppLogger.log('Error fetching my reports: $e');
      if (mounted) {
        setState(() {
          if (e.toString().contains('Sesi pengguna berakhir') ||
              e.toString().contains('Anda belum login')) {
            _reportsError = 'Anda harus login untuk melihat laporan Anda.';
          } else {
            _reportsError =
                'Gagal memuat laporan Anda. (${e.toString().replaceAll('Exception: ', '')})';
          }
          _isLoadingReports = false;
        });
      }
    }
  }

  Widget _buildTextLogo(Color primaryColor) {
    return Text(
      _villageSettings?.selectedKelurahanNama ?? 'Nama Desa',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryColor, // MENGGANTI: Warna logo dengan primaryColor
      ),
    );
  }

  Widget _buildVillageLogo(Color primaryColor) {
    if (_isLoadingSettings) {
      return SizedBox(width: 60, height: 50);
    }

    final logoUrl = _villageSettings?.logoDesa;
    const double logoSize = 70.0;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      String normalizedUrl;

      if (logoUrl.startsWith('http')) {
        normalizedUrl = logoUrl;
      } else if (logoUrl.startsWith('/storage')) {
        normalizedUrl = '$_apiBaseUrl$logoUrl';
      } else {
        normalizedUrl =
            '$_apiBaseUrl/storage/${logoUrl.replaceAll(RegExp(r"^/"), "")}';
      }

      return Image.network(
        normalizedUrl,
        height: logoSize,
        width: logoSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildTextLogo(primaryColor),
      );
    }
    return _buildTextLogo(primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna tema
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    final reports = _myReports;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kustom
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVillageLogo(primaryColor)
                    ], // Meneruskan warna
                  ),
                  const SizedBox(height: 10),

                  // Kolom Input Pencarian/Buat Laporan
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Laporkan keluhan anda disini!',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          TokenService.isLoggedIn().then((isLoggedIn) {
                            if (isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ComplaintFormPage(),
                                ),
                              ).then((_) => _fetchReportsAndSync());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Anda harus login untuk membuat laporan.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
                          backgroundColor: primaryColor,
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text(
                          'Buat Laporan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Area Daftar Laporan
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: const Text(
                'Daftar Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Expanded(
              child: _isLoadingReports
                  ? Center(
                      child: CircularProgressIndicator(
                          color: primaryColor)) // Menerapkan warna tema
                  : _reportsError != null
                      ? _buildErrorState(
                          _reportsError!, primaryColor) // Menerapkan warna tema
                      : reports.isEmpty
                          ? _buildEmptyState(
                              primaryColor) // Menerapkan warna tema
                          : RefreshIndicator(
                              onRefresh: _fetchReportsAndSync,
                              color: primaryColor, // Menerapkan warna tema
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: reports.length,
                                itemBuilder: (context, index) {
                                  final report = reports[index];
                                  return _buildCompactComplaintCard(report,
                                      primaryColor); // Menerapkan warna tema
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactComplaintCard(ReportModel report, Color primaryColor) {
    // Menggunakan warna semantik yang sudah didefinisikan
    final Color statusColor = _getStatusColor(report.latestStatus);
    final String statusText = report.latestStatus;

    // Warna untuk badge kategori (berasal dari tema)
    final categoryBadgeBg = Color.lerp(primaryColor, Colors.white, 0.9);
    final categoryBadgeBorder = Color.lerp(primaryColor, Colors.white, 0.7)!;

    String imageUrl = 'https://via.placeholder.com/150';
    if (report.photos.isNotEmpty) {
      imageUrl = report.photos.first;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ComplaintDetailPage(complaint: report.toJson()),
          ),
        ).then((returned) {
          _fetchReportsAndSync();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image,
                      color: primaryColor
                          .withOpacity(0.6)), // Menggunakan warna tema
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // MENGGANTI: Warna hardcoded dengan warna tema
                        color: categoryBadgeBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: categoryBadgeBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        report.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              primaryColor, // MENGGANTI: Warna hardcoded dengan primaryColor
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Lokasi
                        Flexible(
                          child: Text(
                            report.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Titik Pemisah
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Status
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const Spacer(),

                        // Tanggal Laporan
                        Text(
                          report.createdAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: primaryColor.withOpacity(0.5), // Menggunakan warna tema
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada laporan',
            style: TextStyle(
              fontSize: 16,
              color: primaryColor, // Menggunakan warna tema
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yuk, buat laporan pertama Anda!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: primaryColor), // Menggunakan warna tema
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 16,
                color: primaryColor, // Menggunakan warna tema
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReportsAndSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Menggunakan warna tema
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
