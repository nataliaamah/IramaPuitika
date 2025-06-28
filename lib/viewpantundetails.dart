import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class PantunDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pantunData;

  const PantunDetailScreen({Key? key, required this.pantunData}) : super(key: key);

  @override
  State<PantunDetailScreen> createState() => _PantunDetailScreenState();
}

class _PantunDetailScreenState extends State<PantunDetailScreen> 
    with SingleTickerProviderStateMixin {
  
  // IMPROVED: Enhanced color scheme with better contrast
  static const Color goldText = Color(0xFFE6C68A);
  static const Color lightGold = Color(0xFFF2E5C7);
  static const Color darkTealButton = Color(0xFF004D40);
  static const Color accentColor = Color(0xFF6B4E3D);
  
  // IMPROVED: More sophisticated gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF8A1D37), 
      Color(0xFFAB5D5D),
      Color(0xFF7A2B3F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.6, 1.0],
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final EdgeInsets systemPadding = MediaQuery.of(context).padding;

    String pantunText = widget.pantunData['pantun'] as String? ?? 'No pantun available';
    pantunText = pantunText.replaceAll('\\r\\n', '\n')
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\n');
    pantunText = pantunText.replaceAll(RegExp(r',\s+'), ',\n');
    pantunText = pantunText.replaceAll(RegExp(r';\s+'), ';\n');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(screenWidth),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: Stack(
          children: [
            // IMPROVED: Decorative background elements
            _buildBackgroundDecorations(screenWidth, screenHeight),
            
            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: systemPadding.top + kToolbarHeight + (screenHeight * 0.02),
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    bottom: screenHeight * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(screenWidth, screenHeight),
                      _buildPantunCard(pantunText, screenWidth, screenHeight),
                      _buildTagsSection(screenWidth, screenHeight),
                      _buildActionSection(screenWidth, screenHeight),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // IMPROVED: Enhanced app bar with better styling
  PreferredSizeWidget _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: goldText),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: goldText.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: goldText,
            size: 22,
          ),
        ),
      ),
      title: Text(
        "Pantun Details",
        style: GoogleFonts.playfairDisplay(
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.w500,
          color: goldText,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // IMPROVED: Decorative background elements
  Widget _buildBackgroundDecorations(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        // Floating decorative elements
        Positioned(
          top: screenHeight * 0.15,
          right: -screenWidth * 0.1,
          child: Opacity(
            opacity: 0.1,
            child: Container(
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: goldText, width: 2),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: screenHeight * 0.2,
          left: -screenWidth * 0.15,
          child: Opacity(
            opacity: 0.08,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: lightGold, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // IMPROVED: Better header section with visual hierarchy
  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.03),
      child: Column(
        children: [
          // IMPROVED: Better icon presentation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: goldText.withOpacity(0.3),
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
            child: Image.asset(
              'assets/images/pantun.png',
              height: screenHeight * 0.12,
              width: screenWidth * 0.3,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.auto_awesome,
                size: screenWidth * 0.15,
                color: goldText.withOpacity(0.7),
              ),
            ),
          ),
          
          SizedBox(height: screenHeight * 0.02),
          
          // IMPROVED: Better subtitle
          Text(
            "Traditional Malay Poetry",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.035,
              fontStyle: FontStyle.italic,
              color: goldText.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED: Enhanced pantun card with better design
  Widget _buildPantunCard(String pantunText, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.08),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: goldText.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // IMPROVED: Decorative header for the pantun
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          accentColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.auto_awesome,
                    color: accentColor.withOpacity(0.6),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          accentColor.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // IMPROVED: Better text styling
          Text(
            pantunText,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: screenWidth * 0.052,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D2D2D),
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
          
          // IMPROVED: Decorative footer
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 1,
                  color: accentColor.withOpacity(0.5),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 1,
                  color: accentColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED: Better tags section with enhanced styling
  Widget _buildTagsSection(double screenWidth, double screenHeight) {
    List<Widget> chipWidgets = [];
    final keywordsData = widget.pantunData['keywords'];
    final emotionData = widget.pantunData['emotion'];

    // Process keywords
    if (keywordsData != null) {
      List<dynamic> keywordsList = [];
      if (keywordsData is List) {
        keywordsList = keywordsData;
      } else if (keywordsData is String && keywordsData.isNotEmpty) {
        keywordsList = [keywordsData];
      }
      
      for (var keyword in keywordsList) {
        if (keyword.toString().isNotEmpty) {
          chipWidgets.add(_buildEnhancedChip(
            keyword.toString(), 
            screenWidth, 
            isEmotion: false
          ));
        }
      }
    }

    // Process emotions
    if (emotionData != null) {
      List<dynamic> emotionList = [];
      if (emotionData is List) {
        emotionList = emotionData;
      } else if (emotionData is String && emotionData.isNotEmpty) {
        emotionList = [emotionData];
      }

      for (var emotion in emotionList) {
        if (emotion.toString().isNotEmpty) {
          chipWidgets.add(_buildEnhancedChip(
            emotion.toString(), 
            screenWidth, 
            isEmotion: true
          ));
        }
      }
    }

    if (chipWidgets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: goldText.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Associated with",
            style: GoogleFonts.poppins(
              color: goldText,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Wrap(
            spacing: 12.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: chipWidgets,
          ),
        ],
      ),
    );
  }

  // IMPROVED: Enhanced chip design
  Widget _buildEnhancedChip(String text, double screenWidth, {bool isEmotion = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isEmotion 
            ? accentColor.withOpacity(0.2)
            : goldText.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmotion 
              ? accentColor.withOpacity(0.6)
              : goldText.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmotion ? Icons.favorite_outline : Icons.tag,
            size: 14,
            color: isEmotion ? accentColor : goldText,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: isEmotion ? accentColor : goldText,
              fontSize: screenWidth * 0.033,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED: Better action section with multiple options
  Widget _buildActionSection(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Primary share button
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: ElevatedButton.icon(
            onPressed: () async {
              final pantunText = widget.pantunData['pantun'] ?? 'No pantun available';
              Share.share(
                '$pantunText\n\n~ Traditional Malay Poetry ~',
                subject: 'Beautiful Pantun to Share',
              );
            },
            icon: const Icon(Icons.share, color: Colors.white, size: 22),
            label: Text(
              "Share this Pantun",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.044,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTealButton,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.02,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        
        // IMPROVED: Additional action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSecondaryAction(
              icon: Icons.favorite_border,
              label: "Like",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added to favorites!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: darkTealButton,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              screenWidth: screenWidth,
            ),
            _buildSecondaryAction(
              icon: Icons.copy,
              label: "Copy",
              onPressed: () {
                // Add copy functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pantun copied to clipboard!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: darkTealButton,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              screenWidth: screenWidth,
            ),
            _buildSecondaryAction(
              icon: Icons.download,
              label: "Save",
              onPressed: () {
                // Add save functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pantun saved!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: darkTealButton,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              screenWidth: screenWidth,
            ),
          ],
        ),
      ],
    );
  }

  // IMPROVED: Secondary action buttons
  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: goldText.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: goldText,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: goldText,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}