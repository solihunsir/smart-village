// File: lib/pages/indicator_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/category_model.dart';
import '../services/indicator_service.dart';
import 'variable_category_page.dart'; // Import halaman variabel baru

class IndicatorPage extends StatefulWidget {
  const IndicatorPage({super.key});

  @override
  State<IndicatorPage> createState() => _IndicatorPageState();
}

class _IndicatorPageState extends State<IndicatorPage> {
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  String? _errorLoadingCategories;

  // Mapping sederhana dari nama kategori ke ikon path
  final Map<String, String> _iconMap = {
    'penduduk': 'assets/images/penduduk.png',
    'demografi': 'assets/images/penduduk.aid.png',
    'pendidikan': 'assets/images/pendidikan.png',
    'pekerjaan': 'assets/images/pekerjaan.png',
    'kesehatan': 'assets/images/kesehatan.png',
  };

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _errorLoadingCategories = null;
    });
    try {
      final categories = await IndicatorService.getIndicatorCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingCategories = e.toString().replaceAll('Exception: ', '');
          _isLoadingCategories = false;
        });
      }
    }
  }

  // Helper untuk mendapatkan Icon Data Fallback
  IconData _getFallbackIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('penduduk') || lowerName.contains('demografi'))
      return Icons.groups;
    if (lowerName.contains('pendidikan')) return Icons.school_outlined;
    if (lowerName.contains('pekerjaan') || lowerName.contains('ekonomi'))
      return Icons.business_center_outlined;
    if (lowerName.contains('kesehatan')) return Icons.favorite_border;
    return Icons.category_outlined;
  }

  // Helper untuk mendapatkan path gambar
  String _getIconPath(String name) {
    final lowerName = name.toLowerCase();
    for (final key in _iconMap.keys) {
      if (lowerName.contains(key)) {
        return _iconMap[key]!;
      }
    }
    return ''; // Mengembalikan string kosong jika tidak ditemukan
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // MENGGANTI: Warna ikon hardcoded
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Indikator Desa',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(primaryColor), // Meneruskan primaryColor
            const SizedBox(height: 16),
            _buildCategoryList(primaryColor), // Meneruskan primaryColor
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(Color primaryColor) {
    if (_isLoadingCategories) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        // MENGGANTI: Warna loading hardcoded
        child: CircularProgressIndicator(color: primaryColor),
      ));
    }

    if (_errorLoadingCategories != null) {
      return Center(
        child: Column(
          children: [
            Text(
              'Gagal memuat kategori: $_errorLoadingCategories',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: primaryColor), // MENGGANTI: Warna teks error
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // MENGGANTI: Warna tombol
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Muat Ulang Kategori'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('Tidak ada kategori indikator yang tersedia.'),
      ));
    }

    return Column(
      children: _categories
          .expand((category) => [
                _buildIndicatorCard(
                  context,
                  primaryColor: primaryColor, // Meneruskan primaryColor
                  iconPath: _getIconPath(category.name),
                  label: category.name,
                  fallbackIcon: _getFallbackIcon(category.name),
                  onTap: () {
                    // MODIFIKASI ALUR: Pindah ke VariableCategoryPage (Tahap 2)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VariableCategoryPage(
                          categoryTitle: category.name,
                          categoryId: category.id,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ])
          .toList(),
    );
  }

  Widget _buildInfoBox(Color primaryColor) {
    // Menghitung warna turunan dari primaryColor untuk Info Box
    final lightPrimaryBg =
        Color.lerp(primaryColor, Colors.white, 0.8)!; // Latar belakang ringan
    final lightPrimaryBorder =
        Color.lerp(primaryColor, Colors.white, 0.5)!; // Border lebih gelap

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // MENGGANTI: Warna latar belakang hardcoded
        color: lightPrimaryBg,
        borderRadius: BorderRadius.circular(8),
        // MENGGANTI: Warna border hardcoded
        border: Border.all(color: lightPrimaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            // MENGGANTI: Warna ikon hardcoded
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        'Gunakan Layanan Indikator Desa dengan bijak dan benar.\n',
                    style: TextStyle(
                      fontSize: 12,
                      // MENGGANTI: Warna teks hardcoded
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Indikator Desa tidak bersifat tetap, bisa berubah kapan saja.',
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor, // MENGGANTI: Warna teks hardcoded
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(
    BuildContext context, {
    required Color primaryColor,
    required String iconPath,
    required String label,
    required IconData fallbackIcon,
    VoidCallback? onTap,
  }) {
    // Menghitung warna turunan untuk Card
    final iconBgColor = Color.lerp(primaryColor, Colors.white, 0.8)!;
    final cardBorderColor = Colors.grey.shade300;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            // MENGGANTI: Warna border hardcoded
            border: Border.all(color: cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  // MENGGANTI: Warna latar belakang ikon hardcoded
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: iconPath.isNotEmpty
                    ? Image.asset(
                        iconPath,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            fallbackIcon,
                            size: 24,
                            color:
                                primaryColor, // MENGGANTI: Warna ikon hardcoded
                          );
                        },
                      )
                    : Icon(
                        fallbackIcon,
                        size: 24,
                        color: primaryColor, // MENGGANTI: Warna ikon hardcoded
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              // MENGGANTI: Warna ikon chevron hardcoded
              Icon(
                Icons.chevron_right,
                size: 20,
                color: primaryColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
