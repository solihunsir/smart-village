// File: lib/pages/variable_category_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/annual_category_data.dart'; // Untuk VariableCategory
import '../services/indicator_service.dart';
import 'indicator_detail_page.dart'; // Ke tahap 3

class VariableCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryTitle;

  const VariableCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<VariableCategoryPage> createState() => _VariableCategoryPageState();
}

class _VariableCategoryPageState extends State<VariableCategoryPage> {
  List<VariableCategory> _variables = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVariables();
  }

  Future<void> _fetchVariables() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final variables = await IndicatorService.getVariableCategories(
        categoryId: widget.categoryId,
      );
      if (mounted) {
        setState(() {
          _variables = variables;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // Widget untuk Kotak Informasi (sama dengan di IndicatorPage)
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

  Widget _buildVariableCard(
    BuildContext context, {
    required String label,
    required VoidCallback? onTap,
    required Color primaryColor, // BARU: Menerima primaryColor
  }) {
    // Menghitung warna turunan untuk Card
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
        title: Text(
          'Variabel Kategori',
          style: const TextStyle(
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

            if (_isLoading)
              Center(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                // MENGGANTI: Warna loading hardcoded
                child: CircularProgressIndicator(color: primaryColor),
              ))
            else if (_errorMessage != null)
              Center(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text(
                      'Error memuat variabel: $_errorMessage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: primaryColor), // MENGGANTI: Warna teks error
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchVariables,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor, // MENGGANTI: Warna tombol
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Muat Ulang'),
                    ),
                  ],
                ),
              ))
            else if (_variables.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Tidak ada variabel tersedia untuk kategori ini.'),
              ))
            else
              Column(
                children: _variables
                    .expand((variable) => [
                          _buildVariableCard(
                            context,
                            label: variable.name,
                            primaryColor:
                                primaryColor, // Meneruskan primaryColor
                            onTap: () {
                              // Pindah ke Halaman Detail Data (Tahap 3)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      IndicatorDetailPage.fromVariable(
                                    categoryTitle: widget.categoryTitle,
                                    variableName: variable.name,
                                    categoryId: widget.categoryId,
                                    variableCategoryId: variable.id,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ])
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
