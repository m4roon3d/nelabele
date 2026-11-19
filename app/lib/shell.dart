import 'package:flutter/foundation.dart';

import 'api.dart';
import 'area_sheet.dart';
import 'home_page.dart';
import 'listing_import_page.dart';
import 'map_page.dart';
import 'saved_page.dart';
import 'settings.dart';
import 'share_inbox.dart';
import 'theme.dart';
import 'i18n.dart';
import 'ui.dart';

/// Brand header, List / Map tabs and the settings button.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  bool _mapOpened = false;

  @override
  void initState() {
    super.initState();
    ShareInbox.text.addListener(_onShared);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onShared();
      _openLinkedArea();
    });
  }

  /// A shared link (…/nelabele/?area=123) opens that place's rate card.
  Future<void> _openLinkedArea() async {
    if (!kIsWeb) return;
    final id = int.tryParse(Uri.base.queryParameters['area'] ?? '');
    if (id == null) return;
    try {
      final area = await NelaBeleApi().fetchArea(id);
      if (area != null && mounted) await showAreaSheet(context, area);
    } catch (_) {}
  }

  @override
  void dispose() {
    ShareInbox.text.removeListener(_onShared);
    super.dispose();
  }

  /// A listing shared from another app opens straight in the import screen.
  void _onShared() {
    final text = ShareInbox.text.value;
    if (text == null || !mounted) return;
    ShareInbox.text.value = null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ListingImportPage(initialText: text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36, semanticLabel: 'NelaBele logo'),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Nela'),
                    TextSpan(
                      text: 'Bele',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark ? Brand.redEarthDark : Brand.redEarthText,
                      ),
                    ),
                  ]),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(Lang.kannada ? 'ನೆಲ ಬೆಲೆ · ಅಂದಾಜು ಆಸ್ತಿ ದರಗಳು' : 'ನೆಲ ಬೆಲೆ · indicative property rates',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: t('Settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          const RatesListView(),
          // the map is built the first time its tab opens, then kept alive
          _mapOpened ? const MapPage() : const SizedBox.shrink(),
          const SavedPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          if (i == 1) _mapOpened = true;
        }),
        destinations: [
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: t('List')),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: t('Map')),
          NavigationDestination(icon: Icon(Icons.star_outline), selectedIcon: Icon(Icons.star), label: t('Saved')),
        ],
      ),
    );
  }
}
