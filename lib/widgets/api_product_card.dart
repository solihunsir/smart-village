// lib/widgets/api_product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/api_product.dart';

class ApiProductCard extends StatelessWidget {
  final ApiProduct product;
  final Function() onTap;

  const ApiProductCard({Key? key, required this.product, required this.onTap})
      : super(key: key);

  String _getFormattedPrice(double price) {
    final formatter = NumberFormat("#,###", "id_ID");
    return 'Rp ${formatter.format(price.round())}';
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil primaryColor dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    String imageUrl = product.primaryImageUrl.isNotEmpty
        ? product.primaryImageUrl
        : 'https://via.placeholder.com/150';
    String formattedPrice = _getFormattedPrice(product.priceAsDouble);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // gambar produk (dibuat lebih ringkas: 1.15)
            AspectRatio(
              aspectRatio: 1.15, // Disesuaikan dari 1.2
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 40)),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                                // MENGGANTI: Warna hardcoded dengan primaryColor
                                color: primaryColor),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          // MENGGANTI: Warna hardcoded dengan primaryColor
                          color: primaryColor,
                          shape: BoxShape.circle),
                      child: const Icon(
                          Icons.arrow_forward_ios, // MENGGANTI: Ikon panah
                          color: Colors.white,
                          size: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              // Padding sedikit diubah agar lebih nyaman dilihat
              padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formattedPrice,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Ukuran font tetap kecil
                          // MENGGANTI: Warna hardcoded dengan primaryColor
                          color: primaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4), // Jarak sedikit ditambah
                  Text(product.name,
                      style: TextStyle(
                          fontSize: 13, // Ukuran font tetap kecil
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
