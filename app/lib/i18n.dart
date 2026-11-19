import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n_core.dart';

export 'i18n_core.dart';

/// Interface language: English or Kannada, remembered on this device.
class Lang {
  static const _prefKey = 'language';
  static final ValueNotifier<String> current = ValueNotifier<String>('en');

  static bool get kannada => current.value == 'kn';

  static void _set(String code) {
    languageCode = code;
    current.value = code;
  }

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _set(prefs.getString(_prefKey) == 'kn' ? 'kn' : 'en');
    } catch (_) {}
  }

  static Future<void> save(String code) async {
    _set(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }
}
