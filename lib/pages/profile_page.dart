import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import 'edit_profile_page.dart';
import '../widgets/change_password_modal.dart';
import 'about_page.dart';
import 'terms_page.dart';
import 'notification_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  // State untuk mengontrol dialog loading saat update password
  bool _isUpdatingPassword = false;

  Key _avatarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // 💡 Perbaikan: Selalu cek mounted sebelum setState
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _fetchUserProfile();
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _avatarKey = UniqueKey();
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      // AppLogger.log('🔄 Fetching user profile...');

      final response = await _authService.getUserProfile();
      // AppLogger.log('🌐 API response: $response');

      if (response['success'] == true && response['user'] != null) {
        _currentUser = response['user'];
        // AppLogger.log(
        //   '✅ Updated user from API: ${_currentUser?.name} - ${_currentUser?.email}',
        // );
      } else {
        _currentUser = _authService.currentUser;
        // AppLogger.log(
        //   '📋 Using cached user data: ${_currentUser?.name} - ${_currentUser?.email}',
        // );
      }
    } catch (e) {
      // AppLogger.log('❌ Error fetching user profile: $e');
    }
  }

  Widget _buildAvatar(Color primaryColor) {
    // Menerima primaryColor
    final imageUrl = _currentUser?.photo?.isNotEmpty == true
        ? _currentUser!.photo!
        : _currentUser?.avatarUrl?.isNotEmpty == true
            ? _currentUser!.avatarUrl!
            : null;

    return Container(
      key: _avatarKey,
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: Colors.white,
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _defaultAvatar(primaryColor), // Meneruskan warna
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    // MENGGANTI: Warna hardcoded dengan primaryColor
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                },
              )
            : _defaultAvatar(primaryColor), // Meneruskan warna
      ),
    );
  }

  Widget _defaultAvatar(Color primaryColor) {
    // Menerima primaryColor
    // MENGGANTI: Warna hardcoded dengan primaryColor
    return Icon(Icons.person, size: 50, color: primaryColor);
  }

  void _showLogoutDialog(BuildContext context, Color primaryColor) {
    // Warna tema untuk dialog
    final lightPrimary = Color.lerp(primaryColor, Colors.white, 0.5)!;
    final extraLightPrimary = Color.lerp(primaryColor, Colors.white, 0.8)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    // MENGGANTI: Warna hardcoded (0xFF90EE90) dengan lightPrimary
                    color: lightPrimary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Anda ingin Keluar?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kamu akan keluar dari akun ini.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            // MENGGANTI: Warna latar hardcoded (0xFFE0F7E0) dengan extraLightPrimary
                            color: extraLightPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              // MENGGANTI: Teks hardcoded (0xFF00C853) dengan primaryColor
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          await _authService.logout();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logout berhasil')),
                            );

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login', // Pastikan rute ini benar
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            // MENGGANTI: Latar Pink Muda (0xFFFFE0E5) ke warna netral atau primaryColor sedikit transparan
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Keluar',
                            style: TextStyle(
                              color: Colors.red, // Biarkan merah untuk Logout
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    required Color iconColor, // BARU: Menambahkan parameter iconColor
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // MENGGANTI: Warna ikon hardcoded dengan iconColor
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return ChangePasswordModal(
          currentUser: _currentUser,
          onPasswordUpdate: (bool success) {
            if (mounted) {
              setState(() {
                _isUpdatingPassword = false;
              });

              if (success) {
                _loadUserProfile();
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    // Tampilkan overlay loading saat _isUpdatingPassword true
    if (_isUpdatingPassword) {
      return Scaffold(
        backgroundColor: Colors.black54,
        body: Center(
            child: CircularProgressIndicator(
                color: primaryColor)), // MENGGANTI warna loading
      );
    }

    return Scaffold(
      // MENGGANTI: Warna latar belakang hardcoded dengan primaryColor
      backgroundColor: primaryColor,
      appBar: AppBar(
        // MENGGANTI: Warna AppBar hardcoded dengan primaryColor
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildAvatar(primaryColor), // Meneruskan primaryColor
                          const SizedBox(height: 16),
                          Text(
                            _currentUser?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.email ?? 'user@example.com',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfilePage(user: _currentUser),
                                ),
                              );
                              if (result == true) {
                                await _loadUserProfile();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              // MENGGANTI: foregroundColor hardcoded dengan primaryColor
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Edit Profile >',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // NAVIGASI KE HALAMAN NOTIFIKASI
                            _buildMenuItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifikasi',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationPage(),
                                  ),
                                );
                              },
                              iconColor: primaryColor, // Meneruskan warna
                            ),
                            const SizedBox(height: 8),
                            // Menu Ubah Password memanggil pop-up langsung
                            _buildMenuItem(
                              icon: Icons.lock_outline,
                              title: 'Ubah Password',
                              onTap: _showChangePasswordDialog,
                              iconColor: primaryColor, // Meneruskan warna
                            ),
                            // Arahkan ke AboutPage
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              title: 'Tentang Aplikasi',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AboutPage(),
                                  ),
                                );
                              },
                              iconColor: primaryColor, // Meneruskan warna
                            ),
                            // Arahkan ke TermsPage
                            _buildMenuItem(
                              icon: Icons.description_outlined,
                              title: 'Syarat dan Ketentuan',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsPage(),
                                  ),
                                );
                              },
                              iconColor: primaryColor, // Meneruskan warna
                            ),
                            const SizedBox(height: 24),
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Keluar',
                              textColor: Colors.red,
                              onTap: () => _showLogoutDialog(context,
                                  primaryColor), // Meneruskan primaryColor ke dialog
                              iconColor: Colors.red, // Icon logout tetap merah
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
