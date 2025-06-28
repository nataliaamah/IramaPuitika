import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';

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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _swayController; // Add sway controller

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _swayAnimation; // Declare sway animation

  bool _isSharePressed = false;

  @override
  void initState() {
    super.initState();

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
      leading: Container(
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
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
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
          child: IconButton(
            icon: const Icon(Icons.more_horiz, color: primaryText, size: 20),
            onPressed: () {},
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
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with trending badge
            _buildCardHeader(screenWidth),
            
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
    );
  }

  Widget _buildCardHeader(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Traditional',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '2 Days Ago',
            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: screenWidth * 0.032,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantunSection(String pantunText, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          Text(
            'Beautiful Traditional Pantun',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.w700,
              color: primaryText,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: screenHeight * 0.025),
          
          // Pantun text with quote styling
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              '"$pantunText"',
              style: GoogleFonts.crimsonText(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w500,
                color: primaryText,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
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
          Text(
            'Understanding Pantun',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          Text(
            'Pantun is a traditional Malay poetic form consisting of four-line verses with an ABAB rhyme scheme. The first two lines set up imagery or context, while the final two lines deliver the main message or moral.',
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
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Themes',
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        keyword,
        style: GoogleFonts.poppins(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w500,
          color: accentColor.withOpacity(0.8),
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
            '$pantunText\n\n✨ Shared from Irama Puitika',
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
              color: accentColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
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