import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'package:desaku/utils/app_logger.dart';
import '../services/village_service.dart';
import '../models/village_settings.dart';
import '../config/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _authService = AuthService();
  VillageSettings? _villageSettings;

  @override
  void initState() {
    super.initState();
    _loadVillageSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  // -------------------------------------------------------------
  // FUNGSI LOGIN REGULER
  // -------------------------------------------------------------
  Future<void> _login(Color primaryColor) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email dan password harus diisi')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response['success'] == true && mounted) {
        final userName =
            (response['user'] != null && response['user'].name != null)
                ? response['user'].name
                : 'Pengguna';

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
                    'Login Berhasil!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selamat datang, $userName!',
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
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Email atau password salah'),
            backgroundColor: Colors.red,
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

  // -------------------------------------------------------------
  // FUNGSI LOGIN GOOGLE
  // -------------------------------------------------------------
  Future<void> _loginWithGoogle(Color primaryColor) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.signInWithGoogle(); // <-- AKSI UTAMA

      if (response['success'] == true && mounted) {
        final userName =
            (response['user'] != null && response['user'].name != null)
                ? response['user'].name
                : 'Pengguna Google';

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
                    'Login Berhasil!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selamat datang, $userName!',
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
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Login Google gagal total.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Exception during Google login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan tidak terduga saat login Google.'),
            backgroundColor: Colors.red,
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

  // -------------------------------------------------------------
  // WIDGET HELPERS
  // -------------------------------------------------------------

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required Color primaryColor,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  // WIDGET HELPER YANG HILANG (DIKEMBALIKAN)
  Widget _buildSocialLoginButton({
    required Color primaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
            'assets/images/google_logo.png', // Pastikan path ini benar
            height: 24,
            width: 24,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
          ),
          const Expanded(
            child: Text(
              'Masuk dengan Google',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

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
              // Bagian Logo dan Selamat Datang
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          _buildVillageLogo(primaryColor),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Selamat datang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berbagi informasi seputar Desa!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tombol Masuk dengan Google
                    GestureDetector(
                      // 🎯 HUBUNGKAN AKSI KE FUNGSI BARU DI SINI
                      onTap: _isLoading
                          ? null
                          : () => _loginWithGoogle(primaryColor),
                      child:
                          _buildSocialLoginButton(primaryColor: primaryColor),
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

                    // Input Email
                    _buildInputField(
                      controller: _emailController,
                      hintText: 'Email',
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),

                    // Input Password
                    _buildInputField(
                      controller: _passwordController,
                      hintText: 'Password',
                      primaryColor: primaryColor,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tombol Masuk
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => _login(primaryColor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Link Daftar dan Lupa Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            'Belum punya akun? Daftar disini.',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/forgot-password',
                            );
                          },
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
