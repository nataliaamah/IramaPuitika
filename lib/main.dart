import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Context-based Poetry Recommender System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(), // Set HomePage as the main screen
    );
  }
}
