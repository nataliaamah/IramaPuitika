import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:testing/result.dart';
import 'package:testing/home_page.dart'; // Add this import at the top

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  // Controllers & Animation
  final PageController _pageController = PageController();
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  Animation<double>? _backgroundAnimation;
  Animation<double>? _pulseAnimation;

  // State
  File? _selectedImage;
  String _keywords = 'Upload an image to see scene keywords.';
  String? _selectedEmotion;
  bool _isLoading = false;
  int _currentStep = 0;
  bool _isScenery = false;
  bool _showEmotionPopup = false; // <-- New field
  String? _loadingTask; // <-- Add this line

  // Loading messages
  String? _loadingMessage1, _loadingMessage2, _loadingMessage3;
  Timer? _loadingTimer1, _loadingTimer2, _loadingTimer3;

  // API & Lexicon
  final ImagePicker _picker = ImagePicker();
  final String apiKey = 'AIzaSyA73OQQiAiiUH5j99t60f23dBPECr2jUWk';
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-04-17:generateContent';
  final String flaskApiUrl = "https://iramapuitika-v2-360024071473.asia-southeast1.run.app/recommend";
  final String _invalidSceneryErrorMessage =
      "Error: Image is not a valid scenery. Please upload an image of grasslands, aquatic biomes, or forest biomes.";

  Set<String> joyKeywords = {};
  Set<String> sadnessKeywords = {};
  Set<String> angerKeywords = {};
  Set<String> allEmotionKeywords = {};

  // Color Scheme
  static const Color primaryBackground = Color.fromARGB(255, 76, 123, 101);
  static const Color goldText = Color(0xFFEAD7A6);
  static const Color darkTealButton = Color(0xFF003E4C);
  static const Color lightGoldAccent = Color(0xFFF5EAD0);
  static const Color cardBackground = Color.fromARGB(255, 38, 74, 70);
  static const Color overlayBackground = Color(0xFF1E3A2E);

  @override
  void initState() {
    super.initState();
    loadAllLexicons();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: -0.002, end: 0.002).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    _loadingTimer1?.cancel();
    _loadingTimer2?.cancel();
    _loadingTimer3?.cancel();
    super.dispose();
  }

  // --- Lexicon Loading ---
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
      joyKeywords = await loadEmotionKeywords("assets/txt/joy-NRC-Emotion-Lexicon.txt");
      sadnessKeywords = await loadEmotionKeywords("assets/txt/sadness-NRC-Emotion-Lexicon.txt");
      angerKeywords = await loadEmotionKeywords("assets/txt/anger-NRC-Emotion-Lexicon.txt");
      allEmotionKeywords = joyKeywords.union(sadnessKeywords).union(angerKeywords);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading keyword data. Some features might not work.',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- Loading Overlay ---
  // Modify _setLoading to accept an optional task string
  void _setLoading(bool isLoading, {String? task}) {
    if (!mounted) return;
    setState(() {
      _isLoading = isLoading;
      _loadingTask = task; // <-- Update the loading task
      if (isLoading) {
        _loadingMessage1 = _loadingMessage2 = _loadingMessage3 = null;
        _loadingTimer1?.cancel();
        _loadingTimer2?.cancel();
        _loadingTimer3?.cancel();
        // Adjust timer durations if needed for different tasks
        _loadingTimer1 = Timer(const Duration(seconds: 6), () {
          if (mounted && _isLoading) {
            setState(() {
              _loadingMessage1 = "Just a moment...";
              _loadingMessage2 = _loadingMessage3 = null;
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
                      _loadingMessage1 = _loadingMessage2 = null;
                      _loadingMessage3 = "Finalizing...";
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
        _loadingTimer3?.cancel();
        _loadingMessage1 = _loadingMessage2 = _loadingMessage3 = null;
        _loadingTask = null; // <-- Clear task when loading stops
      }
    });
  }

  // --- Image Picker & Analysis ---
  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _keywords = 'Analyzing image...'; // Keep this initial text
          _isScenery = false;
        });
        _setLoading(true, task: 'image'); // <-- Set task to 'image'
        await _uploadAndAnalyzeImage();
      }
    } catch (e) {
      setState(() {
        _keywords = "Could not select image. Please try again.";
      });
      _setLoading(false); // <-- Clear task on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_keywords, style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndAnalyzeImage() async {
    if (!mounted || _selectedImage == null) {
      if (_selectedImage == null) {
        setState(() {
          _keywords = 'No image selected.';
        });
      }
      _setLoading(false); // <-- Clear task on early exit
      return;
    }
    if (_selectedEmotion == null) {
      setState(() {
        _keywords = 'Please select an emotion before uploading an image.';
      });
      _setLoading(false); // <-- Clear task on early exit
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_keywords, style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }
    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final String promptText = """
You are an AI image analysis assistant for a Pantun Recommender System. Your task is to analyze an uploaded image and extract 5-7 keywords. These keywords must describe both its visual elements and emotional tone, drawing exclusively from the provided emotional lexicons, but *constrained by a user-selected emotion*.

**Primary Task & Image Validation:**
1.  **Scenery Check:** Evaluate if the uploaded image is predominantly a scenery or landscape image.
    *   **Acceptable:** Images focused on natural environments such as grasslands, aquatic biomes (oceans, rivers, lakes), and forest biomes. The presence of people, animals, or objects is acceptable if they are part of the broader scene.
    *   **Not Acceptable:** Images focused on tundra, desert biomes, selfies, isolated portraits, close-ups of single objects, abstract patterns, or screenshots.
2.  If the image is NOT a valid scenery image, respond ONLY with: "$_invalidSceneryErrorMessage"

**Keyword Extraction (Only for Valid Scenery Images):**
1.  Analyze the visual elements and the overall emotional tone evoked by the image.
2.  Based on the user's selected emotion ('$_selectedEmotion'), identify which lexicon(s) are allowed for keyword selection:
    *   If the selected emotion is 'Happy', use ONLY keywords from the 'Joy' lexicon.
    *   If the selected emotion is 'Sad' or 'Angry', use keywords from the 'Sadness' and 'Anger' lexicons.
3.  Select exactly 5-7 keywords from the *allowed lexicon(s)* (identified in step 2) that best describe the image's visual elements and the tone you perceived in step 1. Choose the closest emotional association available in the allowed lexicon(s) if a direct match isn't present.
4.  Ensure the selected keywords strictly adhere to the words listed in the relevant lexicon(s).

**Lexicons (Strictly Adhere to These):**
-   **Joy:** Happy, Content, Joy, Grateful, Blessed, Smile, Fun, Excited, Laughter, Proud
-   **Sadness:** Lonely, Broken, Disappointed, Depressed, Hurt, Frustrated, Crying, Miserable, Hopeless, Regret
-   **Anger:** Angry, Annoying, Hate, Frustrated, Furious, Outrage, Offensive, Cursing, Idiotic, Condemn

**Output Format:**
-   Provide the final list of keywords as a single, comma-separated string.
-   Example for a sunny meadow with user emotion 'Happy': `Happy, Content, Joy, Smile, Grateful`
-   Example for a stormy sea with user emotion 'Sad' or 'Angry': `Angry, Furious, Miserable, Hopeless, Frustrated`

**Final Check:**
-   Is the image confirmed to be a valid scenery image (grasslands, aquatic biomes, or forest biomes)?
-   Are ALL selected words ONLY from the provided lexicons *as constrained by the user's selected emotion*?
-   Is the total number of keywords between 5 and 7?
-   Is the output a comma-separated list?
""";

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": promptText},
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
        String aiResponseText = "";
        if (parts.isNotEmpty && parts[0]['text'] != null) {
          aiResponseText = parts[0]['text'].toString().trim();
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
              .where((word) {
                if (_selectedEmotion == 'Happy') {
                  return joyKeywords.contains(word);
                } else if (_selectedEmotion == 'Sad' || _selectedEmotion == 'Angry') {
                  return sadnessKeywords.contains(word) || angerKeywords.contains(word);
                }
                return false;
              })
              .toList()
              .take(7)
              .toList();

          setState(() {
            _keywords = extractedWords.isNotEmpty
                ? extractedWords.join(", ")
                : "Could not extract specific keywords for the selected emotion. Feel free to choose an emotion!";
            _isScenery = (aiResponseText != _invalidSceneryErrorMessage);
          });

          if (extractedWords.isNotEmpty) {
            _isScenery = true;
          }
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
      if (mounted) _setLoading(false); // <-- Clear task in finally block
    }
  }

  // --- Pantun Recommendation ---
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
          content: Text(errorMessage, style: GoogleFonts.poppins(color: Colors.white)),
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

    _setLoading(true, task: 'pantun'); // <-- Set task to 'pantun'
    try {
      final imageKeywordsList = _keywords.split(', ').map((word) => word.trim()).where((word) => word.isNotEmpty).toList();

      var response = await http.post(
        Uri.parse(flaskApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emotion": _selectedEmotion,
          "image_keywords": (_keywords == _invalidSceneryErrorMessage ||
                  _keywords.startsWith("Could not extract specific keywords") ||
                  _keywords.contains("Analyzing") ||
                  _keywords.startsWith("Upload an image"))
              ? []
              : imageKeywordsList
        }),
      );

      if (mounted) {
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
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch pantun. Check your connection or try again.",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) _setLoading(false); // <-- Clear task in finally block
    }
  }

  // --- UI Helpers ---
  String _getLoadingOverlayText() {
    String baseText;
    // Use _loadingTask to determine the base text
    if (_loadingTask == 'image') {
      baseText = 'Analyzing Image...';
    } else if (_loadingTask == 'pantun') {
      baseText = 'Recommending Pantun...';
    } else {
      baseText = 'Loading...'; // Default or initial state
    }

    if (_loadingMessage3 != null) return '$baseText\n$_loadingMessage3';
    if (_loadingMessage2 != null) return '$baseText\n$_loadingMessage2';
    if (_loadingMessage1 != null) return '$baseText\n$_loadingMessage1';
    return baseText;
  }

  Widget _buildStyledButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required double screenWidth,
    required double screenHeight,
  }) {
    final Color buttonColor = darkTealButton;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: isPrimary ? buttonColor : Colors.transparent,
        border: isPrimary
            ? null
            : Border.all(color: goldText.withOpacity(0.7), width: 1.5),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: goldText,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.018,
            horizontal: screenWidth * 0.12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: goldText,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
    );
  }

  Color _emotionAccentColor(String emotion) {
  switch (emotion) {
    case 'Happy':
      return const Color.fromARGB(255, 218, 165, 32); // Warm golden yellow
    case 'Angry':
      return const Color.fromARGB(255, 205, 92, 92); // Softer coral-red
    case 'Sad':
      return const Color.fromARGB(255, 95, 158, 160); // Muted teal-blue
    default:
      return goldText;
  }
}

Color _emotionBorderColor(String emotion) {
  switch (emotion) {
    case 'Happy':
      return const Color.fromARGB(255, 184, 134, 11); // Deeper gold
    case 'Angry':
      return const Color.fromARGB(255, 169, 69, 69); // Deeper coral
    case 'Sad':
      return const Color.fromARGB(255, 69, 128, 130); // Deeper teal
    default:
      return goldText;
  }
}

// Also consider updating the unselected state to be warmer:
Widget _emotionButton(String emotion, String assetPath, double screenWidth, double screenHeight, [double? textFs]) {
  final bool isSelected = _selectedEmotion == emotion;
  final double buttonSize = screenWidth * 0.25;
  final double fontSize = textFs ?? (screenWidth * 0.045);
  final Color accent = _emotionAccentColor(emotion);
  final Color border = _emotionBorderColor(emotion);
  
  return GestureDetector(
    onTap: _isLoading ? null : () {
      setState(() {
        _selectedEmotion = emotion;
      });
    },
    child: Opacity(
      opacity: _isLoading ? 0.6 : 1.0,
      child: Container(
        width: buttonSize,
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03, horizontal: screenWidth * 0.03),
        decoration: BoxDecoration(
          color: isSelected 
            ? accent.withOpacity(0.85) 
            : const Color.fromARGB(255, 76, 111, 105).withOpacity(0.3), // Warmer dark green instead of black
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? border 
              : const Color.fromARGB(255, 218, 165, 32).withOpacity(0.6), // Warm gold border instead of goldText
            width: isSelected ? 2.2 : 1.5,
          ),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : [
                BoxShadow(
                  color: const Color.fromARGB(255, 76, 111, 105).withOpacity(0.15), // Warmer shadow
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              width: buttonSize * 0.5,
              height: buttonSize * 0.5,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.sentiment_neutral, 
                size: buttonSize * 0.5, 
                color: isSelected ? Colors.white : const Color.fromARGB(255, 218, 165, 32),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              emotion,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color.fromARGB(255, 218, 165, 32), // Warm gold text
              ),
            ),
          ],
        ),
      ),
    )
  );
}

  // --- UI Screens ---
  Widget _emotionSelectionScreen(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.06),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                Text(
                  'Choose Your Emotion',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.w600,
                    color: goldText,
                    fontStyle: FontStyle.italic,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Container(
                  width: screenWidth * 0.3,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        goldText.withOpacity(0.3),
                        goldText,
                        goldText.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          FadeInDown(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'How are you feeling right now?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.042,
                color: lightGoldAccent.withOpacity(0.9),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.08),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldText.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.025,
                alignment: WrapAlignment.center,
                children: [
                  _emotionButton('Happy', 'assets/images/happy.png', screenWidth, screenHeight),
                  _emotionButton('Angry', 'assets/images/angry.png', screenWidth, screenHeight),
                  _emotionButton('Sad', 'assets/images/sad.png', screenWidth, screenHeight),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.20),
          // --- Adaptive spacing and popup above the Continue button ---
          LayoutBuilder(
            builder: (context, constraints) {
              // Reserve a fixed height for the popup + spacing, so the Continue button never moves
              final double popupHeight = screenHeight * 0.048; // enough for popup or just spacing
              return Column(
                children: [
                  SizedBox(
                    height: popupHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _showEmotionPopup
                          ? Container(
                              key: const ValueKey('popup'),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.008,
                                  horizontal: screenWidth * 0.06),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.50),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Please select an emotion first.',
                                style: GoogleFonts.poppins(
                                  color: goldText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.042,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('nopopup'),
                              height: popupHeight,
                            ),
                    ),
                  ),
                  _buildStyledButton(
                    text: 'Continue',
                    onPressed: _selectedEmotion != null && !_isLoading
                        ? () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _showEmotionPopup = false;
                            });
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        : () {
                            if (!_isLoading) {
                              setState(() {
                                _showEmotionPopup = true;
                              });
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) {
                                  setState(() {
                                    _showEmotionPopup = false;
                                  });
                                }
                              });
                            }
                          },
                    isPrimary: true,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const HomePage()),
                              (route) => false,
                            );
                          },
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.045,
                        color: goldText,
                        decoration: TextDecoration.underline,
                        decorationColor: goldText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _imageInputScreen(double screenWidth, double screenHeight) {
  bool showSceneryError = !_isScenery && _keywords == _invalidSceneryErrorMessage && _selectedImage != null;

  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.06,
      vertical: screenHeight * 0.02,
    ),
    child: Column(
      children: [
        SizedBox(height: screenHeight * 0.06),
        
        // Header section matching emotion selection screen
        FadeInDown(
          delay: const Duration(milliseconds: 200),
          child: Column(
            children: [
              Text(
                'Upload Your Scenery',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.w600,
                  color: goldText,
                  fontStyle: FontStyle.italic,
                  height: 1.2,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Container(
                width: screenWidth * 0.3,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      goldText.withOpacity(0.3),
                      goldText,
                      goldText.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: screenHeight * 0.02),
        
        // Subtitle matching the emotion selection screen
        FadeInDown(
          delay: const Duration(milliseconds: 400),
          child: Text(
            'Choose a scenery image that resonates with your emotion',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.042,
              color: lightGoldAccent.withOpacity(0.9),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ),
        
        SizedBox(height: screenHeight * 0.08),
        
        // Image upload container with consistent styling
        FadeInUp(
          delay: const Duration(milliseconds: 600),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: goldText.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Image upload area
                GestureDetector(
                  onTap: _isLoading ? null : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: cardBackground.withOpacity(0.95),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 6,
                                  margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                                  decoration: BoxDecoration(
                                    color: goldText.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(
                                  'Choose Image Source',
                                  style: GoogleFonts.poppins(
                                    color: goldText,
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _pickImage(fromCamera: false);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: goldText.withOpacity(0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(Icons.photo_library, 
                                                   size: screenWidth * 0.08, 
                                                   color: goldText),
                                              SizedBox(height: screenHeight * 0.01),
                                              Text('Gallery', 
                                                   style: GoogleFonts.poppins(
                                                     color: goldText,
                                                     fontSize: screenWidth * 0.04,
                                                     fontWeight: FontWeight.w500,
                                                   )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.04),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _pickImage(fromCamera: true);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: goldText.withOpacity(0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(Icons.camera_alt, 
                                                   size: screenWidth * 0.08, 
                                                   color: goldText),
                                              SizedBox(height: screenHeight * 0.01),
                                              Text('Camera', 
                                                   style: GoogleFonts.poppins(
                                                     color: goldText,
                                                     fontSize: screenWidth * 0.04,
                                                     fontWeight: FontWeight.w500,
                                                   )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: screenHeight * 0.20, // was 0.25
                      maxHeight: screenHeight * 0.25, // was 0.30
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: goldText.withOpacity(0.5), 
                        width: 1.5
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(
                              _selectedImage!, 
                              fit: BoxFit.cover, 
                              width: double.infinity, 
                              height: double.infinity
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.landscape_outlined,
                                size: screenWidth * 0.12,
                                color: goldText,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Text(
                                'Tap to Upload Image',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.045,
                                  color: goldText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.008),
                              Text(
                                'Choose grasslands, forests, or aquatic scenes',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  color: lightGoldAccent.withOpacity(0.8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.02),
                
                // Keywords or error display
                if (showSceneryError)
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.015, 
                      horizontal: screenWidth * 0.04
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.6), 
                        width: 1
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            _keywords,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade300, 
                              fontSize: screenWidth * 0.038, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_selectedImage != null && 
                         !_isLoading && 
                         _keywords != 'Analyzing image...' && 
                         _keywords != _invalidSceneryErrorMessage && 
                         !_keywords.startsWith("Upload an image"))
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.015, 
                      horizontal: screenWidth * 0.04
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4), 
                        width: 1
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade300,
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            "Keywords: $_keywords",
                            style: GoogleFonts.poppins(
                              color: Colors.green.shade300, 
                              fontSize: screenWidth * 0.038, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: screenHeight * 0.12),
        
        // Buttons section with consistent spacing
        LayoutBuilder(
          builder: (context, constraints) {
            final double buttonAreaHeight = screenHeight * 0.2;
            return Column(
              children: [
                SizedBox(
                  height: buttonAreaHeight,
                  child: Column(
                    children: [
                      _buildStyledButton(
                        text: 'Generate Pantun',
                        onPressed: _selectedImage != null && !_isLoading && _isScenery
                            ? () {
                                HapticFeedback.lightImpact();
                                _fetchPantunRecommendations();
                              }
                            : null,
                        isPrimary: true,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            color: _isLoading ? goldText.withOpacity(0.5) : goldText,
                            decoration: TextDecoration.underline,
                            decorationColor: goldText,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    bool canProceedFromStep0 = _selectedEmotion != null && !_isLoading;
    bool canProceedFromStep1 = _selectedImage != null && !_isLoading && _isScenery;
    ScrollPhysics pageViewPhysics = const ClampingScrollPhysics();

    if (_currentStep == 0 && !canProceedFromStep0) {
      pageViewPhysics = const NeverScrollableScrollPhysics();
    } else if (_currentStep == 1 && _isLoading) {
      pageViewPhysics = const NeverScrollableScrollPhysics();
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 63, 119, 124),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          if (_backgroundAnimation != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundAnimation!,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _backgroundAnimation!.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryBackground.withOpacity(0.8),
                            primaryBackground.withOpacity(0.5),
                            cardBackground,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: goldText.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / 2,
                            backgroundColor: goldText.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(goldText),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          "Step ${_currentStep + 1} of 2",
                          style: GoogleFonts.poppins(
                            color: goldText.withOpacity(0.9),
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                  physics: pageViewPhysics,
                  children: [
                    _emotionSelectionScreen(screenWidth, screenHeight),
                    _imageInputScreen(screenWidth, screenHeight),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      overlayBackground.withOpacity(0.8),
                      overlayBackground.withOpacity(0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.08),
                      decoration: BoxDecoration(
                        color: cardBackground.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_pulseAnimation != null)
                            AnimatedBuilder(
                              animation: _pulseAnimation!,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation!.value,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [goldText, goldText.withOpacity(0.7)],
                                      ),
                                    ),
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryBackground),
                                      strokeWidth: 3,
                                    ),
                                  )
                                );
                                },
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Text(
                                _getLoadingOverlayText(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: goldText,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                          ],
                      ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}