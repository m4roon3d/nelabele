import 'package:flutter/material.dart';

import 'settings.dart';
import 'shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EditorKey.load();
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
