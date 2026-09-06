import 'package:desaku/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/post_service.dart';
import '../services/token_service.dart';
import '../config/api_config.dart';
import 'login_page.dart';
import '../models/image_to_post.dart';
import '../services/auth_service.dart';

class PostDetailPage extends StatefulWidget {
  final Post initialPost; // Menerima post dari halaman feed
  const PostDetailPage({super.key, required this.initialPost});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final AuthService _authService = AuthService(); // Inisialisasi AuthService
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUserLoggedIn = false;
  int? _currentUserId; // Tambahkan untuk identifikasi user saat ini

  Post? _currentPost;
  List<Comment> _comments = [];
  bool _isCommentSubmitting = false;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  List<ImageToPost> _commentImages = [];
  static const int MAX_COMMENT_IMAGES = 3;

  bool _isPostLiked = false;
  bool _isLiking = false;

  // Daftar alasan laporan
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
    _currentPost = widget.initialPost;
    _isPostLiked = widget.initialPost.hasLiked;
    _currentUserId = _authService.currentUser?.id; // Ambil ID User
    // Pastikan locale Indonesia dimuat untuk DateFormat
    Intl.defaultLocale = 'id_ID';
    _fetchDetailsAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await TokenService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isUserLoggedIn = isLoggedIn;
        _currentUserId = _authService.currentUser?.id;
      });
    }
  }

  Future<void> _fetchDetailsAndComments() async {
    await _checkLoginStatus();

    try {
      final postData = await PostService.fetchPostAndComments(
        widget.initialPost.id,
      );

      List<Comment> fetchedComments = [];
      try {
        fetchedComments = await PostService.fetchCommentsForPost(
          widget.initialPost.id,
        );
      } catch (e) {
        AppLogger.log(
          'Warning: Failed to fetch comments list due to API error: $e',
        );
      }

      if (mounted) {
        setState(() {
          final newPost = Post.fromJson(postData);
          _currentPost = newPost;
          _isPostLiked = newPost.hasLiked;
          // Membalik urutan agar yang terbaru di atas
          _comments = fetchedComments.reversed.toList();
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _currentPost = null;
        });
      }
    }
  }

  // --- FUNGSI ZOOM GAMBAR (dipertahankan) ---
  void _showImageZoomDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.8,
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
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.red,
                      size: 60,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI PENDUKUNG REPORT, LIKE, OPSI LAINNYA (dilewati) ---

  Future<void> _handleReportPost(Post post, String reason) async {
    if (!_isUserLoggedIn) {
      _showLoginRequiredDialog(context, 'melaporkan postingan');
      return;
    }

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

    String finalReason = reason;
    if (finalReason.length < 10) {
      finalReason = '$reason. Postingan ini melanggar aturan.';
      if (finalReason.length > 255) {
        finalReason = finalReason.substring(0, 255);
      }
    }

    try {
      await PostService.reportPost(post.id, reason: finalReason);

      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirimkan ke Admin.'),
            backgroundColor: Color(0xFF00B140),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();

        String errorMessage = e.toString();
        if (errorMessage.contains('422') ||
            errorMessage.contains('10 characters')) {
          errorMessage = 'Gagal: Alasan laporan terlalu pendek. Mohon ulangi.';
        } else {
          errorMessage = 'Gagal mengirimkan laporan: ${e.toString()}';
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkNotInterested(Post post) async {
    if (!_isUserLoggedIn) {
      _showLoginRequiredDialog(context, 'menyembunyikan postingan');
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
        Navigator.pop(context, true); // Pop dan kirimkan sinyal refresh
        scaffoldMessenger.hideCurrentSnackBar();
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

  Future<void> _toggleLike() async {
    if (!_isUserLoggedIn) {
      await _showLoginRequiredDialog(
        context,
        'memberi Suka (Like) pada pesan ini',
      );
      return;
    }

    if (_isLiking) return;

    setState(() {
      _isLiking = true;
      final bool currentlyLiked = _isPostLiked;
      _isPostLiked = !currentlyLiked;

      if (_currentPost != null) {
        final newLikesCount = currentlyLiked
            ? _currentPost!.likesCount - 1
            : _currentPost!.likesCount + 1;

        _currentPost = _currentPost!.copyWith(likesCount: newLikesCount);
      }
    });

    try {
      await PostService.toggleLike(_currentPost!.id);

      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPostLiked = !_isPostLiked;

          if (_currentPost != null) {
            final rollbackLikesCount = _isPostLiked
                ? _currentPost!.likesCount - 1
                : _currentPost!.likesCount + 1;
            _currentPost = _currentPost!.copyWith(
              likesCount: rollbackLikesCount,
            );
          }

          _isLiking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memberikan Suka: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    if (!_isUserLoggedIn) {
      await _showLoginRequiredDialog(
        context,
        'memberi Suka (Like) pada komentar',
      );
      return;
    }
  }

  Future<void> _handleReportComment(Comment comment, String reason) async {
    if (!_isUserLoggedIn) {
      _showLoginRequiredDialog(context, 'melaporkan komentar');
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Mengirimkan laporan...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await PostService.reportComment(comment.id, reason: reason);

      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Laporan komentar berhasil dikirimkan ke Admin.'),
            backgroundColor: Color(0xFF00B140),
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

  void _showReportManualFormSheet(Comment comment) {
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
                  const Text(
                    'Laporkan Komentar',
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
                    decoration: const InputDecoration(
                      hintText: 'Ketik laporan anda disini...',
                      border: OutlineInputBorder(),
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
                        _handleReportComment(
                          comment,
                          'Lainnya: ${controller.text.trim()}',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Kirim Laporan'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReportOptionsSheet(Comment comment) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Laporkan Komentar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ..._reportReasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  onTap: () {
                    Navigator.pop(context);
                    if (reason == 'Lainnya') {
                      _showReportManualFormSheet(comment);
                    } else {
                      _handleReportComment(comment, reason);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showCommentOptionsSheet(Comment comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.report_problem_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'Laporkan Komentar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportOptionsSheet(comment);
              },
            ),
          ],
        );
      },
    );
  }

  void _showReportManualFormSheetPost(Post post) {
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
                    'Laporkan Postingan',
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

  void _showReportOptionsSheetPost(Post post) {
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
                      'Laporkan Postingan',
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
                              _showReportManualFormSheetPost(post);
                            } else {
                              _handleReportPost(post, reason);
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

  void _showPostOptionsSheet(Post post) {
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
                    _showReportOptionsSheetPost(post);
                  },
                ),
              if (!isMyPost) const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCommentImage() async {
    if (!_isUserLoggedIn) {
      _showLoginRequiredDialog(context, 'menambahkan gambar ke komentar');
      return;
    }
    if (_commentImages.length >= MAX_COMMENT_IMAGES) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batas maksimum 3 gambar per komentar.')),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        Uint8List? bytes;

        if (kIsWeb) {
          bytes = await pickedFile.readAsBytes();
        } else {
          bytes = await File(pickedFile.path).readAsBytes();
        }

        final newImageWithBytes = ImageToPost(
          path: pickedFile.path,
          name: pickedFile.name,
          bytes: bytes,
        );

        if (mounted) {
          setState(() {
            _commentImages.add(newImageWithBytes);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
        );
      }
    }
  }

  void _removeCommentImage(int index) {
    setState(() {
      _commentImages.removeAt(index);
    });
  }

  Future<void> _sendComment() async {
    if (!_isUserLoggedIn) {
      await _showLoginRequiredDialog(context, 'mengirim komentar');
      await _checkLoginStatus();
      if (!_isUserLoggedIn) return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty && _commentImages.isEmpty) return;

    setState(() {
      _isCommentSubmitting = true;
    });

    try {
      final updatedPost = _currentPost!.copyWith(
        commentsCount: _currentPost!.commentsCount + 1,
      );

      await PostService.addComment(
        widget.initialPost.id,
        commentText,
        _commentImages,
      );

      _commentController.clear();
      _commentImages = [];
      FocusScope.of(context).unfocus();

      if (mounted) {
        setState(() {
          _currentPost = updatedPost;
          _isCommentSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar berhasil dikirim.')),
        );
        _fetchDetailsAndComments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCommentSubmitting = false;
          if (_currentPost != null) {
            _currentPost = _currentPost!.copyWith(
              commentsCount: _currentPost!.commentsCount - 1,
            );
          }
        });

        String errorMsg = e.toString().contains('401')
            ? 'Sesi Anda telah berakhir. Silakan login ulang.'
            : e.toString().contains('500')
                ? 'Terjadi kesalahan server saat mengirim komentar.'
                : 'Gagal mengirim komentar: ${e.toString()}';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  Future<void> _showLoginRequiredDialog(
    BuildContext context,
    String action,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: Text('Anda harus masuk terlebih dahulu untuk $action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );

              if (result == true) {
                _fetchDetailsAndComments();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B140),
              foregroundColor: Colors.white,
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

  Widget _buildPostImagesGrid(
    List<String> imageUrls, {
    bool isComment = false,
  }) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (!isComment) {
      // Logika untuk Post Utama
      final int count = imageUrls.length;
      final int crossAxisCount =
          (count == 2 || count == 3) ? 2 : (count >= 4 ? 2 : 1);
      final double mainAxisExtent = ((count == 3) ? 200 : 180);

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
          final rawUrl = imageUrls[index];
          final url = rawUrl.startsWith('http')
              ? rawUrl
              : '${ApiConfig.baseUrl}$rawUrl';

          final bool showOverlay = count > 4 && index == 3;

          return GestureDetector(
            onTap: () => _showImageZoomDialog(context, url), // Tambahkan Zoom
            child: ClipRRect(
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
                ],
              ),
            ),
          );
        },
      );
    }

    // Logika Wrap untuk Komentar (Memastikan Zoom ada)
    const double itemSize = 80;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: imageUrls.map((url) {
        return GestureDetector(
          onTap: () => _showImageZoomDialog(context, url), // Tambahkan Zoom
          child: Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 30,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- MODIFIKASI 1 & 2: RESTRUKTURISASI INPUT AREA ---

  // #1: Tombol Silang dipindahkan ke Kanan Atas (dipertahankan)
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: Colors.white,
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _commentImages.length,
        itemBuilder: (context, index) {
          final imgToPost = _commentImages[index];
          Widget imageWidget;

          if (imgToPost.bytes != null) {
            imageWidget = Image.memory(
              imgToPost.bytes!,
              fit: BoxFit.cover,
              height: 80,
              width: 80,
            );
          } else if (!kIsWeb && imgToPost.path.isNotEmpty) {
            imageWidget = Image.file(
              File(imgToPost.path),
              fit: BoxFit.cover,
              height: 80,
              width: 80,
            );
          } else {
            imageWidget = Container(
              color: Colors.grey[300],
              height: 80,
              width: 80,
              child: const Center(child: Icon(Icons.image)),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () => _removeCommentImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // #2: Fungsi Gabungan untuk Input Area (dipindahkan ke Body Column)
  Widget _buildCommentInputArea(BuildContext context) {
    final isInputDisabled = _isCommentSubmitting || !_isUserLoggedIn;

    Widget sendButton = GestureDetector(
      onTap: isInputDisabled ? null : _sendComment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isInputDisabled ? Colors.grey : const Color(0xFF00B140),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isCommentSubmitting
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );

    // Konten Input Bar yang sebenarnya
    Widget inputBarContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // TOMBOL GALERI
          GestureDetector(
            onTap: isInputDisabled ? null : _pickCommentImage,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 4),
              child: Icon(
                Icons.image_outlined,
                color: isInputDisabled ? Colors.grey[400] : Colors.grey,
                size: 24,
              ),
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: isInputDisabled &&
                      !_isCommentSubmitting &&
                      !_isUserLoggedIn
                  ? GestureDetector(
                      onTap: () => _showLoginRequiredDialog(
                        context,
                        'mengirim komentar',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Login untuk Berkomentar...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLines: 4,
                      minLines: 1,
                      readOnly: isInputDisabled,
                      decoration: InputDecoration(
                        hintText: 'Balas Dengan Pesan...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: sendButton,
          ),
        ],
      ),
    );

    // Gabungkan preview dan input bar, bungkus dengan Container dan SafeArea
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      // Column membungkus kedua bagian (preview dan input bar)
      child: Column(
        mainAxisSize: MainAxisSize.min, // Penting agar ukurannya minimal
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_commentImages.isNotEmpty) _buildImagePreview(),
          // SafeArea(bottom: true) menangani insets bawah (gestur bar)
          SafeArea(top: false, child: inputBarContent),
        ],
      ),
    );
  }

  // --- START PERBAIKAN FUNGSI BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    final post = _currentPost;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pesan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // PENTING: resizeToAvoidBottomInset harus TRUE agar body tergeser
      resizeToAvoidBottomInset: true,
      // HILANGKAN bottomNavigationBar

      // Gunakan Column di body seperti yang berhasil di CommunityPostPage
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00B140)),
            )
          : _errorMessage != null || post == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat detail post: ${_errorMessage ?? "Data post tidak ditemukan."}',
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchDetailsAndComments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B140),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // 1. Konten Utama (Post dan Komentar) - Harus bisa discroll
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchDetailsAndComments,
                        color: const Color(0xFF00B140),
                        child: ListView.builder(
                          // PENTING: Membuat keyboard hilang saat scroll
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // Hapus padding bawah, karena input bar sekarang bagian dari Column body.
                          padding: const EdgeInsets.only(top: 0),
                          itemCount: 1 + _comments.length,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildMainPost(context, post);
                            }
                            final comment = _comments[index - 1];
                            return _buildCommentItem(
                              context,
                              comment,
                              post.user.name,
                            );
                          },
                        ),
                      ),
                    ),
                    // 2. Input Komentar - Berada di bagian bawah body,
                    // sehingga ikut terangkat penuh saat keyboard muncul.
                    _buildCommentInputArea(context),
                  ],
                ),
    );
  }
  // --- END PERBAIKAN FUNGSI BUILD UTAMA ---

  // --- FUNGSI TAMPILAN LAINNYA (dipertahankan) ---
  // ... (Fungsi _buildMainPost dan _buildCommentItem serta fungsi lainnya dipertahankan)
  // ...

  // ... (Sisa kode seperti _buildMainPost, _buildCommentItem, dll. tetap sama)
  // ...
  // ... (Lanjutan kode PostDetailPage)

  // ****************** PASTE SISA KODE DARI SINI ******************

  Widget _buildMainPost(BuildContext context, Post post) {
    final rawUserPhotoPath = post.user.profilePhotoUrl;
    String? userProfileUrl;
    if (rawUserPhotoPath != null && rawUserPhotoPath.isNotEmpty) {
      userProfileUrl = rawUserPhotoPath.startsWith('http')
          ? rawUserPhotoPath
          : '${ApiConfig.baseUrl}$rawUserPhotoPath';
    }
    if (userProfileUrl == null &&
        _authService.currentUser != null &&
        post.user.id == _authService.currentUser!.id) {
      userProfileUrl = _authService.currentUser!.photo;
    }
    final bool showMoreOptions = post.user.id != _currentUserId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                child: userProfileUrl != null
                    ? ClipOval(
                        child: Image.network(
                          userProfileUrl!,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 28,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 28),
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPostDate(post.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showMoreOptions)
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () => _showPostOptionsSheet(post),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (!showMoreOptions)
                const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.transparent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
          if (post.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildPostImagesGrid(post.imageUrls),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  post.commentsCount.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLiking ? null : _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isPostLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _isPostLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likesCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPostLiked ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    Comment comment,
    String postAuthorName,
  ) {
    final rawUserPhotoPath = comment.user.profilePhotoUrl;
    String? userProfileUrl;
    if (rawUserPhotoPath != null && rawUserPhotoPath.isNotEmpty) {
      userProfileUrl = rawUserPhotoPath.startsWith('http')
          ? rawUserPhotoPath
          : '${ApiConfig.baseUrl}$rawUserPhotoPath';
    }
    if (userProfileUrl == null &&
        _authService.currentUser != null &&
        comment.user.id == _authService.currentUser?.id) {
      userProfileUrl = _authService.currentUser!.photo;
    }
    final commentImageUrls = comment.images
        .map(
          (img) => img.imageUrl.startsWith('http')
              ? img.imageUrl
              : '${ApiConfig.baseUrl}${img.imageUrl}',
        )
        .toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: userProfileUrl != null
                ? ClipOval(
                    child: Image.network(
                      userProfileUrl!,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        );
                      },
                    ),
                  )
                : const Icon(Icons.person, color: Colors.grey, size: 20),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatPostDate(comment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Membalas ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      postAuthorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B140),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.commentText,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                if (commentImageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildPostImagesGrid(
                      commentImageUrls,
                      isComment: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
