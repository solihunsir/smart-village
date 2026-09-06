import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final User? user;
  const EditProfilePage({Key? key, this.user}) : super(key: key);
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Hanya controller untuk data profil
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  User? _currentUser;
  bool _isLoading = true;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // AppLogger.log('🔄 Loading user data for edit profile...');
      _currentUser = widget.user ?? _authService.currentUser;

      // Jika user belum ada, ambil dari server
      if (_currentUser == null) {
        final response = await _authService.getUserProfile();
        if (response['success'] == true && response['user'] != null) {
          _currentUser = response['user'];
        }
      }

      if (_currentUser != null) {
        _nameController.text = _currentUser!.name;
        _emailController.text = _currentUser!.email;
        _phoneController.text = _currentUser!.phoneNumber ?? '';
      }
      // AppLogger.log('✅ User data loaded: ${_currentUser?.name}');
    } catch (e) {
      // AppLogger.log('❌ Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildAvatarWidget(Color primaryColor) {
    ImageProvider? imageProvider;

    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (_currentUser?.photo?.isNotEmpty == true) {
      imageProvider = NetworkImage(_currentUser!.photo!);
    } else if (_currentUser?.avatarUrl?.isNotEmpty == true) {
      imageProvider = NetworkImage(_currentUser!.avatarUrl!);
    }

    if (imageProvider == null) {
      return const Icon(Icons.person, size: 60, color: Colors.white);
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
          child: CircularProgressIndicator(color: primaryColor),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.person, size: 60, color: Colors.white);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
            colors: [primaryColor.withOpacity(0.1), Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              color: Colors.grey,
                            ),
                            child: ClipOval(
                                child: _buildAvatarWidget(
                                    primaryColor)), // Meneruskan primaryColor
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              // MENGGANTI: Warna hardcoded (Colors.blue[600]) dengan primaryColor
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ganti Foto',
                              style: TextStyle(
                                // MENGGANTI: Warna hardcoded (Colors.blue[600]) dengan primaryColor
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          label: 'Nama Lengkap',
                          controller: _nameController,
                          primaryColor: primaryColor, // Meneruskan primaryColor
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'Email (Tidak Dapat Diubah)',
                          controller: _emailController,
                          primaryColor: primaryColor, // Meneruskan primaryColor
                          readOnly: true,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'No. Telp',
                          controller: _phoneController,
                          primaryColor: primaryColor, // Meneruskan primaryColor
                          keyboardType: TextInputType.phone,
                        ),

                        // --- FORM KATA SANDI DIHAPUS DARI SINI ---
                        const SizedBox(height: 60),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _saveProfile(
                                primaryColor), // Meneruskan primaryColor
                            style: ElevatedButton.styleFrom(
                              // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Simpan Perubahan Profil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Color primaryColor,
    bool obscureText = false,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: UnderlineInputBorder(
              // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
              borderSide: BorderSide(color: primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Future<void> _saveProfile(Color primaryColor) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );

      final response = await _authService.updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        imageFile: _pickedImage,
        // Kirim data sandi sebagai null/kosong karena ini hanya untuk profil data
        currentPassword: null,
        newPassword: null,
        newPasswordConfirmation: null,
      );

      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Profile berhasil diperbarui!',
              ),
              // MENGGANTI: Warna hardcoded (0xFF00A310) dengan primaryColor
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          setState(() {
            // Reset gambar yang baru dipilih
            _pickedImage = null;
          });

          await _loadUserData();

          // Pop halaman dengan hasil sukses
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Gagal memperbarui profile.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi error saat update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
