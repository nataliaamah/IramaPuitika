import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
import 'select_emotion.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  File? _selectedImage;
  String _response = 'No response yet.';
  bool _isLoading = false; // Show a loading indicator
  final ImagePicker _picker = ImagePicker();

  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM'; // Replace with your valid API key
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
    loadAllLexicons(); // Load emotion lexicons at startup
  }

  /// Load emotion keywords from lexicon text files in assets
  Future<Set<String>> loadEmotionKeywords(String filePath) async {
    final String content = await rootBundle.loadString(filePath);
    return content
        .split('\n')
        .map((line) => line.trim().split(' ')[0].toLowerCase()) // Ignore the "1"
        .toSet();
  }

  /// Load all lexicon files into memory
  Future<void> loadAllLexicons() async {
    joyKeywords = await loadEmotionKeywords("assets/joy-NRC-Emotion-Lexicon.txt");
    sadnessKeywords = await loadEmotionKeywords("assets/sadness-NRC-Emotion-Lexicon.txt");
    angerKeywords = await loadEmotionKeywords("assets/anger-NRC-Emotion-Lexicon.txt");

    // Combine all words into a single set
    allEmotionKeywords = joyKeywords.union(sadnessKeywords).union(angerKeywords);
  }

  /// Opens dialog to choose between Camera or Gallery
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: false);
                },
              ),
            ],
          ),
        );
      },
    );
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
          _response = 'Processing...';
          _isLoading = true; // Show loading indicator
        });

        _uploadAndAnalyzeImage();
      } else {
        setState(() {
          _response = "No image selected.";
        });
      }
    } catch (e) {
      setState(() {
        _response = "Error selecting image: $e";
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
                "text": "Extract exactly 5-7 emotion-related keywords from the image. "
                    "Only use words that match the provided lexicon lists. "
                    "Do NOT include explanations, sentences, or additional text. "
                    "Output format: ['keyword1', 'keyword2', 'keyword3', ...]."
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
          List<String> filteredKeywords = extractedWords.where((word) => allEmotionKeywords.contains(word)).toList();

          // Limit to 5-7 keywords
          filteredKeywords = filteredKeywords.take(7).toList();

          setState(() {
            _response = filteredKeywords.join(", ");  // Display filtered words
            _isLoading = false;
          });
        } else {
          setState(() {
            _response = 'No valid response received.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _response = 'Error ${response.statusCode}: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
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
            Text('Enter Scenery Image', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showImagePickerOptions,
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
                  color: Colors.blueGrey[50], // Light background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                  _response,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  onPressed: _selectedImage != null
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectEmotionScreen(keywords: _response),
                      ),
                    );
                  }
                      : null, // Disable button if no image is uploaded
                  child: Text('Next →', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
