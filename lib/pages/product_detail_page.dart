import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desaku/utils/app_logger.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/user1.png'),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            Text(
              product.seller,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product Images Section
          Container(
            height: 300,
            child: Stack(
              children: [
                // Main product image
                Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[200],
                  child: product.image.isNotEmpty
                      ? Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Thumbnail images at bottom
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 60,
                    child: Row(
                      children: List.generate(4, (index) {
                        return Container(
                          width: 60,
                          height: 60,
                          margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: product.image.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    product.image,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Info Section
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and year
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Text(
                          'Rp${_formatPrice(product.price)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '(Terjual)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 16),
                    // Description Section
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.description.isNotEmpty
                          ? product.description
                          : _getDefaultDescription(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 16),

                    // Location Section
                    const Text(
                      'Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.location.isNotEmpty
                          ? product.location
                          : 'Desa Tanjungjaya',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Condition label
                Text(
                  product.condition.isNotEmpty ? product.condition : 'Bekas',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // WhatsApp button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(product.contactWhatsApp),
                    icon: const Icon(
                      Icons.chat_bubble,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Hubungi di WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF25D366,
                      ), // WhatsApp green
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)}M';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(0)}.${((price % 1000000) / 100000).toInt()}00.000';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}.000';
    }
    return price.toStringAsFixed(0);
  }

  String _getDefaultDescription() {
    return '''BMW F30 320i
PAJAK HIDUP
STNK TERIMA BERSIH
MESIN ISTIMEWA ✅
INTERIOR TERAWAT
EXTERIOR MULUS ✅
AC Dingin
FULL ORIGINAL

Spesifikasi:
- Engine: 2.0L TwinPower Turbo
- Transmission: 8-Speed Automatic
- Exterior Color: Mineral Grey Metallic
- Interior: Black Dakota Leather
- Mileage: 45,000 km
- Service Record: Complete BMW Authorized Service
- Features: iDrive, Xenon Headlights, Sunroof, Premium Sound System

MINAT LANGSUNG TELP/WA 
SERIOUS BUYER ONLY''';
  }

  void _launchWhatsApp(String phoneNumber) async {
    final String phone = phoneNumber.isNotEmpty ? phoneNumber : '6281234567890';
    final Uri url = Uri.parse('https://wa.me/$phone');
    try {
      await launchUrl(url);
    } catch (e) {
      AppLogger.log('Could not launch $url: $e');
    }
  }
}
