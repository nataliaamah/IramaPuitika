import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';

import 'select_emotion.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  File? _selectedImage;
  String _keywords = 'No response yet.';
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM';
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

  /// Picks an image from gallery or camera
  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _keywords = 'Processing...';
          _isLoading = true;
        });

        _uploadAndAnalyzeImage();
      } else {
        setState(() {
          _keywords = "No image selected.";
        });
      }
    } catch (e) {
      setState(() {
        _keywords = "Error selecting image: $e";
      });
    }
  }

  /// Uploads and analyzes the image using Gemini API
  Future<void> _uploadAndAnalyzeImage() async {
    try {
      if (_selectedImage == null) return;

      final imageBytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": "Analyze this scene and generate emotion-related keywords."},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 512,
        }
      };

      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['candidates'] != null &&
            result['candidates'].isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null) {
          final parts = result['candidates'][0]['content']['parts'] as List<dynamic>;

          final textResponse = parts
              .where((part) => part['text'] != null && part['text'] is String)
              .map((part) => part['text'] as String)
              .join('\n');

          setState(() {
            _keywords = textResponse;
            _isLoading = false;
          });
        } else {
          setState(() {
            _keywords = 'No valid response received.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _keywords = 'Error ${response.statusCode}: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _keywords = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Moves to the next page
  void _nextPage() {
    if (_pageController.page == 0 && _selectedImage != null) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Moves to the previous page
  void _previousPage() {
    if (_pageController.page == 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(), // Prevents overscrolling
        children: [
          _imageInputScreen(),
          SelectEmotionScreen(keywords: _keywords),
        ],
      ),
    );
  }

  /// First Page: Image Input
  Widget _imageInputScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Step 1/2',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Image.asset("assets/images/step_1.gif", height: 250, width: 200),

          // Dotted Border for Upload
          GestureDetector(
            onTap: () => _pickImage(fromCamera: false),
            child: DottedBorder(
              color: Colors.grey,
              strokeWidth: 2,
              dashPattern: [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(10),
              child: Container(
                width: 200,
                height: 150,
                alignment: Alignment.center,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload, size: 40, color: Colors.black54),
                    const SizedBox(height: 5),
                    Text('Tap to Upload', style: GoogleFonts.poppins(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Gemini AI Response Section (Loading + Generated Keywords)
          if (_selectedImage != null) ...[
            Text(
              'Gemini Generated Keywords:',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                _keywords,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              ),
              ElevatedButton(
                onPressed: _selectedImage != null ? _nextPage : null,
                child: Text('Next →', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
