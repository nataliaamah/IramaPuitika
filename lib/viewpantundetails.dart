import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class PantunDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pantunData;

  const PantunDetailScreen({Key? key, required this.pantunData}) : super(key: key);

  // Define color constants as static const members of the class
  static const Color goldText = Color(0xFFE6C68A);
  static const Color darkTealButton = Color(0xFF004D40);

  // Consistent gradient with other screens
  static const LinearGradient maroonGradientBackground = LinearGradient(
    colors: [Color(0xFF8A1D37), Color(0xFFAB5D5D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final EdgeInsets systemPadding = MediaQuery.of(context).padding;

    // Process the pantun string for newlines
    String pantunText = pantunData['pantun'] as String? ?? 'No pantun available';
    pantunText = pantunText.replaceAll('\\r\\n', '\n').replaceAll('\\n', '\n').replaceAll('\\r', '\n');
    pantunText = pantunText.replaceAll(RegExp(r',\s+'), ',\n');
    pantunText = pantunText.replaceAll(RegExp(r';\s+'), ';\n');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: goldText),
        title: Text(
          "Pantun",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w500,
            color: goldText.withOpacity(0.8),
          ),
        ),
      ),
      body: Container( // Wrap SingleChildScrollView with a Container for the gradient
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration( // Use the consistent gradient
          gradient: maroonGradientBackground,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: systemPadding.top + kToolbarHeight + (screenHeight * 0.03),
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            bottom: screenHeight * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/pantun.png',
                height: screenHeight * 0.2,
                width: screenWidth * 0.45,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.broken_image, size: screenWidth * 0.2, color: goldText.withOpacity(0.7)),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                pantunText, // Use the processed pantunText
                textAlign: TextAlign.center,
                style: GoogleFonts.alice(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w500,
                  color: goldText,
                  height: 1.4,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "~ Traditional Malay Poetry ~",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.03,
                  fontStyle: FontStyle.italic,
                  color: goldText.withOpacity(0.7),
                ),
              ),
              SizedBox(height: screenHeight * 0.035),

              // Display Keywords and Emotion as Chips
              Builder(
                builder: (context) {
                  List<Widget> chipWidgets = [];
                  final keywordsData = pantunData['keywords'];
                  final emotionData = pantunData['emotion'];

                  // Process keywords
                  if (keywordsData != null) {
                    List<dynamic> keywordsList = [];
                    if (keywordsData is List) {
                      keywordsList = keywordsData;
                    } else if (keywordsData is String && keywordsData.isNotEmpty) {
                      // If it's a non-empty string, treat it as a single keyword.
                      keywordsList = [keywordsData]; 
                    }
                    
                    for (var keyword in keywordsList) {
                      if (keyword.toString().isNotEmpty) { // Ensure keyword is not empty
                        chipWidgets.add(Chip(
                          label: Text(keyword.toString(), style: GoogleFonts.poppins(color: Color(0xFF8A1D37), fontSize: screenWidth * 0.032, fontWeight: FontWeight.w500)),
                          backgroundColor: goldText.withOpacity(0.85),
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.005),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(color: goldText.withOpacity(0.5), width: 0.5),
                          ),
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
                      // If it's a non-empty string, treat it as a single emotion.
                      emotionList = [emotionData];
                    }

                    for (var emotion in emotionList) {
                      if (emotion.toString().isNotEmpty) { // Ensure emotion is not empty
                        chipWidgets.add(Chip(
                          label: Text(emotion.toString(), style: GoogleFonts.poppins(color: Color(0xFF8A1D37), fontSize: screenWidth * 0.032, fontWeight: FontWeight.w500)),
                          backgroundColor: goldText.withOpacity(0.7), // Slightly different for distinction
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.005),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(color: goldText.withOpacity(0.4), width: 0.5),
                          ),
                        ));
                      }
                    }
                  }

                  if (chipWidgets.isNotEmpty) {
                    return Wrap(
                      spacing: 8.0, // Horizontal spacing between chips
                      runSpacing: 4.0, // Vertical spacing between lines of chips
                      alignment: WrapAlignment.center,
                      children: chipWidgets,
                    );
                  }
                  // Return an empty widget if there are no keywords or emotions to display
                  return const SizedBox.shrink(); 
                },
              ),

              SizedBox(height: screenHeight * 0.05),

              ElevatedButton.icon(
                onPressed: () async {
                  final pantunText = pantunData['pantun'] ?? 'No pantun available';
                  Share.share(pantunText);
                },
                icon: const Icon(Icons.share, color: Colors.white, size: 24),
                label: Text(
                  "Share Pantun",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTealButton,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.018),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // Ensure some padding at the very bottom
            ],
          ),
        ),
      ),
    );
  }
}