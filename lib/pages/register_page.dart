import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'package:desaku/utils/app_logger.dart';
import '../services/village_service.dart';
import '../models/village_settings.dart';
import '../config/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  VillageSettings? _villageSettings;

  @override
  void initState() {
    super.initState();
    _loadVillageSettings();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadVillageSettings() async {
    try {
      final settings = await VillageService.getVillageSettings();
      if (mounted) {
        setState(() => _villageSettings = settings);
      }
    } catch (e) {
      AppLogger.log('Error loading village settings for logo: $e');
    }
  }

  // Helper untuk membuat TextFormField
  Widget _buildRegisterTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    required Color primaryColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  // FUNGSI REGISTER BIASA
  Future<void> _register(Color primaryColor) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password tidak cocok')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String rawPhone = _phoneController.text.trim();
    String cleanedPhone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedPhone.startsWith('0')) {
      cleanedPhone = '62' + cleanedPhone.substring(1);
    }

    if (cleanedPhone.isEmpty || cleanedPhone.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nomor HP tidak valid setelah diformat.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final finalPhoneNumber = cleanedPhone;

    try {
      final response = await _authService.register(
        _fullNameController.text,
        _emailController.text,
        _passwordController.text,
        phoneNumber: finalPhoneNumber,
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  'Registrasi berhasil! Silakan login dengan akun Anda.',
            ),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Kembali ke halaman Login
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Registrasi gagal. Silakan coba lagi.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan tidak terduga: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 🌟 FUNGSI BARU: Login/Daftar dengan Google
  Future<void> _registerWithGoogle(Color primaryColor) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil fungsi Google Sign-In yang sama dengan LoginPage
      final response = await _authService.signInWithGoogle();

      if (response['success'] == true && mounted) {
        final userName =
            (response['user'] != null && response['user'].name != null)
                ? response['user'].name
                : 'Pengguna Google';

        // Tampilkan dialog sukses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: primaryColor, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    'Pendaftaran Berhasil!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selamat datang, $userName! Anda masuk menggunakan Google.',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pop();
          // Navigasi ke halaman utama setelah sukses login/daftar via Google
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Login/Daftar Google gagal. Coba lagi.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Exception during Google registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Terjadi kesalahan tidak terduga saat menggunakan Google Sign-In.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget untuk menampilkan logo desa secara dinamis dari API
  Widget _buildVillageLogo(Color primaryColor) {
    final logoUrl = _villageSettings?.logoDesa;
    const double logoSize = 120.0;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      String normalizedUrl;
      if (logoUrl.startsWith('http')) {
        normalizedUrl = logoUrl;
      } else if (logoUrl.startsWith('/storage')) {
        normalizedUrl = '${ApiConfig.baseUrl}$logoUrl';
      } else {
        normalizedUrl =
            '${ApiConfig.baseUrl}/storage/${logoUrl.replaceAll(RegExp(r"^/"), "")}';
      }

      return Image.network(
        normalizedUrl,
        height: logoSize,
        width: logoSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.public,
          size: logoSize,
          color: primaryColor,
        ),
      );
    }
    return Icon(
      Icons.public,
      size: logoSize,
      color: primaryColor,
    );
  }

  // Helper untuk membuat tombol social login
  Widget _buildSocialLoginButton({
    required Color primaryColor,
    required String text,
    required VoidCallback? onTap, // Menerima fungsi onTap
  }) {
    return GestureDetector(
      onTap: onTap, // Hubungkan aksi onTap
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              height: 24,
              width: 24,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
            ),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final linkColor = primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tombol Close 'X'
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bagian Logo dan Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LOGO DINAMIS
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildVillageLogo(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    const Text(
                      'Silahkan Daftar Akun Anda.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bergabunglah dengan komunitas desa untuk berbagi informasi!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 🎯 Tombol Daftar dengan Google (Dihubungkan ke aksi baru)
                    _buildSocialLoginButton(
                      primaryColor: primaryColor,
                      text: 'Daftar dengan Google',
                      onTap: _isLoading
                          ? null
                          : () => _registerWithGoogle(primaryColor),
                    ),

                    const SizedBox(height: 24),

                    // Divider 'atau'
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // FORM REGISTRASI
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nama Lengkap
                          _buildRegisterTextField(
                            controller: _fullNameController,
                            hintText: 'Nama Lengkap',
                            primaryColor: primaryColor,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama wajib diisi.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Email
                          _buildRegisterTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'Email',
                            primaryColor: primaryColor,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return 'Email tidak valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // NOMOR HANDPHONE
                          _buildRegisterTextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            hintText: 'Nomor Handphone ',
                            primaryColor: primaryColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nomor HP wajib diisi.';
                              }
                              String cleaned = value.replaceAll(
                                RegExp(r'[^\d]'),
                                '',
                              );
                              if (cleaned.length < 9) {
                                return 'Nomor HP minimal 9 digit.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password
                          _buildRegisterTextField(
                            controller: _passwordController,
                            obscureText: true,
                            hintText: 'Password ',
                            primaryColor: primaryColor,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password minimal 6 karakter.'; // Diubah dari 8 ke 6 agar konsisten dengan validator
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Konfirmasi Password
                          _buildRegisterTextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            hintText: 'Konfirmasi Password',
                            primaryColor: primaryColor,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password wajib diisi.';
                              }
                              if (value != _passwordController.text) {
                                return 'Password tidak cocok.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Tombol Daftar Reguler
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _register(primaryColor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Sudah punya akun? Masuk disini.',
                          style: TextStyle(
                            color: linkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
