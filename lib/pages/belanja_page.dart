import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/api_product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../widgets/api_product_card.dart';
import './api_product_detail_page.dart';
import './nik_verification_page.dart';
import '../services/token_service.dart';
import '../services/village_service.dart';
import '../models/village_settings.dart';
import '../config/api_config.dart';
import './my_products_page.dart';
import './login_page.dart';
import 'package:desaku/utils/app_logger.dart';

class BelanjaPage extends StatefulWidget {
  const BelanjaPage({Key? key}) : super(key: key);
  @override
  State<BelanjaPage> createState() => _BelanjaPageState();
}

class _BelanjaPageState extends State<BelanjaPage> {
  // ... (Variabel State yang sudah ada)
  List<ApiProduct> products = [];
  List<ProductCategory> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isLoggedIn = false;
  VillageSettings? _villageSettings;

  final formatter = NumberFormat("#,###", "id_ID");
  String selectedCategory = 'Semua';
  String selectedCondition = 'Semua';
  String selectedSortBy = 'created_at_desc'; // Default: Terbaru - Terlama
  String searchQuery = '';
  late RangeValues priceRange;
  late double maxPrice;

  int currentPage = 1;
  bool hasMoreData = true;
  bool isLoadingMore = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    maxPrice = 100000000.0;
    priceRange = const RangeValues(0, 100000000.0);
    _checkLoginStatus();
    _loadInitialData();
    _loadVillageSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FUNGSI-FUNGSI LOGIKA (Penyimpanan data filter ke API) ---

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

  Future<void> _checkLoginStatus() async {
    final loggedIn = await TokenService.isLoggedIn();
    if (mounted) {
      setState(() => isLoggedIn = loggedIn);
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadProducts(), _loadCategories()]);
  }

  // Logika _loadProducts menggunakan selectedSortBy dan selectedCondition
  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMoreData = true;
        products.clear();
      });
    }

    int? categoryId;
    if (selectedCategory != 'Semua') {
      final selectedCat = categories.firstWhere(
        (cat) => cat.name == selectedCategory,
        orElse: () => ProductCategory(
          id: 0,
          name: '',
          description: '',
          createdAt: '',
          updatedAt: '',
        ),
      );
      if (selectedCat.id != 0) categoryId = selectedCat.id;
    }

    // Memproses selectedSortBy untuk API
    String sortByField;
    String sortOrder;
    if (selectedSortBy == 'created_at_desc') {
      sortByField = 'created_at';
      sortOrder = 'desc';
    } else if (selectedSortBy == 'created_at_asc') {
      sortByField = 'created_at';
      sortOrder = 'asc';
    } else if (selectedSortBy == 'price_asc') {
      sortByField = 'price';
      sortOrder = 'asc';
    } else if (selectedSortBy == 'price_desc') {
      sortByField = 'price';
      sortOrder = 'desc';
    } else {
      sortByField = 'created_at';
      sortOrder = 'desc';
    }

    try {
      final response = await ProductService.getProducts(
        status: 'tersedia',
        condition: selectedCondition != 'Semua'
            ? selectedCondition.toLowerCase()
            : null,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        minPrice: priceRange.start > 0 ? priceRange.start.toDouble() : null,
        maxPrice: priceRange.end < maxPrice ? priceRange.end.toDouble() : null,
        categoryId: categoryId,
        sortBy: sortByField,
        sortOrder: sortOrder,
        page: currentPage,
        perPage: 15,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        setState(() {
          if (isRefresh) {
            products = response.data;
          } else {
            products.addAll(response.data);
          }
          hasMoreData = response.pagination?.hasNextPage ?? false;
          isLoading = false;
          isLoadingMore = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          errorMessage = 'Gagal memuat data produk';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoryList = await ProductService.getCategories();
      if (mounted) {
        setState(() => categories = categoryList);
      }
    } catch (e) {
      AppLogger.log('Error loading categories: $e');
    }
  }

  Future<void> _loadMoreProducts() async {
    if (isLoadingMore || !hasMoreData) return;
    if (!mounted) return;
    setState(() {
      isLoadingMore = true;
      currentPage++;
    });
    await _loadProducts();
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      products.clear();
      searchQuery = _searchController.text;
    });
    _loadProducts(isRefresh: true);
  }

  Widget _buildVillageLogo(Color primaryColor) {
    final logoUrl = _villageSettings?.logoDesa;
    const double logoSize = 60.0;

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
          Icons.storefront,
          size: logoSize,
          color: primaryColor,
        ),
      );
    }
    return Icon(
      Icons.storefront,
      size: logoSize,
      color: primaryColor,
    );
  }

  void _handleSellProduct() async {
    if (!isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      await _checkLoginStatus();
      if (isLoggedIn) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NikVerificationPage()),
        );
        if (result == true) _loadProducts(isRefresh: true);
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NikVerificationPage()),
    );
    if (result == true) _loadProducts(isRefresh: true);
  }

  void _handleMyProducts() async {
    if (!isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      await _checkLoginStatus();

      if (isLoggedIn) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyProductsPage()),
        );
        _loadProducts(isRefresh: true);
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyProductsPage()),
    );
    _loadProducts(isRefresh: true);
  }

  // MARK: - Bottom Sheet Kategori
  void _showCategoryBottomSheet(Color primaryColor) {
    String tempCategoryName = selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),

                    // Daftar Kategori
                    RadioListTile<String>(
                      title: const Text('Semua'),
                      value: 'Semua',
                      groupValue: tempCategoryName,
                      onChanged: (value) =>
                          setModalState(() => tempCategoryName = value!),
                      activeColor: primaryColor,
                    ),
                    ...categories.map(
                      (cat) => RadioListTile<String>(
                        title: Text(cat.name),
                        value: cat.name,
                        groupValue: tempCategoryName,
                        onChanged: (value) =>
                            setModalState(() => tempCategoryName = value!),
                        activeColor: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = tempCategoryName;
                              });
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Lihat Barang',
                              style: TextStyle(color: Colors.white),
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
      },
    );
  }

  void _showSortingAndConditionBottomSheet(Color primaryColor) {
    String tempSortBy = selectedSortBy;
    String tempCondition = selectedCondition;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),

                    // --- SORTING Waktu ---
                    const Text(
                      'Waktu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Terbaru - Terlama'),
                      value: 'created_at_desc',
                      groupValue: tempSortBy,
                      onChanged: (value) =>
                          setModalState(() => tempSortBy = value!),
                      activeColor: primaryColor,
                    ),
                    RadioListTile<String>(
                      title: const Text('Terlama - Terbaru'),
                      value: 'created_at_asc',
                      groupValue: tempSortBy,
                      onChanged: (value) =>
                          setModalState(() => tempSortBy = value!),
                      activeColor: primaryColor,
                    ),
                    const SizedBox(height: 12),

                    // --- SORTING Harga ---
                    const Text(
                      'Harga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Termurah - Termahal'),
                      value: 'price_asc',
                      groupValue: tempSortBy,
                      onChanged: (value) =>
                          setModalState(() => tempSortBy = value!),
                      activeColor: primaryColor,
                    ),
                    RadioListTile<String>(
                      title: const Text('Termahal - Termurah'),
                      value: 'price_desc',
                      groupValue: tempSortBy,
                      onChanged: (value) =>
                          setModalState(() => tempSortBy = value!),
                      activeColor: primaryColor,
                    ),
                    const SizedBox(height: 12),

                    // --- FILTER Kondisi ---
                    const Text(
                      'Kondisi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Semua'),
                      value: 'Semua',
                      groupValue: tempCondition,
                      onChanged: (value) =>
                          setModalState(() => tempCondition = value!),
                      activeColor: primaryColor,
                    ),
                    RadioListTile<String>(
                      title: const Text('Baru'),
                      value: 'baru',
                      groupValue: tempCondition,
                      onChanged: (value) =>
                          setModalState(() => tempCondition = value!),
                      activeColor: primaryColor,
                    ),
                    RadioListTile<String>(
                      title: const Text('Bekas'),
                      value: 'bekas',
                      groupValue: tempCondition,
                      onChanged: (value) =>
                          setModalState(() => tempCondition = value!),
                      activeColor: primaryColor,
                    ),
                    const SizedBox(height: 20),

                    // --- Tombol Aksi ---
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedSortBy = tempSortBy;
                                selectedCondition = tempCondition;
                              });
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Lihat Barang',
                              style: TextStyle(color: Colors.white),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil warna dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    // Ketinggian AppBar custom dipertahankan 200.0 (safety margin)
    const double preferredHeight = 200.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(preferredHeight),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              // PERBAIKAN OVERFLOW VERTIKAL: Menghapus padding vertikal dari Padding luar.
              // Hanya menyisakan padding horizontal 16.
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // BARIS 1: Logo & Tombol Aksi
                  const SizedBox(
                      height: 8), // Tambahkan sedikit padding atas jika perlu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo Desa
                      _buildVillageLogo(primaryColor),

                      // Kontainer Tombol Aksi
                      Row(
                        children: [
                          // PRODUK SAYA
                          Container(
                            width: 40,
                            height: 40,
                            // Margin kanan dipertahankan 4
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.black,
                                size: 24,
                              ),
                              onPressed: _handleMyProducts,
                              padding: EdgeInsets.zero,
                              tooltip: 'Produk Saya',
                            ),
                          ),
                          // TAMBAH PRODUK
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.black),
                              onPressed: _handleSellProduct,
                              padding: EdgeInsets.zero,
                              tooltip: 'Tambah Produk',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // BARIS 2: Search Bar
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: primaryColor,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari Barang',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: primaryColor,
                          size: 24,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // BARIS 3: Semua & Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PANGGILAN BARU: Ikon Menu Garis 3 memanggil Bottom Sheet Kategori
                      GestureDetector(
                        onTap: () => _showCategoryBottomSheet(primaryColor),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              // Tampilkan kategori yang sedang dipilih
                              selectedCategory != 'Semua'
                                  ? selectedCategory
                                  : 'Semua Produk',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // PANGGILAN BARU: Ikon Filter (Tune) memanggil Bottom Sheet Sorting & Kondisi
                      GestureDetector(
                        onTap: () =>
                            _showSortingAndConditionBottomSheet(primaryColor),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.tune,
                            // Indikasi Filter Aktif
                            color: (selectedSortBy != 'created_at_desc' ||
                                    selectedCondition != 'Semua')
                                ? primaryColor
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 8), // Tambahkan sedikit padding bawah jika perlu
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(isRefresh: true),
        color: primaryColor,
        child: isLoading && products.isEmpty
            ? Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : errorMessage.isNotEmpty && products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: primaryColor.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadProducts(isRefresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                // MODIFIKASI: Tampilan ketika products.isEmpty
                : products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ikon Kaca Pembesar Besar
                              Icon(
                                Icons.search,
                                size: 96, // Ukuran besar
                                color: primaryColor.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              // Judul
                              const Text(
                                'Produk tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Subteks
                              Text(
                                'Tidak ada produk yang cocok, cari dengan kata kunci lain.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent * 0.9) {
                            _loadMoreProducts();
                          }
                          return false;
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            // childAspectRatio dipertahankan 0.67
                            childAspectRatio: 0.67,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: products.length + (hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= products.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            }
                            final product = products[index];
                            return ApiProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ApiProductDetailPage(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
