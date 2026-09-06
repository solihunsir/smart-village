import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Pastikan path ke service Anda benar
import '../services/auth_service.dart';
import '../services/token_service.dart';

// --- MODEL DATA KATEGORI ---
class ReportCategory {
  final int id;
  final String category;

  ReportCategory({required this.id, required this.category});

  factory ReportCategory.fromJson(Map<String, dynamic> json) {
    return ReportCategory(
      id: json['id'] as int,
      category: json['category'] as String,
    );
  }
}

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});
  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailLocationController = TextEditingController();

  // --- Variabel API & State ---
  static const String _apiBaseUrl = 'https://smart-village-web.citiasiainc.id';
  static const String _apiSubmitReport = '$_apiBaseUrl/api/mobile/reports';

  // State untuk File
  File? _selectedMobileFile;
  Uint8List? _selectedWebFileBytes;
  List<XFile> _uploadedXFiles = [];

  // State untuk Kategori dari API
  List<ReportCategory> _categoriesFromApi = [];
  bool _isLoadingCategories = true;
  String? _selectedCategoryValue;

  // Variabel Form
  int _descriptionLength = 0;
  final int _maxDescriptionLength = 208;
  bool _isSubmitting = false;
  bool _isAgree = false;
  final ImagePicker _picker = ImagePicker();

  // TAMBAHAN: State untuk indikator progress upload dan kontrol dialog
  bool _isShowingProgressDialog = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateDescriptionLength);
    _fetchReportCategories();
  }

  void _updateDescriptionLength() {
    if (mounted) {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateDescriptionLength);
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _detailLocationController.dispose();
    super.dispose();
  }

  // --- FUNGSI FETCH KATEGORI DARI API ---
  Future<void> _fetchReportCategories() async {
    // ... (Kode fetch category, diasumsikan sudah benar)
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final uri = Uri.parse('$_apiBaseUrl/api/report-categories');
      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> categoryListJson = jsonResponse['data'];

        final List<ReportCategory> fetchedCategories = categoryListJson
            .map((json) => ReportCategory.fromJson(json))
            .toList();

        setState(() {
          _categoriesFromApi = fetchedCategories;
          _isLoadingCategories = false;
          if (_categoriesFromApi.isNotEmpty && _selectedCategoryValue == null) {
            _selectedCategoryValue = _categoriesFromApi.first.category;
          }
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat kategori. Status: ${response.statusCode}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koneksi Gagal. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- FUNGSI IMAGE PICKER & WIDGET (Tidak diubah) ---

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        limit: 3 - _uploadedXFiles.length,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _uploadedXFiles.addAll(pickedFiles);
          if (_uploadedXFiles.length > 3) {
            _uploadedXFiles = _uploadedXFiles.sublist(0, 3);
          }
          if (_uploadedXFiles.isNotEmpty) {
            final firstFile = _uploadedXFiles.first;
            if (kIsWeb) {
              firstFile.readAsBytes().then((bytes) {
                if (mounted) {
                  setState(() {
                    _selectedWebFileBytes = bytes;
                    _selectedMobileFile = null;
                  });
                }
              });
            } else {
              _selectedMobileFile = File(firstFile.path);
              _selectedWebFileBytes = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (_uploadedXFiles.length >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maksimal 3 file dokumentasi.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _uploadedXFiles.add(pickedFile);
          if (kIsWeb) {
            pickedFile.readAsBytes().then((bytes) {
              if (mounted) {
                setState(() {
                  _selectedWebFileBytes = bytes;
                  _selectedMobileFile = null;
                });
              }
            });
          } else {
            _selectedMobileFile = File(pickedFile.path);
            _selectedWebFileBytes = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerBottomSheet() {
    if (_uploadedXFiles.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah mengunggah maksimal 3 file.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Gambar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Kamera'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Galeri'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI SUBMIT API (Fokus Perbaikan) ---

  void _submitComplaint() async {
    // 1. Validasi Form Lokal & Persetujuan
    if (!_formKey.currentState!.validate() || !_isAgree) {
      if (!_isAgree) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus menyetujui pernyataan sebelum mengirim.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Pengecekan Kategori
    if (_selectedCategoryValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori laporan harus dipilih.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Pengambilan Token Autentikasi (Pengecekan Kritis)
    final token = await TokenService.getToken();

    if (token == null || token.isEmpty) {
      // Jika token tidak ada, tampilkan dialog penolakan akses.
      if (mounted) {
        _showResultDialog(
          isSuccess: false,
          title: 'Akses Ditolak',
          content: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
        );
      }
      return;
    }

    // Pengecekan status login melalui provider (untuk konsistensi UI)
    final authProvider = AuthProvider.of(context);
    final authService = authProvider?.authService;

    if (authService != null && !authService.isLoggedIn) {
      if (mounted) {
        _showResultDialog(
          isSuccess: false,
          title: 'Akses Ditolak',
          content: 'Status login tidak valid. Silakan login ulang.',
        );
      }
      return;
    }

    // 3. Tampilkan dialog progress
    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });
    _showUploadProgressDialog();

    try {
      final uri = Uri.parse(_apiSubmitReport);
      final request = http.MultipartRequest('POST', uri);

      // *** PERBAIKAN KRITIS: Memastikan Header Authorization terkirim dengan format BEARER TOKEN ***
      request.headers['Authorization'] = 'Bearer $token';
      // *********************************************************************************************

      // Field yang dibutuhkan API
      request.fields['kategori'] = _selectedCategoryValue!;
      request.fields['judul_laporan'] = _titleController.text;
      request.fields['deskripsi_laporan'] = _descriptionController.text;
      request.fields['lokasi_laporan'] = _locationController.text;
      request.fields['detail_lokasi'] = _detailLocationController.text;

      // Tambahkan Files
      for (var xfile in _uploadedXFiles) {
        final bytes = await xfile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file_dokumentasi[]', // Pastikan key ini sesuai dengan API Laravel Anda
            bytes,
            filename: xfile.name,
          ),
        );
      }

      // Kirim request
      final streamedResponse = await request.send();

      // Tutup dialog progress
      if (mounted && _isShowingProgressDialog) {
        Navigator.of(context, rootNavigator: true).pop();
        _isShowingProgressDialog = false;
      }

      final responseBody = await streamedResponse.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);

      // 4. Penanganan Response
      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        // Berhasil (Status 200-299)
        if (!mounted) return;
        _showResultDialog(
          isSuccess: true,
          title: jsonResponse['message'] ?? 'Laporan berhasil dikirim',
          content:
              'Pengaduan Anda telah berhasil dikirim dan akan segera ditindaklanjuti oleh tim terkait.',
        );
      } else if (streamedResponse.statusCode == 401 ||
          streamedResponse.statusCode == 403) {
        // Gagal Otorisasi (Status 401 Unauthorized atau 403 Forbidden)
        if (!mounted) return;
        _showResultDialog(
          isSuccess: false,
          title: 'Akses Ditolak (401/403)',
          content: jsonResponse['message'] ??
              'Token autentikasi tidak valid atau telah kedaluwarsa. Silakan login ulang.',
        );
      } else {
        // Penanganan error umum (400, 422, 500, dll.)
        if (!mounted) return;
        String errorMessage = jsonResponse['message'] ??
            'Terjadi kesalahan. Status: ${streamedResponse.statusCode}';

        if (streamedResponse.statusCode == 422 &&
            jsonResponse['errors'] != null) {
          // Jika Laravel mengembalikan error validasi 422
          errorMessage = 'Validasi Gagal: ' +
              jsonResponse['errors'].values.map((e) => e.first).join('; ');
        }

        _showResultDialog(
          isSuccess: false,
          title: 'Gagal Mengirim Laporan',
          content: errorMessage,
        );
      }
    } catch (e) {
      // Pastikan dialog ditutup jika terjadi error koneksi
      if (mounted && _isShowingProgressDialog) {
        Navigator.of(context, rootNavigator: true).pop();
        _isShowingProgressDialog = false;
      }

      if (!mounted) return;
      _showResultDialog(
        isSuccess: false,
        title: 'Error Koneksi',
        content: 'Tidak dapat terhubung ke server. Error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --- Fungsi Dialog dan Widget lainnya (Pertahankan kode asli) ---

  void _showUploadProgressDialog() {
    _isShowingProgressDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Mengunggah Laporan'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mohon tunggu, kami sedang mengunggah dokumentasi Anda...',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                backgroundColor: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog({
    required bool isSuccess,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? const Color(0xFF4CAF50) : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSuccess ? const Color(0xFF4CAF50) : Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSuccess) {
                _titleController.clear();
                _descriptionController.clear();
                _locationController.clear();
                _detailLocationController.clear();
                _uploadedXFiles.clear();
                _selectedMobileFile = null;
                _selectedWebFileBytes = null;
                _isAgree = false;
                if (Navigator.of(context).canPop()) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    Navigator.of(context).pop();
                  });
                }
              }
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: isSuccess ? const Color(0xFF4CAF50) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Kode Widget Helper (Disertakan kembali untuk kelengkapan) ---

  Widget _buildPhotoUploadSection() {
    // ... (kode widget)
    final bool hasFile = _uploadedXFiles.isNotEmpty;
    Widget? imageWidget;
    if (hasFile) {
      if (kIsWeb && _selectedWebFileBytes != null) {
        imageWidget = Image.memory(
          _selectedWebFileBytes!,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
        );
      } else if (!kIsWeb && _selectedMobileFile != null) {
        imageWidget = Image.file(
          _selectedMobileFile!,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
        );
      }
    }
    return GestureDetector(
      onTap: _showImagePickerBottomSheet,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: hasFile
              ? Border.all(color: const Color(0xFF4CAF50), width: 2)
              : null,
        ),
        child: hasFile && imageWidget != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _uploadedXFiles.clear();
                          _selectedMobileFile = null;
                          _selectedWebFileBytes = null;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (_uploadedXFiles.length > 1)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${_uploadedXFiles.length - 1} File Lainnya',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 40,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan Dokumentasi anda (Max 3)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    'berupa Foto/Video',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    // ... (kode widget)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoadingCategories
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              isExpanded: true,
              value: _selectedCategoryValue,
              items: _categoriesFromApi.map((ReportCategory category) {
                return DropdownMenuItem<String>(
                  value: category.category,
                  child: Text(
                    category.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategoryValue = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kategori harus dipilih';
                }
                return null;
              },
            ),
    );
  }

  Widget _buildStatementSectionSimple() {
    // ... (kode widget)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Pernyataan'),
        const SizedBox(height: 8),
        const Text(
          'Laporan yang saya buat benar dan dapat dipertanggungjawabkan',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Row(
          children: [
            Checkbox(
              value: _isAgree,
              onChanged: (value) {
                setState(() {
                  _isAgree = value!;
                });
              },
              activeColor: const Color(0xFF4CAF50),
              visualDensity: VisualDensity.compact,
            ),
            const Expanded(
              child: Text(
                'Ya, Saya Setuju',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButtonSticky() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isAgree && !_isSubmitting) ? _submitComplaint : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Kirim Laporan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    // ... (kode widget)
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    // ... (kode widget)
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildMultilineTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    // ... (kode widget)
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildMultilineTextFieldWithCounter({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required int maxLength,
    required int currentLength,
    String? Function(String?)? validator,
  }) {
    // ... (kode widget)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: TextInputType.multiline,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Maksimal ${maxLength} Karakter',
                style: TextStyle(
                  fontSize: 10,
                  color: currentLength > maxLength ? Colors.red : Colors.grey,
                ),
              ),
              Text(
                '$currentLength/$maxLength',
                style: TextStyle(
                  fontSize: 10,
                  color: currentLength > maxLength ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Akhir Kode Widget Helper ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Laporan Pengaduan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoUploadSection(),
              const SizedBox(height: 16),
              _buildLabel('Judul Laporan'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: 'Contoh: Jalan berlubang di Jl. Merdeka',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul laporan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Deskripsi Laporan'),
              const SizedBox(height: 8),
              _buildMultilineTextFieldWithCounter(
                controller: _descriptionController,
                hint:
                    'Jelaskan secara detail kejadian atau masalah yang ingin dilaporkan',
                maxLines: 4,
                maxLength: _maxDescriptionLength,
                currentLength: _descriptionLength,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi laporan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Lokasi Laporan'),
              const SizedBox(height: 8),
              _buildMultilineTextField(
                controller: _locationController,
                hint: 'Masukkan alamat lengkap (misal: Jl. Sudirman No. 12)',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi laporan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Detail Lokasi (Opsional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _detailLocationController,
                hint: 'Contoh: Di depan gerbang sekolah, samping pos security',
              ),
              const SizedBox(height: 16),
              _buildLabel('Kategori'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
              _buildStatementSectionSimple(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButtonSticky(),
    );
  }
}
