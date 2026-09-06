// lib/pages/community_chat_page.dart (KODE LENGKAP dengan Perbaikan Tata Letak Gambar)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart'; // <-- TAMBAH: Import package SVG
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/community.dart';
import '../models/post.dart';
import '../services/community_service.dart';
import '../services/post_service.dart';
import '../services/token_service.dart';
import '../config/api_config.dart';
import 'community_post_page.dart';
import 'login_page.dart';
import 'post_detail_page.dart';
import 'community_detail_page.dart';
import 'notification_page.dart';
import '../services/auth_service.dart';

class CommunityChatPage extends StatefulWidget {
  final Community community;
  const CommunityChatPage({super.key, required this.community});

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>>? _communityDetailsFuture;
  List<Post> _posts = [];
  bool _isFetchingPosts = true;
  String _postsError = '';
  bool _isMember = false;
  bool _isUserLoggedIn = false;
  int? _currentUserId;

  final List<String> _reportReasons = [
    'Tidak suka unggahan ini',
    'Penindasan yang tidak diinginkan',
    'Bunuh diri atau gangguan jiwa',
    'Kekerasan',
    'Menjual barang terlarang',
    'Aktivitas seksual',
    'Penipuan',
    'Spam',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id';
    _checkLoginStatusAndFetch();
    _currentUserId = _authService.currentUser?.id;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLoginStatusAndFetch() async {
    _isUserLoggedIn = await TokenService.isLoggedIn();
    _currentUserId = _authService.currentUser?.id;

    setState(() {
      _communityDetailsFuture = _fetchCommunityDetails();
    });
  }

  Future<Map<String, dynamic>> _fetchCommunityDetails() async {
    try {
      final data = await CommunityService.fetchCommunityDetails(
        widget.community.id,
        postPage: 1,
      );

      final List<dynamic> postsJson = data['posts']?['data'] ?? [];

      if (mounted) {
        setState(() {
          _posts = postsJson.map((json) => Post.fromJson(json)).toList();
          _isFetchingPosts = false;
          _isMember = data['is_member'] as bool? ?? false;
        });
      }
      return data;
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsError = e.toString();
          _isFetchingPosts = false;
          _isMember = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _handleMarkNotInterested(Post post) async {
    // BARU: Ambil primaryColor di sini (atau ambil dari build jika perlu)
    final primaryColor =
        Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    if (!_isUserLoggedIn) {
      // PERBAIKAN: Meneruskan primaryColor
      _showLoginRequiredDialog(
          context, 'menyembunyikan postingan', primaryColor);
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Menyembunyikan postingan...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await PostService.markNotInterested(post.id);

      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
        });
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Postingan dari ${post.user.name} disembunyikan.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyembunyikan postingan: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Future<void> _handleReportPost(
    Post post,
    String reason,
    Color primaryColor,
  ) async {
    if (!_isUserLoggedIn) {
      // PERBAIKAN: Meneruskan primaryColor
      _showLoginRequiredDialog(context, 'melaporkan postingan', primaryColor);
      return;
    }

    // Mencegah pelaporan postingan sendiri
    if (post.user.id == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak bisa melaporkan postingan Anda sendiri.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Mengirimkan laporan...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Memastikan 'reason' memiliki panjang minimal 10 karakter
    String finalReason = reason;
    if (finalReason.length < 10) {
      finalReason = '$reason. Komunitas: ${widget.community.name}.';
      if (finalReason.length > 255) {
        finalReason = finalReason.substring(0, 255);
      }
    }

    try {
      await PostService.reportPost(post.id, reason: finalReason);

      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Laporan berhasil dikirimkan ke Admin.'),
            // MENGGANTI: Warna hardcoded dengan primaryColor
            backgroundColor: primaryColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal mengirimkan laporan: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  void _showReportManualFormSheet(Post post, Color primaryColor) {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const Text(
                    'Laporkan Pengguna',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tuliskan alasan anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextFormField(
                    controller: controller,
                    maxLines: 4,
                    minLines: 2,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ketik laporan anda disini...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        // MENGGANTI: Warna hardcoded dengan primaryColor
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Alasan laporan tidak boleh kosong';
                      }
                      if (value.trim().length < 10) {
                        return 'Alasan harus lebih dari 10 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        _handleReportPost(
                          post,
                          'Lainnya: ${controller.text.trim()}',
                          primaryColor, // Meneruskan primaryColor
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Kirim Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  void _showReportOptionsSheet(Post post, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Laporkan Pengguna',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Mengapa anda melaporkan unggahan ini?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Pilih atau tuliskan laporan anda agar diproses pengelola.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _reportReasons.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final reason = _reportReasons[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            if (reason == 'Lainnya') {
                              _showReportManualFormSheet(post,
                                  primaryColor); // Meneruskan primaryColor
                            } else {
                              _handleReportPost(post, reason,
                                  primaryColor); // Meneruskan primaryColor
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  void _showPostOptionsSheet(Post post, Color primaryColor) {
    // Cek apakah postingan ini milik user yang sedang login
    final bool isMyPost = post.user.id == _currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Tombol 'Tidak Tertarik' hanya ditampilkan jika BUKAN postingan sendiri
              if (!isMyPost)
                ListTile(
                  leading: const Icon(
                    Icons.do_not_disturb_on_outlined,
                    color: Colors.grey,
                  ),
                  title: const Text(
                    'Tidak Tertarik',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleMarkNotInterested(post);
                  },
                ),

              // Tombol 'Laporkan Postingan' hanya ditampilkan jika BUKAN postingan sendiri
              if (!isMyPost)
                ListTile(
                  leading: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Laporkan Postingan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportOptionsSheet(
                        post, primaryColor); // Meneruskan primaryColor
                  },
                ),
              if (!isMyPost) const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLikeToggle(Post post) async {
    final primaryColor =
        Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    if (!_isUserLoggedIn) {
      // PERBAIKAN: Meneruskan primaryColor
      _showLoginRequiredDialog(context, 'menyukai postingan', primaryColor);
      return;
    }

    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex != -1) {
      final newLikeStatus = post.hasLiked; // Simpan status lama

      // ✅ PERBAIKAN LOGIKA:
      // Jika status lama (newLikeStatus) true, berarti akan unlike, jadi KURANGI 1 (-1).
      // Jika status lama false, berarti akan like, jadi TAMBAH 1 (+1).
      final newLikesCount = post.likesCount + (newLikeStatus ? -1 : 1);

      setState(() {
        _posts[postIndex] = post.copyWith(
          hasLiked: !newLikeStatus, // Toggle status
          likesCount: newLikesCount,
        );
      });

      try {
        await PostService.toggleLike(post.id);
      } catch (e) {
        if (mounted) {
          // Rollback state jika gagal
          setState(() {
            _posts[postIndex] = post;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyukai: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBookmarkToggle(Post post) async {
    final primaryColor =
        Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    if (!_isUserLoggedIn) {
      // PERBAIKAN: Meneruskan primaryColor
      _showLoginRequiredDialog(context, 'menyimpan postingan', primaryColor);
      return;
    }

    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex != -1) {
      final newBookmarkStatus = !post.hasBookmarked;

      setState(() {
        _posts[postIndex] = post.copyWith(hasBookmarked: newBookmarkStatus);
      });

      try {
        await PostService.toggleBookmark(post.id);
      } catch (e) {
        if (mounted) {
          setState(() {
            _posts[postIndex] = post;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _navigateToCommentDetail(Post post) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(initialPost: post),
      ),
    );

    if (result == true) {
      _checkLoginStatusAndFetch();
    }
  }

  void _navigateToCommunityDetail() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailPage(community: widget.community),
      ),
    );

    _checkLoginStatusAndFetch();
  }

  void _navigateToNotificationPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Future<void> _showLoginRequiredDialog(
    BuildContext context,
    String action,
    Color primaryColor,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Login Diperlukan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Anda harus masuk terlebih dahulu untuk $action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
              _checkLoginStatusAndFetch();
            },
            style: ElevatedButton.styleFrom(
              // MENGGANTI: Warna hardcoded dengan primaryColor
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  String _formatPostDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('d MMM y', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String _getFullImageUrl(String partialUrl) {
    if (partialUrl.startsWith('http')) return partialUrl;
    // Tambahkan logika pembersihan slash jika diperlukan
    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final imagePath =
        partialUrl.startsWith('/') ? partialUrl.substring(1) : partialUrl;

    return '$baseUrl/$imagePath';
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.red,
                        size: 100,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI BARU: Widget Pembantu untuk Satu Gambar dalam Tata Letak Kustom ---
  Widget _buildImageTile(String partialUrl, double height,
      {bool isFullWidth = false}) {
    String url = _getFullImageUrl(partialUrl);

    return GestureDetector(
      onTap: () => _showFullImageDialog(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: isFullWidth ? height : height, // Tinggi untuk semua gambar
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showFullImageDialog(context, url);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- END FUNGSI BARU ---

  // --- FUNGSI MODIFIKASI: _buildPostImagesGrid ---
  Widget _buildPostImagesGrid(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final int count = imageUrls.length;
    final bool isSingleImage = count == 1;

    String firstUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
    if (firstUrl.isNotEmpty && !firstUrl.startsWith('http')) {
      firstUrl = _getFullImageUrl(firstUrl);
    }

    if (isSingleImage) {
      // Kasus 1 Gambar
      return GestureDetector(
        onTap: () => _showFullImageDialog(context, firstUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            firstUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // --- KASUS 3 GAMBAR: Tata Letak Kustom (2 di atas, 1 penuh di bawah) ---
    if (count == 3) {
      const double imageSize = 150;
      const double spacing = 4;

      return Column(
        children: [
          // Baris 1: 2 Gambar di samping
          Row(
            children: [
              Expanded(child: _buildImageTile(imageUrls[0], imageSize)),
              const SizedBox(width: spacing),
              Expanded(child: _buildImageTile(imageUrls[1], imageSize)),
            ],
          ),
          const SizedBox(height: spacing),
          // Baris 2: 1 Gambar Penuh
          _buildImageTile(imageUrls[2], imageSize, isFullWidth: true),
        ],
      );
    }

    // --- KASUS 2, 4, atau Lebih Gambar (Menggunakan GridView) ---
    final int crossAxisCount = (count == 2 || count >= 4) ? 2 : 1;

    // Untuk 2 gambar, gunakan tinggi yang sama 180 (sama dengan _buildImageTile 150+spasi 4)
    final double mainAxisExtent = (count == 2) ? 180 : 180;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: count > 4 ? 4 : count,
      itemBuilder: (context, index) {
        String url = imageUrls[index];
        if (!url.startsWith('http')) {
          url = _getFullImageUrl(url);
        }

        final bool showOverlay = count > 4 && index == 3;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
              if (showOverlay)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${count - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showFullImageDialog(context, url);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- END FUNGSI MODIFIKASI: _buildPostImagesGrid ---

  // Widget untuk tombol "Gabung" di AppBar
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildJoinButtonAppBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () async {
          if (!_isUserLoggedIn) {
            _showLoginRequiredDialog(context, 'bergabung', primaryColor);
            return;
          }
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mencoba bergabung...')),
            );
            await CommunityService.joinCommunity(widget.community.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Berhasil bergabung!'),
                  // MENGGANTI: Warna hardcoded dengan primaryColor
                  backgroundColor: primaryColor,
                ),
              );
              _checkLoginStatusAndFetch();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal bergabung: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          // MENGGANTI: Warna hardcoded dengan primaryColor
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Gabung',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Widget untuk menampilkan ikon Group (Group Detail) di AppBar
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildGroupActionButton(Color primaryColor) {
    return IconButton(
      onPressed: _navigateToCommunityDetail,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // MENGGANTI: Warna hardcoded dengan primaryColor
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.group, color: Colors.white, size: 24),
      ),
    );
  }

  // Widget untuk menampilkan ikon Notifikasi di AppBar
  Widget _buildNotificationActionButton() {
    return IconButton(
      onPressed: _navigateToNotificationPage,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Warna latar belakang seperti desain
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications_none,
          color: Colors.grey,
          size: 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    final bool showCommentInput = _isUserLoggedIn && _isMember;

    // List Aksi di AppBar
    final List<Widget> appBarActions = [];

    // Tampilkan tombol Gabung di AppBar jika user BELUM menjadi anggota
    if (!_isMember) {
      appBarActions.add(_buildJoinButtonAppBar(primaryColor));
    }

    // Tampilkan tombol Group HANYA JIKA pengguna SUDAH menjadi anggota (_isMember == true)
    if (_isMember) {
      appBarActions.add(_buildGroupActionButton(primaryColor));
    }

    // Tombol Notifikasi selalu ditampilkan
    appBarActions.add(_buildNotificationActionButton());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.community.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.community.memberCount} Anggota',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        // Menggunakan list aksi yang sudah disesuaikan
        actions: appBarActions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _communityDetailsFuture,
        builder: (context, snapshot) {
          if (_communityDetailsFuture == null ||
              (snapshot.connectionState == ConnectionState.waiting &&
                  _posts.isEmpty)) {
            return Center(
              child: CircularProgressIndicator(
                // MENGGANTI: Warna hardcoded dengan primaryColor
                color: primaryColor,
              ),
            );
          }
          if (snapshot.hasError || _postsError.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat postingan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _postsError.isNotEmpty
                          ? _postsError
                          : snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (_posts.isEmpty && _isMember) {
            return RefreshIndicator(
              onRefresh: _fetchCommunityDetails,
              // MENGGANTI: Warna hardcoded dengan primaryColor
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada postingan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jadilah yang pertama memposting di komunitas ini',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (_posts.isEmpty && !_isMember) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada postingan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jadilah yang pertama memposting di komunitas ini',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  // CTA Banner sudah tidak menampilkan tombol, hanya deskripsi
                  _buildCtaBanner(primaryColor), // Meneruskan primaryColor
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchCommunityDetails,
            // MENGGANTI: Warna hardcoded dengan primaryColor
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _posts.length + 1 + (_isMember ? 0 : 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Tampilkan banner info HANYA jika TIDAK menjadi anggota
                  if (!_isMember) {
                    return _buildInfoBanner(
                        primaryColor); // Meneruskan primaryColor
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                // Jika TIDAK anggota dan ini adalah item terakhir, tampilkan CTA Banner
                if (!_isMember && index == _posts.length + 1) {
                  return _buildCtaBanner(
                      primaryColor); // Meneruskan primaryColor
                }

                // Postingan dimulai dari indeks 1 jika _isMember, dan indeks 1 setelah info banner jika tidak
                final postIndex = _isMember ? index - 1 : index - 1;
                final post = _posts[postIndex];
                final isMe = post.user.id == _currentUserId;

                return _buildPostItem(context, post, isMe,
                    primaryColor); // Meneruskan primaryColor
              },
            ),
          );
        },
      ),
      floatingActionButton: (showCommentInput)
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CommunityPostPage(community: widget.community),
                  ),
                );
                // Refresh data setelah posting berhasil
                if (result == true) {
                  _checkLoginStatusAndFetch();
                }
              },
              // MENGGANTI: Warna hardcoded dengan primaryColor
              backgroundColor: primaryColor,
              shape: const CircleBorder(),
              elevation: 4,
              child: SvgPicture.asset(
                'assets/images/tambah.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ), // Pastikan ikon SVG berwarna putih
                height: 28, // Sesuaikan ukuran
                width: 28,
              ),
            )
          : null,
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildPostItem(
      BuildContext context, Post post, bool isMe, Color primaryColor) {
    final String? postUserPhotoPath = post.user.profilePhotoUrl;
    String? userProfileUrl;

    if (postUserPhotoPath != null && postUserPhotoPath.isNotEmpty) {
      userProfileUrl = _getFullImageUrl(postUserPhotoPath);
    }

    if (userProfileUrl == null &&
        _authService.currentUser != null &&
        post.user.id == _authService.currentUser!.id) {
      userProfileUrl = _authService.currentUser!.photo;
    }

    // Tentukan apakah tombol titik 3 harus ditampilkan
    final bool showMoreOptions = !isMe;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            GestureDetector(
              onTap: () {
                // Navigate to profile
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade100,
                  child: userProfileUrl != null && userProfileUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            userProfileUrl,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                color: Colors.grey.shade400,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Nama, Waktu)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatPostDate(post.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Content Text
                  Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  // Gambar (Grid)
                  if (post.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPostImagesGrid(post.imageUrls),
                  ],

                  // Actions
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        // Comment
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: post.commentsCount.toString(),
                          onTap: () => _navigateToCommentDetail(post),
                        ),
                        const SizedBox(width: 20),

                        // Like
                        _buildActionButton(
                          icon: post.hasLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: post.likesCount.toString(),
                          color: post.hasLiked ? Colors.red : null,
                          onTap: _isUserLoggedIn
                              ? () => _handleLikeToggle(post)
                              : () => _showLoginRequiredDialog(
                                    context,
                                    'menyukai postingan',
                                    primaryColor, // Meneruskan primaryColor
                                  ),
                        ),

                        const Spacer(),

                        // Bookmark
                        IconButton(
                          icon: Icon(
                            post.hasBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 20,
                            color: post.hasBookmarked
                                // MENGGANTI: Warna hardcoded dengan primaryColor
                                ? primaryColor
                                : Colors.grey.shade600,
                          ),
                          onPressed: _isUserLoggedIn
                              ? () => _handleBookmarkToggle(post)
                              : () => _showLoginRequiredDialog(
                                    context,
                                    'menyimpan postingan',
                                    primaryColor, // Meneruskan primaryColor
                                  ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                        // Titik 3 (More Options)
                        // Hanya tampilkan jika BUKAN postingan pengguna yang sedang login
                        if (showMoreOptions)
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => _showPostOptionsSheet(
                                post, primaryColor), // Meneruskan primaryColor
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildInfoBanner(Color primaryColor) {
    if (_isMember) return const SizedBox.shrink();

    // BARU: Warna latar belakang dan border banner yang lebih terang
    final lightPrimaryColor = Color.lerp(primaryColor, Colors.white, 0.7)!;
    final primaryColorWithOpacity = primaryColor.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // MENGGANTI: Warna hardcoded (red.withOpacity(0.08)) dengan lightPrimaryColor
        color: lightPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        // MENGGANTI: Warna hardcoded (red.withOpacity(0.2)) dengan primaryColorWithOpacity
        border: Border.all(color: primaryColorWithOpacity, width: 1),
      ),
      child: Row(
        children: [
          // MENGGANTI: Warna ikon (red[700]) dengan primaryColor
          Icon(Icons.lock_outline, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hanya Anggota Komunitas yang bisa Posting di komunitas ini',
              style: TextStyle(
                fontSize: 13,
                // MENGGANTI: Warna teks (red[700]) dengan primaryColor
                color: primaryColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CTA Banner ini sekarang hanya berisi teks, tidak ada tombol.
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildCtaBanner(Color primaryColor) {
    // BARU: Menentukan warna berdasarkan status login/member
    final infoColor = _isUserLoggedIn ? primaryColor : Colors.amber;
    final infoBackgroundColor = _isUserLoggedIn
        ? primaryColor.withOpacity(0.1)
        : Colors.amber.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // MENGGANTI: Warna hardcoded dengan infoBackgroundColor
        color: infoBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // MENGGANTI: Warna hardcoded dengan infoColor
          color: infoColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isUserLoggedIn ? 'Gabung Komunitas' : 'Login untuk melihat konten',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              // MENGGANTI: Warna hardcoded dengan infoColor
              color: infoColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isUserLoggedIn
                ? 'Bergabunglah dengan komunitas untuk berinteraksi dengan postingan'
                : 'Anda perlu Login dan bergabung dengan komunitas untuk berinteraksi dengan postingan.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
