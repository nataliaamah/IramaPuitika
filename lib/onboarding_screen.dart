import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Import for Timer
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
  String _keywords = 'Upload an image to see scene keywords.';
  String? _selectedEmotion;
  bool _isLoading = false;
  int _currentStep = 0;
  bool _isScenery = false;

  String? _loadingMessage1; // For the first timed message
  String? _loadingMessage2; // For the second timed message
  String? _loadingMessage3; // For the third timed message
  Timer? _loadingTimer1;
  Timer? _loadingTimer2;
  Timer? _loadingTimer3;

  final ImagePicker _picker = ImagePicker();
  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM'; // IMPORTANT: Secure your API key
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-04-17:generateContent';
  final String flaskApiUrl = "https://context-based-pantun-rec-service-360024071473.asia-southeast1.run.app/recommend"; //

  // Specific error message string for scenery validation
  final String _invalidSceneryErrorMessage = "Error: Image is not a valid scenery. Please upload an image of grasslands, aquatic biomes, or forest biomes.";

  Set<String> joyKeywords = {};
  Set<String> sadnessKeywords = {};
  Set<String> angerKeywords = {};
  Set<String> allEmotionKeywords = {};

  static const LinearGradient maroonGradientBackground = LinearGradient(
    colors: [Color(0xFF8A1D37), Color(0xFFAB5D5D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Color goldText = Color(0xFFE6C68A);
  static const Color darkTealButton = Color(0xFF004D40);
  static const Color lightGoldAccent = Color(0xFFF5EAD0);

  @override
  void initState() {
    super.initState();
    loadAllLexicons();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loadingTimer1?.cancel();
    _loadingTimer2?.cancel();
    _loadingTimer3?.cancel(); // Cancel the third timer
    super.dispose();
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
    try {
      joyKeywords =
          await loadEmotionKeywords("assets/txt/joy-NRC-Emotion-Lexicon.txt");
      sadnessKeywords = await loadEmotionKeywords(
          "assets/txt/sadness-NRC-Emotion-Lexicon.txt");
      angerKeywords =
          await loadEmotionKeywords("assets/txt/anger-NRC-Emotion-Lexicon.txt");

      allEmotionKeywords =
          joyKeywords.union(sadnessKeywords).union(angerKeywords);
    } catch (e) {
      // Handle lexicon loading errors if necessary
      print("Error loading lexicons: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading keyword data. Some features might not work.', style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _setLoading(bool isLoading) {
    if (!mounted) return;

    setState(() {
      _isLoading = isLoading;
      if (isLoading) {
        _loadingMessage1 = null;
        _loadingMessage2 = null;
        _loadingMessage3 = null; // Reset third message
        _loadingTimer1?.cancel();
        _loadingTimer2?.cancel();
        _loadingTimer3?.cancel(); // Cancel third timer

        _loadingTimer1 = Timer(const Duration(seconds: 6), () {
          if (mounted && _isLoading) {
            setState(() {
              _loadingMessage1 = "Just a moment...";
              _loadingMessage2 = null;
              _loadingMessage3 = null;
            });
            _loadingTimer2 = Timer(const Duration(seconds: 6), () {
              if (mounted && _isLoading) {
                setState(() {
                  _loadingMessage1 = null;
                  _loadingMessage2 = "Almost there...";
                  _loadingMessage3 = null;
                });
                _loadingTimer3 = Timer(const Duration(seconds: 7), () {
                  if (mounted && _isLoading) {
                    setState(() {
                      _loadingMessage1 = null;
                      _loadingMessage2 = null;
                      _loadingMessage3 = "Finalizing..."; // Set third message
                    });
                  }
                });
              }
            });
          }
        });
      } else {
        _loadingTimer1?.cancel();
        _loadingTimer2?.cancel();
        _loadingTimer3?.cancel(); // Cancel third timer
        _loadingMessage1 = null;
        _loadingMessage2 = null;
        _loadingMessage3 = null; // Reset third message
      }
    });
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _keywords = 'Analyzing image...';
          _isScenery = false; // Reset scenery status
        });
        _setLoading(true);
        await _uploadAndAnalyzeImage(); // await here to ensure loading state is accurate
      }
    } catch (e) {
      setState(() {
        _keywords = "Could not select image. Please try again.";
      });
      _setLoading(false);
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
    // Ensure _isLoading is true at the start of this async operation
    if (!mounted || _selectedImage == null) {
      if (_selectedImage == null) {
         setState(() {
          _keywords = 'No image selected.';
        });
      }
      _setLoading(false);
      return;
    }

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "You are an AI image analysis assistant for a Pantun Recommender System. Your task is to analyze an uploaded image and extract 5-7 keywords. These keywords must describe both its visual elements and emotional tone, drawing exclusively from the provided emotional lexicons.\n\n**Primary Task & Image Validation:**\n1. **Scenery Check:** Evaluate if the uploaded image is predominantly a scenery or landscape image.\n   - **Acceptable:** Images focused on natural environments such as grasslands, aquatic biomes (oceans, rivers, lakes), and forest biomes. The presence of people, animals, or objects is acceptable if they are part of the broader scene.\n   - **Not Acceptable:** Images focused on tundra, desert biomes, selfies, isolated portraits, close-ups of single objects, abstract patterns, or screenshots.\n2. If the image is NOT a valid scenery image, respond ONLY with: \"$_invalidSceneryErrorMessage\"\n\n**Keyword Extraction (Only for Valid Scenery Images):**\n1. Extract exactly 5-7 keywords.\n2. Use ONLY words from the provided emotional lexicons (Joy, Sadness, Anger).\n3. Interpret visual elements and emotional tone using the lexicons. For example:\n   - A dark, stormy sky → 'Angry', 'Furious', 'Miserable'.\n   - A sunny field → 'Happy', 'Joy', 'Content'.\n4. Select the closest emotional association if no direct match exists.\n5. Ensure the keywords reflect the dominant visual characteristics and emotional tone.\n\n**Lexicons (Strictly Adhere to These):**\n- **Joy:** Happy, Content, Joy, Grateful, Blessed, Smile, Fun, Excited, Laughter, Proud\n- **Sadness:** Lonely, Broken, Disappointed, Depressed, Hurt, Frustrated, Crying, Miserable, Hopeless, Regret\n- **Anger:** Angry, Annoying, Hate, Frustrated, Furious, Outrage, Offensive, Cursing, Idiotic, Condemn\n\n**Output Format:**\n- Provide the final list of keywords as a single, comma-separated string.\n- Example for a stormy sea: `Angry, Furious, Miserable, Hopeless, Frustrated`\n- Example for a sunny meadow: `Happy, Content, Joy, Smile, Grateful`\n\n**Final Check:**\n- Is the image confirmed to be a valid scenery image (grasslands, aquatic biomes, or forest biomes)?\n- Are ALL selected words ONLY from the provided lexicons?\n- Is the total number of keywords between 5 and 7?\n- Is the output a comma-separated list?"
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

      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final parts = result['candidates']?[0]['content']['parts'] as List<dynamic>? ?? [];
        String aiResponseText = "";
        if (parts.isNotEmpty && parts[0]['text'] != null) {
          aiResponseText = parts[0]['text'].toString().trim();
          print("AI Response Text: '$aiResponseText'");
        }

        if (aiResponseText == _invalidSceneryErrorMessage) {
          setState(() {
            _keywords = _invalidSceneryErrorMessage;
            _isScenery = false;
          });
        } else {
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
                : "Could not extract specific keywords. Feel free to choose an emotion!";
            _isScenery = extractedWords.isNotEmpty; // Be more precise: scenery if keywords found
          });
        }
      } else {
        setState(() {
          _keywords = "Sorry, image analysis failed (Error ${response.statusCode}). Please try again.";
          _isScenery = false;
        });
      }
    } catch (e) {
      setState(() {
        _keywords = 'Error analyzing image. Check connection or try another image.';
        _isScenery = false;
      });
    } finally {
      if (mounted) {
        _setLoading(false);
      }
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

    _setLoading(true);
    try {
      final imageKeywordsList = _keywords.split(', ').map((word) => word.trim()).where((word) => word.isNotEmpty).toList();
      
      var response = await http.post(
        Uri.parse(flaskApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emotion": _selectedEmotion,
          "image_keywords": (_keywords == _invalidSceneryErrorMessage || _keywords.startsWith("Could not extract specific keywords") || _keywords.contains("Analyzing") || _keywords.startsWith("Upload an image"))
            ? [] 
            : imageKeywordsList
        }),
      );

      if (mounted) { // Check mounted before further setState or navigation
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          List<Map<String, dynamic>> pantunResults = List<Map<String, dynamic>>.from(data['pantuns']);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(result: pantunResults),
            ),
          );
        } else {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch pantun. Check your connection or try again.",
              style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  String _getLoadingOverlayText() {
    String baseText;
    if (_keywords == 'Analyzing image...' && _currentStep == 0) {
      baseText = 'Analyzing Image...';
    } else if (_selectedEmotion != null && _currentStep == 1) {
      baseText = 'Generating Pantun...';
    } else {
      baseText = 'Loading...'; // Fallback
    }

    String finalText = baseText;
    if (_loadingMessage3 != null) {
      finalText += '\n$_loadingMessage3';
    } else if (_loadingMessage2 != null) {
      finalText += '\n$_loadingMessage2';
    } else if (_loadingMessage1 != null) {
      finalText += '\n$_loadingMessage1';
    }
    return finalText;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define some responsive scaling factors or direct calculations
    final double titleFontSize = screenWidth * 0.07;
    final double subtitleFontSize = screenWidth * 0.04;
    final double bodyFontSize = screenWidth * 0.035;
    final double buttonTextFontSize = screenWidth * 0.045;
    final double smallTextFontSize = screenWidth * 0.032;

    // Determine if swiping from step 1 to step 2 should be allowed
    bool canProceedFromStep1 = _selectedImage != null && !_isLoading && _isScenery;
    ScrollPhysics pageViewPhysics = const ClampingScrollPhysics(); // Default physics

    if (_currentStep == 0 && !canProceedFromStep1) {
      pageViewPhysics = const NeverScrollableScrollPhysics();
    } else if (_currentStep == 1 && _isLoading) { // Also prevent swiping back from step 2 if loading
      pageViewPhysics = const NeverScrollableScrollPhysics();
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: maroonGradientBackground),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: screenHeight * 0.02,
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: (_currentStep + 1) / 2,
                          backgroundColor: goldText.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(goldText),
                          minHeight: screenHeight * 0.008,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.008, bottom: screenHeight * 0.005),
                          child: Text(
                            // Restored full text for clarity
                            _currentStep == 0 ? "Step 1 of 2" : "Step 2 of 2",
                            style: GoogleFonts.poppins(
                                color: lightGoldAccent.withOpacity(0.9),
                                fontSize: smallTextFontSize),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                        // Recalculate physics when page changes, though primary control is on build
                      });
                    },
                    physics: pageViewPhysics, // Apply dynamic physics here
                    children: [
                      _imageInputScreen(screenWidth, screenHeight, titleFontSize, subtitleFontSize, bodyFontSize, buttonTextFontSize, smallTextFontSize),
                      _emotionSelectionScreen(screenWidth, screenHeight, titleFontSize, subtitleFontSize, buttonTextFontSize, smallTextFontSize),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(goldText)),
                      SizedBox(height: screenHeight * 0.025),
                      Text(
                        _getLoadingOverlayText(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: goldText,
                            fontSize: subtitleFontSize * 1.05, // Slightly larger than subtitle
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imageInputScreen(double screenWidth, double screenHeight, double titleFs, double subtitleFs, double bodyFs, double buttonFs, double smallFs) {
    bool showSceneryError = !_isScenery && _keywords == _invalidSceneryErrorMessage && _selectedImage != null;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.02),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.05), // Adjusted
          Text(
            'Step 1: Upload Scenery',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: titleFs,
              fontWeight: FontWeight.w600,
              color: goldText,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'Choose a scenery image that resonates with you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: subtitleFs,
              color: lightGoldAccent,
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          GestureDetector(
            onTap: _isLoading ? null : () => _pickImage(fromCamera: false),
            child: Container(
              width: screenWidth * 0.7, // Responsive width
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.7, // Max width based on screen
                minHeight: screenHeight * 0.22, // Min height based on screen
                maxHeight: screenHeight * 0.25, // Max height based on screen
              ),
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
                          size: screenWidth * 0.12, // Responsive icon size
                          color: goldText,
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          'Tap to Upload Scenery',
                          style: GoogleFonts.poppins(
                            fontSize: subtitleFs * 0.9, // Slightly smaller subtitle
                            color: goldText,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          if (showSceneryError)
            Container(
              margin: EdgeInsets.only(top: 0, bottom: screenHeight * 0.01),
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012, horizontal: screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1),
              ),
              child: Text(
                _keywords,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.red.shade300, fontSize: bodyFs * 0.95, fontWeight: FontWeight.w500),
              ),
            )
          else if (_selectedImage != null && !_isLoading && _keywords != 'Analyzing image...' && _keywords != _invalidSceneryErrorMessage && !_keywords.startsWith("Upload an image"))
             Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
              child: Text(
                "Keywords: $_keywords",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: lightGoldAccent, fontSize: bodyFs),
              ),
            ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: _selectedImage != null && !_isLoading && _isScenery
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTealButton,
              foregroundColor: goldText,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.018),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: GoogleFonts.poppins(fontSize: buttonFs, fontWeight: FontWeight.w600),
            ),
            child: const Text('Next Step'),
          ),
          SizedBox(height: screenHeight * 0.02),
          TextButton(
            onPressed: _isLoading ? null : () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Back to Home',
              style: GoogleFonts.poppins(
                fontSize: subtitleFs * 0.9,
                color: _isLoading ? goldText.withOpacity(0.5) : goldText,
                decoration: TextDecoration.underline,
                decorationColor: goldText.withOpacity(0.8),
                decorationThickness: 1.5,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Widget _emotionSelectionScreen(double screenWidth, double screenHeight, double titleFs, double subtitleFs, double buttonFs, double smallFs) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.02),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight * 0.08),
          Text(
            'Step 2: Choose Emotion',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: titleFs,
              fontWeight: FontWeight.w600,
              color: goldText,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'How are you feeling right now?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: subtitleFs,
              color: lightGoldAccent,
            ),
          ),
          SizedBox(height: screenHeight * 0.07),
          Wrap(
            spacing: screenWidth * 0.04, // Responsive spacing
            runSpacing: screenHeight * 0.02, // Responsive runSpacing
            alignment: WrapAlignment.center,
            children: [
              _emotionButton('Happy', 'assets/images/happy.png', screenWidth, screenHeight, subtitleFs * 0.85),
              _emotionButton('Angry', 'assets/images/angry.png', screenWidth, screenHeight, subtitleFs * 0.85),
              _emotionButton('Sad', 'assets/images/sad.png', screenWidth, screenHeight, subtitleFs * 0.85),
            ],
          ),
          SizedBox(height: screenHeight * 0.07),
          ElevatedButton(
            onPressed: _selectedEmotion != null && !_isLoading ? _fetchPantunRecommendations : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTealButton,
              foregroundColor: goldText,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.018),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: GoogleFonts.poppins(fontSize: buttonFs, fontWeight: FontWeight.w600),
            ),
            child: const Text('Generate Pantun'),
          ),
          SizedBox(height: screenHeight * 0.025),
          TextButton(
            onPressed: _isLoading ? null : () => _pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
            child: Text(
              'Go Back',
              style: GoogleFonts.poppins(
                fontSize: subtitleFs * 0.9,
                color: _isLoading ? goldText.withOpacity(0.5) : goldText,
                decoration: TextDecoration.underline,
                decorationColor: goldText.withOpacity(0.8),
                decorationThickness: 1.5,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Widget _emotionButton(String emotion, String assetPath, double screenWidth, double screenHeight, double textFs) {
    final bool isSelected = _selectedEmotion == emotion;
    final double buttonSize = screenWidth * 0.25; // Responsive button width/height base

    return GestureDetector(
      onTap: _isLoading ? null : () {
        setState(() {
          _selectedEmotion = emotion;
        });
      },
      child: Opacity(
        opacity: _isLoading ? 0.6 : 1.0,
        child: Container(
          width: buttonSize, // Make width responsive
          // height: buttonSize * 1.2, // Optionally make height responsive, or let padding define it
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03, horizontal: screenWidth * 0.03), // Responsive padding
          decoration: BoxDecoration(
            color: isSelected ? darkTealButton.withOpacity(0.85) : Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? goldText : goldText.withOpacity(0.5),
              width: isSelected ? 2.2 : 1.5,
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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // Center content
            children: [
              Image.asset(
                assetPath,
                width: buttonSize * 0.5, // Responsive image size
                height: buttonSize * 0.5, // Responsive image size
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.sentiment_neutral, size: buttonSize * 0.5, color: isSelected ? Colors.white : goldText,
                ),
              ),
              SizedBox(height: screenHeight * 0.01), // Responsive spacing
              Text(
                emotion,
                style: GoogleFonts.poppins(
                  fontSize: textFs, // Responsive text
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : goldText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}