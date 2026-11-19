import 'dart:convert';

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

/// What a saved place looked like when its changes were last acknowledged,
/// per property type: guidance, market middle, number of market prices.
class SavedSnapshot {
  static const _prefKey = 'saved_snapshot';
  static const _dateKey = 'saved_snapshot_date';

  static Future<(Map<int, Map<String, List<num?>>>, DateTime?)> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      final date = DateTime.tryParse(prefs.getString(_dateKey) ?? '');
      if (raw == null) return (<int, Map<String, List<num?>>>{}, date);
      final data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return (
        {
          for (final MapEntry(:key, :value) in data.entries)
            int.parse(key): {
              for (final MapEntry(key: type, value: v) in (value as Map).cast<String, dynamic>().entries)
                type: (v as List).cast<num?>(),
            },
        },
        date,
      );
    } catch (_) {
      return (<int, Map<String, List<num?>>>{}, null);
    }
  }

  static Future<void> save(Map<int, Map<String, List<num?>>> snap, {bool touchDate = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode({for (final e in snap.entries) '${e.key}': e.value}));
      if (touchDate) await prefs.setString(_dateKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }
}

/// A contact for a saved place: seller, broker, lawyer.
class PlaceContact {
  const PlaceContact(this.name, this.phone, {this.role = ''});

  final String name;
  final String phone;
  final String role;

  Map<String, String> toJson() => {'name': name, 'phone': phone, 'role': role};

  static PlaceContact fromJson(Map<String, dynamic> j) =>
      PlaceContact(j['name'] as String? ?? '', j['phone'] as String? ?? '', role: j['role'] as String? ?? '');
}

/// Notes, contacts and document photos for a place, kept on this device only.
class PlaceNotes {
  PlaceNotes({this.text = '', List<PlaceContact>? contacts, List<String>? photos, this.updated})
      : contacts = contacts ?? [],
        photos = photos ?? [];

  String text;
  final List<PlaceContact> contacts;

  /// Photo ids in the device's photo store, with an optional caption after a tab.
  final List<String> photos;
  DateTime? updated;

  bool get isEmpty => text.trim().isEmpty && contacts.isEmpty && photos.isEmpty;

  static String _key(int id) => 'place_notes_$id';

  /// Places that have notes, so lists can show a marker.
  static final ValueNotifier<Set<int>> withNotes = ValueNotifier<Set<int>>(const {});
  static const _indexKey = 'place_notes_index';

  static Future<void> loadIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      withNotes.value = (prefs.getStringList(_indexKey) ?? const <String>[]).map(int.tryParse).whereType<int>().toSet();
    } catch (_) {}
  }

  static Future<PlaceNotes> load(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(id));
      if (raw == null) return PlaceNotes();
      final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return PlaceNotes(
        text: j['text'] as String? ?? '',
        contacts: [for (final c in (j['contacts'] as List? ?? const [])) PlaceContact.fromJson((c as Map).cast())],
        photos: (j['photos'] as List? ?? const []).cast<String>().toList(),
        updated: DateTime.tryParse(j['updated'] as String? ?? ''),
      );
    } catch (_) {
      return PlaceNotes();
    }
  }

  Future<void> save(int id) async {
    updated = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final index = {...withNotes.value};
    if (isEmpty) {
      await prefs.remove(_key(id));
      index.remove(id);
    } else {
      await prefs.setString(
        _key(id),
        jsonEncode({
          'text': text,
          'contacts': [for (final c in contacts) c.toJson()],
          'photos': photos,
          'updated': updated!.toIso8601String(),
        }),
      );
      index.add(id);
    }
    withNotes.value = index;
    await prefs.setStringList(_indexKey, [for (final i in index) '$i']);
  }
}
