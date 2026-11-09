import 'package:flutter/material.dart';

import 'home_page.dart';
import 'theme.dart';

void main() => runApp(const NelaBeleApp());

class NelaBeleApp extends StatelessWidget {
  const NelaBeleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NelaBele',
      debugShowCheckedModeBanner: false,
      theme: nelabeleTheme(Brightness.light),
      darkTheme: nelabeleTheme(Brightness.dark),
      home: const HomePage(),
    );
  }
}
