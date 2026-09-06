import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_product_page.dart';
import '../services/token_service.dart';
import '../services/seller_profile_service.dart';
import 'package:desaku/utils/app_logger.dart';

class SellerProfile {
  final String nik;
  SellerProfile({required this.nik});

  static SellerProfile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return SellerProfile(nik: json['nik'] ?? '');
  }
}
// ----------------------------------------------------

class NikVerificationPage extends StatefulWidget {
  const NikVerificationPage({Key? key}) : super(key: key);

  @override
  State<NikVerificationPage> createState() => _NikVerificationPageState();
}

class _NikVerificationPageState extends State<NikVerificationPage> {
  final _nikController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _nikController.addListener(_formatNIK);
    _checkVerificationStatus(); // Cek status NIK saat inisialisasi
  }

  @override
  void dispose() {
    _nikController.removeListener(_formatNIK);
    _nikController.dispose();
    super.dispose();
  }

  // --- FUNGSI BARU: CEK STATUS VERIFIKASI ---
  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => _isCheckingStatus = false);
        }
        return;
      }

      // Mengambil data mentah (Map)
      final Map<String, dynamic>? rawProfile =
          await SellerProfileService.getSellerProfile(token: token);

      // Mengkonversi ke model/object jika data ada
      final SellerProfile? existingProfile = SellerProfile.fromJson(rawProfile);

      if (existingProfile != null && mounted) {
        AppLogger.log(
            '✅ NIK sudah diverifikasi. Langsung navigasi ke AddProductPage.');

        // Navigasi dengan pushReplacement untuk menggantikan halaman NIK ini
        final result = await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AddProductPage()),
        );

        // Jika AddProductPage mengembalikan true (produk berhasil diunggah)
        if (mounted && result == true) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // Jika terjadi error (misalnya 401, 500, atau error parsing), biarkan user mencoba manual
      AppLogger.log('❌ Error checking initial seller status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  void _formatNIK() {
    String text = _nikController.text.replaceAll(' ', '');
    if (text.length > 16) {
      text = text.substring(0, 16);
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      // Perbaiki logika spasi agar NIK tidak diawali spasi
      if (i > 0 && (i == 2 || i == 4 || i == 6 || i == 12)) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    if (formatted != _nikController.text) {
      _nikController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String? _validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK wajib diisi';
    }

    String cleanNik = value.replaceAll(' ', '');

    if (cleanNik.length != 16) {
      return 'NIK harus 16 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanNik)) {
      return 'NIK hanya boleh berisi angka';
    }

    // Validasi basic format NIK (kode provinsi, kabupaten, dll)
    String provinsi = cleanNik.substring(0, 2);
    String kabupaten = cleanNik.substring(2, 4);
    String kecamatan = cleanNik.substring(4, 6);

    if (int.tryParse(provinsi) == null || int.parse(provinsi) == 0) {
      return 'Kode provinsi NIK tidak valid';
    }
    if (int.tryParse(kabupaten) == null || int.parse(kabupaten) == 0) {
      return 'Kode kabupaten NIK tidak valid';
    }
    if (int.tryParse(kecamatan) == null || int.parse(kecamatan) == 0) {
      return 'Kode kecamatan NIK tidak valid';
    }

    return null;
  }

  void _submitNIK() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi berakhir. Silakan login kembali.');
      }

      final nik = _nikController.text.replaceAll(' ', '');

      bool verified = false;

      // 1. Coba buat/update profil penjual
      try {
        verified = await SellerProfileService.createSellerProfile(
          token: token,
          nik: nik,
        );
      } catch (e) {
        AppLogger.log('NikVerificationPage: createSellerProfile failed: $e');
      }

      // 2. Fallback: Jika pembuatan gagal (misal 500) TAPI NIK sudah diverifikasi sebelumnya (409/422 sudah di-handle di service),
      // coba ambil ulang profil sebagai jaminan.
      if (!verified) {
        final existing = await SellerProfileService.getSellerProfile(
          token: token,
        );
        if (existing != null) {
          verified = true;
          AppLogger.log('NikVerificationPage: NIK existed, proceeding.');
        }
      }

      if (!verified) {
        throw Exception(
          'Verifikasi NIK gagal. Coba ulangi atau hubungi admin.',
        );
      }

      if (!mounted) return;

      // Navigasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIK berhasil diverifikasi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigasi ke add product page setelah NIK terverifikasi
      // Menggunakan pushReplacement agar halaman NIK hilang
      final result = await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddProductPage()),
      );

      // Return result ke marketplace
      if (mounted && result == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verifikasi NIK gagal. ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan Loading Status Cek
    if (_isCheckingStatus) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text(
                'Memeriksa status verifikasi...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan Input NIK
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi NIK',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 48,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Verifikasi Identitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Untuk keamanan, silakan masukkan NIK Anda sebelum dapat menjual produk',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // NIK Input
              const Text(
                'Nomor Induk Kependudukan (NIK)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nikController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(20), // 16 digits + 4 spaces
                ],
                validator: _validateNIK,
                decoration: InputDecoration(
                  hintText: '32 74 01 010190 0001',
                  prefixIcon: const Icon(
                    Icons.credit_card,
                    color: Color(0xFF4CAF50),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4CAF50),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'NIK Anda akan digunakan untuk verifikasi identitas dan keamanan transaksi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 0, 78, 145),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitNIK,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Verifikasi & Lanjutkan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
