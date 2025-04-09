import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pantun Text in a Minimalist Card
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Custom Illustration (Placeholder)
                      Image.asset(
                        'assets/images/pantun.png', // Add your custom illustration
                        height: 150,
                        width: 200,
                      ),

                      // Pantun Text with Elegant Typography
                      Text(
                        pantunData['pantun'] ?? 'No pantun available',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Decorative Divider
                      Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                        height: 20,
                      ),
                      // Small Quote or Tagline
                      Text(
                        "~ Traditional Malay Poetry ~",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

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

              const SizedBox(height: 32),

              // Share Button (Elevated Button)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Get the pantun text
                    final pantunText = pantunData['pantun'] ?? 'No pantun available';

                    // Share the pantun text
                    Share.share(pantunText);

                    // Save user preference (theme)
                    final theme = pantunData['theme'];  // Use 'theme' instead of 'emotion'
                    if (theme != null) {
                      try {
                        final response = await http.post(
                          Uri.parse('http://172.20.10.6:5000/save_preference'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'theme': theme}),
                        );

                        if (response.statusCode == 200) {
                          print('Preference saved successfully');
                        } else {
                          print('Failed to save preference: ${response.statusCode}');
                        }
                      } catch (e) {
                        print('Error saving preference: $e');
                      }
                    }
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
                    backgroundColor: Colors.black87,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.black87,
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
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