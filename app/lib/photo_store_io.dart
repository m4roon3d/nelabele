import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<File> _file(String id) async {
  final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/place_photos');
  if (!await dir.exists()) await dir.create(recursive: true);
  return File('${dir.path}/$id.jpg');
}

Future<void> write(String id, Uint8List bytes) async => (await _file(id)).writeAsBytes(bytes, flush: true);

Future<Uint8List?> read(String id) async {
  final f = await _file(id);
  return await f.exists() ? f.readAsBytes() : null;
}

Future<void> remove(String id) async {
  final f = await _file(id);
  if (await f.exists()) await f.delete();
}
