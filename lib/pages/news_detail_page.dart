import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/news_service.dart';
import '../models/news_item.dart';

class NewsDetailPage extends StatefulWidget {
  final String slug;
  const NewsDetailPage({Key? key, required this.slug}) : super(key: key);

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

String _formatDateShort(String? d) {
  if (d == null) return '';
  try {
    final parsed = DateTime.parse(d);
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  } catch (_) {
    final s = d;
    final idx = s.indexOf('T');
    if (idx > 0) return s.substring(0, idx);
    return s;
  }
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  NewsItem? _news;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // <<< MODIFIKASI: Tambahkan helper function untuk membersihkan HTML
  String _stripHtmlTags(String htmlText) {
    if (htmlText.isEmpty) return '';
    final cleanText = htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '') // Hapus semua tag <...>
        .replaceAll(
          RegExp(r'&[^;]+;'),
          ' ',
        ); // Hapus HTML entities (e.g., &nbsp;)

    // Hapus spasi berlebihan dan trim
    return cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  // -----------------------------------------------------------

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await NewsService.detail(widget.slug);
      setState(() {
        _news = item;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat detail berita';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Berita'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null || _news == null)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Data tidak ditemukan'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadDetail,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: _buildHeaderImage(_news!.image),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _news!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDateShort(_news!.date ?? '-'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _news!.author ?? 'Admin Desa',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(height: 1, color: Colors.grey[300]),
                        const SizedBox(height: 24),
                        Text(
                          // <<< MODIFIKASI: Terapkan pembersihan HTML di sini
                          _stripHtmlTags(_news!.content ?? '-'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _buildHeaderImage(String? url) {
  final normalized = _normalizeImageUrl(url);
  if (normalized == null) {
    return _placeholderHeader();
  }
  return Image.network(
    normalized,
    width: double.infinity,
    height: 200,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stack) => _placeholderHeader(),
  );
}

String? _normalizeImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/storage')) return '${ApiConfig.baseUrl}$u';
  if (u.startsWith('storage')) return '${ApiConfig.baseUrl}/$u';
  // Fallback: treat as relative path under /storage
  String path = u;
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  return '${ApiConfig.baseUrl}/storage/$path';
}

Widget _placeholderHeader() {
  return Container(
    width: double.infinity,
    height: 200,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      ),
    ),
    child: const Center(
      child: Icon(Icons.article, size: 60, color: Colors.white),
    ),
  );
}
