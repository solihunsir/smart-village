import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/api_product.dart';
import '../services/product_service.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart'; // Diperlukan untuk mengakses currentUser
import './edit_product_page.dart'; // Import halaman edit
import './nik_verification_page.dart'; // Import halaman tambah produk

// ====================================================================
// MyProductsPage (StatefulWidget)
// ====================================================================

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({Key? key}) : super(key: key);

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  List<ApiProduct> _products = [];
  bool _isLoading = true;
  String _selectedStatus = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _authToken;
  int? _currentSellerId;

  final List<String> _statusOptions = ['Semua', 'Tersedia', 'Terjual'];

  @override
  void initState() {
    super.initState();
    // Inisialisasi tidak perlu context, jadi aman di sini.
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int?> _getSellerId() async {
    try {
      // Ambil ID dari data user di TokenService
      final userJson = await TokenService.getUserData();
      if (userJson != null && userJson.isNotEmpty) {
        final parsed = jsonDecode(userJson);
        if (parsed is Map && parsed['id'] != null) {
          return parsed['id'] is int
              ? parsed['id']
              : int.tryParse(parsed['id'].toString());
        }
      }
    } catch (_) {}

    // Fallback menggunakan cached user di AuthService
    if (AuthService().currentUser != null) {
      return AuthService().currentUser!.id;
    }
    return null;
  }

  Future<void> _initialize() async {
    final token = await TokenService.getToken();
    final sellerId = await _getSellerId();

    if (token == null || sellerId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Pastikan context valid sebelum showSnackBar
        // Note: _initialize dipanggil di initState, showSnackBar mungkin tidak aman di sini
      }
      return;
    }
    _authToken = token;
    _currentSellerId = sellerId;
    _loadProducts();
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (_currentSellerId == null) {
      if (!isRefresh) setState(() => _isLoading = false);
      return;
    }

    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _products = [];
      });
    }

    try {
      final statusFilter =
          _selectedStatus == 'Semua' ? null : _selectedStatus.toLowerCase();

      // KRUSIAL: Memanggil endpoint publik dengan filter sellerId
      final response = await ProductService.getProducts(
        sellerId: _currentSellerId, // FILTER KRUSIAL
        status: statusFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: 'created_at',
        sortOrder: 'desc',
      );

      if (response != null && response.success) {
        setState(() {
          // Asumsi response.data mengembalikan List<ApiProduct>
          _products = response.data.cast<ApiProduct>();
          _isLoading = false;
        });
      } else {
        throw Exception(response?.message ?? 'Gagal memuat data produk Anda.');
      }
    } catch (e) {
      // AppLogger.log('Error loading my products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateProductStatus(int productId, String newStatus) async {
    if (_authToken == null) return;
    try {
      final bool success = await ProductService.updateProductStatus(
        token: _authToken!,
        productId: productId,
        newStatus: newStatus,
      );
      if (success && mounted) {
        _loadProducts(isRefresh: true); // Muat ulang data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status produk berhasil diubah menjadi ${newStatus.toUpperCase()}',
            ),
          ),
        );
      } else if (!success && mounted) {
        throw Exception('Gagal memperbarui status di server.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    }
  }

  Future<void> _deleteProduct(int productId, Color primaryColor) async {
    if (_authToken == null) return;

    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus produk ini secara permanen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              // MENGGANTI: Warna tombol hapus dengan primaryColor untuk konsistensi
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final bool success = await ProductService.deleteProduct(
          token: _authToken!,
          productId: productId,
        );
        if (success && mounted) {
          _loadProducts(isRefresh: true); // Muat ulang
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil dihapus')),
          );
        } else if (!success && mounted) {
          throw Exception('Gagal menghapus produk di server.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  void _handleSearch() {
    _searchQuery = _searchController.text;
    _loadProducts(isRefresh: true);
  }

  // MARK: - Fungsi Navigasi Tambah Produk
  void _navigateToAddNewProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NikVerificationPage()),
    );
    // Refresh list jika produk baru berhasil ditambahkan
    if (result == true) {
      _loadProducts(isRefresh: true);
    }
  }

  // MARK: - Fungsi untuk menampilkan Popup Menu Opsi Produk (Edit/Hapus) - MODIFIKASI
  void _showProductOptionsPopup(
      ApiProduct product, GlobalKey key, Color primaryColor) async {
    if (!mounted) return;

    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Tentukan posisi menu (di kanan bawah tombol titik tiga)
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx + size.width * 0.5, // Sedikit ke kanan
      offset.dy + size.height * 0.5, // Sedikit ke bawah
      MediaQuery.of(context).size.width -
          (offset.dx + size.width), // Jarak ke kanan layar
      0,
    );

    // Opsi Pop-up Menu
    const String edit = 'Edit';
    const String delete = 'Hapus';

    final String? selectedOption = await showMenu<String>(
      context: context,
      position: position,
      // Custom shape/style untuk menyesuaikan dengan desain card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      items: <PopupMenuEntry<String>>[
        // Opsi Edit
        PopupMenuItem<String>(
          value: edit,
          // Menggunakan Builder untuk mendapatkan konteks dan menutup pop-up
          child: Builder(builder: (context) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(
                    context, edit); // Tutup pop-up dengan hasil 'Edit'
              },
              child: const SizedBox(
                width: 150, // Sesuaikan lebar item
                child: Text('Edit', style: TextStyle(fontSize: 16)),
              ),
            );
          }),
        ),
        // Divider
        const PopupMenuDivider(height: 1),
        // Opsi Hapus (Dengan warna merah sesuai desain)
        PopupMenuItem<String>(
          value: delete,
          // Menggunakan Builder untuk mendapatkan konteks dan menutup pop-up
          child: Builder(builder: (context) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(
                    context, delete); // Tutup pop-up dengan hasil 'Hapus'
              },
              child: const SizedBox(
                width: 150, // Sesuaikan lebar item
                child: Text('Hapus',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            );
          }),
        ),
      ],
      // Menentukan ukuran Pop-up Menu agar sesuai dengan desain
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
    );

    // Logika setelah memilih opsi
    if (selectedOption == edit) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProductPage(product: product),
        ),
      );
      if (result == true) {
        _loadProducts(isRefresh: true);
      }
    } else if (selectedOption == delete) {
      _deleteProduct(product.id, primaryColor); // Meneruskan primaryColor
    }
  }

  // MARK: - Widget Khusus: Tampilan Produk Kosong
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildNoProductsView(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon Kotak
            Icon(
              Icons.inventory_2_outlined,
              size: 100,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 24),

            // Judul
            const Text(
              'Anda belum membuat iklan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subteks
            Text(
              'Tidak ada produk yang anda unggah, buat iklan anda disini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),

            // Tombol "Buat Iklan"
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: _navigateToAddNewProduct, // Panggil fungsi navigasi
                style: ElevatedButton.styleFrom(
                  // MENGGANTI: Warna hardcoded (0xFF00B140) dengan primaryColor
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Buat iklan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // MODIFIKASI: _buildSearchBar (Sesuai Desain Kapsul Hijau)
  // MENGGANTI: Menambahkan parameter primaryColor
  // ====================================================================
  Widget _buildSearchBar(Color primaryColor) {
    const double borderRadius = 28.0;
    // MENGHAPUS: const Color primaryGreen = Color(0xFF00B140);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        // MENGGANTI: Border hardcoded dengan primaryColor
        border: Border.all(color: primaryColor, width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari Barang',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          // Hapus semua border default InputDecoration karena sudah di handle Container
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          // Ikon kaca pembesar di ujung kanan
          suffixIcon: IconButton(
            // MENGGANTI: Warna hardcoded dengan primaryColor
            icon: Icon(Icons.search, color: primaryColor),
            onPressed: _handleSearch,
          ),
        ),
        onSubmitted: (_) => _handleSearch(),
      ),
    );
  }

  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildFilterSection(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Status Produk: ',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              DropdownButton<String>(
                value: _selectedStatus,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(fontSize: 16, color: Colors.black),
                underline: Container(),
                items: _statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                    _loadProducts(isRefresh: true);
                  }
                },
              ),
            ],
          ),
          IconButton(
            // MENGGANTI: Warna ikon dengan primaryColor
            icon: Icon(Icons.tune, color: primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter lanjutan belum tersedia.'),
                ),
              );
            },
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // ====================================================================
        // MODIFIKASI: Leading Button (Sesuai Desain Back dengan Latar Bulat)
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100, // Latar belakang abu-abu muda
            ),
            child: IconButton(
              // Mengganti Icons.arrow_back menjadi Icons.arrow_back_ios_new untuk desain yang lebih mirip
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        // Search bar sebagai title
        title: _buildSearchBar(primaryColor), // Meneruskan primaryColor
        // Menghilangkan actions karena search sudah di dalam title
        actions: const [
          SizedBox(width: 8),
        ],
        // ====================================================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: _buildFilterSection(primaryColor), // Meneruskan primaryColor
        ),
      ),
      body: RefreshIndicator(
        // MENGGANTI: Warna refresh indicator dengan primaryColor
        color: primaryColor,
        onRefresh: () => _loadProducts(isRefresh: true),
        child: _isLoading
            ? Center(
                // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
                child: CircularProgressIndicator(color: primaryColor),
              )
            : _products.isEmpty
                ? _buildNoProductsView(primaryColor) // Meneruskan primaryColor
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      // Inisialisasi GlobalKey untuk setiap item
                      final GlobalKey actionKey = GlobalKey();
                      return ProductListItem(
                        product: product,
                        onMarkSold: () =>
                            _updateProductStatus(product.id, 'terjual'),
                        onMarkAvailable: () =>
                            _updateProductStatus(product.id, 'tersedia'),
                        actionKey: actionKey,
                        onShowOptions: () => _showProductOptionsPopup(product,
                            actionKey, primaryColor), // Meneruskan primaryColor
                        primaryColor:
                            primaryColor, // BARU: Meneruskan primaryColor
                      );
                    },
                  ),
      ),
    );
  }
}

// ====================================================================
// Widget: ProductListItem (Komponen Card Produk)
// ====================================================================

class ProductListItem extends StatelessWidget {
  final ApiProduct product;
  final VoidCallback onMarkSold;
  final VoidCallback onMarkAvailable;
  final VoidCallback onShowOptions;
  final GlobalKey actionKey;
  final Color primaryColor; // BARU: Menambahkan primaryColor

  const ProductListItem({
    Key? key,
    required this.product,
    required this.onMarkSold,
    required this.onMarkAvailable,
    required this.onShowOptions,
    required this.actionKey,
    required this.primaryColor, // BARU
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###", "id_ID");
    final isAvailable = product.isAvailable;
    String formattedPrice;
    try {
      // Gunakan product.priceAsDouble atau parse jika product.price adalah string
      formattedPrice = formatter.format(product.price is double
          ? product.price
          : double.tryParse(product.price.toString()) ??
              0); // Perbaikan parsing
    } catch (_) {
      formattedPrice = product.price.toString(); // Pastikan default string
    }

    String datePosted;
    try {
      final dateTime = DateTime.parse(product.createdAt);
      datePosted = DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (_) {
      datePosted = 'N/A';
    }

    // BARU: Hitung warna latar terang untuk tombol "Tandai Tersedia" (PERBAIKAN ERROR)
    // Menggunakan Color.lerp untuk mendapatkan gradasi terang dari primaryColor
    final lightPrimaryColor = Color.lerp(primaryColor, Colors.white, 0.7)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Produk
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.primaryImageUrl.isNotEmpty
                        ? product.primaryImageUrl
                        : 'https://via.placeholder.com/100', // Placeholder
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Produk dan Opsi Titik Tiga
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Ikon Titik Tiga (Opsi)
                          GestureDetector(
                            key: actionKey, // Pasang GlobalKey di sini
                            onTap: onShowOptions, // Panggil fungsi popup
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.more_vert, // Ikon Titik Tiga
                                size: 24,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Harga
                      Text(
                        'Rp$formattedPrice',
                        style: TextStyle(
                          fontSize: 14,
                          // MENGGANTI: Warna hardcoded dengan primaryColor
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status dan Tanggal
                      Row(
                        children: [
                          Text(
                            product.status[0].toUpperCase() +
                                product.status.substring(1), // Tersedia/Terjual
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              // MENGGANTI: Warna Tersedia (Hijau) dengan primaryColor
                              color: isAvailable ? primaryColor : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.circle, size: 4, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            datePosted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tombol Aksi (Sesuai Status)
            Row(
              mainAxisAlignment: isAvailable
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.spaceBetween,
              children: isAvailable
                  ? [
                      // Jika Tersedia: Hanya tombol "Tandai Terjual"
                      Expanded(
                        child: _buildActionButton(
                          text: 'Tandai Terjual',
                          color: Colors.grey.shade300,
                          textColor: Colors.black,
                          onTap: onMarkSold,
                        ),
                      ),
                    ]
                  : [
                      // Jika Terjual: "Tandai Tersedia"
                      Expanded(
                        child: _buildActionButton(
                          text: 'Tandai Tersedia',
                          // PERBAIKAN: Mengganti primaryColor.shade100 dengan lightPrimaryColor
                          color: lightPrimaryColor,
                          // MENGGANTI: Warna teks dengan primaryColor
                          textColor: primaryColor,
                          onTap: onMarkAvailable,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
