import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:desaku/utils/app_logger.dart';

const String _apiBaseUrl = 'https://smart-village-web.citiasiainc.id';
final List<String> statusSteps = ['Terkirim', 'Diproses', 'Selesai'];

// --- Definisi Warna Status Konsisten ---
const Color _colorSent = Color(0xFF007F99); // Biru Kehijauan (DIPERTAHANKAN)
const Color _colorProcessed = Color(0xFFB89A00); // Emas/Oker (DIPERTAHANKAN)
const Color _colorRejected = Color(0xFFBC0000); // Merah (DIPERTAHANKAN)

// Warna kustom yang akan diganti dengan primaryColor di runtime:
// const Color _colorDoneTimeline = Color(0xFF4CAF50); // Hijau untuk status "Selesai" di timeline
// const Color _colorAccent = Color(0xFF4CAF50); // Hijau

const Color _colorDefault = Colors.grey;
const Color _colorGreyChip = Color(
  0xFFE0E0E0,
); // Warna abu-abu yang lebih terang untuk chip
const Color _colorGreyText = Color(0xFF616161); // Warna teks untuk chip abu-abu
const Color _colorGreyDotInactive = Color(
  0xFFD6D6D6,
); // Warna abu-abu untuk dot inactive

class ComplaintDetailPage extends StatefulWidget {
  final Map<String, dynamic> complaint;
  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  Map<String, dynamic>? _liveComplaintData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _liveComplaintData = widget.complaint;
    _fetchReportDetails();
  }

  Color _getStatusColor(String status, Color primaryColor) {
    final statusKey = status.toLowerCase();
    if (statusKey.contains('terkirim') || statusKey.contains('kirim'))
      return _colorSent;
    if (statusKey.contains('diproses') || statusKey.contains('proses'))
      return _colorProcessed;
    if (statusKey.contains('selesai'))
      return primaryColor; // MENGGANTI: _colorDoneTimeline dengan primaryColor
    if (statusKey.contains('tolak') || statusKey.contains('reject'))
      return _colorRejected;
    return _colorDefault;
  }

  int _getStatusIndex(String status) {
    final key = status.toLowerCase();
    if (key.contains('selesai')) return 2;
    if (key.contains('proses')) return 1;
    return 0;
  }

  String _formatDateTimeForLog(String dateStr) {
    try {
      if (dateStr.isEmpty) return '-';
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _safeString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num) return v.toString();
    if (v is Map) {
      if (v.containsKey('name')) return _safeString(v['name']);
      if (v.containsKey('category')) return _safeString(v['category']);
      if (v.containsKey('title')) return _safeString(v['title']);
      if (v.containsKey('url')) return _safeString(v['url']);
      if (v.containsKey('path')) return _safeString(v['path']);
      if (v.containsKey('file')) return _safeString(v['file']);
      return json.encode(v);
    }
    return v.toString();
  }

  String _normalizePhotoItem(dynamic p) {
    if (p == null) return '';
    if (p is String) return p;
    if (p is Map) {
      final keys = ['url', 'path', 'file', 'photo', 'image'];
      for (final k in keys) {
        if (p.containsKey(k) && p[k] != null) {
          return _safeString(p[k]);
        }
      }
      if (p.values.isNotEmpty) return _safeString(p.values.first);
      return '';
    }
    return p.toString();
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '-';
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchReportDetails() async {
    final encryptedId =
        widget.complaint['encryptedId'] ?? widget.complaint['encrypted_id'];
    if (encryptedId == null || (encryptedId is String && encryptedId.isEmpty)) {
      setState(() {
        _errorMessage = "ID Laporan tidak valid untuk diperbarui.";
        _isLoading = false;
      });
      return;
    }

    final uri = Uri.parse('$_apiBaseUrl/api/reports/$encryptedId');
    if (_liveComplaintData == widget.complaint && _liveComplaintData != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final latestData = (jsonResponse['data'] is Map)
            ? jsonResponse['data'] as Map<String, dynamic>
            : {};

        final dynamic logsRaw =
            latestData['logs'] ?? latestData['log'] ?? widget.complaint['logs'];
        List<dynamic> logs = [];
        if (logsRaw is List) logs = logsRaw;

        if (logs.isEmpty) {
          logs.add({
            'status': _safeString(
              latestData['status'] ?? widget.complaint['status'],
            ),
            'description': _safeString(
              latestData['description'] ?? widget.complaint['description'],
            ),
            'created_at': _safeString(
              latestData['created_at'] ?? widget.complaint['created_at'],
            ),
          });
        }

        try {
          logs.sort((a, b) {
            final dateA = DateTime.tryParse(_safeString(a['created_at']));
            final dateB = DateTime.tryParse(_safeString(b['created_at']));
            if (dateA != null && dateB != null) {
              return dateA.compareTo(dateB);
            }
            return 0;
          });
        } catch (_) {}

        dynamic latestLog = logs.isNotEmpty ? logs.last : {};

        final String statusFromLatestLog = _safeString(
          latestLog != null
              ? latestLog['status'] ?? latestLog['status_name']
              : null,
        ).isNotEmpty
            ? _safeString(latestLog['status'] ?? latestLog['status_name'])
            : _safeString(
                latestData['status'] ??
                    latestData['latest_status'] ??
                    widget.complaint['status'],
              );

        final String statusDesc = _safeString(
          latestLog != null
              ? (latestLog['status_description'] ??
                  latestLog['description'] ??
                  latestLog['note'])
              : null,
        ).isNotEmpty
            ? _safeString(
                latestLog['status_description'] ??
                    latestLog['description'] ??
                    latestLog['note'],
              )
            : _safeString(
                latestData['description'] ?? widget.complaint['description'],
              );

        String updatedAt = _safeString(
          latestLog != null
              ? (latestLog['created_at'] ??
                  latestLog['updated_at'] ??
                  latestLog['tanggal'])
              : null,
        );
        if (updatedAt.isEmpty) {
          updatedAt = _safeString(
            latestData['updated_at'] ??
                latestData['tanggal'] ??
                latestData['submissionDate'] ??
                latestData['created_at'] ??
                widget.complaint['submissionDate'] ??
                widget.complaint['updated_at'],
          );
        }

        final dynamic catRaw =
            latestData['category'] ?? widget.complaint['category'];
        String categoryStr = '';
        if (catRaw != null) {
          if (catRaw is String)
            categoryStr = catRaw;
          else if (catRaw is Map) {
            categoryStr = _safeString(
              catRaw['category'] ??
                  catRaw['name'] ??
                  catRaw['title'] ??
                  catRaw['label'],
            );
          } else {
            categoryStr = catRaw.toString();
          }
        }

        final List<dynamic> rawPhotos = (latestData['photos'] is List)
            ? List<dynamic>.from(latestData['photos'])
            : ((widget.complaint['photos'] is List)
                ? List<dynamic>.from(widget.complaint['photos'])
                : []);

        final List<String> normalizedPhotos = rawPhotos
            .map((p) => _normalizePhotoItem(p))
            .where((s) => s.isNotEmpty)
            .map((s) {
          if (s.startsWith('http')) return s;
          final cleanedPath = s.startsWith('/') ? s.substring(1) : s;
          if (!cleanedPath.toLowerCase().startsWith('storage/')) {
            return '$_apiBaseUrl/storage/$cleanedPath';
          }
          return '$_apiBaseUrl/$cleanedPath';
        }).toList();

        if (mounted) {
          setState(() {
            _liveComplaintData = {
              ...widget.complaint,
              ...latestData,
              'status': statusFromLatestLog.isNotEmpty
                  ? statusFromLatestLog
                  : (_safeString(latestData['status']).isNotEmpty
                      ? _safeString(latestData['status'])
                      : _safeString(widget.complaint['status'])),
              'status_description': statusDesc,
              'updated_at': updatedAt,
              'category': categoryStr.isNotEmpty
                  ? categoryStr
                  : (_safeString(widget.complaint['category'])),
              'photos': normalizedPhotos,
              'logs': logs,
            };
            _isLoading = false;
          });
        }
      } else {
        throw Exception(
          'Gagal memuat detail laporan. status=${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.log('Fetch report details error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat status terbaru. Silakan coba lagi.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null || _liveComplaintData == null) {
      return Center(
        child: Text(_errorMessage ?? "Data laporan tidak tersedia."),
      );
    }

    final complaint = _liveComplaintData!;
    final String status = _safeString(complaint['status']).isNotEmpty
        ? _safeString(complaint['status'])
        : 'Terkirim';
    final int currentIndex = _getStatusIndex(status);
    final String category = _safeString(complaint['category']).isNotEmpty
        ? _safeString(complaint['category'])
        : 'Umum';

    final String reportId = _safeString(
      complaint['id'] ?? complaint['encrypted_id'] ?? 'N/A',
    );
    final String createdAtRaw = _safeString(complaint['created_at']);
    final String createdAt =
        createdAtRaw.isNotEmpty ? _formatDate(createdAtRaw) : '-';

    final String submitterName = _safeString(
      complaint['submitterName'] ??
          complaint['user']?['name'] ??
          complaint['user_name'],
    );
    final String submitterEmail = _safeString(
      complaint['submitterEmail'] ??
          complaint['user']?['email'] ??
          complaint['user_email'] ??
          'N/A',
    );

    final String location = _safeString(complaint['location']);
    final String description = _safeString(complaint['description']);
    final String locationDetail = _safeString(
      complaint['location_detail'] ?? complaint['locationDetail'],
    );
    final List<String> photos = (complaint['photos'] is List)
        ? List<String>.from(
            (complaint['photos'] as List).map((e) => _safeString(e)),
          )
        : [];

    final List<dynamic> logs = (complaint['logs'] is List)
        ? List<dynamic>.from(complaint['logs'])
        : [];

    final List<dynamic> logsToDisplay = logs.isNotEmpty
        ? logs
        : [
            {
              'status': status,
              'description': description,
              'created_at': createdAtRaw,
            },
          ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Laporan', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context, status),
        ),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportDetails,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPhotoSlider(photos),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // Meneruskan primaryColor
                child: _buildHeaderInfoCard(
                  reportId,
                  category,
                  createdAt,
                  primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // Meneruskan primaryColor
                child: _buildStatusTimelineCard(
                    status, currentIndex, primaryColor),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // Meneruskan primaryColor
                child: _buildReporterCard(
                    submitterName, submitterEmail, primaryColor),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLocationDetailCard(location, locationDetail),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildDescriptionCard(description),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // Meneruskan primaryColor
                child: _buildLogTimelineCard(logsToDisplay, primaryColor),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildHeaderInfoCard(
    String reportId,
    String category,
    String createdAt,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildHeaderItem(
              'ID Laporan',
              reportId,
              // MENGGANTI: _colorAccent dengan primaryColor
              textColor: primaryColor,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildHeaderItem(
              'Kategori',
              category,
              // MENGGANTI: _colorAccent dengan primaryColor
              textColor: primaryColor,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildHeaderItem(
              'Tanggal Laporan',
              createdAt,
              // MENGGANTI: _colorAccent dengan primaryColor
              textColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildStatusTimelineCard(
    String currentStatus,
    int currentIndex,
    Color primaryColor,
  ) {
    // MENGGANTI: Meneruskan primaryColor ke _getStatusColor
    final Color mainActiveColor = _getStatusColor(currentStatus, primaryColor);

    // Warna garis progress yang sudah dilewati
    final Color activeTrackColor = mainActiveColor.withOpacity(0.5);
    // Warna garis background/belum aktif
    const Color inactiveTrackColor = Color(
      0xFFE0E0E0,
    ); // Abu-abu terang untuk garis

    // Warna dot untuk status aktif
    final Color activeDotColor = mainActiveColor;
    // Warna dot untuk status belum aktif
    const Color inactiveDotColor = _colorGreyDotInactive;

    // Ketebalan garis
    const double trackHeight = 4.0;
    // Ukuran dot
    const double dotSize = 20.0;
    const double halfDot = dotSize / 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Baris Bulatan (Dot) dan Garis
          LayoutBuilder(
            builder: (context, constraints) {
              double totalTrackWidth = constraints.maxWidth - dotSize;
              double stepTrackWidth =
                  totalTrackWidth / (statusSteps.length - 1);
              double progressTrackWidth = stepTrackWidth * currentIndex;

              return SizedBox(
                height: dotSize,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Garis background abu-abu (penuh)
                    Positioned(
                      left: halfDot,
                      right: halfDot,
                      top: (dotSize - trackHeight) / 2,
                      child: Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: inactiveTrackColor,
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),
                    ),
                    // Garis progress (terisi)
                    Positioned(
                      left: halfDot,
                      top: (dotSize - trackHeight) / 2,
                      width: progressTrackWidth,
                      child: Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: activeTrackColor,
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                        ),
                      ),
                    ),

                    // Bulatan di setiap step
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(statusSteps.length, (index) {
                        bool isActiveStep = index <= currentIndex;
                        Color dotColor =
                            isActiveStep ? activeDotColor : inactiveDotColor;

                        return Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // 2. Baris Label Status CHIP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(statusSteps.length, (index) {
              final String status = statusSteps[index];
              final bool isCurrent = index == currentIndex;

              Color chipColor;
              Color textColor;

              if (isCurrent) {
                // Status aktif: gunakan warna aktif utama dengan opasitas
                chipColor = mainActiveColor.withOpacity(0.2);
                textColor = mainActiveColor;
              } else {
                // Status dilewati atau belum tercapai: abu-abu
                chipColor = _colorGreyChip;
                textColor = _colorGreyText;
              }

              // Jika status adalah "Selesai" dan sedang aktif,
              // pastikan warna sesuai primaryColor
              if (currentStatus.toLowerCase().contains('selesai') &&
                  isCurrent) {
                chipColor = primaryColor.withOpacity(0.2);
                textColor = primaryColor;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // 3. Teks Status Laporan Besar
          Center(
            child: Column(
              children: [
                Text(
                  'Status Laporan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStatus,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mainActiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhotoSlider(List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) => Image.network(
          photos[index],
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildReporterCard(String name, String email, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          // Nama Pengguna
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama Pengguna',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // MENGGANTI: _colorAccent dengan primaryColor
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // MENGGANTI: _colorAccent dengan primaryColor
                    color: primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailCard(String mainLocation, String detailLocation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi Laporan',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            mainLocation,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Detail Lokasi',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            detailLocation,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permasalahan',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 PERBAIKAN: Garis vertikal log status selalu abu-abu
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildLogTimelineCard(List<dynamic> logs, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...logs.asMap().entries.map((entry) {
            final int index = entry.key;
            final dynamic log = entry.value;

            final String status = _safeString(
              log['status'] ?? log['status_name'] ?? 'Status Tidak Diketahui',
            );
            final String dateRaw = _safeString(
              log['created_at'] ?? log['updated_at'] ?? log['tanggal'],
            );
            final String date = dateRaw.isNotEmpty ? _formatDate(dateRaw) : '-';
            final String description = _safeString(
              log['status_description'] ??
                  log['description'] ??
                  log['note'] ??
                  '',
            );

            // MENGGANTI: Meneruskan primaryColor ke _getStatusColor
            final Color logPrimaryColor = _getStatusColor(status, primaryColor);

            final bool isLast = index == logs.length - 1;

            // Garis vertikal tetap abu-abu (tidak berwarna)
            const Color verticalLineColor = Color(0xFFBDBDBD);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: logPrimaryColor, // Dot tetap sesuai warna status
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 100,
                        color:
                            verticalLineColor, // Garis vertikal sekarang abu-abu
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: logPrimaryColor,
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description.length > 300
                              ? "${description.substring(0, 300)}..."
                              : description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
