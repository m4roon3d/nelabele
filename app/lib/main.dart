import 'package:flutter/material.dart';

import 'home_page.dart';

void main() => runApp(const NelaBeleApp());

class NelaBeleApp extends StatelessWidget {
  const NelaBeleApp({super.key});

  static const _seed = Color(0xFF8A5A2B); // red-earth brown

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NelaBele',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
