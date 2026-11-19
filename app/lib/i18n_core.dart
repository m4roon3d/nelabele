/// Translation lookup without Flutter, so plain Dart tools can use format.dart.
library;

import 'kn.dart';

/// 'en' or 'kn'; set by Lang in i18n.dart.
String languageCode = 'en';

bool get isKannada => languageCode == 'kn';

/// The interface text [en] in the chosen language, with {name} placeholders
/// filled from [args]. Text without a Kannada version stays in English.
String t(String en, [Map<String, String>? args]) {
  var s = isKannada ? (kn[en] ?? en) : en;
  if (args != null) {
    for (final MapEntry(:key, :value) in args.entries) {
      s = s.replaceAll('{$key}', value);
    }
  }
  return s;
}
