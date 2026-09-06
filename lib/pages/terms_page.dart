import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext context) {
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
          'Syarat & Ketentuan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Dengan menggunakan aplikasi "e-Village by Citiasia Inc.", Anda setuju untuk mematuhi dan terikat oleh syarat dan ketentuan berikut. Jika Anda tidak setuju dengan syarat dan ketentuan ini, mohon untuk tidak menggunakan aplikasi ini.\n\n'
              '1. PENERIMAAN SYARAT\n'
              'Dengan mengunduh, menginstal, atau menggunakan aplikasi ini, Anda menyetujui untuk terikat pada Syarat & Ketentuan ini. Jika Anda tidak menyetujui syarat ini, jangan menggunakan aplikasi ini.\n\n'
              '2. DESKRIPSI LAYANAN\n'
              'e-Village by Citiasia Inc. adalah platform digital yang dirancang untuk memfasilitasi komunikasi dan kolaborasi antara warga desa, pemerintah desa, dan stakeholder terkait.\n\n'
              '3. AKUN PENGGUNA\n'
              'Anda bertanggung jawab untuk menjaga kerahasiaan akun dan kata sandi Anda. Anda setuju untuk menerima tanggung jawab atas semua aktivitas yang terjadi di bawah akun Anda.\n\n'
              '4. PENGGUNAAN YANG DIIZINKAN\n'
              'Anda setuju untuk menggunakan aplikasi ini hanya untuk tujuan yang sah dan sesuai dengan hukum yang berlaku. Anda tidak diperkenankan untuk:\n'
              '• Menggunakan aplikasi untuk tujuan yang melanggar hukum\n'
              '• Mengganggu atau merusak integritas atau kinerja aplikasi\n'
              '• Mencoba mendapatkan akses tidak sah ke sistem atau jaringan\n\n'
              '5. KONTEN PENGGUNA\n'
              'Anda bertanggung jawab penuh atas konten yang Anda bagikan melalui aplikasi ini. Anda menjamin bahwa konten tersebut tidak melanggar hak cipta, merek dagang, atau hak kekayaan intelektual lainnya.\n\n'
              '6. PRIVASI\n'
              'Penggunaan informasi pribadi Anda diatur oleh Kebijakan Privasi kami. Dengan menggunakan aplikasi ini, Anda menyetujui pengumpulan dan penggunaan informasi sesuai kebijakan tersebut.\n\n'
              '7. PENOLAKAN JAMINAN\n'
              'Aplikasi ini disediakan "sebagaimana adanya" tanpa jaminan apapun. Citiasia Inc. tidak menjamin bahwa layanan akan selalu tersedia atau bebas dari kesalahan.\n\n'
              '8. BATASAN TANGGUNG JAWAB\n'
              'Citiasia Inc. tidak akan bertanggung jawab atas kerugian langsung, tidak langsung, insidental, atau konsekuential yang timbul dari penggunaan aplikasi ini.\n\n'
              '9. PERUBAHAN SYARAT\n'
              'Kami berhak mengubah syarat dan ketentuan ini sewaktu-waktu. Perubahan akan berlaku efektif setelah dipublikasikan dalam aplikasi.\n\n'
              '10. HUKUM YANG BERLAKU\n'
              'Syarat dan ketentuan ini diatur oleh hukum Republik Indonesia. Setiap sengketa akan diselesaikan melalui pengadilan yang berwenang di Indonesia.\n\n'
              'Jika Anda memiliki pertanyaan tentang Syarat & Ketentuan ini, silakan hubungi kami melalui informasi kontak yang tersedia dalam aplikasi.\n\n'
              'Terakhir diperbarui: September 2025',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
