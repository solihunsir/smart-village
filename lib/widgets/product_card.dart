import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:desaku/utils/app_logger.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function() onTap;
  const ProductCard({Key? key, required this.product, required this.onTap})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppLogger.log('ProductCard GestureDetector onTap called');
        onTap();
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: product.image.isNotEmpty
                      ? Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp${_formatPrice(product.price)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 8,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: CustomPaint(
                painter: WarningTapePainter(),
                size: const Size(double.infinity, 8),
              ),
            ),
          ],
        ),
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
}

class WarningTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint yellowPaint = Paint()..color = const Color(0xFFFFD700);
    final Paint blackPaint = Paint()..color = Colors.black;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), yellowPaint);

    const double stripeWidth = 12.0;

    for (double i = -size.height;
        i < size.width + size.height;
        i += stripeWidth * 2) {
      final path = Path();
      path.moveTo(i, 0);
      path.lineTo(i + stripeWidth, 0);
      path.lineTo(i + stripeWidth + size.height, size.height);
      path.lineTo(i + size.height, size.height);
      path.close();

      canvas.drawPath(path, blackPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
