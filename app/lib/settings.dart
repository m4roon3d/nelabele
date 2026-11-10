import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bulk_import_page.dart';
import 'listing_import_page.dart';

/// Light, dark or follow the phone; remembered on this device.
class ThemeChoice {
  static const _prefKey = 'theme_mode';
  static final ValueNotifier<ThemeMode> current = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      current.value = switch (prefs.getString(_prefKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {}
  }

  static Future<void> save(ThemeMode mode) async {
    current.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }
}

/// The owner's private editor key, kept on this device only.
class EditorKey {
  static const _prefKey = 'editor_key';
  static final ValueNotifier<String?> current = ValueNotifier<String?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    current.value = prefs.getString(_prefKey);
  }

  static Future<void> save(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    final k = key?.trim();
    if (k == null || k.isEmpty) {
      await prefs.remove(_prefKey);
      current.value = null;
    } else {
      await prefs.setString(_prefKey, k);
      current.value = k;
    }
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final k = _controller.text.trim();
    if (k.split('.').length != 3) {
      setState(() => _error = "That doesn't look like an editor key. Paste the whole key.");
      return;
    }
    await EditorKey.save(k);
    _controller.clear();
    if (!mounted) return;
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editor key saved')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<String?>(
        valueListenable: EditorKey.current,
        builder: (context, key, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Appearance', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeChoice.current,
              builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Phone')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => ThemeChoice.save(s.first),
              ),
            ),
            const SizedBox(height: 28),
            Text('Editor key', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'With an editor key you can log market rates you come across. '
              'Keep it private: anyone with it can add rates.',
              style: muted,
            ),
            const SizedBox(height: 16),
            if (key != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Editor key saved on this device'),
                  subtitle: Text('…${key.substring(key.length - 6)}'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => EditorKey.save(null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove key'),
              ),
              const SizedBox(height: 24),
              Text('Add market rates', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'On Android you can also share a listing from 99acres, MagicBricks, Housing or '
                'any app straight to NelaBele.',
                style: muted,
              ),
              const SizedBox(height: 8),
              Card.outlined(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('From a listing'),
                    subtitle: const Text('Paste a listing’s text; NelaBele reads the price and size'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ListingImportPage()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.playlist_add),
                    title: const Text('Bulk import'),
                    subtitle: const Text('Paste many rates, one per line'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const BulkImportPage()),
                    ),
                  ),
                ]),
              ),
            ] else ...[
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Paste your editor key',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('Save key')),
            ],
          ],
        ),
      ),
    );
  }
}
