import 'package:desaku/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../config/api_config.dart';
import 'community_chat_page.dart';
import '../services/token_service.dart'; // Import TokenService
import 'login_page.dart'; // Import LoginPage

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage> {
  List<Community> _communities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Memanggil API Publik (list komunitas)
      final fetchedList = await CommunityService.fetchCommunities();
      if (mounted) {
        setState(() {
          _communities = fetchedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.log('Error fetching communities: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_communities.isEmpty) {
            _errorMessage = 'Gagal memuat saluran. Silakan coba lagi.';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat data baru: $e')),
            );
          }
        });
      }
    }
  }

  // FUNGSI BARU: Menangani navigasi dengan pengecekan login
  Future<void> _handleNavigationToChat(Community community) async {
    final isLoggedIn = await TokenService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Jika sudah login, lanjutkan ke halaman chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityChatPage(community: community),
        ),
      );
    } else {
      // Jika belum login, arahkan ke halaman login
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      // Setelah kembali dari login, cek status dan navigasi jika berhasil login
      if (await TokenService.isLoggedIn()) {
        if (mounted) {
          Navigator.pushReplacement(
            // Ganti halaman login dengan halaman chat
            context,
            MaterialPageRoute(
              builder: (context) => CommunityChatPage(community: community),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Saluran Komunitas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00B140)),
      );
    }

    if (_communities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _errorMessage != null
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                size: 48,
                color: _errorMessage != null ? Colors.orange[600] : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage != null
                    ? 'Gagal Memuat Data'
                    : 'Belum Ada Saluran Komunikasi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage != null
                    ? 'Terjadi masalah saat mengambil data. Periksa koneksi Anda.'
                    : 'Data saluran komunitas masih kosong di server.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (true) // Selalu tampilkan tombol coba lagi jika kosong
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: _fetchCommunities,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B140),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCommunities,
      color: const Color(0xFF00B140),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _communities.length,
        itemBuilder: (context, index) {
          final community = _communities[index];
          return _buildCommunityListItem(context, community);
        },
      ),
    );
  }

  Widget _buildCommunityListItem(BuildContext context, Community community) {
    final fullImageUrl = '${ApiConfig.baseUrl}${community.imageUrl}';

    return Column(
      children: [
        InkWell(
          // PERUBAHAN: Memanggil fungsi yang mengecek login sebelum navigasi
          onTap: () => _handleNavigationToChat(community),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.groups, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${community.memberCount} Anggota',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}
