import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../pages/featured_products_list_page.dart';
import '../pages/destinations_list_page.dart';
import '../pages/resources_list_page.dart';

class PusatDesaSection extends StatelessWidget {
  const PusatDesaSection({super.key});

  Widget _tile(
    BuildContext context,
    String
        primaryAsset, // Ikon LAMA (unggulan, destinasi, sumber) - Ikon UTAMA JELAS
    String
        backgroundAsset, // Ikon BARU (produk2, destinasi2, sumber2) - Ikon LATAR BELAKANG SAMAR
    String label,
    VoidCallback onTap,
    Color primaryColor,
  ) {
    // WARNA
    final primaryIconColor = primaryColor;
    final backgroundIconColor = Colors.grey.withOpacity(0.12);
    final tileBackgroundColor = Colors.white;

    // Tentukan ketinggian minimum (misalnya 155.0) yang cukup untuk konten 3 baris teks
    // dan memastikan semua tile memiliki tinggi yang sama.
    const double tileHeight = 155.0; // Nilai ini dapat disesuaikan

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Set tinggi Container agar semua tile memiliki tinggi yang sama
          height: tileHeight,
          // PERBAIKAN OVERFLOW: Mengurangi margin horizontal dari 8 menjadi 6.
          // Total margin horizontal yang digunakan di Row: (6*2) * 3 tiles = 36.
          // Sebelumnya: (8*2) * 3 tiles = 48. Ini yang menyebabkan overflow.
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: tileBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Icon Latar Belakang (BARU - Samar/Besar)
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    backgroundAsset,
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      backgroundIconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              // 2. Konten Utama (Icon JELAS & Teks)
              // Menggunakan Align dan Padding untuk memposisikan konten utama
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Biarkan Column hanya setinggi isinya
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Spasi di atas ikon utama
                      const SizedBox(height: 10),

                      // Container Ikon Utama (LAMA - Jelas)
                      Container(
                        width: 56,
                        height: 56,
                        color: Colors.transparent,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: SvgPicture.asset(
                            primaryAsset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              primaryIconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      // Spasi antara ikon dan teks
                      const SizedBox(height: 8),

                      // Label text
                      // PERBAIKAN ERROR CONST: Hapus kata kunci 'const' karena menggunakan variabel 'label'
                      SizedBox(
                        // Tinggi 48.0 cukup untuk 3 baris teks dengan fontSize 13 dan height 1.2
                        height: 48.0,
                        child: Text(
                          label,
                          style: const TextStyle(
                            // TextStyle bisa tetap const
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          // Pastikan teks hanya memakan 3 baris maksimum
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Ikon panah (Positioned at bottom right)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider untuk mendapatkan primaryColor
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return Padding(
      // PERBAIKAN OVERFLOW: Mengubah padding horizontal dari 8.0 menjadi 6.0
      // Padding luar 6 + margin dalam 6 = 12. Jadi total lebar luar (12+12) = 24.
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tile(
            context,
            'assets/images/unggulan.svg',
            'assets/images/produk2.svg',
            'Produk\nUnggulan',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FeaturedProductsListPage()),
              );
            },
            primaryColor,
          ),
          _tile(
            context,
            'assets/images/destinasi.svg',
            'assets/images/destinasi2.svg',
            'Destinasi\nWisata',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DestinationsListPage()),
              );
            },
            primaryColor,
          ),
          _tile(
            context,
            'assets/images/sumber.svg',
            'assets/images/sumber2.svg',
            'Sumber Daya\nAlam',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResourcesListPage()),
              );
            },
            primaryColor,
          ),
        ],
      ),
    );
  }
}
