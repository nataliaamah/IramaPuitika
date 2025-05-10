import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'viewpantundetails.dart'; // Assuming this is your detail screen

// Colors from onboarding_screen.dart for cohesion
const LinearGradient maroonGradientBackground = LinearGradient(
  colors: [Color(0xFF8A1D37), Color(0xFFAB5D5D)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
const Color goldText = Color(0xFFE6C68A);
const Color darkTealButton = Color(0xFF004D40); // Can be used for text or accents
const Color lightGoldAccent = Color(0xFFF5EAD0); // Good for card backgrounds

class ResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> result;

  const ResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int currentIndex = 0; // This will be updated by onUpdateIndex for the Text widget
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: maroonGradientBackground),
        child: SafeArea( // Content will be within the safe area
          child: widget.result.isEmpty
              ? _noResultsFound(screenWidth, screenHeight)
              : Column(
                  children: [
                    Expanded(
                      child: CardSwiper(
                        controller: _swiperController,
                        cardsCount: widget.result.length,
                        numberOfCardsDisplayed: widget.result.length < 3 ? widget.result.length : 3,
                        isLoop: true,
                        backCardOffset: const Offset(0, 10),
                        // ADJUST THIS PADDING TO CONTROL CARD SIZE AND ASPECT RATIO:
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.001, // Example: try adjusting this
                          vertical: screenHeight * 0.12  // Example: try adjusting this
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
                          return true; // Allow the undo.
                        },
                        cardBuilder: (context, index, hThreshold, vThreshold) {
                          final pantunData = widget.result[index];
                          // Determine if the card is the front card based on the state's currentIndex
                          bool isEffectivelyFront = index == currentIndex;
                          return _pantunCard(context, pantunData, isDimmed: !isEffectivelyFront);
                        },
                      ),
                    ),
                    if (widget.result.length > 1)
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.02, top: screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios, color: lightGoldAccent.withOpacity(0.8)),
                              onPressed: widget.result.isNotEmpty
                                  ? () => _swiperController.undo()
                                  : null,
                            ),
                            Text(
                              // This Text widget uses the _ResultScreenState.currentIndex
                              "${currentIndex + 1} / ${widget.result.length}",
                              style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.04,
                                  color: lightGoldAccent,
                                  fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward_ios, color: lightGoldAccent.withOpacity(0.8)),
                              onPressed: widget.result.isNotEmpty
                                  ? () => _swiperController.swipe(CardSwiperDirection.right)
                                  : null,
                            ),
                          ],
                        ),
                      )
                  ],
                ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        "Results",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: goldText, // Use goldText for AppBar title
        ),
      ),
      centerTitle: true,
      elevation: 0, // No shadow for a flatter look with gradient
      backgroundColor: maroonGradientBackground.colors.first, // Match gradient start
      iconTheme: const IconThemeData(color: goldText), // Gold back button
    );
  }

  Widget _pantunCard(BuildContext context, Map<String, dynamic> pantunData, {bool isDimmed = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
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

    final pantunTextColor = isDimmed
        ? Colors.black.withOpacity(0.5)
        : Colors.black87;

    return Opacity(
      opacity: isDimmed ? 0.75 : 1.0,
      child: Transform.scale(
        scale: isDimmed ? 0.92 : 1.0,
        // Removed Padding widget here or set its padding to EdgeInsets.zero
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
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImagePath),
                fit: BoxFit.fitHeight, // Or BoxFit.fitHeight
                onError: (exception, stackTrace) {
                  debugPrint('Error loading image $backgroundImagePath: $exception');
                },
              ),
            ),
            child: Padding(
              // This padding is for the text *inside* the image card
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 45.0), // Adjust as needed
              child: Center(
                child: Text(
                  pantunData['pantun'] ?? 'Pantun not available',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tangerine(
                    fontSize: screenWidth * 0.07, // Slightly increased text size
                    fontWeight: FontWeight.w700,
                    color: pantunTextColor,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatKeywords(dynamic keywords) {
    if (keywords is List) {
      return keywords.join(', ');
    } else if (keywords is String) {
      return keywords;
    }
    return 'N/A';
  }

  Widget _noResultsFound(double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: screenWidth * 0.2, color: lightGoldAccent.withOpacity(0.7)),
            SizedBox(height: screenHeight * 0.03),
            Text(
              "No Matching Pantun Found",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w600,
                color: goldText,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              "We couldn't find any pantun based on your image and emotion. Try a different scene or emotion!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.038,
                color: lightGoldAccent.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
