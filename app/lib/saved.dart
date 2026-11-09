import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Places starred on this device, newest first.
class SavedPlaces {
  static const _prefKey = 'saved_places';
  static final ValueNotifier<List<int>> ids = ValueNotifier<List<int>>(const []);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      ids.value = (prefs.getStringList(_prefKey) ?? const <String>[]).map(int.tryParse).whereType<int>().toList();
    } catch (_) {}
  }

  static bool contains(int id) => ids.value.contains(id);

  static Future<void> toggle(int id) async {
    final next = [...ids.value];
    if (!next.remove(id)) next.insert(0, id);
    ids.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, [for (final i in next) '$i']);
    } catch (_) {}
  }
}
