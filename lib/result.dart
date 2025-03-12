import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> result; // ✅ Now accepts pantun results

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pantun Recommendations",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: result.isEmpty
          ? _noResultsFound()
          : ListView.builder(
        itemCount: result.length,
        itemBuilder: (context, index) {
          final pantunData = result[index];
          return _pantunCard(pantunData);
        },
      ),
    );
  }

  /// 📌 Show Pantun Card
  Widget _pantunCard(Map<String, dynamic> pantunData) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pantunData['pantun'] ?? 'No pantun available',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Keywords: ${_formatKeywords(pantunData['keywords'])}\nEmotion: ${_formatKeywords(pantunData['emotion'])}",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
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


  Widget _noResultsFound() {
    return Center(
      child: Text(
        "No matching pantun found!",
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
      ),
    );
  }
}
