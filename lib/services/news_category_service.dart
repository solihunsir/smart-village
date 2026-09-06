import '../models/news_category.dart';

class NewsCategoryService {
  static Future<List<NewsCategory>> list() async {
      // If API failed or returned empty, return default categories
    return [
      NewsCategory(id: 0, name: 'Semua', slug: null),
      NewsCategory(id: 2, name: 'Berita Desa', slug: 'berita-desa'),
      NewsCategory(id: 3, name: 'Kegiatan', slug: 'kegiatan'),
      NewsCategory(id: 4, name: 'Pengumuman', slug: 'pengumuman'),
    ];
  }
}
