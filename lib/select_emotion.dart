import 'package:flutter/material.dart';

class SelectEmotionScreen extends StatefulWidget {

  const SelectEmotionScreen({super.key});

  @override
  State<SelectEmotionScreen> createState() => _SelectEmotionScreenState();
}

class _SelectEmotionScreenState extends State<SelectEmotionScreen> {
  String? _selectedEmotion; // Store the selected emotion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Emotion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step 2 Title
            const Text(
              'Step 2',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Display Uploaded Image
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),

            // Select Emotion Text
            const Text(
              'Select Emotion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),

            // Emotion Selection Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _emotionButton('Happy', Icons.sentiment_satisfied_alt, Colors.yellow),
                const SizedBox(width: 15),
                _emotionButton('Anger', Icons.sentiment_dissatisfied, Colors.red),
                const SizedBox(width: 15),
                _emotionButton('Sad', Icons.sentiment_very_dissatisfied, Colors.blue),
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
                  onPressed: _selectedEmotion != null
                      ? () {
                    // Navigate to the next step (Replace with your next screen)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Generating for $_selectedEmotion...')),
                    );
                  }
                      : null, // Disable button if no emotion is selected
                  child: const Text('Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Emotion Selection Button Widget
  Widget _emotionButton(String emotion, IconData icon, Color color) {
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
              color: _selectedEmotion == emotion ? color.withOpacity(0.6) : Colors.grey[200],
              border: Border.all(
                color: _selectedEmotion == emotion ? color : Colors.grey,
                width: 2,
              ),
            ),
            child: Icon(icon, size: 40, color: _selectedEmotion == emotion ? Colors.white : color),
          ),
          const SizedBox(height: 5),
          Text(emotion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
