import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:testing/home_page.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // Initialize the SDK

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Context-based Pantun Recommender System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(), // Set HomePage as the main screen
    );
  }
}
