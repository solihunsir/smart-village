import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../pages/news_detail_page.dart';
import '../pages/all_news_page.dart';
import '../utils/ui_helpers.dart';

class NewsSection extends StatelessWidget {
  final List<NewsItem> news;
  final bool isLoading;

  const NewsSection({
    super.key,
    required this.news,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final newsToShow = news.take(3).toList(); // Maksimal 3 berita

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllNewsPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 25),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320, // Tinggi disesuaikan karena konten terpisah
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : news.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada berita',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: newsToShow.length,
                      separatorBuilder: (context, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = newsToShow[index];
                        return NewsCard(item: item);
                      },
                    ),
        ),
      ],
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsItem item;

  const NewsCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(slug: item.slug),
          ),
        );
      },
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: buildNetworkImageWithFallback(
                  item.image,
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and date row
                    Row(
                      children: [
                        // Source chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.author ?? 'RCTI News',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Date
                        if (item.date != null)
                          Text(
                            formatDateShort(item.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    if (item.content?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          item.content!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}