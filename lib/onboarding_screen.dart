import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:testing/result.dart'; // Assuming this is your result screen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  File? _selectedImage;
  String _keywords = 'Upload an image to see scene keywords.'; // Changed initial message
  String? _selectedEmotion;
  bool _isLoading = false;
  int _currentStep = 0;

  final ImagePicker _picker = ImagePicker();
  // IMPORTANT: Secure your API key in a production environment.
  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM';
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';
  // IMPORTANT: This is a local IP. For wider use, deploy your Flask API.
  final String flaskApiUrl = "http://172.20.10.6:5000/recommend";

  Set<String> joyKeywords = {};
  Set<String> sadnessKeywords = {};
  Set<String> angerKeywords = {};
  Set<String> allEmotionKeywords = {};

  // --- UI Theme Colors (Adjusted) ---
  static const LinearGradient maroonGradientBackground = LinearGradient(
    colors: [Color(0xFF8A1D37), Color(0xFFAB5D5D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Color goldText = Color(0xFFE6C68A);
  static const Color darkTealButton = Color(0xFF004D40);
  // Made lightGoldAccent slightly brighter for better contrast
  static const Color lightGoldAccent = Color(0xFFF5EAD0);
  // Adjusted card background for better content visibility
  static const Color cardBackgroundColor = Color(0x33000000); // Darker semi-transparent

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
    // Consider adding error handling for loading lexicons
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
        imageQuality: 80, // Optional: compress image slightly
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _keywords = 'Analyzing image...'; // User-friendly processing message
          _isLoading = true;
        });
        _uploadAndAnalyzeImage();
      }
    } catch (e) {
      setState(() {
        _keywords = "Could not select image. Please try again.";
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_keywords, style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: Colors.redAccent),
        );
      }
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
        final parts = result['candidates']?[0]['content']['parts'] as List<dynamic>? ?? [];

        List<String> extractedWords = parts
            .where((part) => part['text'] != null)
            .map((part) => part['text'].toString().toLowerCase().trim())
            .expand((text) => text.split(','))
            .map((word) => word.trim())
            .where((word) => allEmotionKeywords.contains(word))
            .toList()
            .take(7) // Take up to 7 valid keywords
            .toList();

        setState(() {
          _keywords = extractedWords.isNotEmpty
              ? extractedWords.join(", ")
              : "Could not extract specific keywords. Feel free to choose an emotion!"; // User-friendly message
          _isLoading = false;
        });
      } else {
        // User-friendly error message based on status code
        String errorMessage;
        if (response.statusCode == 429) {
          errorMessage = "Analysis service is busy. Please try again in a moment.";
        } else {
          errorMessage = "Sorry, image analysis failed (Error ${response.statusCode}). Please try again.";
        }
        setState(() {
          _keywords = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        // User-friendly generic error
        _keywords = 'Error analyzing image. Check connection or try another image.';
        _isLoading = false;
      });
    }
  }

 Future<void> _fetchPantunRecommendations() async {
    if (_selectedEmotion == null || _keywords.startsWith('Upload an image') || _keywords.contains('Analyzing image...') || _keywords.contains('Error') || _keywords.contains('Could not')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload an image and select an emotion first.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent, // Changed color for warning
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final imageKeywordsList = _keywords.split(', ').map((word) => word.trim()).where((word) => word.isNotEmpty).toList();
      
      // If keywords failed to extract, send an empty list or a placeholder.
      // Here, we are sending what we have, which might be an error message if analysis failed.
      // The backend should ideally handle cases where keywords are not as expected.
      // For now, we proceed, but this logic could be refined based on API requirements.

      var response = await http.post(
        Uri.parse(flaskApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emotion": _selectedEmotion,
          // Ensure keywords are only sent if they are actual keywords, not error messages.
          "image_keywords": imageKeywordsList.any((k) => k.contains(" ") || k.length > 15) && ( _keywords.contains("Error") || _keywords.contains("Could not") || _keywords.contains("Analyzing"))
            ? [] // Send empty if keywords are likely error/status messages
            : imageKeywordsList
        }),
      );

      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<Map<String, dynamic>> pantunResults = List<Map<String, dynamic>>.from(data['pantuns']);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(result: pantunResults),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Sorry, couldn't fetch recommendations (Server Error: ${response.statusCode}). Please try again.",
                style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch pantun. Check your connection or try again.",
              style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: maroonGradientBackground),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 5.0), // Adjusted padding
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: goldText.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(goldText),
                  minHeight: 6, // Slightly thicker progress bar
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                physics: const ClampingScrollPhysics(), // Good choice
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

  Widget _styledCard({required Widget child}) {
    return Card(
      elevation: 3, // Slightly reduced elevation
      color: cardBackgroundColor, // Using the new card background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Slightly smaller radius
        side: BorderSide(color: goldText.withOpacity(0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Adjusted padding
        child: child,
      ),
    );
  }

  Widget _imageInputScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Adjusted padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 80),
          Text(
            'Step 1: Upload Scenery', // Shortened title
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28, // Reduced font size
              fontWeight: FontWeight.w600, // Added weight
              color: goldText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a scenery image that resonates with you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: lightGoldAccent,
            ),
          ),
          const SizedBox(height: 35), // Increased spacing
          GestureDetector(
            onTap: () => _pickImage(fromCamera: false), // Add option for camera later if needed
            child: Container(
              width: double.infinity, // Make it wider
              constraints: const BoxConstraints(maxWidth: 250, maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: goldText.withOpacity(0.7), width: 2),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.landscape_outlined,
                          size: 50, // Slightly smaller icon
                          color: goldText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to Upload Scenery',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: goldText,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 25), // Increased spacing
          /*
          // Conditional display for loading or keywords
          if (_isLoading && _selectedImage != null && _keywords.contains('Analyzing'))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(goldText),
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    _keywords, // "Analyzing image..."
                    style: GoogleFonts.poppins(color: lightGoldAccent, fontSize: 15),
                  )
                ],
              ),
            )
          else if (_selectedImage != null) // Show keywords or error message from analysis
            _styledCard(
              child: Text(
                "Scene Keywords: $_keywords",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: lightGoldAccent, // Text color for inside the card
                  height: 1.4, // Improved line spacing
                ),
              ),
            )
          else // Default message if no image is selected yet
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                _keywords, // "Upload an image to see scene keywords."
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: lightGoldAccent.withOpacity(0.8), fontSize: 15),
              ),
            ),
          */
          const SizedBox(height: 35), // Increased spacing
          ElevatedButton(
            onPressed: _selectedImage != null && !_isLoading && !_keywords.contains('Analyzing') && !_keywords.contains('Error') && !_keywords.contains('Could not')
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    )
                : null, // Disabled if no image, loading, or error in keywords
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTealButton,
              foregroundColor: goldText,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16), // Adjusted padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: const Text('Next Step'),
          ),
          const SizedBox(height: 20), // Increased spacing
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Back to Home',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: goldText,
                decoration: TextDecoration.underline,
                decorationColor: goldText.withOpacity(0.8),
                decorationThickness: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  Widget _emotionSelectionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Adjusted padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Text(
            'Step 2: Choose Emotion', // Shortened title
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28, // Reduced font size
              fontWeight: FontWeight.w600, // Added weight
              color: goldText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How are you feeling right now?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: lightGoldAccent,
            ),
          ),
          const SizedBox(height: 70), // Increased spacing
          Wrap(
            spacing: 18.0, // Adjusted spacing
            runSpacing: 18.0, // Adjusted spacing
            alignment: WrapAlignment.center,
            children: [
              // Ensure you have these assets in assets/images/ and declared in pubspec.yaml
              _emotionButton('Happy', 'assets/images/happy.png'),
              _emotionButton('Angry', 'assets/images/angry.png'),
              _emotionButton('Sad', 'assets/images/sad.png'),
            ],
          ),
          const SizedBox(height: 70), // Increased spacing
          ElevatedButton(
            onPressed: _selectedEmotion != null && !_isLoading ? _fetchPantunRecommendations : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTealButton,
              foregroundColor: goldText,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16), // Adjusted padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: _isLoading && _selectedEmotion != null // Show loader only if this button initiated loading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(goldText)))
                : const Text('Generate Pantun'),
          ),
          const SizedBox(height: 25), // Increased spacing
          TextButton(
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
            child: Text(
              'Go Back',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: goldText,
                decoration: TextDecoration.underline,
                decorationColor: goldText.withOpacity(0.8),
                decorationThickness: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  Widget _emotionButton(String emotion, String assetPath) {
    final bool isSelected = _selectedEmotion == emotion;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmotion = emotion;
        });
      },
      child: Container(
        width: 100, // Keep width
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10), // Adjusted padding
        decoration: BoxDecoration(
          color: isSelected ? darkTealButton.withOpacity(0.85) : Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          border: Border.all(
            color: isSelected ? goldText : goldText.withOpacity(0.5),
            width: isSelected ? 2.2 : 1.5, // Adjusted border width
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: darkTealButton.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow( // Subtle shadow for unselected too
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
              ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 40, // Slightly smaller icon
              height: 40, // Slightly smaller icon
              errorBuilder: (context, error, stackTrace) => Icon( // Fallback icon
                Icons.sentiment_neutral, size: 40, color: isSelected ? Colors.white : goldText,
              ),
            ),
            const SizedBox(height: 8), // Adjusted spacing
            Text(
              emotion,
              style: GoogleFonts.poppins(
                fontSize: 14, // Slightly smaller font
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : goldText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}