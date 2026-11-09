import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Text shared to NelaBele from another Android app (e.g. a property portal).
class ShareInbox {
  static const _channel = MethodChannel('nelabele/share');
  static final ValueNotifier<String?> text = ValueNotifier<String?>(null);

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared' && call.arguments is String) text.value = call.arguments as String;
    });
    try {
      final initial = await _channel.invokeMethod<String>('initialText');
      if (initial != null && initial.trim().isNotEmpty) text.value = initial;
    } catch (_) {}
  }
}
