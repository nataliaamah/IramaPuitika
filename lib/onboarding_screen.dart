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
  int _currentStep = 0; // Track current onboarding step

  final ImagePicker _picker = ImagePicker();
  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM';
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';
  final String flaskApiUrl = "http://192.168.50.160:5000/recommend"; // Flask URL

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
      body: Column(
        children: [
          // Onboarding progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
    );
  }

  Widget _imageInputScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step 1/2',
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold,),
          ),
          Text(
            'Select Scenery',
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.bold,),
          ),
          Image.asset('assets/images/step_1.gif', height: 200, width: 300,),
          const SizedBox(height: 20),
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
                    Text('Tap to Upload',
                        style: GoogleFonts.poppins(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading) const CircularProgressIndicator(),
          if (!_isLoading && _selectedImage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Gemini Generated Keywords:\n$_keywords",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              // Generate Button (Proceed)
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _selectedImage != null
                    ? () =>
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emotionSelectionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step 2/2',
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Select Emotion',
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Image.asset('assets/images/step_2.gif',height: 200, width: 300,),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _emotionButton('Happy', 'assets/images/happy.png', Colors.amber),
              const SizedBox(width: 15),
              _emotionButton('Angry', 'assets/images/angry.png', Colors.red),
              const SizedBox(width: 15),
              _emotionButton('Sad', 'assets/images/sad.png', Colors.blue),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              ElevatedButton(
                onPressed: _selectedEmotion != null ? _fetchPantunRecommendations : null,
                child: const Text('Generate Pantun'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Emotion Selection Button Widget (Uses Asset Images)
  Widget _emotionButton(String emotion, String assetPath, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmotion = emotion;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedEmotion == emotion
                  ? color.withOpacity(0.3)
                  : Colors.grey[200],
              // ✅ Light highlight instead of removing image
              border: Border.all(
                color: _selectedEmotion == emotion ? color : Colors.grey,
                width: 2,
              ),
            ),
            child: Image.asset(
              assetPath,
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            emotion,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _selectedEmotion == emotion ? color : Colors
                  .black, // ✅ Highlight text color if selected
            ),
          ),
        ],
      ),
    );
  }
}
