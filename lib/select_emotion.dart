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

            // Display Uploaded Image (Placeholder Box)
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Image Here",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            // Select Emotion Text
            const Text(
              'Select Emotion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _selectedEmotion == emotion ? color : Colors.black, // ✅ Highlight text color if selected
            ),
          ),
        ],
      ),
    );
  }
}
