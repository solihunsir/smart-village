import 'package:desaku/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/resource_service.dart';
import '../config/api_config.dart';
import 'resource_detail_page.dart';

class ResourcesListPage extends StatefulWidget {
  const ResourcesListPage({Key? key}) : super(key: key);

  @override
  State<ResourcesListPage> createState() => _ResourcesListPageState();
}

class _ResourcesListPageState extends State<ResourcesListPage> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ResourceService.list(perPage: 50, isActive: true);
      setState(() => _items = r);
    } catch (e) {
      AppLogger.log('ResourcesListPage: failed to load items: $e');
      setState(() => _items = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  String _titleOf(dynamic it) {
    try {
      if (it is Map)
        return (it['name'] ?? it['title'] ?? it['nama'] ?? '').toString();
      return it.toString();
    } catch (_) {
      return '';
    }
  }

  String _imageOf(dynamic it) {
    try {
      if (it is Map) {
        final img = it['photo_url'] ??
            it['photoUrl'] ??
            it['image'] ??
            it['featured_image'] ??
            it['photo'];
        if (img == null) return '';
        final s = img.toString();
        if (s.startsWith('http')) return s;
        if (s.startsWith('/')) return '${ApiConfig.baseUrl}$s';
        return '${ApiConfig.baseUrl}/$s';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sumber Daya Alam')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty
              ? _emptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final it = _items[i];
                    final title = _titleOf(it);
                    final img = _imageOf(it);
                    final category = ((it is Map)
                                ? (it['category'] ?? it['kategori'])
                                : null)
                            ?.toString() ??
                        '';
                    return GestureDetector(
                      onTap: () {
                        // Ke Detail
                        final id = (it is Map) ? it['id'] : null;
                        if (id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ResourceDetailPage(resourceId: id as int),
                            ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(color: Colors.grey[200]),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.55),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                right: 8,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (category.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          left: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
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
                )),
    );
  }

  Widget _emptyState() {
    if (kDebugMode) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: 6,
        itemBuilder: (context, i) {
          final img = 'https://picsum.photos/seed/res$i/800/600';
          final title = 'Contoh Sumber ${i + 1}';
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: Image.network(img, fit: BoxFit.cover)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    right: 8,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.park_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Belum ada sumber daya alam',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
