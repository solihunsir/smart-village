import 'package:desaku/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import '../services/community_service.dart';
import '../services/token_service.dart';
import 'login_page.dart';

class CommunityDetailPage extends StatefulWidget {
  final Community community;
  const CommunityDetailPage({super.key, required this.community});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  Future<Map<String, dynamic>>? _communityDetailsFuture;
  bool _isMember = false;
  bool _isUserLoggedIn = false;

  List<User> _members = [];
  bool _isLoadingMembers = true;

  int _currentMemberCount = 0;

  @override
  void initState() {
    super.initState();
    _currentMemberCount = widget.community.memberCount;
    _checkLoginStatusAndFetch();
  }

  Future<void> _checkLoginStatusAndFetch() async {
    _isUserLoggedIn = await TokenService.isLoggedIn();
    setState(() {
      _communityDetailsFuture = _fetchCommunityDetails();
    });
    _fetchMembers();
  }

  Future<void> _handleRefresh() async {
    await _checkLoginStatusAndFetch();
    await _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final Map<String, dynamic> response =
          await CommunityService.fetchCommunityMembers(widget.community.id);

      final List<dynamic> rawMembers = response['data']['data'] ?? [];

      List<User> tempMembers = [];
      for (var json in rawMembers) {
        try {
          tempMembers.add(User.fromJson(json));
        } catch (e) {
          AppLogger.log(
            'Gagal memproses JSON Anggota (dari API members): $json. Error: $e',
          );
        }
      }

      if (mounted) {
        setState(() {
          _members = tempMembers;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      AppLogger.log('Gagal memuat daftar anggota lengkap: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchCommunityDetails() async {
    try {
      final data = await CommunityService.fetchCommunityDetails(
        widget.community.id,
        postPage: 1,
      );

      if (mounted) {
        setState(() {
          _isMember = data['is_member'] as bool? ?? false;
          _currentMemberCount =
              data['members_count'] as int? ?? _currentMemberCount;
        });
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleMembershipToggle() async {
    if (!_isUserLoggedIn) {
      _showLoginRequiredDialog(context, 'bergabung/keluar komunitas');
      return;
    }

    setState(() => _isLoadingMembers = true);

    try {
      final success = _isMember
          ? await CommunityService.leaveCommunity(widget.community.id)
          : await CommunityService.joinCommunity(widget.community.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isMember ? 'Berhasil keluar komunitas.' : 'Berhasil bergabung!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _checkLoginStatusAndFetch();
        _fetchMembers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
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
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
              _checkLoginStatusAndFetch();
              _fetchMembers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF00B140),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _communityDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError && _members.isEmpty) {
              return Center(
                child: Text('Gagal memuat detail: ${snapshot.error}'),
              );
            }

            return _buildContent(context, _isLoadingMembers);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool loading) {
    final community = widget.community;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          backgroundColor: const Color(0xFF00B140),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Image.network(
              '${ApiConfig.baseUrl}${community.imageUrl}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_currentMemberCount Anggota',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Keluar / Bergabung
                      TextButton(
                        onPressed: _handleMembershipToggle,
                        style: TextButton.styleFrom(
                          backgroundColor: _isMember
                              ? Colors.white
                              : const Color(0xFF00B140),
                          foregroundColor:
                              _isMember ? Colors.red : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color:
                                  _isMember ? Colors.red : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isMember ? 'Keluar' : 'Bergabung',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    community.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Bagian Anggota Header
            Container(color: Colors.grey.shade100, height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
              child: Text(
                'Anggota',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            if (loading && _members.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF00B140)),
                ),
              )
            else if (_members.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Komunitas ini belum memiliki anggota.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              // Menampilkan daftar anggota lengkap dari _members
              ..._members.map((member) => _buildMemberItem(member)).toList(),

            const SizedBox(height: 40),
          ]),
        ),
      ],
    );
  }

  // 🎯 FUNGSI _buildMemberItem yang DIPERBAIKI: Menggunakan member.photoUrl
  Widget _buildMemberItem(User member) {
    String role = member.id == widget.community.creatorId ? ' (Admin)' : '';

    // Ambil URL lengkap dari photoUrl, karena API sudah menyediakannya
    final String? fullImageUrl = member.photoUrl;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            // Gunakan NetworkImage jika fullImageUrl tersedia
            backgroundImage:
                fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
            // Fallback ke ikon default jika gambar tidak ada
            child: fullImageUrl == null
                ? const Icon(Icons.person, color: Colors.grey, size: 30)
                : null,
          ),
          title: Text(
            '${member.name}$role',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          onTap: () {
            // Aksi saat anggota diklik
          },
        ),
        Divider(height: 1, indent: 72, color: Colors.grey.shade200),
      ],
    );
  }
}
