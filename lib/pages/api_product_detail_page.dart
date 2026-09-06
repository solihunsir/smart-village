// File: api_product_detail_page.dart (KODE LENGKAP REVISI FINAL)

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/api_product.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../services/product_service.dart';
import './edit_product_page.dart';

class ApiProductDetailPage extends StatefulWidget {
  final ApiProduct product;
  const ApiProductDetailPage({Key? key, required this.product})
      : super(key: key);

  @override
  State<ApiProductDetailPage> createState() => _ApiProductDetailPageState();
}

class _ApiProductDetailPageState extends State<ApiProductDetailPage> {
  bool _isOwner = false;
  bool _isDeleting = false;
  late ApiProduct _currentProduct;

  int _currentImageIndex = 0;
  late PageController _pageController;

  // DIHAPUS: static const Color _whatsAppColor = Color(0xFF25D366);

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _pageController = PageController(initialPage: _currentImageIndex);
    _determineOwnership();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Utility Functions ---

  Future<void> _determineOwnership() async {
    try {
      final userData = await TokenService.getUserData();
      if (userData != null) {
        final Map<String, dynamic> parsed = userData.isNotEmpty
            ? (jsonDecodeSafe(userData) as Map<String, dynamic>)
            : {};
        final id = parsed['id'];
        if (id != null && id == widget.product.sellerId) {
          if (mounted) setState(() => _isOwner = true);
        }
      } else if (AuthService().isLoggedIn &&
          AuthService().currentUser != null) {
        if (AuthService().currentUser!.id == widget.product.sellerId) {
          if (mounted) setState(() => _isOwner = true);
        }
      }
    } catch (_) {}
  }

  dynamic jsonDecodeSafe(String s) {
    try {
      return s.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(s)) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _onDelete(Color primaryColor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isDeleting = true);
    final token = await TokenService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menghapus')),
      );
      if (mounted) setState(() => _isDeleting = false);
      return;
    }

    final ok = await ProductService.deleteProduct(
      token: token,
      productId: widget.product.id,
    );
    if (mounted) setState(() => _isDeleting = false);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Produk dihapus'),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus produk'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshProductDetail() async {
    try {
      final product = await ProductService.getProductById(_currentProduct.id);
      if (mounted && product != null) {
        setState(() {
          _currentProduct = product;
        });
      }
    } catch (e) {
      // AppLogger.log('Failed to refresh product detail: $e');
    }
  }

  void _launchWhatsApp() async {
    // Fungsi ini tidak perlu passing warna

    String contactNumber = _currentProduct.sellerContactNumber;

    if (contactNumber.isEmpty && _isOwner) {
      contactNumber = AuthService().currentUser?.phoneNumber ?? '';
    }

    if (contactNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nomor kontak penjual tidak tersedia di data produk. Penjual perlu memperbarui profil.',
            ),
          ),
        );
      }
      return;
    }

    String cleanedNumber = contactNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedNumber.startsWith('0')) {
      cleanedNumber = '62' + cleanedNumber.substring(1);
    } else if (cleanedNumber.startsWith('+62')) {
      cleanedNumber = cleanedNumber.substring(1);
    }

    if (!cleanedNumber.startsWith('62') || cleanedNumber.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Nomor HP penjual dalam format tidak valid (62xxxx).'),
          ),
        );
      }
      return;
    }

    final String formattedPrice = _currentProduct.formattedPrice;
    final message =
        "Halo, saya tertarik dengan produk Anda: ${_currentProduct.name} ($formattedPrice). Apakah masih tersedia?";

    final url = Uri.parse(
      "whatsapp://send?phone=$cleanedNumber&text=${Uri.encodeComponent(message)}",
    );

    final fallbackUrl = Uri.parse(
      "https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.platformDefault);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal membuka WhatsApp. Pastikan aplikasi terinstal.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan saat membuka WhatsApp: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  void _showImageZoomDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.8,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      value: null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.red,
                      size: 60,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widget Builders ---

  Widget _buildStatusBadge(bool isAvailable, Color primaryColor) {
    if (isAvailable) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            'TERJUAL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(ProductPhoto photo, int index, Color primaryColor) {
    final isSelected = index == _currentImageIndex;
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _currentImageIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.network(
            photo.photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image, size: 20, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag(
      String category, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImageIndicator(int totalImages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_currentImageIndex + 1}/$totalImages',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    IconData? icon,
    required Color primaryColor,
  }) {
    final cardBg = primaryColor.withOpacity(0.05);
    final cardBorder = primaryColor.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: primaryColor),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
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

  Widget _buildDetailItem({
    required String title,
    required String content,
    required bool showSeparator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Isi/Content
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (showSeparator)
          Column(
            children: const [
              Divider(height: 1, color: Colors.grey),
              SizedBox(height: 20),
            ],
          ),
      ],
    );
  }

  Widget _buildFooterInfo(String location, String condition) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KONDISI
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kondisi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    condition[0].toUpperCase() + condition.substring(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              // LOKASI
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Lokasi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final secondaryColor = themeProvider.secondaryColor;

    final p = _currentProduct;
    final List<String> allImageUrls =
        p.photos.map((ph) => ph.photoUrl).toList();
    if (allImageUrls.isEmpty && p.primaryImageUrl.isNotEmpty) {
      allImageUrls.add(p.primaryImageUrl);
    }

    final isAvailable = p.isAvailable;
    final categoryName = p.categoryName;
    final conditionText = p.conditionProduct;
    final locationText = p.location;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back, size: 20, color: primaryColor),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          p.seller?.name ?? '',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: _isOwner
            ? [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProductPage(product: p),
                      ),
                    );
                    if (changed == true) {
                      await _refreshProductDetail();
                      Navigator.pop(context, true);
                    }
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                  onPressed: _isDeleting ? null : () => _onDelete(primaryColor),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Photo View & Thumbnail ---
                  Container(
                    height: 360,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (allImageUrls.isNotEmpty) {
                              _showImageZoomDialog(
                                context,
                                allImageUrls[_currentImageIndex].isNotEmpty
                                    ? allImageUrls[_currentImageIndex]
                                    : 'https://via.placeholder.com/300',
                              );
                            }
                          },
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: allImageUrls.length,
                            onPageChanged: (index) {
                              if (mounted) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              }
                            },
                            itemBuilder: (context, index) {
                              final url = allImageUrls[index];
                              return Image.network(
                                url.isNotEmpty
                                    ? url
                                    : 'https://via.placeholder.com/300',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (p.photos.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: p.photos.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final photo = entry.value;
                                    return _buildThumbnail(
                                        photo, index, primaryColor);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildCategoryTag(
                              categoryName, primaryColor, secondaryColor),
                        ),
                        if (allImageUrls.length > 1)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: _buildImageIndicator(allImageUrls.length),
                          ),
                      ],
                    ),
                  ),

                  // --- 2. Info Utama (Harga, Judul, Status) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // 2A. Judul Produk
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // 2B. Harga
                        Row(
                          children: [
                            Text(
                              p.formattedPrice,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 2C. Status (Terjual)
                            if (!isAvailable)
                              const Text(
                                '(Terjual)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Garis pemisah
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // --- 3. Detail Item (Deskripsi, Lokasi Detail) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deskripsi
                        _buildDetailItem(
                          title: 'Deskripsi',
                          content: p.description,
                          showSeparator: true,
                        ),

                        // Lokasi Detail (Untuk detail spesifik jika ada)
                        _buildDetailItem(
                          title: 'Lokasi Detail',
                          content: p
                              .location, // Menggunakan lokasi sebagai contoh detail
                          showSeparator: true, // Garis pemisah
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // --- 4. Footer Info (Kondisi & Lokasi Sederhana) ---
                  _buildFooterInfo(locationText, conditionText),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // --- 5. Bottom Button (WhatsApp) ---
          if (isAvailable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _launchWhatsApp,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 22),
                    label: const Text(
                      'Hubungi di WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      // MODIFIKASI KRUSIAL: Menggunakan primaryColor untuk latar belakang
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
