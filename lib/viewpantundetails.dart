import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PantunDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pantunData;

  const PantunDetailScreen({Key? key, required this.pantunData}) : super(key: key);

  @override
  State<PantunDetailScreen> createState() => _PantunDetailScreenState();
}

class _PantunDetailScreenState extends State<PantunDetailScreen>
    with TickerProviderStateMixin {
  // Theme colors
  static const Color primaryText = Color(0xFF2C3E50);
  static const Color secondaryText = Color(0xFF7F8C8D);
  static const Color accentColor = Color(0xFF3498DB);
  static const Color cardBackground = Colors.white;
  static const Color backgroundColor = Color(0xFFF8F9FA);

  // API Constants
  final String apiKey = 'AIzaSyA73OQQiAiiUH5j99t60f23dBPECr2jUWk'; // Note: It's better to store keys securely and not in source code.
  final String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-04-17:generateContent';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _swayController; // Add sway controller

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _swayAnimation; // Declare sway animation

  bool _isSharePressed = false;
  String _interpretation = 'Generating interpretation...'; // State for AI-generated interpretation

  // Lexicon sets for keyword coloring
  Set<String> joyKeywords = {};
  Set<String> sadnessKeywords = {};
  Set<String> angerKeywords = {};

  @override
  void initState() {
    super.initState();
    loadAllLexicons(); // Load keywords for coloring
    _generateInterpretation(); // Generate interpretation on screen load

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _swayController = AnimationController( // Initialize sway controller
      duration: const Duration(seconds: 8), // Match home page duration
      vsync: this,
    ); // Initialize controller first

    _swayAnimation = Tween<double>(begin: -0.003, end: 0.003).animate( // Initialize sway animation
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    // Now start the repeat after the animation is initialized
    _swayController.repeat(reverse: true);


    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));


    // Start other animations
    _fadeController.forward();
    _slideController.forward();
  }

  // --- AI Interpretation Generation ---
  Future<void> _generateInterpretation() async {
    final pantun = widget.pantunData['pantun'] as String? ?? '';
    if (pantun.isEmpty) {
      if (mounted) {
        setState(() {
          _interpretation = 'No pantun text available to interpret.';
        });
      }
      return;
    }

    final String promptText = """
You are a masterful storyteller and an expert in Malay pantun. Your task is to reveal the deep meaning of a pantun's core message (the isi) in a way that is both beautiful and easy to understand.

**Instructions:**
1.  **Focus on the Core Message:** Analyze only the isi (lines 3-4).
2.  **Uncover Symbolism:** Gently explain the metaphors and emotional heart of the pantun.
3.  **Be Clear and Concise:** The interpretation must be under 50 words and use language that is simple and clear for everyone.
4.  **Evocative, Not Academic:** Write with a touch of poetry, not like a textbook.
5.  **Just the Interpretation:** Provide only the final interpretation text, without any extra words or introductions.

**Example:**
- Pantun: "Pulau Pandan jauh ke tengah, Gunung Daik bercabang tiga; Hancur badan dikandung tanah, Budi yang baik dikenang juga."
- Interpretation: This pantun teaches that our physical life is fleeting, but the legacy of our kindness and good character endures forever, remembered by all.

**Your Task:**
Provide an interpretation for this pantun: "$pantun"
""";

    try {
      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [{"text": promptText}]
            }
          ],
          "generationConfig": {
            "temperature": 0.5,
            "topK": 32,
            "topP": 1,
            "maxOutputTokens": 1000,
          }
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          final parts = result['candidates']?[0]['content']['parts'] as List<dynamic>? ?? [];
          String aiResponseText = "Sorry, could not generate an interpretation at this time.";
          if (parts.isNotEmpty && parts[0]['text'] != null) {
            aiResponseText = parts[0]['text'].toString().trim();
          }
          setState(() {
            _interpretation = aiResponseText;
          });
        } else {
          setState(() {
            _interpretation = 'Failed to get interpretation (Error ${response.statusCode}).';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _interpretation = 'Error generating interpretation. Please check your connection.';
        });
      }
    }
  }

  // --- Lexicon Loading for Keyword Coloring ---
  Future<void> loadAllLexicons() async {
    try {
      joyKeywords = await _loadEmotionKeywords("assets/txt/joy-NRC-Emotion-Lexicon.txt");
      sadnessKeywords = await _loadEmotionKeywords("assets/txt/sadness-NRC-Emotion-Lexicon.txt");
      angerKeywords = await _loadEmotionKeywords("assets/txt/anger-NRC-Emotion-Lexicon.txt");
      if (mounted) {
        setState(() {}); // Rebuild with loaded keywords
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error loading lexicons: $e");
    }
  }

  Future<Set<String>> _loadEmotionKeywords(String filePath) async {
    final String content = await rootBundle.loadString(filePath);
    return content
        .split('\n')
        .map((line) => line.split(RegExp(r'\s+')).first.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  // --- Keyword Chip Coloring ---
  Color _getColorForKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (joyKeywords.contains(lowerKeyword)) {
      return const Color.fromARGB(255, 218, 165, 32); // Happy/Joy color
    }
    if (sadnessKeywords.contains(lowerKeyword)) {
      return const Color.fromARGB(255, 80, 100, 150); // Sad color
    }
    if (angerKeywords.contains(lowerKeyword)) {
      return const Color.fromARGB(255, 190, 50, 50); // Angry color
    }
    // Default color if not found in any lexicon
    return accentColor;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _swayController.dispose(); // Dispose sway controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    String pantunText = widget.pantunData['pantun'] as String? ?? 'No pantun available';
    pantunText = pantunText.replaceAll('\\r\\n', '\n')
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\n');
    pantunText = pantunText.replaceAll(RegExp(r',\s+'), ',\n');
    pantunText = pantunText.replaceAll(RegExp(r';\s+'), ';\n');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor, // This is the fallback color if the image doesn't load
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Batik pattern background
          _buildBatikBackground(),

          // Batik element top right
          Positioned(
            top: -screenHeight * 0.1, // Adjust position as needed
            right: -screenWidth * 0.3, // Adjust position as needed
            child: FadeInRight( // Use FadeInRight for entry animation
              delay: const Duration(milliseconds: 300), // Match or adjust delay
              duration: const Duration(milliseconds: 800), // Match or adjust duration
              child: RotationTransition(
                turns: _swayAnimation, // Use the sway animation
                child: Image.asset(
                  'assets/images/batik_element_top_right.png',
                  width: screenWidth * 0.8, // Adjust size as needed
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: screenWidth * 0.4, height: screenWidth * 0.35, color: Colors.transparent), // Placeholder
                ),
              ),
            ),
          ),

          // Batik element bottom left
          Positioned(
            bottom: -screenHeight * 0.1, // Adjust position as needed
            left: -screenWidth * 0.3, // Adjust position as needed
            child: FadeInLeft( // Use FadeInLeft for entry animation
              delay: const Duration(milliseconds: 300), // Match or adjust delay
              duration: const Duration(milliseconds: 800), // Match or adjust duration
              child: RotationTransition(
                turns: _swayAnimation, // Use the sway animation
                child: Image.asset(
                  'assets/images/batik_element_bottom_left.png',
                  width: screenWidth * 0.8, // Adjust size as needed
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: screenWidth * 0.45, height: screenWidth * 0.4, color: Colors.transparent), // Placeholder
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Main content card
                      _buildMainContentCard(pantunText, screenWidth, screenHeight),
                      
                      SizedBox(height: screenHeight * 0.03),
                      
                      // Share button
                      _buildShareButton(pantunText, screenWidth, screenHeight),
                      
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF003E4C).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 8,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFFEAD7A6),
            size: 22,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatikBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: const Color.fromARGB(255, 76, 123, 101),
      ),
      child: Image.asset( // Use Image.asset for the background image
        'assets/images/background.png', // Path to your background image
        fit: BoxFit.cover, // Cover the entire container
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildMainContentCard(String pantunText, double screenWidth, double screenHeight) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                
                // Pantun text section
                _buildPantunSection(pantunText, screenWidth, screenHeight),
                
                // Separator line
                _buildSeparator(screenWidth),
                
                // Definition section
                _buildDefinitionSection(screenWidth, screenHeight),
                
                // Keywords section
                _buildKeywordsSection(screenWidth, screenHeight),
                
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPantunSection(String pantunText, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.06,
      ),
      child: Column(
        children: [
          Text(
              '"$pantunText"',
              style: GoogleFonts.crimsonText(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w500,
                color: primaryText,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildSeparator(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            secondaryText.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionSection(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Interpretation',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Disclaimer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        content: Text(
                          'The interpretation provided is generated by an AI model and may not be entirely accurate. It should be used for informational purposes only.',
                          style: GoogleFonts.poppins(
                            color: secondaryText,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              'OK',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline_rounded,
                  color: secondaryText,
                  size: screenWidth * 0.05,
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          Text(
            _interpretation,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.w400,
              color: secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordsSection(double screenWidth, double screenHeight) {
    List<String> allKeywords = [];
    
    // Process keywords and emotions
    final keywordsData = widget.pantunData['keywords'];
    final emotionData = widget.pantunData['emotion'];

    if (keywordsData != null) {
      List<dynamic> keywordsList = keywordsData is List ? keywordsData : [keywordsData];
      for (var keyword in keywordsList) {
        if (keyword.toString().isNotEmpty) {
          allKeywords.add(keyword.toString());
        }
      }
    }

    if (emotionData != null) {
      List<dynamic> emotionList = emotionData is List ? emotionData : [emotionData];
      for (var emotion in emotionList) {
        if (emotion.toString().isNotEmpty) {
          allKeywords.add(emotion.toString());
        }
      }
    }

    if (allKeywords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Keywords',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: allKeywords.map((keyword) => _buildKeywordChip(keyword, screenWidth)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String keyword, double screenWidth) {
    final Color keywordColor = _getColorForKeyword(keyword);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: keywordColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: keywordColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        keyword,
        style: GoogleFonts.poppins(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w500,
          color: keywordColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildShareButton(String pantunText, double screenWidth, double screenHeight) {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isSharePressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => setState(() => _isSharePressed = false),
        onTapCancel: () => setState(() => _isSharePressed = false),
        onTap: () async {
          await Share.share(
            '$pantunText\n\n✨ Get recommended pantuns using Irama Puitika',
            subject: 'Beautiful Pantun to Share',
          );
        },
        child: AnimatedScale(
          scale: _isSharePressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.018,
              horizontal: screenWidth * 0.06,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF003E4C),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF003E4C).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Share this Pantun',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for batik pattern background
class BatikPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8F4FD).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final circlePaint = Paint()
      ..color = const Color(0xFFBDE3FF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle geometric pattern
    for (double x = 0; x < size.width; x += 80) {
      for (double y = 0; y < size.height; y += 80) {
        // Draw small circles
        canvas.drawCircle(Offset(x + 20, y + 20), 8, circlePaint);
        canvas.drawCircle(Offset(x + 60, y + 60), 6, circlePaint);
        
        // Draw small rectangles
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x + 40, y + 10), width: 12, height: 4),
            const Radius.circular(2),
          ),
          paint,
        );
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x + 10, y + 50), width: 4, height: 12),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}