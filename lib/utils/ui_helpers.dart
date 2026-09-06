import 'package:flutter/material.dart';
import '../config/api_config.dart';

String formatDateShort(String? d) {
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
    final s = d;
    final idx = s.indexOf('T');
    if (idx > 0) return s.substring(0, idx);
    return s;
  }
}

Widget buildNetworkImageWithFallback(String? url, {
  List<Color>? colors,
  BoxFit? fit,
}) {
  final fallbackColors = colors ?? [Colors.grey[300]!, Colors.grey[400]!];
  String? normalized;
  if (url != null && url.isNotEmpty) {
    final u = url.trim();
    if (u.startsWith('http')) {
      normalized = u;
    } else if (u.startsWith('/storage')) {
      normalized = '${ApiConfig.baseUrl}$u';
    } else if (u.startsWith('storage')) {
      normalized = '${ApiConfig.baseUrl}/$u';
    } else {
      // Fallback: relative path like "settings/foo.png" or "news/bar.jpg"
      String path = u;
      while (path.startsWith('/')) {
        path = path.substring(1);
      }
      normalized = '${ApiConfig.baseUrl}/storage/$path';
    }
  }

  Widget buildPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fallbackColors,
        ),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white54)
            : const Icon(Icons.image, color: Colors.white, size: 32),
      ),
    );
  }

  if (normalized == null) {
    return buildPlaceholder();
  }

  return Image.network(
    normalized,
    fit: fit ?? BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return buildPlaceholder(isLoading: true);
    },
  );
}