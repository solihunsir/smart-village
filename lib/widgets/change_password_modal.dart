// File: lib/widgets/change_password_modal.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../services/auth_service.dart';
import '../models/auth_models.dart';

class ChangePasswordModal extends StatefulWidget {
  final User? currentUser;
  final Function(bool success) onPasswordUpdate;

  const ChangePasswordModal({
    super.key,
    required this.currentUser,
    required this.onPasswordUpdate,
  });

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ✅ PENTING: Controller sekarang berada di dalam State dan diinisialisasi/dibaca sekali
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _newPasswordConfirmationController;

  final AuthService _authService = AuthService();
  bool _isSaving = false;

  // State lokal untuk visibilitas sandi
  bool _showOldPassword = true;
  bool _showNewPassword = true;
  bool _showConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _newPasswordConfirmationController = TextEditingController();
  }

  @override
  // ✅ PENTING: DISPOSE() DIJAMIN BERJALAN DENGAN AMAN
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmationController.dispose();
    super.dispose();
  }

  // Helper Field
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isLast,
    String? Function(String?)? validator,
    required bool showPasswordState,
    required Function(bool) toggleVisibility,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: showPasswordState,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Color(0xFFD0D0D0)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Color(0xFFD0D0D0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              // MENGGANTI: Warna hardcoded (0xFF00C853) dengan primaryColor
              borderSide: BorderSide(color: primaryColor),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPasswordState ? Icons.visibility : Icons.visibility_off,
                // MENGGANTI: Warna hardcoded (0xFF00C853) dengan primaryColor
                color: primaryColor,
              ),
              onPressed: () => toggleVisibility(!showPasswordState),
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _savePassword(Color primaryColor) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Tutup modal ubah sandi SEBELUM menampilkan dialog loading utama
    if (mounted) Navigator.of(context).pop(false);

    // Tampilkan loading di halaman ProfilePage
    widget.onPasswordUpdate(false);

    try {
      final response = await _authService.updateUserProfile(
        name: widget.currentUser?.name ?? '',
        phoneNumber: widget.currentUser?.phoneNumber,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        newPasswordConfirmation: _newPasswordConfirmationController.text.trim(),
        imageFile: null,
      );

      if (mounted) {
        // Beri tahu ProfilePage hasilnya
        widget.onPasswordUpdate(response['success'] == true);

        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Kata sandi berhasil diperbarui!',
              ),
              // MENGGANTI: Warna hardcoded (0xFF00C853) dengan primaryColor
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Gagal memperbarui kata sandi.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onPasswordUpdate(
          false,
        ); // Beri tahu ProfilePage bahwa proses selesai (gagal)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi error saat update sandi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Ubah Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan Password lama dan baru, geser kebawah bila anda menutup pengaturan ubah password ini.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Password Lama
                    _buildPasswordTextField(
                      controller: _currentPasswordController,
                      hintText: 'Password Lama',
                      showPasswordState: _showOldPassword,
                      isLast: false,
                      toggleVisibility: (newValue) =>
                          setState(() => _showOldPassword = newValue),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        return null;
                      },
                      primaryColor: primaryColor, // Meneruskan primaryColor
                    ),
                    const SizedBox(height: 16),

                    // Password Baru
                    _buildPasswordTextField(
                      controller: _newPasswordController,
                      hintText: 'Password Baru',
                      showPasswordState: _showNewPassword,
                      isLast: false,
                      toggleVisibility: (newValue) =>
                          setState(() => _showNewPassword = newValue),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        if (val.length < 8) return 'Minimal 8 Karakter';
                        return null;
                      },
                      primaryColor: primaryColor, // Meneruskan primaryColor
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password dapat berupa angka, huruf, dan simbol. Minimal 8 Karakter.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ulangi Password Baru
                    _buildPasswordTextField(
                      controller: _newPasswordConfirmationController,
                      hintText: 'Ulangi Password Baru',
                      showPasswordState: _showConfirmPassword,
                      isLast: true,
                      toggleVisibility: (newValue) =>
                          setState(() => _showConfirmPassword = newValue),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        if (val != _newPasswordController.text)
                          return 'Password tidak cocok';
                        return null;
                      },
                      primaryColor: primaryColor, // Meneruskan primaryColor
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Link Batal
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal Mengatur ulang Password',
                  style: TextStyle(
                    // MENGGANTI: Warna hardcoded (0xFF00C853) dengan primaryColor
                    color: primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _savePassword(
                          primaryColor), // Meneruskan primaryColor
                  style: ElevatedButton.styleFrom(
                    // MENGGANTI: Warna hardcoded (0xFF00C853) dengan primaryColor
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Ubah Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
