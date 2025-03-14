import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'viewpantundetails.dart';

class ResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pantun Recommendations",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0, // Remove shadow
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: result.isEmpty
            ? _noResultsFound()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: result.length,
          itemBuilder: (context, index) {
            final pantunData = result[index];
            return _pantunCard(context, pantunData);
          },
        ),
      ),
    );
  }

  /// 📌 Show Pantun Card
  Widget _pantunCard(BuildContext context, Map<String, dynamic> pantunData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantunDetailScreen(pantunData: pantunData),
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pantunData['pantun'] ?? 'No pantun available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Keywords: ${_formatKeywords(pantunData['keywords'])}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_emotions,
                      size: 16,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Emotion: ${_formatKeywords(pantunData['emotion'])}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.deepPurple.shade700,
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

  /// ✅ Function to safely format keywords
  String _formatKeywords(dynamic keywords) {
    if (keywords is List) {
      return keywords.join(', '); // ✅ Properly joins a list
    } else if (keywords is String) {
      return keywords; // ✅ Already a string, return as is
    }
    return 'Unknown'; // ✅ Fallback
  }

  /// 📌 No Results Found
  Widget _noResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.deepPurple.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No matching pantun found!",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your keywords or emotion.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.deepPurple.shade500,
            ),
          ),
        ],
      ),
    );
  }
}