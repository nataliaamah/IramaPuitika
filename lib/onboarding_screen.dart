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
  bool _isScenery = false; // Add this flag to track if the image is a scenery

  final ImagePicker _picker = ImagePicker();
  // IMPORTANT: Secure your API key in a production environment.
  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM';
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-exp-03-25:generateContent';
  // IMPORTANT: This is a local IP. For wider use, deploy your Flask API.
  final String flaskApiUrl = "http://192.168.132.34:5000/recommend";

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
                "text": "You are an AI image analysis assistant for a Pantun Recommender System. Your task is to analyze an uploaded image and extract 5-7 keywords. These keywords must describe both its visual elements and emotional tone, drawing exclusively from the provided emotional lexicons.\n\n**Primary Task & Image Validation:**\n1. **Scenery Check:** Evaluate if the uploaded image is predominantly a scenery or landscape image.\n   - **Acceptable:** Images focused on natural environments such as grasslands, aquatic biomes (oceans, rivers, lakes), and forest biomes. The presence of people, animals, or objects is acceptable if they are part of the broader scene.\n   - **Not Acceptable:** Images focused on tundra, desert biomes, selfies, isolated portraits, close-ups of single objects, abstract patterns, or screenshots.\n2. If the image is NOT a valid scenery image, respond ONLY with: \"Error: Image is not a valid scenery. Please upload an image of grasslands, aquatic biomes, or forest biomes.\"\n\n**Keyword Extraction (Only for Valid Scenery Images):**\n1. Extract exactly 5-7 keywords.\n2. Use ONLY words from the provided emotional lexicons (Joy, Sadness, Anger).\n3. Interpret visual elements and emotional tone using the lexicons. For example:\n   - A dark, stormy sky → 'Angry', 'Furious', 'Miserable'.\n   - A sunny field → 'Happy', 'Joy', 'Content'.\n4. Select the closest emotional association if no direct match exists.\n5. Ensure the keywords reflect the dominant visual characteristics and emotional tone.\n\n**Lexicons (Strictly Adhere to These):**\n- **Joy:** Happy, Content, Joy, Grateful, Blessed, Smile, Fun, Excited, Laughter, Proud\n- **Sadness:** Lonely, Broken, Disappointed, Depressed, Hurt, Frustrated, Crying, Miserable, Hopeless, Regret\n- **Anger:** Angry, Annoying, Hate, Frustrated, Furious, Outrage, Offensive, Cursing, Idiotic, Condemn\n\n**Output Format:**\n- Provide the final list of keywords as a single, comma-separated string.\n- Example for a stormy sea: `Angry, Furious, Miserable, Hopeless, Frustrated`\n- Example for a sunny meadow: `Happy, Content, Joy, Smile, Grateful`\n\n**Final Check:**\n- Is the image confirmed to be a valid scenery image (grasslands, aquatic biomes, or forest biomes)?\n- Are ALL selected words ONLY from the provided lexicons?\n- Is the total number of keywords between 5 and 7?\n- Is the output a comma-separated list?"
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
          "maxOutputTokens": 10000,
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

        if (parts.isNotEmpty && parts[0]['text'] != null) {
          print("AI Response Text: '${parts[0]['text'].toString()}'"); // Log the raw response
        }

        // Ensure this string EXACTLY matches the error message in your AI prompt
        final String expectedErrorMessage = "Error: Image is not a valid scenery. Please upload an image of grasslands, aquatic biomes, or forest biomes.";

        // Trim the AI's response text before comparing
        if (parts.isNotEmpty && parts[0]['text'] != null && parts[0]['text'].toString().trim() == expectedErrorMessage) {
          setState(() {
            _keywords = expectedErrorMessage; // Use the same expected message
            _isScenery = false; // Mark as not a scenery
            _isLoading = false;
          });
        } else {
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
                : "Could not extract specific keywords. Feel free to choose an emotion!";
            _isScenery = true; // Mark as valid scenery
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _keywords = "Sorry, image analysis failed (Error ${response.statusCode}). Please try again.";
          _isScenery = false; // Mark as not a scenery
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _keywords = 'Error analyzing image. Check connection or try another image.';
        _isScenery = false; // Mark as not a scenery
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPantunRecommendations() async {
    String? errorMessage;
    if (_selectedEmotion == null && !_isScenery) {
      errorMessage = 'Please upload a valid scenery image and select an emotion.';
    } else if (_selectedEmotion == null) {
      errorMessage = 'Please select an emotion first.';
    } else if (!_isScenery) {
      errorMessage = 'Please upload a valid scenery image. The previous image was not suitable or analysis failed.';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Additional check for keywords still in initial or analyzing state,
    // though !_isScenery should cover most non-ready states.
    if (_keywords.startsWith('Upload an image') || _keywords.contains('Analyzing image...')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image analysis may not be complete or no image was processed successfully.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imageKeywordsList = _keywords.split(', ').map((word) => word.trim()).where((word) => word.isNotEmpty).toList();
      
      var response = await http.post(
        Uri.parse(flaskApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emotion": _selectedEmotion,
          "image_keywords": (_keywords.contains("Error") || _keywords.startsWith("Could not extract specific keywords") || _keywords.contains("Analyzing") || _keywords.startsWith("Upload an image"))
            ? [] // Send empty if keywords are error/status messages or not extracted
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
          SizedBox(height: 60),
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
          if (!_isScenery && _keywords.contains("Error")) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                _keywords, // Display the error message
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 15),
              ),
            ),
          const SizedBox(height: 35), // Increased spacing
          ElevatedButton(
            onPressed: _selectedImage != null && !_isLoading && _isScenery
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    )
                : null, // Disabled if no image, loading, or not a scenery
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
          SizedBox(height: 80),
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
        width: 80, // Keep width
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 5), // Adjusted padding
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