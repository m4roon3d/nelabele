import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

String _key(String id) => 'place_photo_$id';

Future<void> write(String id, Uint8List bytes) async {
  final prefs = await SharedPreferences.getInstance();
  if (!await prefs.setString(_key(id), base64Encode(bytes))) {
    throw StateError('Browser storage is full');
  }
}

Future<Uint8List?> read(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString(_key(id));
  return s == null ? null : base64Decode(s);
}

Future<void> remove(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_key(id));
}
