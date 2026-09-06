// lib/pages/resource_detail_page.dart (KODE LENGKAP DENGAN PERBAIKAN PETA)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/resource_service.dart';
import '../config/api_config.dart';

// --- API KEY Google Static Maps Anda ---
const String _kGoogleStaticMapsApiKey =
    'AIzaSyDipz2WwRtfxHxZF-TWM7dOg10L7_wOySA';

class ResourceDetailPage extends StatefulWidget {
  final int resourceId;

  const ResourceDetailPage({Key? key, required this.resourceId})
      : super(key: key);

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  Map<String, dynamic>? _resourceData;
  bool _loading = true;
  String? _error;

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
      final data = await ResourceService.getDetail(widget.resourceId);
      setState(() {
        _resourceData = data;
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

  // --- FUNGSI Konversi URL Google Maps menjadi URL Gambar Statis ---
  String? _getStaticMapImageUrl(String mapsUrl, double width, double height) {
    // ⚠️ KODE DEBUGGING SEMENTARA ⚠️
    // Gunakan URL dummy yang valid untuk menguji apakah masalahnya pada Regex.
    // Jika peta muncul dengan kode ini, masalahnya pasti di format mapsUrl dari API Anda.
    const dummyMapsUrl = 'https://www.google.com/maps/@-6.2088,106.8456,12z';

    // Gunakan mapsUrl asli jika dummy di atas dihapus.
    String urlToParse = mapsUrl;

    // Regex mencari koordinat dan zoom level dari URL Google Maps
    // Mendukung format umum: @<lat>,<lon>,<zoom>z
    final regex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+),(\d+z)');
    final match = regex.firstMatch(urlToParse);

    if (match != null) {
      final lat = match.group(1);
      final lon = match.group(2);
      final zoom = match.group(3)?.replaceAll('z', '');

      final size = '${width.toInt()}x${height.toInt()}';

      String staticUrl = 'https://maps.googleapis.com/maps/api/staticmap'
          '?center=$lat,$lon'
          '&zoom=$zoom'
          '&size=$size'
          '&markers=color:red%7Csize:mid%7C$lat,$lon'
          '&sensor=false';

      // Menambahkan API Key
      staticUrl += '&key=$_kGoogleStaticMapsApiKey';

      return staticUrl;
    }
    // Hapus baris di bawah jika Anda ingin menguji dengan URL dummy
    return null;
    // GANTI return null; dengan return _getStaticMapImageUrl(dummyMapsUrl, width, height);
    // jika Anda ingin menguji dengan URL dummy yang valid (contoh Jakarta)
  }
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final resource = _resourceData;
    final String fullImageUrl = _getFullImageUrl(resource?['photo_url']);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : (resource == null
                  ? _buildNotFoundState()
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 250.0,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              resource['name'] ?? 'Detail Sumber Daya',
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
                                    resource['description'] ??
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
                                    resource['url_maps'],
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

  // --- Implementasi Map Section dengan Static Image ---
  Widget _buildMapsSection(String? url, double? lat, double? lon) {
    final hasMapUrl = url != null && url.isNotEmpty;
    final hasCoords = lat != null && lon != null;

    const double mapHeight = 250;
    final staticMapWidth = MediaQuery.of(context).size.width - 32;

    // Mencoba membuat URL gambar statis menggunakan API Key
    final staticMapUrl = hasMapUrl
        ? _getStaticMapImageUrl(url, staticMapWidth, mapHeight)
        : null;

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
              ? Image.network(
                  staticMapUrl!,
                  fit: BoxFit.cover,
                  // Jika gambar statis gagal dimuat
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: hasCoords
                        ? _buildInteractiveMapPlaceholder(lat!, lon!)
                        : _buildMapErrorPlaceholder(),
                  ),
                )
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

  // --- Widget Tambahan ---
  Widget _buildMapErrorPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_off, size: 40, color: Colors.red),
        SizedBox(height: 8),
        Text('Gagal memuat peta statis.',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInteractiveMapPlaceholder(double lat, double lon) {
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
            'Sumber daya alam tidak ditemukan',
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
