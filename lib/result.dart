import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; // Correct import for card swiper
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CardSwiper(
          cardsCount: widget.result.length, // Required: number of cards to swipe
          cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
            final pantunData = widget.result[index % widget.result.length];
            return _pantunCard(context, pantunData);
          },
          isLoop: true, // Enable looping after last card
          numberOfCardsDisplayed: 5, // Display 5 cards at once
          scale: 0.9, // Scale down the cards behind the front card to create the stack effect
          maxAngle: 30, // Max angle during swipe
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25), // Adjust the padding for overlap
            onSwipe: (previousIndex, currentIndex, direction) {
              setState(() {
                this.currentIndex = currentIndex! % widget.result.length;
              });
              return true;
            },
            onEnd: () {
            print("End of the stack, looping back!");
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

  Widget _pantunCard(BuildContext context, Map<String, dynamic> pantunData) {
    return Padding(
      padding: const EdgeInsets.all(10.0), // Padding for overlapping effect
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantunDetailScreen(pantunData: pantunData),
            ),
          );
        },
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
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
