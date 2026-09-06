import 'package:desaku/utils/app_logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
// Memastikan impor ini benar-benar ada dan mendefinisikan ProductCategory
import '../models/api_product.dart';
import '../services/product_service.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';

class ProductUploadException implements Exception {
  final String message;
  final dynamic data;
  ProductUploadException(this.message, {this.data});
  @override
  String toString() => 'ProductUploadException: $message';
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  // State Variables
  List<ProductCategory> _categories = [];
  ProductCategory? _selectedCategory;
  final _manualAddCategoryPlaceholder = ProductCategory(
    id: -99,
    name: 'Tambah Kategori Baru...',
    description: '',
    createdAt: '',
    updatedAt: '',
  );

  String _selectedCondition = 'baru';
  List<XFile> _selectedImages = [];

  final List<String> _imagePaths = [];
  final List<Uint8List> _previewBytes = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  String _currentUserName = '';
  String _currentUserPhone = '';
  // ⭐ [MODIFIKASI] Tambah variabel untuk URL foto profil
  String? _currentUserPhotoUrl;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCurrentUserInfo();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---
  Future<void> _loadCurrentUserInfo() async {
    String? name;
    String? phone;
    // ⭐ [MODIFIKASI] Variabel untuk URL Foto
    String? photoUrl;

    try {
      final userData = await TokenService.getUserData();

      if (userData != null) {
        try {
          final Map<String, dynamic> map = json.decode(userData);

          if (map['name'] is String) {
            name = map['name'] as String;
          }
          if (map.containsKey('phone_number') &&
              map['phone_number'] is String) {
            phone = map['phone_number'] as String;
          } else if (map.containsKey('phoneNumber') &&
              map['phoneNumber'] is String) {
            phone = map['phoneNumber'] as String;
          }
          // ⭐ [MODIFIKASI] Ambil URL Foto dari JWT/SharedPrefs
          if (map.containsKey('photo') && map['photo'] is String) {
            photoUrl = map['photo'] as String;
          } else if (map.containsKey('avatarUrl') &&
              map['avatarUrl'] is String) {
            photoUrl = map['avatarUrl'] as String;
          }
        } catch (_) {}
      }

      name ??= AuthService().currentUser?.name;
      phone ??= AuthService().currentUser?.phoneNumber;
      // ⭐ [MODIFIKASI] Ambil dari AuthService().currentUser
      photoUrl ??= AuthService().currentUser?.photo ??
          AuthService().currentUser?.avatarUrl;

      if (mounted) {
        setState(() {
          _currentUserName =
              (name != null && name.isNotEmpty) ? name : 'Pengguna';
          _currentUserPhone = (phone != null && phone.isNotEmpty) ? phone : '';
          _phoneController.text = _currentUserPhone;
          // ⭐ [MODIFIKASI] Simpan URL Foto
          _currentUserPhotoUrl = photoUrl;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUserName = 'Pengguna';
          _currentUserPhone = '';
          _phoneController.text = '';
          // ⭐ [MODIFIKASI] Reset URL Foto
          _currentUserPhotoUrl = null;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    // ... logic ...
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await ProductService.getCategories();

      if (mounted) {
        setState(() {
          // Tipe data ini sekarang menggunakan ProductCategory dari import, bukan dari definisi lokal.
          _categories = categories;
          _isLoading = false;
          // Tambahkan placeholder untuk 'Tambah Kategori Baru'
          _categories.add(_manualAddCategoryPlaceholder);
        });
      }
    } catch (e) {
      // AppLogger.log('Error loading categories: $e');

      if (mounted) {
        setState(() {
          // Jika gagal, pastikan placeholder tetap ada
          _categories = [_manualAddCategoryPlaceholder];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Gagal memuat kategori server. Buat kategori manual atau coba lagi.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ✅ [PENAMBAHAN KODE] - Menampilkan dialog untuk input nama kategori baru
  // MENGGANTI: Menambahkan parameter primaryColor
  Future<void> _showAddCategoryDialog(Color primaryColor) async {
    final newCategoryNameController = TextEditingController();

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              // MENGGANTI: Warna ikon hardcoded dengan primaryColor
              Icon(Icons.add_circle_outline, color: primaryColor),
              const SizedBox(width: 8),
              const Text('Tambah Kategori Baru',
                  style: TextStyle(fontSize: 18)),
            ],
          ),
          content: TextField(
            controller: newCategoryNameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nama Kategori (ex: Perhiasan)',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                // MENGGANTI: Warna border hardcoded dengan primaryColor
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = newCategoryNameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
              style: ElevatedButton.styleFrom(
                // MENGGANTI: Warna hardcoded dengan primaryColor
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      _addManualCategory(newName);
    }
  }

  // ✅ [PENAMBAHAN KODE] - Menambahkan kategori baru ke dalam list lokal
  void _addManualCategory(String name) {
    // ... logic ...
    final newCategory = ProductCategory(
      // ID Negatif menandakan kategori baru yang belum tersimpan di server
      id: -1,
      name: name,
      description: 'Kategori ditambahkan secara manual oleh pengguna.',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      // Hapus dan masukkan placeholder agar selalu di akhir
      _categories.remove(_manualAddCategoryPlaceholder);
      _categories.insert(0, newCategory);
      _categories.add(_manualAddCategoryPlaceholder);
      _selectedCategory = newCategory;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kategori "$name" ditambahkan dan dipilih.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // MENGGANTI: Warna hardcoded dengan primaryColor
        backgroundColor: Colors
            .green, // Biarkan hijau untuk sukses, tapi ini perlu diubah jika tema mendukung
      ),
    );
  }

  Future<int?> _createCategoryOnServer(String name) async {
    // ... logic ...
    try {
      final token = await TokenService.getToken();

      if (token == null) {
        throw Exception("Pengguna tidak terautentikasi.");
      }

      final newCategory = await ProductService.createCategory(
        token: token,
        name: name,
        description: "Kategori dibuat melalui aplikasi mobile oleh user.",
      );

      return newCategory?.id;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Gagal membuat kategori baru di server.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error: Tidak dapat menghubungi server kategori.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _pickImages() async {
    // ... logic ...
    if (_selectedImages.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maksimal 5 foto'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        for (var image in images) {
          if (_selectedImages.length >= 5) break;

          try {
            final bytes = await image.readAsBytes();

            setState(() {
              _selectedImages.add(image);
              _previewBytes.add(bytes); // Simpan bytes untuk preview

              if (!kIsWeb) {
                _imagePaths.add(image.path); // Simpan path untuk upload mobile
              }
            });
          } catch (e) {
            AppLogger.log('Failed to read image bytes/path: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membaca file gambar: ${e.toString()}'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih foto: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    // ... logic ...
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);

        if (_previewBytes.length > index) {
          _previewBytes.removeAt(index);
        }

        if (!kIsWeb && _imagePaths.length > index) {
          _imagePaths.removeAt(index);
        }

        if (_selectedImages.isEmpty) {
          _currentImageIndex = 0;
        } else if (_currentImageIndex >= _selectedImages.length) {
          _currentImageIndex = _selectedImages.length - 1;
        }

        if (_pageController.hasClients && _selectedImages.isNotEmpty) {
          _pageController.animateToPage(
            _currentImageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _submitProduct(Color primaryColor) async {
    // ... logic ...
    if (!_formKey.currentState!.validate()) {
      // AppLogger.log('AddProductPage: form validation failed');
      return;
    }

    if (_selectedCategory == null ||
        _selectedCategory == _manualAddCategoryPlaceholder) {
      // AppLogger.log('AddProductPage: no valid category selected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pilih kategori produk'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    if (_selectedImages.isEmpty) {
      // AppLogger.log('AddProductPage: no images selected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pilih minimal 1 foto produk'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    int finalCategoryId = _selectedCategory!.id;

    try {
      if (_selectedCategory!.id < 0) {
        final newId = await _createCategoryOnServer(_selectedCategory!.name);

        if (newId == null) {
          throw Exception(
            "Kategori gagal dibuat di server. Pengunggahan produk dibatalkan.",
          );
        }

        finalCategoryId = newId;
        _loadCategories();
      }

      final token = await TokenService.getToken();

      if (token == null) {
        // AppLogger.log('AddProductPage: token is null - user not logged in');
        throw Exception('Anda harus login untuk mengunggah produk');
      }

      final priceText = _priceController.text.replaceAll(RegExp(r'[^\d]'), '');
      final price = int.parse(priceText);

      if (_descriptionController.text.trim().length < 10) {
        throw Exception('Deskripsi produk minimal 10 karakter');
      }

      String rawSellerPhone = _phoneController.text.trim();

      if (rawSellerPhone.isEmpty) {
        throw Exception('Nomor telepon harus diisi.');
      }

      String cleanedPhone = rawSellerPhone.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanedPhone.startsWith('0')) {
        cleanedPhone = '62' + cleanedPhone.substring(1);
      } else if (cleanedPhone.startsWith('+62')) {
        cleanedPhone = cleanedPhone.substring(1);
      }

      final String sellerPhone = cleanedPhone;

      if (sellerPhone.isEmpty || sellerPhone.length < 8) {
        throw Exception('Nomor telepon tidak valid.');
      }

      final List<MultipartFile> files = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final x = _selectedImages[i];
        final filename = x.name.isNotEmpty ? x.name : 'photo_$i.jpg';
        final lower = filename.toLowerCase();

        MediaType contentType = MediaType('image', 'jpeg');
        if (lower.endsWith('.png')) {
          contentType = MediaType('image', 'png');
        } else if (lower.endsWith('.webp')) {
          contentType = MediaType('image', 'webp');
        } else if (lower.endsWith('.gif')) {
          contentType = MediaType('image', 'gif');
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          contentType = MediaType('image', 'jpeg');
        }

        if (kIsWeb) {
          if (_previewBytes.length <= i || _previewBytes[i].isEmpty) {
            throw Exception(
              'Data gambar ke-${i + 1} hilang saat pengunggahan (WEB).',
            );
          }
          final bytes = _previewBytes[i];
          files.add(
            MultipartFile.fromBytes(
              bytes,
              filename: filename,
              contentType: contentType,
            ),
          );
        } else {
          if (_imagePaths.length <= i || _imagePaths[i].isEmpty) {
            throw Exception(
              'Path file gambar ke-${i + 1} hilang saat pengunggahan (MOBILE).',
            );
          }
          files.add(
            await MultipartFile.fromFile(
              _imagePaths[i],
              filename: filename,
              contentType: contentType,
            ),
          );
        }
      }

      final newProduct = await ProductService.createProductMultipart(
        token: token,
        categoryId: finalCategoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        status: "tersedia",
        conditionProduct: _selectedCondition,
        location: _locationController.text.trim(),
        sellerPhone: sellerPhone,
        photoFiles: files,
      );

      if (newProduct != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Produk berhasil diunggah!'),
              ],
            ),
            // MENGGANTI: Warna hardcoded dengan primaryColor
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        _selectedImages.clear();
        _imagePaths.clear();
        _previewBytes.clear();

        Navigator.pop(context, true);
      } else {
        throw Exception('Server tidak mengembalikan data produk. Coba lagi.');
      }
    } on DioException catch (e) {
      // AppLogger.log('Upload product DioException: ${e.message}');
      // AppLogger.log('Upload product DioException response: ${e.response?.data}');

      if (!mounted) return;

      String errorMessage = 'Gagal mengunggah produk';
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (data is Map) {
        if (data['message'] is String &&
            (data['message'] as String).isNotEmpty) {
          errorMessage = data['message'];
        } else if (data['errors'] is Map &&
            (data['errors'] as Map).isNotEmpty) {
          final firstKey = (data['errors'] as Map).keys.first;
          final firstErr =
              (data['errors'][firstKey] as List?)?.first?.toString();
          if (firstErr != null && firstErr.isNotEmpty) {
            errorMessage = firstErr;
          }
        }
      }

      if (_selectedCategory!.id <= 0) {
        errorMessage =
            "Produk terkirim, namun server menolak ID kategori baru. Gunakan kategori yang sudah ada.";
      }

      if (status == 403) {
        final emailNotVerified =
            (data is Map && data['email_verified'] == false);
        if (emailNotVerified) {
          final message = (data['message'] as String?) ??
              'Email Anda belum diverifikasi. Silakan verifikasi email terlebih dahulu.';
          _showEmailNotVerifiedSheet(
              message, primaryColor); // Meneruskan primaryColor
          return;
        }
        errorMessage = errorMessage.isNotEmpty
            ? errorMessage
            : 'Akses ditolak. Pastikan akun Anda telah terverifikasi.';
      } else if (status == 401) {
        errorMessage = 'Sesi Anda berakhir. Silakan login kembali.';
      } else if (status == 409) {
        if (data is Map && data['message'] is String) {
          errorMessage = data['message'];
        } else {
          errorMessage = 'Terjadi konflik pada server.';
        }
      } else if (status == 422) {
        errorMessage = errorMessage.isNotEmpty
            ? errorMessage
            : 'Data produk tidak valid. Periksa kembali form.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Tidak dapat terhubung ke server.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal mengunggah produk';

        if (e is ProductUploadException) {
          final d = e.data;
          if (d is Map && d['message'] is String) {
            errorMessage = d['message'];
          } else if (d is String) {
            errorMessage = d;
          }
        } else {
          final s = e.toString();
          if (s.contains('Unauthenticated')) {
            errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
          } else if (s.contains('Validation')) {
            errorMessage =
                'Data produk tidak valid. Periksa kembali form Anda.';
          } else if (s.contains('network') || s.contains('connection')) {
            errorMessage = 'Periksa koneksi internet Anda dan coba lagi.';
          } else if (s.contains('ProductUploadException')) {
            errorMessage = s;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Future<void> _showEmailNotVerifiedSheet(
      String message, Color primaryColor) async {
    // ... logic ...
    final token = await TokenService.getToken();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.mark_email_unread, color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verifikasi Email Diperlukan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(message, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: token == null
                          ? null
                          : () async {
                              final ok =
                                  await AuthService.resendVerificationEmail(
                                token,
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Email verifikasi telah dikirim ulang.'
                                        : 'Gagal mengirim ulang email verifikasi.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Kirim Ulang'),
                      style: ElevatedButton.styleFrom(
                        // MENGGANTI: Warna hardcoded dengan primaryColor
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRupiah(String value) {
    // ... logic ...
    if (value.isEmpty) return '';

    String digits = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return '';

    String formatted = '';

    for (int i = digits.length - 1; i >= 0; i--) {
      formatted = digits[i] + formatted;

      if ((digits.length - i) % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }

    return 'Rp $formatted';
  }

  // 📦 WIDGET REUSABLE UNTUK DEKORASI INPUT
  // MENGGANTI: Menambahkan parameter primaryColor
  InputDecoration _buildInputDecoration({
    required String hintText,
    bool alignLabelWithHint = false,
    required Color primaryColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor:
          Colors.white, // Sesuaikan dengan screenshot (putih/abu-abu terang)
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1.0,
        ), // Garis tipis seperti di screenshot
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // MENGGANTI: Warna hardcoded dengan primaryColor
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      alignLabelWithHint: alignLabelWithHint,
      // prefixIcon dihapus karena tidak ada di screenshot (hanya teks placeholder)
      // kecuali untuk harga
    );
  }

  // 🛠️ WIDGET TEMPLATE INPUT TEXT BIASA (Judul, Lokasi, No. Telp, Deskripsi)
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildSimpleInput({
    required TextEditingController controller,
    required String hintText,
    String? label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _buildInputDecoration(
            hintText: hintText,
            alignLabelWithHint: maxLines > 1,
            primaryColor: primaryColor, // Meneruskan primaryColor
          ),
          validator: validator,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16), // Jarak antar field
      ],
    );
  }

  // 🛠️ WIDGET PREVIEW GAMBAR
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildImagePreview(Color primaryColor) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _selectedImages.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final bytesAvailable =
                _previewBytes.length > index && _previewBytes[index].isNotEmpty;

            if (bytesAvailable) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _previewBytes[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            }
            return const Center(
              child: Icon(Icons.error_outline, color: Colors.red),
            );
          },
        ),
        // Tombol Hapus (Overlay)
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(_currentImageIndex),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        // Indikator Halaman & Tombol Tambah
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                _selectedImages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white54,
                    border: Border.all(color: Colors.black54, width: 0.5),
                  ),
                ),
              ),
              if (_selectedImages.length < 5) const SizedBox(width: 16),
              if (_selectedImages.length < 5)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // MENGGANTI: Warna hardcoded dengan primaryColor
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ Tambah Foto (${_selectedImages.length}/5)',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      // Background warna putih agar tampilan bersih
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Menyesuaikan AppBar dengan tampilan screenshot
        backgroundColor: Colors.white,
        elevation: 0.5, // Tambahkan sedikit elevasi untuk pemisah
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          // Judul yang disederhanakan dari screenshot
          'Tambahkan Produk',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
              // MENGGANTI: Warna hardcoded dengan primaryColor
              child: CircularProgressIndicator(color: primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 80.0,
              ), // Padding untuk tombol bawah
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // 1. User/Penjual Info (Sesuai Screenshot: Naura farisyah)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey, // Warna default
                            child: ClipOval(
                              child: _currentUserPhotoUrl != null &&
                                      _currentUserPhotoUrl!.isNotEmpty
                                  ? Image.network(
                                      _currentUserPhotoUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) =>
                                          Image.asset(
                                        'assets/placeholder_profile.png',
                                        fit: BoxFit.cover,
                                      ),
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            // MENGGANTI: Warna hardcoded dengan primaryColor
                                            color: primaryColor,
                                          ),
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/placeholder_profile.png', // Fallback jika URL null
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUserName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _selectedImages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.grey[500],
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tambahkan Foto',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '0/5', // Menyesuaikan dengan teks di screenshot
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildImagePreview(
                                  primaryColor), // Meneruskan primaryColor
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Form Inputs (Judul, Harga, Kondisi, Kategori, No. Telp, Lokasi, Deskripsi)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          // Judul
                          _buildSimpleInput(
                            controller: _nameController,
                            hintText: 'Judul',
                            primaryColor:
                                primaryColor, // Meneruskan primaryColor
                            validator: (v) =>
                                v!.isEmpty ? 'Judul harus diisi' : null,
                          ),

                          // Harga
                          _buildPriceInput(
                              primaryColor), // Meneruskan primaryColor

                          // Kondisi
                          _buildConditionDropdown(
                              primaryColor), // Meneruskan primaryColor

                          // ✅ [PENAMBAHAN KODE] - Kategori Produk
                          _buildCategoryDropdown(
                              primaryColor), // Meneruskan primaryColor

                          // No. Telp
                          _buildSimpleInput(
                            controller: _phoneController,
                            hintText: 'No. Telp',
                            primaryColor:
                                primaryColor, // Meneruskan primaryColor
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v!.isEmpty ? 'Nomor telepon harus diisi' : null,
                          ),

                          // Lokasi
                          _buildSimpleInput(
                            controller: _locationController,
                            hintText: 'Lokasi',
                            primaryColor:
                                primaryColor, // Meneruskan primaryColor
                            validator: (v) =>
                                v!.isEmpty ? 'Lokasi harus diisi' : null,
                          ),

                          // Deskripsi
                          _buildSimpleInput(
                            controller: _descriptionController,
                            hintText: 'Deskripsi',
                            primaryColor:
                                primaryColor, // Meneruskan primaryColor
                            maxLines: 5,
                            validator: (v) {
                              if (v!.isEmpty) return 'Deskripsi harus diisi';
                              if (v.trim().length < 10)
                                return 'Deskripsi minimal 10 karakter';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

      // Tombol Unggah yang diletakkan di bawah (persistent)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => _submitProduct(primaryColor), // Meneruskan primaryColor
            style: ElevatedButton.styleFrom(
              // MENGGANTI: Warna hardcoded dengan primaryColor
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  8,
                ), // Menyesuaikan dengan sudut screenshot
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Unggah',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  // 🛠️ WIDGET INPUT KHUSUS HARGA (Karena berbeda styling)
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildPriceInput(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Harga (opsional, jika ingin tetap ada)
        // const Padding(
        //   padding: EdgeInsets.only(bottom: 8.0),
        //   child: Text('Harga', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        // ),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration(
            hintText: 'Harga',
            primaryColor: primaryColor, // Meneruskan primaryColor
          ),
          onChanged: (value) {
            String formatted = _formatRupiah(value);
            if (formatted != value) {
              _priceController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Harga tidak boleh kosong';
            String digits = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.isEmpty ||
                int.tryParse(digits) == null ||
                int.parse(digits) <= 0) {
              return 'Harga harus lebih dari 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // 🛠️ WIDGET DROPDOWN KONDISI (Menyesuaikan dengan styling TextFormFied biasa)
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildConditionDropdown(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Kondisi (opsional, jika ingin tetap ada)
        // const Padding(
        //   padding: EdgeInsets.only(bottom: 8.0),
        //   child: Text('Kondisi', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        // ),
        DropdownButtonFormField<String>(
          value: _selectedCondition,
          isExpanded: true,
          decoration: _buildInputDecoration(
            hintText: 'Kondisi',
            primaryColor: primaryColor, // Meneruskan primaryColor
          ),
          items: const [
            DropdownMenuItem(value: 'baru', child: Text('Baru')),
            DropdownMenuItem(value: 'bekas', child: Text('Bekas')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCondition = value!;
            });
          },
          validator: (value) => value == null ? 'Pilih kondisi produk' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ✅ [PENAMBAHAN KODE] - WIDGET DROPDOWN KATEGORI
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildCategoryDropdown(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<ProductCategory>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: _buildInputDecoration(
            hintText: 'Pilih Kategori',
            primaryColor: primaryColor, // Meneruskan primaryColor
          ),
          items: _categories.map<DropdownMenuItem<ProductCategory>>((
            ProductCategory category,
          ) {
            return DropdownMenuItem<ProductCategory>(
              value: category,
              child: Text(
                category.name,
                style: category == _manualAddCategoryPlaceholder
                    ? TextStyle(
                        fontStyle: FontStyle.italic,
                        // MENGGANTI: Warna hardcoded dengan primaryColor
                        color: primaryColor,
                      )
                    : null,
              ),
            );
          }).toList(),
          onChanged: (ProductCategory? newValue) {
            if (newValue == _manualAddCategoryPlaceholder) {
              // Jika memilih opsi 'Tambah Kategori Baru...'
              _showAddCategoryDialog(primaryColor); // Meneruskan primaryColor
            } else {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null || value == _manualAddCategoryPlaceholder) {
              return 'Kategori harus dipilih';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
