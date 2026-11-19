import 'dart:typed_data';

import 'photo_store_web.dart' if (dart.library.io) 'photo_store_io.dart' as impl;

/// Document photos for saved places, kept on this device only: files in the
/// app's private folder on Android, browser storage on the web.
class PhotoStore {
  static Future<String> add(Uint8List bytes) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    await impl.write(id, bytes);
    return id;
  }

  static Future<Uint8List?> read(String id) => impl.read(id);

  static Future<void> remove(String id) => impl.remove(id);
}
