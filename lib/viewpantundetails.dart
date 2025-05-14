import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class PantunDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pantunData;

  const PantunDetailScreen({Key? key, required this.pantunData}) : super(key: key);

  // Define color constants as static const members of the class
  static const Color goldText = Color(0xFFE6C68A);
  static const Color darkTealButton = Color(0xFF004D40);
  static const LinearGradient maroonGradientBackground = LinearGradient(
    colors: [Color(0xFF8A1D37), Color(0xFFAB5D5D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final EdgeInsets systemPadding = MediaQuery.of(context).padding; // Get system padding (status bar)

    return Scaffold(
      extendBodyBehindAppBar: true, // Make body extend behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, 
        centerTitle: true,
        iconTheme: const IconThemeData(color: goldText), // Use gold color for back arrow
        title: Text(
          "Pantun Details",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.052,
            fontWeight: FontWeight.w600,
            color: goldText,
          ),
        ),
      ),
      body: Container( // This Container now only handles the gradient and fills the screen
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: maroonGradientBackground),
        child: SingleChildScrollView(
          // Apply padding here to position the content correctly below the transparent AppBar
          padding: EdgeInsets.only(
            top: systemPadding.top + kToolbarHeight + (screenHeight * 0.02), // Status bar + AppBar height + extra space
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            bottom: screenHeight * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pantun Text in a Minimalist Card
              Container(
                width: screenWidth * 0.85,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.025),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: goldText.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    // Custom Illustration (Placeholder)
                    Image.asset(
                      'assets/images/pantun.png', // Add your custom illustration
                      height: screenHeight * 0.18,
                      width: screenWidth * 0.4,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: screenWidth * 0.2, color: goldText),
                    ),

                    // Pantun Text with Elegant Typography
                    Text(
                      pantunData['pantun'] ?? 'No pantun available',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alice(
                        fontSize: screenWidth * 0.048, // Adjusted from 0.05
                        fontWeight: FontWeight.w500,
                        color: goldText,
                        fontStyle: FontStyle.italic,
                        height: 1.35, // Slightly increased line height for Alice font
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // Decorative Divider
                    Divider(
                      color: goldText.withOpacity(0.4),
                      thickness: 1.2,
                      height: screenHeight * 0.02,
                    ),
                    // Small Quote or Tagline
                    Text(
                      "~ Traditional Malay Poetry ~",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.033, // Adjusted from 0.035
                        fontStyle: FontStyle.italic,
                        color: goldText.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              // Keywords Section
              _buildDetailSection(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                icon: Icons.tag,
                title: "Keywords",
                content: _formatKeywords(pantunData['keywords']),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Emotion Section
              _buildDetailSection(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                icon: Icons.emoji_emotions,
                title: "Emotion",
                content: _formatKeywords(pantunData['emotion']),
              ),

              SizedBox(height: screenHeight * 0.05),

              // Share Button (Elevated Button)
              ElevatedButton.icon(
                onPressed: () async {
                  // Get the pantun text
                  final pantunText = pantunData['pantun'] ?? 'No pantun available';

                  // Share the pantun text
                  Share.share(pantunText);
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text(
                  "Share Pantun",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTealButton,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.016),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📌 Build a Detail Section with Icon and Text
  Widget _buildDetailSection({
    required double screenWidth,
    required double screenHeight,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: screenWidth * 0.85,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.018), // Adjusted vertical padding
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: PantunDetailScreen.goldText.withOpacity(0.5), width: 1.5), // Access via ClassName.goldText
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align icon and text centrally if content is short
        children: [
          Icon(
            icon,
            size: screenWidth * 0.065, // Adjusted icon size
            color: PantunDetailScreen.goldText, // Access via ClassName.goldText
          ),
          SizedBox(width: screenWidth * 0.035), // Adjusted spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.042, // Adjusted from 0.045
                    fontWeight: FontWeight.w600,
                    color: PantunDetailScreen.goldText, // Access via ClassName.goldText
                  ),
                ),
                SizedBox(height: screenHeight * 0.006), // Adjusted spacing
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.037, // Adjusted from 0.04
                    color: PantunDetailScreen.goldText.withOpacity(0.9), // Access via ClassName.goldText
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Function to safely format keywords
  String _formatKeywords(dynamic keywords) {
    if (keywords is List) {
      return keywords.join(', ');
    } else if (keywords is String) {
      return keywords;
    }
    return 'Unknown';
  }
}