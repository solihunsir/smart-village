import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/featured_product.dart';
import '../models/paginated_response.dart';
import '../services/featured_product_service.dart';
import '../config/api_config.dart';

// <<< MODIFIKASI: Gunakan alias (prefix) 'detail' untuk mengimpor halaman detail
// Ini memastikan Model FeaturedProduct dari file ini yang digunakan.
import 'featured_product_detail_page.dart' as detail;
// ---------------------------------------------------------------------

class FeaturedProductsListPage extends StatefulWidget {
  const FeaturedProductsListPage({super.key});

  @override
  State<FeaturedProductsListPage> createState() =>
      _FeaturedProductsListPageState();
}

class _FeaturedProductsListPageState extends State<FeaturedProductsListPage> {
  final ScrollController _scrollController = ScrollController();
  final List<FeaturedProduct> _products = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  PaginatedResponse<FeaturedProduct>? _lastResponse;
  final List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final clean = url.startsWith('/') ? url.substring(1) : url;
    if (clean.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$clean';
    }
    return '${ApiConfig.baseUrl}/storage/$clean';
  }

  void _onScroll() {
    if (_hasMore && !_loading) {
      final metrics = _scrollController.position;
      final maxScroll = metrics.maxScrollExtent;
      final currentScroll = metrics.pixels;

      // Mengubah ambang batas pemicu pemuatan menjadi 300 pixels
      if (currentScroll >= maxScroll - 300) {
        _loadProducts(refresh: false);
      }
    }
  }

  Future<void> _loadProducts({bool refresh = true}) async {
    if (!mounted) return;

    // Mencegah double loading
    if (!refresh && _loading) return;

    setState(() {
      if (refresh) {
        _currentPage = 1;
        _products.clear();
        _hasMore = true;
      }
      _loading = true;
      _error = null;
    });

    try {
      // Perbaiki: Pastikan page hanya di-increment jika ada data baru dimuat
      final pageToSend = refresh ? 1 : _currentPage;

      final response = await FeaturedProductService.list(
        page: pageToSend,
        perPage: 10,
        isActive: true,
        productCategory: _selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        _lastResponse = response;

        if (refresh) {
          _products.clear();
          // _categories.clear(); // Baris ini sudah diperbaiki sebelumnya
        }

        _products.addAll(response.data);

        // Collect categories for filter row
        final newCats = response.data
            .map((p) => (p.productCategory ?? '').trim())
            .where((c) => c.isNotEmpty)
            .toSet();

        // Gunakan Set untuk menghindari duplikasi saat mengumpulkan kategori
        final existingCats = Set<String>.from(_categories);
        for (final c in newCats) {
          if (!existingCats.contains(c)) {
            _categories.add(c);
            existingCats.add(c); // Update existing set
          }
        }

        _hasMore = response.hasNextPage;
        if (response.hasNextPage) {
          _currentPage = pageToSend + 1;
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // PERBAIKAN: Tangani error HTTP 0 secara spesifik karena sering terjadi pada emulator/jaringan
        if (e.toString().contains('statusCode: 0')) {
          _error =
              'Gagal koneksi ke server. Periksa koneksi internet Anda atau coba lagi.';
        } else {
          _error = e.toString();
        }
        _loading = false;
      });
    }
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildLoadingIndicator(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildErrorWidget(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada produk unggulan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildProductItem(FeaturedProduct product, Color primaryColor) {
    // BARU: Menghitung warna latar belakang chip yang lebih terang
    final lightPrimaryColor = Color.lerp(primaryColor, Colors.white, 0.7)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Image.network(
                _normalizeImageUrl(product.image),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Menggunakan Expanded dan Flexible untuk menghindari overflow jika konten teks panjang
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      if ((product.productCategory ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // MENGGANTI: Warna hardcoded (0xFFE8F5E9) dengan lightPrimaryColor
                            color: lightPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.productCategory ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              // MENGGANTI: Warna hardcoded (0xFF2E7D32) dengan primaryColor
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildProductsList(Color primaryColor) {
    if (_loading && _products.isEmpty) {
      return SingleChildScrollView(child: _buildLoadingIndicator(primaryColor));
    }

    if (_error != null) {
      return _buildErrorWidget(primaryColor);
    }

    if (_products.isEmpty && _categories.isEmpty) {
      return _buildEmptyWidget();
    }

    // Menggunakan Column dan Expanded untuk menampung Filter dan GridView
    return RefreshIndicator(
      onRefresh: () => _loadProducts(),
      // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
      color: primaryColor,
      child: Column(
        children: [
          // Filter Chips
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 1 + _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final label = isAll ? 'Semua' : _categories[index - 1];
                    final selected = (isAll && _selectedCategory == null) ||
                        (!isAll && _selectedCategory == label);

                    // BARU: Warna latar belakang chip yang dipilih
                    final selectedBackgroundColor =
                        Color.lerp(primaryColor, Colors.white, 0.7)!;

                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (v) async {
                        setState(() {
                          _selectedCategory = isAll ? null : label;
                          _currentPage = 1;
                          _products.clear();
                          _hasMore = true;
                        });
                        await _loadProducts(refresh: true);
                      },
                      // MENGGANTI: Warna hardcoded (0xFFE8F5E9) dengan selectedBackgroundColor
                      selectedColor: selectedBackgroundColor,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        // MENGGANTI: Warna hardcoded (0xFF2E7D32) dengan primaryColor
                        color: selected ? primaryColor : Colors.black87,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Products Grid (Dibungkus dengan Expanded)
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _products.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (_products.isEmpty) {
                  // Perbaikan: Jika produk kosong setelah filter, tampilkan empty state di tengah Expanded
                  if (_loading) return _buildLoadingIndicator(primaryColor);
                  if (_selectedCategory != null) return _buildEmptyWidget();
                  return Container();
                }

                if (index >= _products.length)
                  return _buildLoadingIndicator(primaryColor);

                final product = _products[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // <<< MODIFIKASI: Panggil menggunakan alias 'detail.'
                        builder: (context) =>
                            detail.FeaturedProductDetailPage(product: product),
                      ),
                    );
                  },
                  child: _buildProductItem(
                      product, primaryColor), // Meneruskan primaryColor
                );
              },
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Produk Unggulan',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: _buildProductsList(primaryColor), // Meneruskan primaryColor
    );
  }
}
