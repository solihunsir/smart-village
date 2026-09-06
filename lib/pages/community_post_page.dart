import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../models/community.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../models/image_to_post.dart';
import 'package:desaku/utils/app_logger.dart';

class CommunityPostPage extends StatefulWidget {
  final Community community;
  const CommunityPostPage({super.key, required this.community});

  @override
  State<CommunityPostPage> createState() => _CommunityPostPageState();
}

class _CommunityPostPageState extends State<CommunityPostPage> {
  String _currentUserName = 'Pengguna';
  String? _currentUserAvatarUrl;

  List<ImageToPost> _selectedImages = [];

  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  static const int MAX_IMAGES = 4;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final userData = await TokenService.getUserData();
      String? name;
      String? avatarPath;

      if (userData != null) {
        try {
          final Map<String, dynamic> map = json.decode(userData);
          name = map['name'] as String?;
          avatarPath = map['photo'] as String? ?? map['avatar_url'] as String?;
        } catch (_) {}
      }

      name ??= AuthService().currentUser?.name;

      if (mounted) {
        setState(() {
          _currentUserName =
              (name != null && name.isNotEmpty) ? name : 'Pengguna';
          if (avatarPath != null && avatarPath.isNotEmpty) {
            _currentUserAvatarUrl = '${ApiConfig.baseUrl}$avatarPath';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUserName = 'Pengguna';
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= MAX_IMAGES) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batas maksimum 4 gambar tercapai.')),
        );
      }
      return;
    }

    List<XFile> pickedFiles = [];
    if (source == ImageSource.gallery) {
      final List<XFile> files = await _picker.pickMultiImage();
      final remainingQuota = MAX_IMAGES - _selectedImages.length;
      pickedFiles = files.take(remainingQuota).toList();
    } else if (source == ImageSource.camera) {
      final XFile? cameraFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      pickedFiles = cameraFile != null ? [cameraFile] : [];
    }

    if (pickedFiles.isNotEmpty) {
      List<ImageToPost> newImagesReady = [];

      for (var xFile in pickedFiles) {
        Uint8List? bytes;

        try {
          bytes = await xFile.readAsBytes();
        } catch (e) {
          AppLogger.log('Error membaca file bytes: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memproses gambar: ${xFile.name}')),
            );
          }
          continue;
        }

        if (bytes != null) {
          final newImage = ImageToPost(
            path: xFile.path,
            bytes: bytes,
            name: xFile.name,
          );
          newImagesReady.add(newImage);
        }
      }

      if (newImagesReady.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(newImagesReady);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost(BuildContext context) async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Post tidak boleh kosong. Harap isi pesan atau tambahkan gambar.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await PostService.createPost(
        communityId: widget.community.id,
        content: content,
        selectedImages: _selectedImages,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil diunggah!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah postingan: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // --- START MODIFIKASI ---

  // Membuat widget terpisah untuk tombol aksi agar kodenya lebih rapi
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildActionButtons(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _isPosting ? null : () => _pickImage(ImageSource.camera),
            icon: Icon(
              Icons.camera_alt_outlined,
              // MENGGANTI: Warna hardcoded dengan primaryColor
              color: primaryColor,
            ),
            tooltip: 'Ambil Foto',
          ),
          IconButton(
            onPressed:
                _isPosting ? null : () => _pickImage(ImageSource.gallery),
            icon: Icon(
              Icons.photo_library_outlined,
              // MENGGANTI: Warna hardcoded dengan primaryColor
              color: primaryColor,
            ),
            tooltip: 'Pilih dari Galeri',
          ),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    // Membungkus seluruh body dengan Column dan mengatur agar tombol aksi
    // berada di bagian bawah, tetapi masih dalam body, dan konten utama
    // di atasnya dapat discroll.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Post ke ${widget.community.name}',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isPosting ? null : () => _submitPost(context),
              style: ElevatedButton.styleFrom(
                // MENGGANTI: Warna hardcoded dengan primaryColor
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Unggah',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      // Hapus bottomNavigationBar:
      // bottomNavigationBar: Container(...),

      // Gunakan Column di body, dengan Expanded untuk konten yang dapat discroll
      body: Column(
        children: [
          // Konten Utama (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Profil Pengguna
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        child: _currentUserAvatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _currentUserAvatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 28,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _currentUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Kolom Input Pesan
                  TextField(
                    controller: _contentController,
                    autofocus: true,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Ketik Pesan Anda...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 16),

                  // Pratinjau Gambar (Gallery)
                  if (_selectedImages.isNotEmpty)
                    Container(
                      height: 120,
                      padding: const EdgeInsets.only(top: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final imgToPost = _selectedImages[index];

                          Widget imageWidget;

                          if (imgToPost.bytes != null) {
                            imageWidget = Image.memory(
                              imgToPost.bytes!,
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            );
                          } else if (!kIsWeb && imgToPost.path.isNotEmpty) {
                            imageWidget = Image.file(
                              File(imgToPost.path),
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            );
                          } else {
                            imageWidget = Container(
                              width: 100,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(
                              right:
                                  index == _selectedImages.length - 1 ? 0 : 8,
                            ),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageWidget,
                                ),
                                GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // **Tambahkan padding di bawah konten agar tombol aksi
                  // tidak langsung menempel saat scroll mentok.**
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Tombol Aksi (Kamera & Galeri)
          _buildActionButtons(primaryColor), // Meneruskan primaryColor
        ],
      ),
    );
  }
}
