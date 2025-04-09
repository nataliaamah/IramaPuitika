import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'viewpantundetails.dart';

class ResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> result;

  const ResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.result.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _noResultsFound(),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CardSwiper(
          cardsCount: widget.result.length,
          numberOfCardsDisplayed: 5,
          isLoop: true,
          scale: 1.0,
          backCardOffset: Offset.zero,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
          maxAngle: 5,
          onSwipe: (prev, newIndex, direction) {
            setState(() {
              currentIndex = newIndex! % widget.result.length;
            });
            return true;
          },
          onEnd: () {
            print("Reached end of cards");
          },
          cardBuilder: (context, index, hThreshold, vThreshold) {
            final pantunData = widget.result[index % widget.result.length];
            final isFront = index == currentIndex;

            if (isFront) {
              // Full visible front card
              return _pantunCard(context, pantunData);
            }

            // Back cards: show real content, but dimmed and slightly offset
            final offsetX = ((index % 3) - 1) * 8.0;
            final offsetY = ((index % 4) - 1.5) * 6.0;
            final angle = ((index % 5) - 2) * 0.015;

            return Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Transform.rotate(
                angle: angle,
                child: Opacity(
                  opacity: 1,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.3),
                      BlendMode.srcATop,
                    ),
                    child: _pantunCard(context, pantunData, isDimmed: true),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        "Results",
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  Widget _pantunCard(BuildContext context, Map<String, dynamic> pantunData, {bool isDimmed = false}) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: IgnorePointer( // Prevent tap on back cards
        ignoring: isDimmed,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Card(
            elevation: 12,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDimmed ? Colors.grey.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pantunData['pantun'] ?? 'No pantun available',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.tag, size: 16, color: Colors.black87),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          "Keywords: ${_formatKeywords(pantunData['keywords'])}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.emoji_emotions, size: 16, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        "Emotion: ${_formatKeywords(pantunData['emotion'])}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
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
    return 'Unknown';
  }

  Widget _noResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No matching pantun found!",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your keywords or emotion.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
