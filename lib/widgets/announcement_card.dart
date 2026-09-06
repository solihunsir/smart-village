import 'package:flutter/material.dart';
import '../pages/announcement_detail_page.dart';
import '../models/announcement_item.dart';
import '../config/api_config.dart';
import 'package:desaku/utils/app_logger.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementItem announcement;
  final String Function(String?) formatDate;
  final double width;
  final EdgeInsetsGeometry? margin;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    required this.formatDate,
    this.width = 200,
    this.margin,
  }) : super(key: key);

  String? _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Jika URL relatif, tambahkan base URL
    return ApiConfig.baseUrl +
        (imageUrl.startsWith('/') ? imageUrl : '/$imageUrl');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getFullImageUrl(announcement.image);

    return Container(
      width: width,
      margin: margin,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailPage(
                title: announcement.title,
                date: formatDate(announcement.date),
                location: announcement.location ?? '-',
                content: announcement.content ?? '-',
                imageUrl: announcement.image,
                author: announcement.author,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            AppLogger.log('Error loading image: $error');
                            AppLogger.log('Image URL: $imageUrl');
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFF4CAF50),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.photo_outlined,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content overlay
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(announcement.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
