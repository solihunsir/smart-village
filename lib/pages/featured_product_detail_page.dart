import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../config/api_config.dart';
// PASTIKAN BARIS INI ADA:
import '../models/featured_product.dart';
// PASTIKAN TIDAK ADA DEFINISI class FeaturedProduct { ... } DI SINI

class FeaturedProductDetailPage extends StatelessWidget {
  // Model FeatureProduct yang diterima sekarang berasal dari '../models/featured_product.dart'
  final FeaturedProduct product;

  const FeaturedProductDetailPage({
    super.key,
    required this.product,
  });

  // --- Helper Functions ---
  String _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final clean = url!.startsWith('/') ? url.substring(1) : url;
    if (clean.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$clean';
    }
    return '${ApiConfig.baseUrl}/storage/$clean';
  }

  String _stripHtmlTags(String htmlText) {
    if (htmlText.isEmpty) return '';
    final cleanText = htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[^;]+;'), ' ');

    return cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildHeaderImage(String? url) {
    final normalized = _normalizeImageUrl(url);
    if (normalized.isEmpty) {
      return _placeholderImage();
    }
    return Image.network(
      normalized,
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.shopping_bag, size: 60, color: Colors.grey),
      ),
    );
  }

  // --- Widget Build Utama ---
  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    // BARU: Menghitung warna latar belakang pill kategori yang lebih terang
    final lightPrimaryColor = Color.lerp(primaryColor, Colors.white, 0.7)!;

    final cleanDescription = _stripHtmlTags(product.description ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Produk',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Gambar Produk
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[300],
              child: _buildHeaderImage(product.image),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Kategori (Pill Hijau)
                  if (product.productCategory != null &&
                      product.productCategory!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // MENGGANTI: Warna hardcoded (0xFFE8F5E9) dengan lightPrimaryColor
                        color: lightPrimaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.productCategory!,
                        style: TextStyle(
                          fontSize: 12,
                          // MENGGANTI: Warna hardcoded (0xFF2E7D32) dengan primaryColor
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 3. Judul Produk
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Deskripsi Produk
                  Text(
                    cleanDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
