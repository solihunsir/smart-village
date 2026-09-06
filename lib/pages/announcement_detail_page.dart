import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../config/api_config.dart';

// --- FUNGSI HELPER: Membersihkan HTML ---
String _stripHtmlTags(String htmlText) {
  if (htmlText.isEmpty) return '';
  final cleanText = htmlText
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'&[^;]+;'), ' ');

  return cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
}
// ----------------------------------------

class AnnouncementDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final String? location;
  final String? imageUrl;
  final String content;
  final String? author;
  const AnnouncementDetailPage({
    Key? key,
    required this.title,
    required this.date,
    this.location,
    this.imageUrl,
    required this.content,
    this.author,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: _buildFullImage(imageUrl),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateShort(date),
                    style: TextStyle(
                      // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (author != null && author!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Text(
                        author!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  // FIX: Menerapkan _stripHtmlTags pada content
                  Text(
                    _stripHtmlTags(content),
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final s = d!;
    final idx = s.indexOf('T');
    if (idx > 0) return s.substring(0, idx);
    return s;
  }
}

String _normalizeImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('/storage')) return '${ApiConfig.baseUrl}$u';
  if (u.startsWith('storage')) return '${ApiConfig.baseUrl}/$u';
  var path = u;
  while (path.startsWith('/')) path = path.substring(1);
  return '${ApiConfig.baseUrl}/storage/$path';
}

Widget _buildFullImage(String? url) {
  final n = _normalizeImageUrl(url);
  if (n.isEmpty) return _placeholderImage();
  return Image.network(
    n,
    width: double.infinity,
    fit: BoxFit.fitWidth,
    errorBuilder: (context, error, stack) => _placeholderImage(),
  );
}

Widget _placeholderImage() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32),
    color: Colors.grey[200],
    child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
  );
}
