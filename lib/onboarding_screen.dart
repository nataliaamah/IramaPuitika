import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/result.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  File? _selectedImage;
  String _keywords = 'No response yet.';
  String? _selectedEmotion;
  bool _isLoading = false;
  int _currentStep = 0;

  final ImagePicker _picker = ImagePicker();
  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM';
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';
  final String flaskApiUrl = "http://172.20.10.6:5000/recommend";

  Set<String> joyKeywords = {};
  Set<String> sadnessKeywords = {};
  Set<String> angerKeywords = {};
  Set<String> allEmotionKeywords = {};

  @override
  void initState() {
    super.initState();
    loadAllLexicons();
  }

  Future<Set<String>> loadEmotionKeywords(String filePath) async {
    final String content = await rootBundle.loadString(filePath);
    return content
        .split('\n')
        .map((line) => line.split(RegExp(r'\s+'))[0].trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  Future<void> loadAllLexicons() async {
    joyKeywords =
    await loadEmotionKeywords("assets/txt/joy-NRC-Emotion-Lexicon.txt");
    sadnessKeywords =
    await loadEmotionKeywords("assets/txt/sadness-NRC-Emotion-Lexicon.txt");
    angerKeywords =
    await loadEmotionKeywords("assets/txt/anger-NRC-Emotion-Lexicon.txt");

    allEmotionKeywords =
        joyKeywords.union(sadnessKeywords).union(angerKeywords);
  }

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
      }
    } catch (e) {
      setState(() {
        _keywords = "Error selecting image: $e";
      });
    }
  }

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
                "text": "Analyze the given image and extract 5-7 keywords that best describe both its visual elements and emotional tone."
                    "\nYou MUST strictly choose words only from the predefined lexicons below. Do NOT add new words."
                    "\nIf no word from the list applies to the scene, select the closest matching words from the lexicon."
                    "\nThe final output should be a mix of descriptive and emotional words from this predefined list."
                    "\nOnly use words from the following lexicons:"
                    "\nJoy: ${joyKeywords.join(', ')}"
                    "\nSadness: ${sadnessKeywords.join(', ')}"
                    "\nAnger: ${angerKeywords.join(', ')}"
                    "\nDO NOT generate words outside this list. If a word is not in the list, exclude it."
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
        final parts = result['candidates']?[0]['content']['parts'] as List<
            dynamic>? ?? [];

        List<String> extractedWords = parts
            .where((part) => part['text'] != null)
            .map((part) => part['text'].toString().toLowerCase().trim())
            .expand((text) => text.split(','))
            .map((word) => word.trim())
            .where((word) => allEmotionKeywords.contains(word))
            .toList()
            .take(7)
            .toList();

        setState(() {
          _keywords = extractedWords.isNotEmpty
              ? extractedWords.join(", ")
              : "No valid keywords detected.";
          _isLoading = false;
        });
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

  Future<void> _fetchPantunRecommendations() async {
    try {
      print("🚀 Sending to API: ${jsonEncode({
        "emotion": _selectedEmotion,
        "image_keywords": _keywords.split(', ').map((word) => word.trim()).toList()
      })}");

      var response = await http.post(
        Uri.parse(flaskApiUrl), // Your Flask API Endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emotion": _selectedEmotion,
          "image_keywords": _keywords.split(', ').map((word) => word.trim()).toList()
        }),
      );

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<Map<String, dynamic>> pantunResults = List<Map<String, dynamic>>.from(data['pantuns']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(result: pantunResults), // ✅ Now explicitly defined
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch pantun: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Plain white background
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                physics: const ClampingScrollPhysics(),
                children: [
                  _imageInputScreen(),
                  _emotionSelectionScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageInputScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step 1: Upload Your Scenery',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Choose an image that inspires you',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => _pickImage(fromCamera: false),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: 250,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 50,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to Upload',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (_isLoading)
            CircularProgressIndicator(
              color: Colors.black87,
            ),
          if (!_isLoading && _selectedImage != null)
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "Keywords: $_keywords",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _selectedImage != null
                ? () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Next',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 5,),
          TextButton(
            onPressed: () {
              // Navigate back to HomePage
              Navigator.pop(context);
            },
            child: Text(
              'Back to Home',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emotionSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step 2: Choose Your Emotion',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'How does the scenery make you feel?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _emotionButton('Happy', 'assets/images/happy.png'),
              _emotionButton('Angry', 'assets/images/angry.png'),
              _emotionButton('Sad', 'assets/images/sad.png'),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _selectedEmotion != null ? _fetchPantunRecommendations : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Generate Pantun',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: Text(
              'Back',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emotionButton(String emotion, String assetPath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmotion = emotion;
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedEmotion == emotion ? Colors.grey.shade200 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _selectedEmotion == emotion ? Colors.black87 : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                assetPath,
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 10),
              Text(
                emotion,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
