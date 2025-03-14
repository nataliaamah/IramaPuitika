import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PantunDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pantunData;

  const PantunDetailScreen({super.key, required this.pantunData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pantun Details",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pantun Text in a Decorative Box
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.deepPurple.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Decorative Icon at the Top
                      Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: Colors.deepPurple.shade400,
                      ),
                      const SizedBox(height: 10),
                      // Pantun Text with Creative Typography
                      Text(
                        pantunData['pantun'] ?? 'No pantun available',
                        style: GoogleFonts.dancingScript(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Decorative Divider
                      Divider(
                        color: Colors.deepPurple.shade300,
                        thickness: 1,
                        height: 20,
                      ),
                      // Small Quote or Tagline
                      Text(
                        "~ Traditional Malay Poetry ~",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Keywords Section
              _buildDetailSection(
                icon: Icons.tag,
                title: "Keywords",
                content: _formatKeywords(pantunData['keywords']),
              ),

              const SizedBox(height: 20),

              // Emotion Section
              _buildDetailSection(
                icon: Icons.emoji_emotions,
                title: "Emotion",
                content: _formatKeywords(pantunData['emotion']),
              ),

              const SizedBox(height: 30),

              // Share Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Add share functionality here
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: Text(
                    "Share Pantun",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.deepPurple.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.deepPurple.shade700,
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