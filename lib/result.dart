import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:animate_do/animate_do.dart';
import 'viewpantundetails.dart'; // Assuming this is your detail screen

// Updated colors to match HomePage theme
const Color goldText = Color(0xFFEAD7A6); // Matching HomePage goldText
const Color buttonColor = Color(0xFF003E4C); // Matching HomePage buttonColor
const Color backgroundSolid = Color.fromARGB(255, 63, 124, 96); // Matching HomePage background
const Color lightGoldAccent = Color(0xFFF5EAD0); // Keeping existing accent
const Color cardOverlay = Color(0xFF1A3A32); // Subtle dark overlay for better text contrast

class ResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> result;

  const ResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  final CardSwiperController _swiperController = CardSwiperController();

  // Animation controller for subtle animations matching HomePage
  late AnimationController _swayController;
  Animation<double>? _swayAnimation; // Make nullable to avoid LateInitializationError

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(begin: -0.002, end: 0.002).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundSolid, // Matching HomePage background
      extendBodyBehindAppBar: true, // Add this line
      appBar: _buildAppBar(screenWidth),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image matching HomePage structure
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: backgroundSolid,
              ),
            ),
          ),

          // Subtle decorative elements (optional, matching HomePage style)
          // Add null check for _swayAnimation
          if (_swayAnimation != null) // <-- Add this check
            Positioned(
              top: -50,
              right: -100,
              child: RotationTransition(
                turns: _swayAnimation!, // <-- Use non-null assertion after check
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/batik_element_top_right.png',
                    width: screenWidth * 0.6,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: widget.result.isEmpty
                ? _noResultsFound(screenWidth, screenHeight)
                : FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        // Title section matching HomePage style
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.07,
                            vertical: screenHeight * 0.02,
                          ),
                          child: FadeInDown(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              children: [
                                Text(
                                  'Your Pantun',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: screenWidth * 0.08,
                                    color: goldText,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: screenWidth * 0.4,
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
                                const SizedBox(height: 8),
                                Text(
                                  'Recommended based on your\nemotion and surroundings',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.035,
                                    color: goldText.withOpacity(0.8),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Card swiper section
                        Expanded(
                          child: FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: CardSwiper(
                              controller: _swiperController,
                              cardsCount: widget.result.length,
                              numberOfCardsDisplayed: widget.result.length < 3 ? widget.result.length : 3,
                              isLoop: true,
                              backCardOffset: const Offset(0, 15),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenHeight * 0.04,
                              ),
                              onSwipe: (prevIndex, newSwipedIndex, direction) {
                                if (mounted) {
                                  setState(() {
                                    currentIndex = newSwipedIndex ?? 0;
                                  });
                                }
                                return true;
                              },
                              onUndo: (previousIndex, originalIndex, direction) {
                                if (mounted) {
                                  setState(() {
                                    currentIndex = originalIndex;
                                  });
                                }
                                return true;
                              },
                              cardBuilder: (context, index, hThreshold, vThreshold) {
                                final pantunData = widget.result[index];
                                bool isEffectivelyFront = index == currentIndex;
                                return _pantunCard(context, pantunData, screenWidth, isDimmed: !isEffectivelyFront);
                              },
                            ),
                          ),
                        ),

                        // Navigation controls matching HomePage button style
                        if (widget.result.length > 1)
                          FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: screenHeight * 0.03,
                                top: screenHeight * 0.02,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: buttonColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildNavButton(
                                    icon: Icons.arrow_back_ios_rounded,
                                    onPressed: () => _swiperController.undo(),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      "${currentIndex + 1} / ${widget.result.length}",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.04,
                                        color: goldText,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  _buildNavButton(
                                    icon: Icons.arrow_forward_ios_rounded,
                                    onPressed: () => _swiperController.swipe(CardSwiperDirection.right),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: goldText.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: goldText,
          size: 20,
        ),
      ),
    );
  }

  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      title: Text(
        "Results",
        style: GoogleFonts.playfairDisplay(
          fontSize: screenWidth * 0.055,
          fontWeight: FontWeight.w500,
          color: goldText,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.0,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: goldText),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.8),
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
            color: goldText,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _pantunCard(BuildContext context, Map<String, dynamic> pantunData, double screenWidth, {bool isDimmed = false}) {
    final String theme = pantunData['theme'] as String? ?? 'default';

    String backgroundImagePath;
    switch (theme.toLowerCase()) {
      case 'budi':
        backgroundImagePath = 'assets/images/background_budi.png';
        break;
      case 'kias dan ibarat':
      case 'kias_dan_ibarat':
        backgroundImagePath = 'assets/images/background_kias_dan_ibarat.png';
        break;
      case 'percintaan':
        backgroundImagePath = 'assets/images/background_percintaan.png';
        break;
      default:
        backgroundImagePath = 'assets/images/default_paper_style_background.png';
    }

    // Process the pantun string
    String pantunText = pantunData['pantun'] as String? ?? 'Pantun not available';
    pantunText = pantunText.replaceAll('\\r\\n', '\n').replaceAll('\\n', '\n').replaceAll('\\r', '\n');
    pantunText = pantunText.replaceAll(RegExp(r',\s+'), ',\n');
    pantunText = pantunText.replaceAll(RegExp(r';\s+'), ';\n');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Transform.scale(
        scale: isDimmed ? 0.95 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isDimmed ? 0.7 : 1.0,
          child: GestureDetector(
            onTap: () {
              if (!isDimmed) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantunDetailScreen(pantunData: pantunData),
                  ),
                );
              }
            },
            child: Container( // This container provides the overall shape/decoration
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Background image layer
                  Positioned.fill( // Ensure the image layer fills the stack
                    child: Transform.scale( // Apply scale specifically to the background image
                      scale: 1.15, // Adjust this value to control the zoom level
                      child: Image.asset(
                        backgroundImagePath,
                        fit: BoxFit.cover, // Image should cover the scaled area
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image $backgroundImagePath: $error');
                          // Return a fallback widget, e.g., a solid color or a placeholder
                          return Container(
                            color: Colors.grey[300], // Fallback color
                            child: Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Optional: Subtle overlay for better text readability (if needed)
                  /*
                  Positioned.fill(
                    child: Container(
                      color: cardOverlay.withOpacity(isDimmed ? 0.3 : 0.2),
                    ),
                  ),
                  */

                  // Text content layer
                  Positioned.fill( // Ensure the text layer fills the stack
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 50.0),
                      child: Center(
                        child: Text(
                          pantunText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.greatVibes(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.w500,
                            color: isDimmed
                                ? const Color.fromARGB(255, 45, 45, 45).withOpacity(0.6)
                                : const Color.fromARGB(255, 45, 45, 45),
                            height: 1.3,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Subtle tap indicator
                  if (!isDimmed)
                    Positioned(
                      bottom: 90, // Keep original position
                      right: 15, // Keep original position
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF8A1D37).withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.touch_app_rounded,
                          color: goldText,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  Widget _noResultsFound(double screenWidth, double screenHeight) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: screenWidth * 0.15,
                    color: goldText.withOpacity(0.7),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  "No Matching Pantun Found",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.w500,
                    color: goldText,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Text(
                  "We couldn't find any pantun based on your image and emotion.\nTry a different scene or emotion to discover new poetry!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.038,
                    color: goldText.withOpacity(0.8),
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: goldText,
                    minimumSize: const Size(200, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Try Again',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}