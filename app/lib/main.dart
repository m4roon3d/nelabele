import 'package:flutter/material.dart';

import 'saved.dart';
import 'search.dart';
import 'settings.dart';
import 'share_inbox.dart';
import 'shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EditorKey.load();
  await ThemeChoice.load();
  await SavedPlaces.load();
  await ShareInbox.init();
  SearchIndex.load(); // in the background; search uses the server until it arrives
  runApp(const NelaBeleApp());
}

class NelaBeleApp extends StatelessWidget {
  const NelaBeleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeChoice.current,
      builder: (context, mode, _) => MaterialApp(
        title: 'NelaBele',
        debugShowCheckedModeBanner: false,
        theme: nelabeleTheme(Brightness.light),
        darkTheme: nelabeleTheme(Brightness.dark),
        themeMode: mode,
        home: const AppShell(),
      ),
    );
  }
}
