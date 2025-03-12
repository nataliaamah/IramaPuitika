import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'result.dart'; // Import the result screen

class SelectEmotionScreen extends StatefulWidget {
  final String keywords; // Accept keywords as a parameter

  const SelectEmotionScreen({super.key, required this.keywords});

  @override
  State<SelectEmotionScreen> createState() => _SelectEmotionScreenState();
}

class _SelectEmotionScreenState extends State<SelectEmotionScreen> {
  String? _selectedEmotion; // Store the selected emotion
  bool _isLoading = false; // Track loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step 2 Title
            Text(
              'Step 2/2',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Display Uploaded Image (Placeholder Box)
            Image.asset("assets/images/step_2.gif", height: 250, width: 200,),

            // Select Emotion Text
            Text(
              'Select Emotion',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),

            // Emotion Selection Buttons (Using Assets)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _emotionButton('Happy', 'assets/images/happy.png', Colors.amber),
                const SizedBox(width: 15),
                _emotionButton('Angry', 'assets/images/angry.png', Colors.red),
                const SizedBox(width: 15),
                _emotionButton('Sad', 'assets/images/sad.png', Colors.blue),
              ],
            ),
            const SizedBox(height: 30),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                // Generate Button (Proceed)
                ElevatedButton(
                  onPressed: _selectedEmotion != null && !_isLoading
                      ? () => _sendDataToAPI()
                      : null, // Disable button if no emotion is selected or loading
                  child: _isLoading
                      ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Emotion Selection Button Widget (Uses Asset Images)
  Widget _emotionButton(String emotion, String assetPath, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmotion = emotion;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedEmotion == emotion ? color.withOpacity(0.3) : Colors.grey[200], // ✅ Light highlight instead of removing image
              border: Border.all(
                color: _selectedEmotion == emotion ? color : Colors.grey,
                width: 2,
              ),
            ),
            child: Image.asset(
              assetPath,
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            emotion,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _selectedEmotion == emotion ? color : Colors.black, // ✅ Highlight text color if selected
            ),
          ),
        ],
      ),
    );
  }

  /// Send selected emotion & keywords to Flask API
  Future<void> _sendDataToAPI() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    const String apiUrl = "http://127.0.0.1:5000/recommend"; // Flask API URL
    final Map<String, dynamic> requestData = {
      "emotion": _selectedEmotion,
      "keywords": widget.keywords.split(',') // Convert string to list
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        List<dynamic> pantunResults = jsonDecode(response.body);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(result: pantunResults),
            ),
          );
        }
      } else {
        _showError("Failed to fetch data. Please try again.");
      }
    } catch (error) {
      _showError("Error: $error");
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

  /// Show error message as a Snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
