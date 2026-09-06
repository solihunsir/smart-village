import 'package:flutter/material.dart';
import '../pages/all_announcements_page.dart';
import '../models/announcement_item.dart';
import './announcement_card.dart';

class AnnouncementSection extends StatelessWidget {
  final List<AnnouncementItem> announcements;
  final bool isLoading;
  final String Function(String?) formatDate;
  final String title;
  final Widget? viewAllDestination;

  const AnnouncementSection({
    Key? key,
    required this.announcements,
    required this.isLoading,
    required this.formatDate,
    this.title = 'Pengumuman Terbaru',
    this.viewAllDestination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (viewAllDestination != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => viewAllDestination!,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllAnnouncementsPage(),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 25),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180, // Mengurangi tinggi container
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                )
              : announcements.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada pengumuman',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: announcements.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: i != announcements.length - 1 ? 8 : 0,
                          ),
                          child: AnnouncementCard(
                            announcement: announcements[i],
                            formatDate: formatDate,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}