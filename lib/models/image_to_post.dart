import 'dart:typed_data';

// Model pembantu untuk menangani file dan bytes (untuk Web)
class ImageToPost {
  final String path;
  final Uint8List? bytes;
  final String name;

  ImageToPost({required this.path, this.bytes, required this.name});
}
