import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/destination_service.dart';
import '../config/api_config.dart'; // Digunakan untuk baseUrl gambar

class DestinationDetailPage extends StatefulWidget {
  final int destinationId;

  const DestinationDetailPage({Key? key, required this.destinationId})
      : super(key: key);

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  // Ganti dengan API Key Anda yang sudah disediakan (Ditempatkan di sini)
  static const String _mapApiKey =
      'AIzaSyDipz2WwRtfxHxZF-TWM7dOg10L7_wOySA'; // PASTIKAN KEY INI AKTIF

  Map<String, dynamic>? _destinationData;
  bool _loading = true;
  String? _error;

  // Variabel untuk menyimpan Koordinat Peta (jika API menyediakannya)
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await DestinationService.getDetail(widget.destinationId);
      setState(() {
        _destinationData = data;
        // Mencoba ekstraksi koordinat dari data API
        _latitude =
            data['latitude'] is num ? data['latitude'].toDouble() : null;
        _longitude =
            data['longitude'] is num ? data['longitude'].toDouble() : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _getFullImageUrl(String? partialUrl) {
    if (partialUrl == null || partialUrl.isEmpty) return '';
    if (partialUrl.startsWith('http')) return partialUrl;
    return '${ApiConfig.baseUrl}$partialUrl';
  }

  Future<void> _launchMapsUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka lokasi peta.')),
      );
    }
  }

  // --- FUNGSI MODIFIKASI: Mendapatkan URL Static Map (Menggunakan Fallback Koordinat) ---
  String? _getStaticMapImageUrl(
      String? mapsUrl, double width, double height, double? lat, double? lon) {
    String? finalLat;
    String? finalLon;
    String zoom = '15'; // Default zoom

    // 1. Coba ekstraksi koordinat dari URL peta (prioritas utama)
    if (mapsUrl != null) {
      final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+),(\d+z)');
      final match = regex.firstMatch(mapsUrl);
      if (match != null) {
        finalLat = match.group(1);
        finalLon = match.group(2);
        zoom = match.group(3)?.replaceAll('z', '') ?? zoom;
      }
    }

    // 2. Fallback: Gunakan koordinat dari data API jika ekstraksi URL gagal
    if (finalLat == null && lat != null && lon != null) {
      finalLat = lat.toString();
      finalLon = lon.toString();
    }

    // Jika koordinat ditemukan (baik dari URL atau Fallback API Data)
    if (finalLat != null && finalLon != null) {
      final size = '${width.toInt()}x${height.toInt()}';

      // Membangun URL Statis dengan API Key
      return 'https://maps.googleapis.com/maps/api/staticmap'
          '?center=$finalLat,$finalLon'
          '&zoom=$zoom'
          '&size=$size'
          '&markers=color:red%7Csize:mid%7C$finalLat,$finalLon'
          '&sensor=false'
          '&key=$_mapApiKey'; // API Key wajib
    }
    return null;
  }
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final destination = _destinationData;
    final String fullImageUrl = _getFullImageUrl(destination?['photo_url']);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : (destination == null
                  ? _buildNotFoundState()
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 250.0,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              destination['name'] ?? 'Detail Destinasi',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                shadows: [
                                  Shadow(
                                      blurRadius: 3.0, color: Colors.black54),
                                ],
                              ),
                            ),
                            background: fullImageUrl.isNotEmpty
                                ? Image.network(
                                    fullImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(color: Colors.grey[300]),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate([
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Deskripsi',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    destination['description'] ??
                                        'Deskripsi tidak tersedia.',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Divider(height: 32),
                                  const Text(
                                    'Lokasi',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMapsSection(
                                    destination['url_maps'],
                                    _latitude,
                                    _longitude,
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ],
                    )),
    );
  }

  // --- MODIFIKASI: Implementasi Map Section menggunakan Static Map URL yang diperbaiki ---
  Widget _buildMapsSection(String? url, double? lat, double? lon) {
    final hasMapUrl = url != null && url.isNotEmpty;
    // hasCoords sekarang hanya digunakan untuk tampilan placeholder, logic utama di _getStaticMapImageUrl
    final hasCoords = lat != null && lon != null;

    const double mapHeight = 250;

    // Panggil fungsi yang sudah diperbaiki, memberikan data koordinat sebagai fallback
    final staticMapUrl = _getStaticMapImageUrl(
        url, MediaQuery.of(context).size.width - 32, mapHeight, lat, lon);

    final canShowStaticMap = staticMapUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: mapHeight,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: canShowStaticMap
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    staticMapUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    // Jika gambar statis gagal dimuat (ini mungkin karena API Key bermasalah atau Pembatasan Geo-lokasi)
                    errorBuilder: (context, error, stackTrace) {
                      // Jika gagal memuat static map, coba tampilkan placeholder koordinat
                      return Center(
                          child: hasCoords
                              ? _buildInteractiveMapPlaceholder(lat!, lon!)
                              : _buildMapErrorPlaceholder());
                    },
                  ),
                )
              // Jika Static Map URL TIDAK BISA dibuat dari data manapun
              : hasCoords
                  ? _buildInteractiveMapPlaceholder(lat!, lon!)
                  : _buildMapErrorPlaceholder(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: hasMapUrl ? () => _launchMapsUrl(url) : null,
          icon: const Icon(Icons.pin_drop),
          label: const Text('Buka di Google Maps Eksternal'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  // --- Widget Tambahan (Tidak Ada Perubahan, hanya untuk referensi) ---
  Widget _buildMapErrorPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_off, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Peta internal tidak tersedia.',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInteractiveMapPlaceholder(double lat, double lon) {
    // Placeholder untuk kasus koordinat tersedia tapi belum ada package GoogleMap
    return Container(
        color: Colors.blueGrey[50],
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.map, size: 50, color: Colors.blue),
          const SizedBox(height: 8),
          const Text('Peta Interaktif (PLACEHOLDER)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Lat: $lat, Lon: $lon'),
          const Text('Instal google_maps_flutter untuk implementasi penuh.')
        ])));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadDetail,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Destinasi tidak ditemukan',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
