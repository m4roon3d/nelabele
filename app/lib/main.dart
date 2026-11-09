import 'package:flutter/material.dart';

import 'saved.dart';
import 'settings.dart';
import 'share_inbox.dart';
import 'shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EditorKey.load();
  await SavedPlaces.load();
  await ShareInbox.init();
  runApp(const NelaBeleApp());
}

class NelaBeleApp extends StatelessWidget {
  const NelaBeleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NelaBele',
      debugShowCheckedModeBanner: false,
      theme: nelabeleTheme(Brightness.light),
      darkTheme: nelabeleTheme(Brightness.dark),
      home: const AppShell(),
    );
  }
}
