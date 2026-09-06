import 'package:flutter/material.dart';
import '../models/api_product.dart';
import '../services/product_service.dart';
import '../widgets/api_product_card.dart';
import './api_product_detail_page.dart';
import './nik_verification_page.dart';
import '../services/token_service.dart';
import 'package:desaku/utils/app_logger.dart';
import '../services/village_service.dart';
import '../models/village_settings.dart';
import '../config/api_config.dart';

class MarketplacePage extends StatefulWidget {
  final String title;

  const MarketplacePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<ApiProduct> _products = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _perPage = 20;

  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _isLoggedIn = false;

  // LOGO DESA STATE
  VillageSettings? _villageSettings;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVillageSettings(); // Memuat logo desa
    _loadCategories();
    _loadProducts();
    _checkLoginStatus();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVillageSettings() async {
    try {
      final settings = await VillageService.getVillageSettings();
      if (mounted) {
        setState(() {
          _villageSettings = settings;
        });
      }
    } catch (e) {
      AppLogger.log('Error loading village settings for logo: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ProductService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      AppLogger.log('Error loading categories: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final loggedIn = await TokenService.isLoggedIn();
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
        });
      }
    } catch (e) {
      AppLogger.log('Error checking login status: $e');
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _products.clear();
        _hasMoreProducts = true;
      }
    });

    try {
      final response = await ProductService.getProducts(
        page: _currentPage,
        perPage: _perPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
      );

      setState(() {
        if (refresh) {
          _products = response?.data ?? [];
        } else {
          _products.addAll(response?.data ?? []);
        }
        _hasMoreProducts = (response?.data.length ?? 0) == _perPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMoreProducts &&
        !_isLoading) {
      _loadProducts();
    }
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadProducts(refresh: true);
  }

  void _filterByCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadProducts(refresh: true);
  }

  // Helper untuk menampilkan Logo Desa
  Widget _buildVillageLogo() {
    final logoUrl = _villageSettings?.logoDesa;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      // Normalisasi URL seperti di home_page.dart (diasumsikan)
      String normalizedUrl;
      if (logoUrl.startsWith('http')) {
        normalizedUrl = logoUrl;
      } else if (logoUrl.startsWith('/storage')) {
        normalizedUrl = '${ApiConfig.baseUrl}$logoUrl';
      } else if (logoUrl.startsWith('storage')) {
        normalizedUrl = '${ApiConfig.baseUrl}/$logoUrl';
      } else {
        String path = logoUrl;
        while (path.startsWith('/')) {
          path = path.substring(1);
        }
        normalizedUrl = '${ApiConfig.baseUrl}/storage/$path';
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          normalizedUrl,
          height: 32,
          width: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildTextLogo();
          },
        ),
      );
    }
    return _buildTextLogo();
  }

  // Fallback logo teks jika gambar tidak tersedia
  Widget _buildTextLogo() {
    return const Text(
      'Citimum', // Menggunakan nama default dari desain
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(110.0), // Tinggi AppBar disesuaikan
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 16, right: 16),
              child: Column(
                children: [
                  // Logo Desa/Nama Desa (Kiri) dan Tombol Tambah (Kanan)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVillageLogo(), // Menggunakan Logo/Nama Desa
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black),
                        onPressed: () {
                          // Logika tombol tambah (Jual Produk)
                          _handleSellProduct();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search Bar di bawah Logo
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade400, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari Barang',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              prefixIcon: null, // Hapus prefixIcon di sini
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search,
                                    color:
                                        Color(0xFF00B140)), // Ikon Cari Hijau
                                onPressed: _performSearch,
                              ),
                              border: InputBorder
                                  .none, // Hapus border bawaan TextField
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _isLoggedIn ? _buildFloatingActionButton() : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Semua',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.grey),
                  onPressed: () {
                    // Tampilkan filter/sort option (Sesuai ikon desain Anda)
                    _showFilterOptions(context);
                  },
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: _products.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada produk ditemukan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadProducts(refresh: true),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount:
                              _products.length + (_hasMoreProducts ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _products.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final product = _products[index];
                            return ApiProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ApiProductDetailPage(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menangani tombol Jual Produk
  void _handleSellProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NikVerificationPage(),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil diunggah'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadProducts(refresh: true);
    }
  }

  // Fungsi untuk FAB yang diperbarui
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _handleSellProduct,
      icon: const Icon(Icons.add),
      label: const Text('Jual Produk'),
      backgroundColor: Colors.green,
    );
  }

  // Fungsi placeholder untuk opsi filter
  void _showFilterOptions(BuildContext context) {
    // Implementasi untuk menampilkan dialog filter/sort options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter & Urutkan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Implementasikan kategori filter di sini jika diperlukan,
              // atau gunakan widget FilterChip yang sudah ada
              ..._categories
                  .map((category) => CheckboxListTile(
                        title: Text(category.name),
                        value: _selectedCategoryId == category.id,
                        onChanged: (bool? selected) {
                          Navigator.pop(context); // Tutup bottom sheet
                          _filterByCategory(
                              selected == true ? category.id : null);
                        },
                      ))
                  .toList(),
              // Tambahkan opsi pengurutan (Sort by Price, Date, etc.)
            ],
          ),
        );
      },
    );
  }
}
