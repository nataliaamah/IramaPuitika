import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Emotion keywords loaded from the lexicon files
  Set<String> joyKeywords = {};
  Set<String> sadnessKeywords = {};
  Set<String> angerKeywords = {};
  Set<String> allEmotionKeywords = {};

  @override
  void initState() {
    super.initState();
    loadAllLexicons().then((_) {
      print("Lexicons loaded: ${allEmotionKeywords.length} words"); // Debugging
    });
  }


  /// Load emotion keywords from lexicon text files in assets
  Future<Set<String>> loadEmotionKeywords(String filePath) async {
    final String content = await rootBundle.loadString(filePath);
    return content
        .split('\n')
        .map((line) => line.split(' ')[0].trim().toLowerCase()) // Remove spaces and convert to lowercase
        .toSet();
  }

  /// Load all lexicon files into memory
  Future<void> loadAllLexicons() async {
    joyKeywords = await loadEmotionKeywords("assets/txt/joy-NRC-Emotion-Lexicon.txt");
    sadnessKeywords = await loadEmotionKeywords("assets/txt/sadness-NRC-Emotion-Lexicon.txt");
    angerKeywords = await loadEmotionKeywords("assets/txt/anger-NRC-Emotion-Lexicon.txt");

    // Combine all words into a single set
    allEmotionKeywords = joyKeywords.union(sadnessKeywords).union(angerKeywords);
  }

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
              {
                "text": "Extract exactly 5-7 emotion-related keywords from the image."
                    "Only use words from this predefined lexicon:"
                    "\nJoy: ${joyKeywords.join(', ')}"
                    "\nSadness: ${sadnessKeywords.join(', ')}"
                    "\nAnger: ${angerKeywords.join(', ')}"
                    "\nDo NOT generate words outside this list."
                    "\nFormat the output as a comma-separated list: keyword1, keyword2, keyword3, ..."

              },
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
          "temperature": 0.5,
          "topK": 40,
          "topP": 0.9,
          "maxOutputTokens": 50
        }
      };

      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("Raw API Response: $result"); // DEBUGGING

        if (result['candidates'] != null &&
            result['candidates'].isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null) {
          final parts = result['candidates'][0]['content']['parts'] as List<dynamic>;

          // Extract and clean keywords
          String rawKeywords = parts
              .where((part) => part['text'] != null && part['text'] is String)
              .map((part) => part['text'] as String)
              .join(',');

          List<String> extractedWords = rawKeywords.split(',').map((word) => word.trim().toLowerCase()).toList();

          // Filter keywords against the lexicons
          List<String> filteredKeywords = extractedWords.where((word) {
            String cleanedWord = word.trim().toLowerCase(); // Normalize API word
            bool isInLexicon = allEmotionKeywords.contains(cleanedWord);
            print("Checking word: '$cleanedWord' - In Lexicon: $isInLexicon"); // Debugging
            return isInLexicon;
          }).toList();

          // Limit to 5-7 keywords
          filteredKeywords = filteredKeywords.take(7).toList();

          setState(() {
            _keywords = filteredKeywords.join(", ");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        children: [
          _imageInputScreen(),
          SelectEmotionScreen(keywords: _keywords),
        ],
      ),
    );
  }

  /// First Page: Image Input
  Widget _imageInputScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 100,),
            Text(
              'Step 1/2',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Image.asset("assets/images/step_1.gif", height: 250, width: 200),

            GestureDetector(
              onTap: _pickImage,
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

            // Gemini AI Response Section
            if (_selectedImage != null) ...[
              Text('Gemini Generated Keywords:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(_keywords, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
