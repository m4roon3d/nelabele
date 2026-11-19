import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n.dart';
import 'property_tax.dart';
import 'saved.dart';
import 'search.dart';
import 'settings.dart';
import 'share_inbox.dart';
import 'shell.dart';
import 'theme.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EditorKey.load();
  await ThemeChoice.load();
  await SavedPlaces.load();
  await PlaceNotes.loadIndex();
  await Lang.load();
  await OwnedProperties.load();
  await ShareInbox.init();
  SearchIndex.load(); // in the background; search uses the server until it arrives
  runApp(const NelaBeleApp());
}

class NelaBeleApp extends StatelessWidget {
  const NelaBeleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Lang.current,
      builder: (context, lang, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeChoice.current,
        builder: (context, mode, _) => MaterialApp(
          // a new key rebuilds every screen in the new language
          key: ValueKey(lang),
          title: 'NelaBele',
          debugShowCheckedModeBanner: false,
          theme: nelabeleTheme(Brightness.light),
          darkTheme: nelabeleTheme(Brightness.dark),
          themeMode: mode,
          locale: Locale(lang),
          supportedLocales: const [Locale('en'), Locale('kn')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AppShell(),
        ),
      ),
    );
  }
}
