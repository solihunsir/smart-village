import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'information_page.dart';
import 'profile_page.dart' as profile;
import 'notification_page.dart';
import 'login_page.dart';
import 'belanja_page.dart';
import 'announcement_detail_page.dart';
import 'news_detail_page.dart';
import 'complaint_list_page.dart';
import 'community_list_page.dart';
import 'village_profile_page.dart';
import 'indicator_page.dart';
import '../services/token_service.dart';
import '../services/village_service.dart';
import '../models/village_settings.dart';
import '../services/announcement_service.dart';
import '../services/news_service.dart';
import '../models/announcement_item.dart';
import '../models/news_item.dart';
import '../config/api_config.dart';
import '../widgets/pusat_desa_section.dart';
import '../services/channel_service.dart';
import '../models/community_channel.dart';
import '../services/destination_service.dart';

// Helper functions (tetap sama)
String _stripHtmlTags(String htmlText) {
  if (htmlText.isEmpty) return '';
  final cleanText = htmlText
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'&[^;]+;'), ' ');

  return cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
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

Widget _buildNetworkOrPlaceholder(String? url, List<Color> fallbackColors) {
  String? normalized;
  if (url != null && url.isNotEmpty) {
    final u = url.trim();
    if (u.startsWith('http')) {
      normalized = u;
    } else if (u.startsWith('/storage')) {
      normalized = '${ApiConfig.baseUrl}$u';
    } else if (u.startsWith('storage')) {
      normalized = '${ApiConfig.baseUrl}/$u';
    } else {
      String path = u;
      while (path.startsWith('/')) {
        path = path.substring(1);
      }
      normalized = '${ApiConfig.baseUrl}/storage/$path';
    }
  }

  // Gunakan warna pertama dari list untuk fallback yang konsisten
  final fallbackColor =
      fallbackColors.isNotEmpty ? fallbackColors.first : Colors.grey;

  if (normalized == null) {
    return Container(
      decoration: BoxDecoration(color: fallbackColor),
      child: const Center(
        child: Icon(Icons.image, color: Colors.white, size: 32),
      ),
    );
  }

  return Image.network(
    normalized,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        decoration: BoxDecoration(color: fallbackColor),
        child: const Center(
          child: Icon(Icons.image, color: Colors.white, size: 32),
        ),
      );
    },
  );
}

Widget _buildSkeletonBlock({
  required double width,
  required double height,
  BorderRadius? borderRadius,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    ),
  );
}

// --- WIDGET SKELETON: Horizontal List (for News/Announcement) ---
class HorizontalListSkeleton extends StatelessWidget {
  final double height;
  const HorizontalListSkeleton({Key? key, required this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 170,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Top placeholder
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildSkeletonBlock(width: 170, height: 100),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date/Author placeholder
                      _buildSkeletonBlock(width: 80, height: 10),
                      const SizedBox(height: 8),
                      // Title placeholder (2 lines)
                      _buildSkeletonBlock(width: 130, height: 14),
                      const SizedBox(height: 4),
                      _buildSkeletonBlock(width: 100, height: 14),
                      if (height > 250) ...[
                        const SizedBox(height: 8),
                        // Content Preview placeholder
                        _buildSkeletonBlock(width: 146, height: 10),
                        const SizedBox(height: 4),
                        _buildSkeletonBlock(width: 120, height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGET SKELETON: PusatDesaSection ---
class PusatDesaSectionSkeleton extends StatelessWidget {
  const PusatDesaSectionSkeleton({Key? key}) : super(key: key);

  Widget _buildIconSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        _buildSkeletonBlock(width: 40, height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(4, (index) => _buildIconSkeleton()),
    );
  }
}

// --- WIDGET SKELETON: HomeContent ---
class HomeContentSkeleton extends StatelessWidget {
  const HomeContentSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Header Placeholder
    final double appBarHeight = MediaQuery.of(context).padding.top + 50;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar Area
          Container(
            padding: EdgeInsets.fromLTRB(20, appBarHeight - 20, 20, 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonBlock(width: 100, height: 20),
                _buildSkeletonBlock(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ),

          // Banner Placeholder
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBlock(width: 150, height: 10),
                        const SizedBox(height: 8),
                        _buildSkeletonBlock(width: 180, height: 18),
                        const SizedBox(height: 4),
                        _buildSkeletonBlock(width: 120, height: 18),
                        const SizedBox(height: 12),
                        _buildSkeletonBlock(
                          width: 100,
                          height: 32,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: _buildSkeletonBlock(
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pesona Desa Section Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBlock(width: 120, height: 16),
                const SizedBox(height: 12),
                const PusatDesaSectionSkeleton(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Saluran Desa Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBlock(width: 100, height: 16),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildSkeletonBlock(
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBlock(width: 150, height: 16),
                          const SizedBox(height: 4),
                          _buildSkeletonBlock(width: 100, height: 12),
                        ],
                      ),
                      const Spacer(),
                      _buildSkeletonBlock(width: 16, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Indikator Desa Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSkeletonBlock(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          // Pengumuman Terbaru Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBlock(width: 150, height: 16),
                const SizedBox(height: 12),
                const HorizontalListSkeleton(height: 200),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Berita Terbaru Placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBlock(width: 130, height: 16),
                const SizedBox(height: 12),
                const HorizontalListSkeleton(height: 322),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// --- HomePage Class ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _initialInfoTab;

  // Widget khusus untuk item navigasi bawah (bottom nav bar)
  Widget _buildSizedNavItem({
    required int width,
    required bool isSelected,
    required String assetPath,
    required IconData fallbackIcon,
    required IconData activeIcon,
    required String title,
    required int index,
    required Color primaryColor, // Parameter warna tema
  }) {
    const onPrimaryColor = Colors.white;

    return GestureDetector(
      onTap: () async {
        if (index == 2 || index == 4) {
          final isLoggedIn = await TokenService.isLoggedIn();
          if (!isLoggedIn) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );

            if (result == true) {
              setState(() {
                _currentIndex = index;
              });
            }
            return;
          }
        }
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: 59,
        width: width.toDouble(),
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          // Menerapkan primaryColor dari API
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Menggunakan SvgPicture.asset
            SvgPicture.asset(
              assetPath,
              width: 26,
              height: 26,
              colorFilter: ColorFilter.mode(
                // Menggunakan primaryColor dari API
                isSelected ? onPrimaryColor : primaryColor,
                BlendMode.srcIn,
              ),
              // Tambahkan placeholder jika gambar SVG tidak dapat dimuat
              placeholderBuilder: (BuildContext context) => Icon(
                isSelected ? activeIcon : fallbackIcon,
                size: 26,
                // Menggunakan primaryColor dari API
                color: isSelected ? onPrimaryColor : primaryColor,
              ),
            ),

            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil warna dari ThemeProvider untuk seluruh HomePage (terutama bottom nav)
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) => false,
        child: _currentIndex == 0
            ? HomeContent(
                onTabChange: (index, {String? section}) {
                  setState(() {
                    _currentIndex = index;
                    _initialInfoTab = section;
                  });
                },
              )
            : _currentIndex == 1
                ? InformationPage(initialTab: _initialInfoTab)
                : _currentIndex == 2
                    ? const ComplaintListPage()
                    : _currentIndex == 3
                        ? const BelanjaPage()
                        : const profile.ProfilePage(),
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const int horizontalOuterPadding = 8;
              const int outerVerticalPadding = 6;
              final double availableWidth =
                  constraints.maxWidth - (horizontalOuterPadding * 2);

              const int itemCount = 5;
              final List<int> flexList = List<int>.generate(
                itemCount,
                (i) => (_currentIndex == i ? 3 : 1),
              );

              final int totalFlex = flexList.fold<int>(0, (a, b) => a + b);

              const int interItemGap = 8;
              final int totalGap = interItemGap * (itemCount - 1);

              final double widthForItemsDouble = availableWidth - totalGap;
              final int widthForItems = widthForItemsDouble.floor();

              int basePerFlex = widthForItems ~/ totalFlex;
              int remainder = widthForItems - (basePerFlex * totalFlex);

              List<int> itemWidths = List<int>.filled(itemCount, 0);
              for (int i = 0; i < itemCount; i++) {
                itemWidths[i] = basePerFlex * flexList[i];
                if (remainder > 0) {
                  itemWidths[i] += 1;
                  remainder -= 1;
                }
              }

              final items = [
                {
                  'asset': 'assets/images/home.svg',
                  'fallback': Icons.home_outlined,
                  'active': Icons.home,
                  'title': 'Beranda',
                },
                {
                  'asset': 'assets/images/pemberitahuan.svg',
                  'fallback': Icons.info_outlined,
                  'active': Icons.info,
                  'title': 'Informasi',
                },
                {
                  'asset': 'assets/images/pengaduan.svg',
                  'fallback': Icons.assignment_outlined,
                  'active': Icons.assignment,
                  'title': 'Laporan',
                },
                {
                  'asset': 'assets/images/belanja.svg',
                  'fallback': Icons.shopping_bag_outlined,
                  'active': Icons.shopping_bag,
                  'title': 'Belanja',
                },
                {
                  'asset': 'assets/images/profile.svg',
                  'fallback': Icons.person_outlined,
                  'active': Icons.person,
                  'title': 'Akun',
                },
              ];

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalOuterPadding.toDouble(),
                  vertical: outerVerticalPadding.toDouble(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(itemCount * 2 - 1, (idx) {
                    if (idx.isOdd) {
                      return SizedBox(width: interItemGap.toDouble());
                    }
                    final int itemIndex = idx ~/ 2;
                    final bool isSelected = _currentIndex == itemIndex;
                    final int width = itemWidths[itemIndex];

                    return _buildSizedNavItem(
                      width: width,
                      isSelected: isSelected,
                      assetPath: items[itemIndex]['asset'] as String,
                      fallbackIcon: items[itemIndex]['fallback'] as IconData,
                      activeIcon: items[itemIndex]['active'] as IconData,
                      title: items[itemIndex]['title'] as String,
                      primaryColor: primaryColor, // Meneruskan warna tema
                      index: itemIndex,
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- HomeContent Class ---
class HomeContent extends StatefulWidget {
  final Function(int, {String? section}) onTabChange;
  const HomeContent({Key? key, required this.onTabChange}) : super(key: key);
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  VillageSettings? villageSettings;
  bool isLoading = true;
  String errorMessage = '';
  List<AnnouncementItem> _homeAnnouncements = [];
  bool _loadingHomeAnnouncements = true;
  List<NewsItem> _homeNews = [];
  bool _loadingHomeNews = true;

  List<CommunityChannel> _channels = [];
  int _totalCommunityCount = 0;
  bool _loadingChannels = true;
  String _channelError = '';

  // State untuk jumlah destinasi
  int _totalDestinationCount = 0;
  bool _loadingDestinations = true;

  // State untuk jumlah Map Points/Fasilitas
  int _totalMapPointsCount = 0;
  bool _loadingMapPoints = true;

  @override
  void initState() {
    super.initState();
    // Memuat semua data
    _loadInitialData();
    _loadHomeAnnouncements();
    _loadHomeNews();
    _loadDestinationCount();
    _loadMapPointsCount(); // Memuat jumlah Map Points
  }

  Future<void> _loadInitialData() async {
    await _loadVillageSettings();
    await _loadChannels();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (villageSettings == null && !isLoading) {
      _loadVillageSettings();
    }
  }

  // Fungsi untuk memuat jumlah destinasi
  Future<void> _loadDestinationCount() async {
    if (!mounted) return;
    setState(() => _loadingDestinations = true);
    try {
      final count = await DestinationService.countDestinations();
      if (!mounted) return;
      setState(() {
        _totalDestinationCount = count;
        _loadingDestinations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalDestinationCount = 0;
        _loadingDestinations = false;
      });
    }
  }

  // Fungsi untuk memuat jumlah Map Points (Fasilitas)
  Future<void> _loadMapPointsCount() async {
    if (!mounted) return;
    setState(() => _loadingMapPoints = true);
    try {
      final count = await DestinationService.countMapPoints();
      if (!mounted) return;
      setState(() {
        _totalMapPointsCount = count;
        _loadingMapPoints = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalMapPointsCount = 0;
        _loadingMapPoints = false;
      });
    }
  }

  // 💡 PERBAIKAN: Menambahkan pengecekan 'mounted'
  Future<void> _loadHomeAnnouncements() async {
    if (!mounted) return;
    setState(() => _loadingHomeAnnouncements = true);
    try {
      final items = await AnnouncementService.list(page: 1, perPage: 3);
      if (!mounted) return;
      setState(() {
        _homeAnnouncements = items;
        _loadingHomeAnnouncements = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHomeAnnouncements = false);
    }
  }

  // 💡 PERBAIKAN: Menambahkan pengecekan 'mounted'
  Future<void> _loadHomeNews() async {
    if (!mounted) return;
    setState(() => _loadingHomeNews = true);
    try {
      final items = await NewsService.list(page: 1, perPage: 3);
      if (!mounted) return;
      setState(() {
        _homeNews = items;
        _loadingHomeNews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHomeNews = false);
    }
  }

  // 💡 PERBAIKAN: Menambahkan pengecekan 'mounted'
  Future<void> _loadChannels() async {
    if (!mounted) return;
    setState(() => _loadingChannels = true);
    try {
      final fetchedChannels = await ChannelService.fetchPublicChannels();
      if (!mounted) return;

      int totalCount = 0;
      for (var channel in fetchedChannels) {
        totalCount += channel.communitiesCount;
      }

      setState(() {
        _channels = fetchedChannels;
        _totalCommunityCount = totalCount;
        _loadingChannels = false;
        _channelError = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _channelError = 'Gagal memuat saluran.';
        _loadingChannels = false;
        _totalCommunityCount = 0;
      });
    }
  }

  // 💡 PERBAIKAN: Menambahkan pengecekan 'mounted'
  Future<void> _loadVillageSettings() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final settings = await VillageService.getVillageSettings();
      if (!mounted) return; // Check kedua setelah operasi asinkron

      setState(() {
        villageSettings = settings;
        isLoading = false;
        if (settings == null) {
          errorMessage = 'Data pengaturan desa kosong.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal terhubung ke server.';
      });
    }
  }

  // Widget untuk Empty State Data (Warna Ikon disesuaikan)
  Widget _buildEmptyState({required String title, String? subtitle}) {
    // Ambil primaryColor untuk ikon empty state
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
    // Warna sekunder untuk ikon, lebih terang dari primary
    final lightPrimary = primaryColor.withOpacity(0.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 40, color: lightPrimary), // Warna tema
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- BARU: Ambil tema dari Provider ---
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final secondaryColor = themeProvider.secondaryColor;

    // 1. Tampilkan Skeleton Screen jika data utama (settings/channels/theme) masih loading
    if (isLoading ||
        _loadingChannels ||
        themeProvider.isLoading ||
        _loadingDestinations ||
        _loadingMapPoints) {
      return const HomeContentSkeleton();
    }

    // Fallback data
    final villageName =
        villageSettings?.selectedKelurahanNama.isNotEmpty == true
            ? villageSettings!.selectedKelurahanNama
            : 'Desa';

    final channelCountText = _channels.isEmpty && _channelError.isNotEmpty
        ? 'Gagal memuat saluran'
        : _channels.isEmpty
            ? '0 Saluran'
            : '(${_totalCommunityCount} Komunitas)';

    final communityImageUrl =
        _channels.isNotEmpty && _channels.first.imageUrl.isNotEmpty
            ? '${ApiConfig.baseUrl}${_channels.first.imageUrl}'
            : null;

    // Warna untuk gradient Indikator, lebih gelap dari secondaryColor
    final darkSecondary = Color.lerp(secondaryColor, Colors.black, 0.2)!;

    // Teks untuk jumlah destinasi
    final destinationCountDisplay = _totalDestinationCount > 999
        ? '999+ Destinasi'
        : '$_totalDestinationCount Destinasi';

    // Teks untuk jumlah Map Points/Fasilitas
    final mapPointsCountDisplay = _totalMapPointsCount > 999
        ? '999+ Fasilitas'
        : '$_totalMapPointsCount Penunjang';

    return Column(
      children: [
        // --- KONTEN UTAMA ---
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadVillageSettings(),
                _loadChannels(),
                _loadHomeAnnouncements(),
                _loadHomeNews(),
                _loadDestinationCount(),
                _loadMapPointsCount(), // Refresh hitungan Map Points
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).fetchActiveTheme(),
              ]);
            },
            color: primaryColor,
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      16,
                    ),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logika Logo Desa & Nama Desa (tidak ada perubahan warna yang signifikan)
                        Row(
                          children: [
                            if (villageSettings != null &&
                                villageSettings!.logoDesa != null &&
                                villageSettings!.logoDesa!.isNotEmpty)
                              Container(
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1),
                                  child: Image.network(
                                    villageSettings!.logoDesa!.startsWith(
                                      'http',
                                    )
                                        ? villageSettings!.logoDesa!
                                        : '${ApiConfig.baseUrl}/storage/${villageSettings!.logoDesa!.startsWith('/') ? villageSettings!.logoDesa!.substring(1) : villageSettings!.logoDesa!}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                        ),
                                        child: const Text(
                                          'D',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationPage(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.notifications_none,
                              // Ganti warna hardcoded dengan primaryColor
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // START: Banner "Jelajahi Desa"
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      // Menerapkan secondaryColor di gradient banner
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          secondaryColor, // Warna tema sekunder
                          Color.lerp(secondaryColor, Colors.white, 0.4)!,
                          Colors.white,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Overlay gelap untuk memastikan kontras teks deskripsi
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    // Mulai gelap kuat di kiri atas
                                    Colors.black.withOpacity(0.5),
                                    Colors.black.withOpacity(0.3),
                                    // Menghilang ke transparan di kanan bawah
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 20,
                            right: 160,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'SELAMAT DATANG DIDESA KAMI',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Temukan Pesona\ndan Potensi Desa\n$villageName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 4,
                                        color: Color.fromARGB(150, 0, 0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Jelajahi keindahan alam, kekayaan budaya, dan keramahan warga. Mari kenali lebih dekat denyut kehidupan di desa kami.',
                                  style: TextStyle(
                                    fontSize: 9,
                                    // Warna diubah menjadi putih solid
                                    color: Colors.white,
                                    height: 1.2,
                                    // Shadow dihilangkan
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const VillageProfilePage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    // Menerapkan primaryColor di tombol
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    elevation: 3,
                                    minimumSize: const Size(0, 32),
                                    shadowColor: Colors.black.withOpacity(0.3),
                                  ),
                                  child: const Text(
                                    'JELAJAHI DESA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Posisi Foto Kepala Desa
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    // Menerapkan primaryColor di border foto
                                    color: primaryColor,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      // Menerapkan primaryColor di shadow foto
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: villageSettings != null &&
                                            villageSettings!
                                                .photoKepalaDesaUrl.isNotEmpty
                                        ? Image.network(
                                            villageSettings!.photoKepalaDesaUrl,
                                            width: 104,
                                            height: 104,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 104,
                                                height: 104,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.transparent,
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color:
                                                      primaryColor, // Menggunakan primaryColor
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 104,
                                            height: 104,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.transparent,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              size: 50,
                                              color:
                                                  primaryColor, // Menggunakan primaryColor
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Posisi Floating Badge 1 (Destinasi Wisata)
                          Positioned(
                            right: 135,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      // Menerapkan primaryColor di badge
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 8,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Menampilkan jumlah destinasi
                                      Text(
                                        destinationCountDisplay,
                                        style: TextStyle(
                                          // Non-const
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          // Menerapkan primaryColor di teks
                                          color: primaryColor,
                                        ),
                                      ),
                                      const Text(
                                        'Wisata',
                                        style: TextStyle(
                                          fontSize: 5,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Posisi Floating Badge 2 (Fasilitas) - MENGGUNAKAN DATA DINAMIS MAP POINTS
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      // Menerapkan primaryColor di badge
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Menampilkan jumlah Map Points
                                      Text(
                                        mapPointsCountDisplay,
                                        style: TextStyle(
                                          // Non-const
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          // Menerapkan primaryColor di teks
                                          color: primaryColor,
                                        ),
                                      ),
                                      // BARU: Menambahkan teks "Penunjang"
                                      const Text(
                                        'Penunjang',
                                        style: TextStyle(
                                          fontSize: 5,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // END: Banner "Jelajahi Desa"
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesona Desa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const PusatDesaSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // START: SALURAN DESA (Community)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saluran Desa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CommunityListPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
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
                                    child: communityImageUrl != null
                                        ? Image.network(
                                            communityImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  // Menerapkan primaryColor di icon fallback
                                                  color: primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.groups,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              // Menerapkan primaryColor di icon fallback
                                              color: primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.groups,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Komunitas Desa $villageName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        channelCountText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // END: SALURAN DESA (Community)
                  const SizedBox(height: 20),
                  // START: KARTU INDIKATOR DESA YANG DIKEMBALIKAN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IndicatorPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                        decoration: BoxDecoration(
                          // Menggunakan secondaryColor di gradient
                          gradient: LinearGradient(
                            colors: [
                              darkSecondary,
                              secondaryColor,
                            ], // Darker Secondary to Secondary
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              color: Colors.white,
                              size: 36,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Indikator Desa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tampilan Diagram, Stastistik dan Tabel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // END: KARTU INDIKATOR DESA YANG DIKEMBALIKAN
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pengumuman Terbaru',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.onTabChange(1, section: 'announcements');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _loadingHomeAnnouncements
                              ? const HorizontalListSkeleton(height: 200)
                              : _homeAnnouncements.isEmpty
                                  ? _buildEmptyState(
                                      title: 'Tidak Ada Pengumuman Saat Ini',
                                      subtitle:
                                          'Informasi akan muncul setelah ada pembaruan dari desa.',
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _homeAnnouncements.length,
                                      itemBuilder: (context, index) {
                                        final a = _homeAnnouncements[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AnnouncementDetailPage(
                                                  title: _stripHtmlTags(
                                                    a.title,
                                                  ),
                                                  date: _formatDateShort(
                                                    a.date ?? '-',
                                                  ),
                                                  location: a.location ?? '-',
                                                  content: a.content ?? '-',
                                                  imageUrl: a.image,
                                                  author: a.author,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 170,
                                            margin: EdgeInsets.only(
                                              right: index ==
                                                      _homeAnnouncements
                                                              .length -
                                                          1
                                                  ? 0
                                                  : 12, // Penyesuaian margin
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                16,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.black.withOpacity(
                                                    0.08,
                                                  ),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                16,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child:
                                                        _buildNetworkOrPlaceholder(
                                                      a.image,
                                                      [
                                                        primaryColor, // Menggunakan primaryColor
                                                        secondaryColor, // Menggunakan secondaryColor
                                                      ],
                                                    ),
                                                  ),
                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black
                                                                .withOpacity(
                                                                    0.7),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 16,
                                                    left: 16,
                                                    right: 16,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _formatDateShort(
                                                            a.date ?? '-',
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 10,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          _stripHtmlTags(
                                                              a.title),
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Berita Terbaru',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.onTabChange(1, section: 'news');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 322,
                          child: _loadingHomeNews
                              ? const HorizontalListSkeleton(height: 322)
                              : _homeNews.isEmpty
                                  ? _buildEmptyState(
                                      title: 'Tidak Ada Berita Terbaru',
                                      subtitle:
                                          'Berita akan muncul setelah ada publikasi resmi.',
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _homeNews.length,
                                      itemBuilder: (context, index) {
                                        final n = _homeNews[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    NewsDetailPage(
                                                        slug: n.slug),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 250,
                                            margin: EdgeInsets.only(
                                              right:
                                                  index == _homeNews.length - 1
                                                      ? 0
                                                      : 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.black.withOpacity(
                                                    0.08,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      12,
                                                    ),
                                                    topRight: Radius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  child: AspectRatio(
                                                    aspectRatio: 16 / 9,
                                                    child:
                                                        _buildNetworkOrPlaceholder(
                                                      n.image,
                                                      const [
                                                        // Warna placeholder netral/terang untuk berita
                                                        Color(0xFFE8F5E9),
                                                        Color(0xFFC8E6C9),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      12,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              n.author ??
                                                                  'RCTI News',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            Text(
                                                              _formatDateShort(
                                                                n.date ?? '-',
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          n.title,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                Colors.black87,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            height: 1.3,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (n.content !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            _stripHtmlTags(
                                                              n.content!,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                              height: 1.4,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                        const Spacer(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
