import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class PantunDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pantunData;

  PantunDetailScreen({Key? key, required this.pantunData}) : super(key: key);

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
                pantunText,
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
              Builder(
                builder: (context) {
                  List<Widget> chipWidgets = [];
                  final keywordsData = pantunData['keywords'];
                  final emotionData = pantunData['emotion'];

                  if (keywordsData != null) {
                    List<dynamic> keywordsList = [];
                    if (keywordsData is List) {
                      keywordsList = keywordsData;
                    } else if (keywordsData is String && keywordsData.isNotEmpty) {
                      keywordsList = [keywordsData];
                    }
                    
                    for (var keyword in keywordsList) {
                      if (keyword.toString().isNotEmpty) {
                        chipWidgets.add(Chip(
                          label: Text(
                            keyword.toString(),
                            style: GoogleFonts.poppins(
                              color: PantunDetailScreen.goldText,
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.006),
                          shape: StadiumBorder(
                            side: BorderSide(color: PantunDetailScreen.goldText.withOpacity(0.6), width: 1.0),
                          ),
                        ));
                      }
                    }
                  }

                  if (emotionData != null) {
                    List<dynamic> emotionList = [];
                    if (emotionData is List) {
                      emotionList = emotionData;
                    } else if (emotionData is String && emotionData.isNotEmpty) {
                      emotionList = [emotionData];
                    }

                    for (var emotion in emotionList) {
                      if (emotion.toString().isNotEmpty) {
                        chipWidgets.add(Chip(
                          label: Text(
                            emotion.toString(),
                            style: GoogleFonts.poppins(
                              color: PantunDetailScreen.goldText,
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.006),
                          shape: StadiumBorder(
                            side: BorderSide(color: PantunDetailScreen.goldText.withOpacity(0.5), width: 1.0),
                          ),
                        ));
                      }
                    }
                  }

                  if (chipWidgets.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Associated Tags:",
                          style: GoogleFonts.poppins(
                            color: PantunDetailScreen.goldText.withOpacity(0.8),
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          alignment: WrapAlignment.center,
                          children: chipWidgets,
                        ),
                      ],
                    );
                  }
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
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}