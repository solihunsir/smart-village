import 'package:flutter/material.dart';

class RoundedTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final void Function()? onTap;
  final double borderRadius;
  final List<Color> fallbackColors;

  const RoundedTile({
    Key? key,
    required this.title,
    this.imageUrl,
    this.onTap,
    this.borderRadius = 16,
    this.fallbackColors = const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
  }) : super(key: key);

  String _normalize(String? u, String baseUrl) {
    if (u == null || u.isEmpty) return '';
    final s = u.trim();
    if (s.startsWith('http')) return s;
    if (s.startsWith('/storage')) return '$baseUrl$s';
    if (s.startsWith('storage')) return '$baseUrl/$s';
    var p = s;
    while (p.startsWith('/')) p = p.substring(1);
    return '$baseUrl/storage/$p';
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = '';
    final normalized = _normalize(imageUrl, baseUrl);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (normalized.isNotEmpty)
                Image.network(
                  normalized,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: fallbackColors),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: fallbackColors),
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
