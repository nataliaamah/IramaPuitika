import 'package:flutter/material.dart';
import 'image_input.dart'; // Import the new file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Image Analysis',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ImageInputScreen(), // Use ImageInputScreen instead of HomeScreen
    );
  }
}
