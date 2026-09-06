// lib/pages/notification_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/post.dart';
// NOTE: Kita perlu import model user untuk User model dummy
import '../models/user.dart' as model_user;
import '../models/activity.dart'; // <<< PENTING: Model Aktivitas
import '../config/api_config.dart';
import '../services/post_service.dart';

// Enum yang digunakan untuk mengelompokkan tampilan notifikasi
enum DisplayType { likeGroup, comment, commentReply }

// Struktur baru untuk menampung item yang akan ditampilkan di list
class DisplayNotificationItem {
  final DisplayType type;
  final Post post;
  final List<ActivityItem> activityList; // Berisi 1 Comment atau List of Likes

  DisplayNotificationItem({
    required this.type,
    required this.post,
    required this.activityList,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DisplayNotificationItem> _displayItems = [];
  bool _isLoadingReplies = true;

  List<Post> _bookmarkedPosts = [];
  bool _isLoadingBookmarks = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchActivity();
    _fetchBookmarks();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 0 &&
        _displayItems.isEmpty &&
        !_isLoadingReplies) {
      _fetchActivity();
    } else if (_tabController.index == 1 &&
        _bookmarkedPosts.isEmpty &&
        !_isLoadingBookmarks) {
      _fetchBookmarks();
    }
    setState(() {});
  }

  // --- FUNGSI UTAMA: MENGAMBIL DAN MENGELOMPOKKAN AKTIVITAS ---
  Future<void> _fetchActivity() async {
    setState(() {
      _isLoadingReplies = true;
    });

    try {
      final myPostsSummary = await PostService.fetchMyPostsActivitySummary();
      List<DisplayNotificationItem> finalDisplayList = [];

      for (var postSummary in myPostsSummary) {
        final activities = await PostService.fetchPostActivityDetail(
          postSummary.id,
        );
        if (activities.isEmpty) continue;

        // 1. Sortir: Urutkan berdasarkan waktu terbaru
        activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // 2. Kelompokkan Like pada postingan yang sama
        List<ActivityItem> likes =
            activities.where((a) => a.type == ActivityType.like).toList();

        if (likes.isNotEmpty) {
          // Buat satu item notifikasi untuk semua like pada postingan ini
          finalDisplayList.add(
            DisplayNotificationItem(
              type: DisplayType.likeGroup,
              post: postSummary,
              activityList: likes, // Semua likers
            ),
          );
        }

        // 3. Tambahkan Komentar (setiap komentar adalah item terpisah)
        List<ActivityItem> comments =
            activities.where((a) => a.type == ActivityType.comment).toList();
        for (var comment in comments) {
          finalDisplayList.add(
            DisplayNotificationItem(
              type: DisplayType.comment,
              post: postSummary,
              activityList: [comment], // Hanya satu komentar
            ),
          );
        }
      }

      // 4. Sortir Ulang List Akhir berdasarkan waktu aktivitas paling baru
      finalDisplayList.sort(
        (a, b) => b.activityList.first.createdAt.compareTo(
          a.activityList.first.createdAt,
        ),
      );

      if (mounted) {
        setState(() {
          _displayItems = finalDisplayList;
          _isLoadingReplies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReplies = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat aktivitas postingan: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // --- FUNGSI DUMMY USER UNTUK FALLBACK ---
  model_user.User _getDummyUser() {
    return model_user.User(
      id: 0,
      name: 'Pengguna Dihapus',
      email: 'deleted@app.com',
      status: 'deleted',
      verificationStatus: 'unverified',
      createdAt: '',
      updatedAt: '',
    );
  }

  Future<void> _fetchBookmarks() async {
    setState(() {
      _isLoadingBookmarks = true;
    });

    try {
      final fetchedPosts = await PostService.fetchBookmarkedPosts();

      if (mounted) {
        setState(() {
          _bookmarkedPosts = fetchedPosts;
          _isLoadingBookmarks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBookmarks = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat bookmark: ${e.toString()}')),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inHours < 24) {
      final hours = duration.inHours;
      if (hours > 0) return '$hours Jam yang lalu';
      final minutes = duration.inMinutes;
      if (minutes > 0) return '$minutes Menit yang lalu';
      return 'Baru saja';
    }
    return DateFormat('d MMM y').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemberitahuan'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          // MENGGANTI: indicatorColor hardcoded dengan primaryColor
          indicatorColor: primaryColor,
          // MENGGANTI: labelColor hardcoded dengan primaryColor
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Balasan'),
            Tab(text: 'Simpan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityList(primaryColor), // Meneruskan primaryColor
          _buildBookmarkList(primaryColor), // Meneruskan primaryColor
        ],
      ),
    );
  }

  // --- WIDGET LIST AKTIVITAS POSTINGAN (Balasan) ---
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildActivityList(Color primaryColor) {
    if (_isLoadingReplies) {
      return Center(
        child: CircularProgressIndicator(
          // MENGGANTI: Warna hardcoded (0xFF00B140) dengan primaryColor
          color: primaryColor,
        ),
      );
    }

    if (_displayItems.isEmpty) {
      return const Center(child: Text('Tidak ada balasan atau suka baru.'));
    }

    return ListView.builder(
      itemCount: _displayItems.length,
      itemBuilder: (context, index) {
        final item = _displayItems[index];

        if (item.type == DisplayType.likeGroup) {
          return _buildGroupedLikeNotification(item);
        } else {
          return _buildCommentNotification(item);
        }
      },
    );
  }

  // Helper untuk mendapatkan avatar user
  Widget _buildUserAvatar(String? userPhoto) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: userPhoto != null && userPhoto.isNotEmpty
          ? NetworkImage('${ApiConfig.baseUrl}$userPhoto')
          : null,
      child: userPhoto == null || userPhoto.isEmpty
          ? const Icon(Icons.person, color: Colors.grey, size: 24)
          : null,
    );
  }

  // WIDGET UNTUK LIKE YANG DIKELOMPOKKAN
  Widget _buildGroupedLikeNotification(DisplayNotificationItem item) {
    final totalLikes = item.activityList.length;
    final firstLiker = item.activityList.first;
    final lastActivityTime = firstLiker.createdAt;

    // Ambil 3 likers teratas
    final topLikers = item.activityList.take(3).toList();

    final likerNames = topLikers.map((a) => a.userName).toList();
    String namesText;

    if (totalLikes == 1) {
      namesText = '${likerNames.first} menyukai pesan ini';
    } else if (totalLikes == 2) {
      namesText = '${likerNames[0]} dan ${likerNames[1]} menyukai pesan ini';
    } else {
      namesText =
          '${likerNames[0]}, ${likerNames.sublist(1).join(', ')} dan ${totalLikes - topLikers.length} orang lainnya menyukai pesan ini';
    }

    // Tampilkan 4 avatar pertama
    // Avatar stack tidak digunakan di sini, tapi dipertahankan
    /*
    List<Widget> avatarStack = topLikers
        .take(4)
        .map((a) => _buildUserAvatar(a.userPhoto))
        .toList();
    */

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                // Icon hati tetap merah untuk Like
                const Icon(Icons.favorite, color: Colors.red, size: 40),
                // Tampilkan avatar di atas hati (opsional, tergantung desain persis)
              ],
            ),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
              children: [
                TextSpan(
                  text: namesText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Tampilkan waktu dari aktivitas terbaru
              Text(_formatTimeAgo(lastActivityTime)),
              const SizedBox(height: 4),
              // Tampilkan Postingan yang disukai
              Text(
                item.post.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          onTap: () {
            // Navigasi ke PostDetailPage
          },
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  // WIDGET UNTUK KOMENTAR TUNGGAL
  Widget _buildCommentNotification(DisplayNotificationItem item) {
    final activity = item.activityList.first;
    final post = item.post;

    // Teks konten: Isi komentar
    final commentText = activity.commentText ?? 'Mengomentari postingan Anda.';

    // Waktu aktivitas
    final activityTime = activity.createdAt;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildUserAvatar(activity.userPhoto),
          title: Row(
            children: [
              Text(
                activity.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(activityTime),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Teks Aksi (misal: "Membalas Rehan JGU")
              Text(
                'Mengomentari postingan Anda:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              // Konten komentar
              Text(
                commentText,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              // Postingan yang dikomentari
              Text(
                post.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          onTap: () {
            // Navigasi ke PostDetailPage
          },
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  // --- WIDGET LIST SIMPAN (BOOKMARK) ---
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildBookmarkList(Color primaryColor) {
    if (_isLoadingBookmarks) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            // MENGGANTI: Warna hardcoded (0xFF00B140) dengan primaryColor
            color: primaryColor,
          ),
        ),
      );
    }

    if (_bookmarkedPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bookmark_add_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda belum menyimpan postingan apa pun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchBookmarks,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Muat Ulang'),
                style: ElevatedButton.styleFrom(
                  // MENGGANTI: Warna hardcoded (0xFF00B140) dengan primaryColor
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _bookmarkedPosts.length,
      itemBuilder: (context, index) {
        final post = _bookmarkedPosts[index];
        final bool hasImage = post.imageUrls.isNotEmpty;

        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(
                Icons.bookmark,
                // MENGGANTI: Warna hardcoded (0xFF00B140) dengan primaryColor
                color: primaryColor,
              ),
              title: Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disimpan dari ${post.user.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  // Menampilkan jumlah like dan komentar dari Postingan Bookmark
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.commentsCount.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likesCount.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: hasImage
                  ? SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '${ApiConfig.baseUrl}${post.imageUrls.first}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                // Navigasi ke PostDetailPage(initialPost: post)
              },
            ),
            Divider(height: 1, color: Colors.grey.shade200, indent: 16),
          ],
        );
      },
    );
  }
}
