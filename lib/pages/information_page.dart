import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import 'announcement_detail_page.dart';
import 'news_detail_page.dart';
import '../services/village_service.dart';
import '../models/village_settings.dart';
import 'notification_page.dart';
import '../services/announcement_service.dart';
import '../services/news_service.dart';
import '../models/announcement_item.dart';
import '../models/news_item.dart';
import '../config/api_config.dart';
import 'home_page.dart' show CustomIcons;

// --- FUNGSI GLOBAL BARU: Membersihkan HTML dari Judul/Teks ---
String _stripHtmlTags(String htmlText) {
  if (htmlText.isEmpty) return '';
  final cleanText = htmlText
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'&[^;]+;'), ' ');

  return cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
}
// -----------------------------------------------------------

class InformationPage extends StatefulWidget {
  final String? initialTab;
  const InformationPage({Key? key, this.initialTab}) : super(key: key);
  @override
  _InformationPageState createState() => _InformationPageState();
}

String _formatDateShort(String? d) {
  if (d == null) return '';
  try {
    final parsed = DateTime.parse(d);
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  } catch (_) {
    final s = d;
    final idx = s.indexOf('T');
    if (idx > 0) return s.substring(0, idx);
    return s;
  }
}

class _InformationPageState extends State<InformationPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  // News data
  List<NewsItem> _news = [];
  bool _loadingNews = true;
  String? _errorNews;
  String? _selectedCategory;
  List<String> _categories = [];

  // Announcement data
  List<AnnouncementItem> _announcements = [];
  bool _loadingAnnouncements = true;
  String? _errorAnnouncements;

  @override
  bool get wantKeepAlive => true; // Keep the state when switching tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'news' ? 1 : 0,
    )..addListener(() {
        // Reload data when tab changes
        if (_tabController.index == 1 &&
            mounted &&
            _news.isEmpty &&
            !_loadingNews) {
          // AppLogger.log('InformationPage: Tab changed to news, loading data...');
          _loadNews();
        } else if (_tabController.index == 0 &&
            mounted &&
            _announcements.isEmpty &&
            !_loadingAnnouncements) {
          // AppLogger.log(
          //     'InformationPage: Tab changed to announcements, loading data...');
          _loadAnnouncements();
        }
      });
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant InformationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika initialTab berubah, update index controller
    if (widget.initialTab != oldWidget.initialTab) {
      if (widget.initialTab == 'news' && _tabController.index != 1) {
        _tabController.index = 1;
      } else if (widget.initialTab == 'announcements' &&
          _tabController.index != 0) {
        _tabController.index = 0;
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadAnnouncements(),
        _loadNews(),
      ]);
    } catch (e) {
      // AppLogger.log('Error loading initial data: $e');
    }
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() {
      _loadingAnnouncements = true;
      _errorAnnouncements = null;
    });
    try {
      // AppLogger.log('Loading announcements...');
      final items = await AnnouncementService.list(page: 1, perPage: 10);
      // AppLogger.log('Received ${items.length} announcements');

      if (mounted) {
        setState(() {
          _announcements = items;
          _loadingAnnouncements = false;
        });
      }
    } catch (e) {
      // AppLogger.log('Failed to load announcements: $e');
      if (mounted) {
        setState(() {
          _loadingAnnouncements = false;
          _errorAnnouncements = 'Gagal memuat pengumuman';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pengumuman: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _updateCategories() {
    // Map untuk menghitung jumlah berita per kategori
    final categoryCount = <String, int>{};

    // Hitung jumlah berita untuk setiap kategori
    for (var news in _news) {
      final category = _shortCategoryLabel(news.category);
      if (category.isNotEmpty) {
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    // Filter kategori yang memiliki minimal 1 berita
    final validCategories =
        categoryCount.keys.where((cat) => categoryCount[cat]! > 0).toList();

    if (!mounted) return;
    setState(() {
      if (validCategories.isNotEmpty) {
        validCategories.sort();
        _categories = ['Semua', ...validCategories];
        _selectedCategory ??= 'Semua';
      } else {
        _categories = [];
        _selectedCategory = null;
      }
    });
  }

  Future<void> _loadNews() async {
    // AppLogger.log('Loading news...');
    if (!mounted) return;
    setState(() {
      _loadingNews = true;
      _errorNews = null;
    });

    try {
      // AppLogger.log('Calling NewsService.list()');
      final items = await NewsService.list(
        page: 1,
        perPage: 10,
      );
      // AppLogger.log('Received ${items.length} news items');

      if (mounted) {
        setState(() {
          _news = items;
          _loadingNews = false;
        });
        _updateCategories();
      }
    } catch (e) {
      // AppLogger.log('Failed to load news: $e');
      if (mounted) {
        setState(() {
          _loadingNews = false;
          _errorNews = 'Gagal memuat berita';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat berita: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<VillageSettings?>(
          future: VillageService.getVillageSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data;
            final logoUrl = settings?.logoDesa ?? '';

            if (logoUrl.isNotEmpty) {
              return Container(
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    logoUrl.startsWith('http')
                        ? logoUrl
                        : '${ApiConfig.baseUrl}/storage/${logoUrl.startsWith('/') ? logoUrl.substring(1) : logoUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'e-Village',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return const Text(
              'e-Village',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              // MENGGANTI: Warna hardcoded (0xFF00B140) dengan primaryColor
              color: primaryColor,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          // MENGGANTI: labelColor hardcoded dengan primaryColor
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          // MENGGANTI: indicatorColor hardcoded dengan primaryColor
          indicatorColor: primaryColor,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Pengumuman'),
            Tab(text: 'Berita'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncementTab(),
          _buildNewsTab(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementTab() {
    // BARU: Ambil warna dari ThemeProvider (untuk CircularProgressIndicator dan ElevatedButton)
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    if (_loadingAnnouncements) {
      // MENGGANTI: Warna loading indicator hardcoded
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (_errorAnnouncements != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorAnnouncements!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              style: ElevatedButton.styleFrom(
                // MENGGANTI: Style button hardcoded
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_announcements.isEmpty) {
      return const Center(child: Text('Belum ada pengumuman'));
    }
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      // MENGGANTI: Warna RefreshIndicator hardcoded
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final a = _announcements[index];
          return _buildInformationCard(
            title: _stripHtmlTags(a.title), // MODIFIKASI: Render HTML Title
            subtitle: a.location ?? '-',
            date: _formatDateShort(a.date ?? '-'),
            imageUrl: _normalizeImageUrl(a.image),
            author: a.author,
            category: a.status ?? '', // Menggunakan status sebagai kategori
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnouncementDetailPage(
                    title: _stripHtmlTags(
                        a.title), // MODIFIKASI: Kirim Title yang sudah bersih
                    date: _formatDateShort(a.date ?? '-'),
                    location: a.location ?? '-',
                    content: a.content ?? '-',
                    imageUrl: a.image,
                    author: a.author,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<NewsItem> _getFilteredNews() {
    if (_selectedCategory == null ||
        _selectedCategory == 'Semua' ||
        _categories.isEmpty) {
      return _news;
    }
    return _news.where((news) {
      final category = _shortCategoryLabel(news.category);
      return category == _selectedCategory;
    }).toList();
  }

  Widget _buildNewsTab() {
    // BARU: Ambil warna dari ThemeProvider (untuk CircularProgressIndicator dan ElevatedButton)
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    if (_loadingNews) {
      // MENGGANTI: Warna loading indicator hardcoded
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (_errorNews != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorNews!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadNews,
              style: ElevatedButton.styleFrom(
                // MENGGANTI: Style button hardcoded
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_news.isEmpty) {
      return const Center(child: Text('Belum ada berita'));
    }

    final filteredNews = _getFilteredNews();

    return Column(
      children: [
        // Category tabs - hanya tampilkan jika ada berita dan kategori valid
        if (_news.isNotEmpty && _categories.isNotEmpty)
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    if (!mounted) return;
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      // MENGGANTI: Warna background hardcoded dengan primaryColor
                      color: isSelected ? primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        // MENGGANTI: Warna border hardcoded dengan primaryColor
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        // MENGGANTI: Warna teks hardcoded dengan primaryColor
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // News list
        if (filteredNews.isEmpty)
          const Expanded(
            child: Center(
              child: Text('Tidak ada berita dalam kategori ini'),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNews,
              // MENGGANTI: Warna RefreshIndicator hardcoded
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredNews.length,
                itemBuilder: (context, index) {
                  final n = filteredNews[index];
                  return _buildInformationCard(
                    title: _stripHtmlTags(
                        n.title), // MODIFIKASI: Render HTML Title
                    subtitle: '-',
                    date: _formatDateShort(n.date ?? '-'),
                    imageUrl: _normalizeImageUrl(n.image),
                    author: n.author,
                    category: n.category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(slug: n.slug),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInformationCard({
    required String title,
    required String subtitle,
    required String date,
    required String? imageUrl,
    String? author,
    dynamic category,
    required VoidCallback onTap,
  }) {
    // BARU: Ambil warna di sini (sebelum dipanggil di build list)
    final primaryColor = context.read<ThemeProvider>().primaryColor;
    final secondaryColor = context.read<ThemeProvider>().secondaryColor;

    final normalized = _normalizeImageUrl(imageUrl);

    // Logika untuk menyembunyikan badge jika status adalah 'published'
    final displayCategory = (category != null &&
            category.toString().toLowerCase() != 'published' &&
            category.toString().toLowerCase().trim().isNotEmpty)
        ? _shortCategoryLabel(category)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // MENGGANTI: Border card hardcoded (0xFF4CAF50) dengan primaryColor
        border: Border.all(color: primaryColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (normalized.isNotEmpty)
                      ? Image.network(
                          normalized,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _placeholderTile(
                                primaryColor, secondaryColor);
                          },
                        )
                      : _placeholderTile(primaryColor, secondaryColor),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and status category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Badge
                        if (displayCategory != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              // MENGGANTI: Background badge hardcoded (Colors.green[50]) dengan primaryColor (lebih terang)
                              color:
                                  Color.lerp(primaryColor, Colors.white, 0.9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                // MENGGANTI: Border badge hardcoded (Colors.green[100]) dengan primaryColor (lebih terang)
                                color: Color.lerp(
                                    primaryColor, Colors.white, 0.7)!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              displayCategory,
                              style: TextStyle(
                                fontSize: 10,
                                // MENGGANTI: Warna teks badge hardcoded (Colors.green[700]) dengan primaryColor
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location or subtitle
                    if (subtitle != '-') ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Date and author info
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (author != null && author.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              author,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  String _avatarInitials(String? value) {
    if (value == null || value.trim().isEmpty) return 'MK';
    final parts = value.trim().split(RegExp(r"\s+"));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _shortCategoryLabel(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      for (final k in ['name', 'title', 'nama', 'label']) {
        final v = value[k];
        if (v != null && v.toString().trim().isNotEmpty)
          return v.toString().trim();
      }
      if (value.values.isNotEmpty) return value.values.first.toString();
    }
    if (value is Iterable && value.isNotEmpty) {
      final first = value.first;
      if (first != null) return first.toString();
    }
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    if ((s.startsWith('{') && s.endsWith('}')) ||
        (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final decoded = json.decode(s);
        if (decoded is Map) {
          for (final k in ['name', 'title', 'nama', 'label']) {
            final v = decoded[k];
            if (v != null && v.toString().trim().isNotEmpty)
              return v.toString().trim();
          }
          if (decoded.values.isNotEmpty) return decoded.values.first.toString();
        }
        if (decoded is List && decoded.isNotEmpty)
          return decoded.first.toString();
      } catch (_) {
        // ignore JSON errors and fall back to regex
      }
    }
    final patterns = [
      RegExp(
        r'''['"]?name['"]?\s*[:=]\s*['"]?([^,}\n'"]+)['"]?''',
        caseSensitive: false,
      ),
      RegExp(
        r'''['"]?title['"]?\s*[:=]\s*['"]?([^,}\n'"]+)['"]?''',
        caseSensitive: false,
      ),
      RegExp(
        r'''['"]?nama['"]?\s*[:=]\s*['"]?([^,}\n'"]+)['"]?''',
        caseSensitive: false,
      ),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(s);
      if (m != null) return m.group(1)!.trim();
    }

    final simpleNameMatch = RegExp(
      r'name[:=]\s*([^,}]+)',
      caseSensitive: false,
    ).firstMatch(s);
    if (simpleNameMatch != null) return simpleNameMatch.group(1)!.trim();

    if (s.length > 30) {
      final parts = s
          .split(RegExp(r'[,|\n;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty)
        return parts[0].replaceAll(RegExp(r'[{}\[\]"]'), '').trim();
      return s.substring(0, 30) + '...';
    }

    return s.replaceAll(RegExp(r'[{}\[\]"]'), '').trim();
  }

  String _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/storage')) return '${ApiConfig.baseUrl}$u';
    if (u.startsWith('storage')) return '${ApiConfig.baseUrl}/$u';
    // Fallback: relative path without storage prefix (e.g., "settings/..", "news/..")
    String path = u;
    // remove any leading slashes before appending to /storage
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '${ApiConfig.baseUrl}/storage/$path';
  }

  // MENGGANTI: Menambahkan parameter warna tema
  Widget _placeholderTile(Color primaryColor, Color secondaryColor) {
    return Container(
      decoration: BoxDecoration(
        // MENGGANTI: Gradient hardcoded dengan primaryColor dan secondaryColor
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.campaign, color: Colors.white, size: 24),
      ),
    );
  }
}
