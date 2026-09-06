import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/api_product.dart';
import '../services/product_service.dart';
import '../services/token_service.dart';

// Struktur baru untuk menyimpan semua gambar (lama dan baru)
class EditableImage {
  final String id;
  final String? url;
  final XFile? file;

  EditableImage.fromUrl(ProductPhoto photo)
      : id = photo.id.toString(),
        url = photo.photoUrl,
        file = null;

  EditableImage.fromFile(XFile file)
      : id = DateTime.now().millisecondsSinceEpoch.toString(),
        url = null,
        file = file;

  bool get isNew => url == null;
}

class EditProductPage extends StatefulWidget {
  final ApiProduct product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;

  String? _selectedCondition;
  ProductCategory? _selectedCategory;
  List<ProductCategory> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  // --- State Baru untuk Gambar ---
  List<EditableImage> _currentImages = [];
  static const int MAX_IMAGES = 5;

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi Controller
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );

    final priceFormatter = NumberFormat('#', 'id_ID');
    _priceController = TextEditingController(
      text: priceFormatter.format(widget.product.priceAsDouble.round()),
    );
    _locationController = TextEditingController(text: widget.product.location);

    // 2. Inisialisasi state dropdown
    _selectedCondition = widget.product.conditionProduct;

    // 3. Inisialisasi daftar gambar
    _currentImages =
        widget.product.photos.map((p) => EditableImage.fromUrl(p)).toList();

    // 4. Muat kategori
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ProductService.getCategories();
      if (mounted) {
        // Cari kategori yang cocok. Jika tidak ada, biarkan null.
        final initialCategory = categories.cast<ProductCategory?>().firstWhere(
              (cat) => cat?.id == widget.product.categoryId,
              orElse: () => null,
            );

        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
          _selectedCategory = initialCategory;
        });
      }
    } catch (e) {
      // AppLogger.log('Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  // --- FUNGSI BARU: Tambah Gambar ---
  Future<void> _pickImage() async {
    if (_currentImages.length >= MAX_IMAGES) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Batas maksimum $MAX_IMAGES gambar tercapai.')),
        );
      }
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _currentImages.add(EditableImage.fromFile(pickedFile));
      });
    }
  }

  // --- FUNGSI BARU: Hapus Gambar ---
  void _removeImage(EditableImage imageToRemove) {
    setState(() {
      _currentImages.removeWhere((img) => img.id == imageToRemove.id);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pilih kategori produk.')));
      }
      return;
    }
    if (_currentImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk harus memiliki minimal 1 gambar.'),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final token = await TokenService.getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi berakhir. Mohon login kembali.')),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    try {
      final priceString = _priceController.text.replaceAll(RegExp(r'[.,]'), '');
      final priceInt = int.tryParse(priceString) ?? 0;

      // Filter: Pisahkan gambar baru dan ID gambar lama yang dipertahankan
      final List<XFile> newFiles = _currentImages
          .where((img) => img.isNew)
          .map((img) => img.file!)
          .toList();

      final List<int> keptImageIds = _currentImages
          .where((img) => !img.isNew)
          .map((img) => int.parse(img.id))
          .toList();

      // PANGGILAN BARU: Gunakan ProductService.updateProduct yang sudah dimodifikasi
      final updatedProduct = await ProductService.updateProduct(
        token: token!,
        productId: widget.product.id,
        categoryId: _selectedCategory!.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: priceInt,
        status: widget.product.status,
        conditionProduct: _selectedCondition!,
        location: _locationController.text,
        newPhotos: newFiles,
        keptPhotoIds: keptImageIds,
      );

      if (updatedProduct != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigasi kembali dan kirim sinyal 'true' untuk refresh
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Gagal memperbarui produk. Cek respons API.');
      }
    } catch (e) {
      // AppLogger.log('Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // --- WIDGET BARU: Tampilan Pratinjau Gambar yang dapat diedit ---
  // MENGGANTI: Menambahkan parameter primaryColor
  Widget _buildEditableImageGrid(Color primaryColor) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 1. Kotak Tambah Gambar (Selalu ada jika kuota belum penuh)
          if (_currentImages.length < MAX_IMAGES)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    // MENGGANTI: Warna hardcoded dengan primaryColor
                    color: primaryColor,
                    width: 2,
                    // PERBAIKAN: Menggunakan BorderStyle.solid
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      // MENGGANTI: Warna hardcoded dengan primaryColor
                      color: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambah Gambar',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      '(${_currentImages.length}/$MAX_IMAGES)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Daftar Gambar yang Sudah Ada/Baru Dipilih
          ..._currentImages.map((img) {
            Widget imageWidget;

            if (img.url != null) {
              // Gambar lama dari server (gunakan NetworkImage)
              imageWidget = Image.network(
                img.url!,
                fit: BoxFit.cover,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image));
                },
              );
            } else if (img.file != null) {
              // Gambar baru dari galeri (gunakan File atau Memory Image)
              imageWidget = kIsWeb
                  ? FutureBuilder<Uint8List>(
                      future: img.file!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: 150,
                            height: 150,
                          );
                        }
                        // MENGGANTI: Warna CircularProgressIndicator dengan primaryColor
                        return Center(
                            child: CircularProgressIndicator(
                          color: primaryColor,
                        ));
                      },
                    )
                  : Image.file(
                      File(img.file!.path),
                      fit: BoxFit.cover,
                      width: 150,
                      height: 150,
                    );
            } else {
              imageWidget = const Icon(Icons.error);
            }

            return Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageWidget,
                  ),
                  // Tombol Hapus
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(img),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
        title: const Text('Edit Produk'),
        // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Tampilan Gambar Produk (Editable Grid)
              Center(
                child: _buildEditableImageGrid(
                    primaryColor), // <-- Meneruskan primaryColor
              ),
              const SizedBox(height: 20),

              // Input Nama Produk
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Harga
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  if (int.tryParse(value.replaceAll(RegExp(r'[.,]'), '')) ==
                      null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
                // Tambahkan format saat input
                onChanged: (text) {
                  String cleaned = text.replaceAll(RegExp(r'[.,]'), '');
                  if (cleaned.isNotEmpty) {
                    final formatter = NumberFormat('#,###', 'id_ID');
                    final value = int.tryParse(cleaned);
                    if (value != null) {
                      final formatted = formatter.format(value);
                      _priceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Kategori
              _isLoadingCategories
                  ? Center(
                      // MENGGANTI: Warna hardcoded dengan primaryColor
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : DropdownButtonFormField<ProductCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((ProductCategory category) {
                        return DropdownMenuItem<ProductCategory>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (ProductCategory? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih kategori';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // Dropdown Kondisi
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Produk',
                  border: OutlineInputBorder(),
                ),
                items: ['baru', 'bekas'].map((String condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text(
                      condition[0].toUpperCase() + condition.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCondition = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih kondisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Lokasi
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Deskripsi
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    // MENGGANTI: Warna hardcoded (0xFF4CAF50) dengan primaryColor
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 18),
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
