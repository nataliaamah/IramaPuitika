import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';
import 'select_emotion.dart';

class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  File? _selectedImage;
  String _response = 'No response yet.';
  bool _isLoading = false; // Show a loading indicator
  final ImagePicker _picker = ImagePicker();

  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM'; // Replace with your valid API key
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

  /// Opens dialog to choose between Camera or Gallery
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Picks an image from gallery or camera
  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );

      if (pickedFile != null) {
        if (_selectedImage?.path == pickedFile.path) {
          setState(() {
            _response = "This image has already been processed."; // Avoid duplicate API calls
          });
          return;
        }

        setState(() {
          _selectedImage = File(pickedFile.path);
          _response = 'Processing...';
          _isLoading = true; // Show loading indicator
        });

        _uploadAndAnalyzeImage();
      } else {
        setState(() {
          _response = "No image selected.";
        });
      }
    } catch (e) {
      setState(() {
        _response = "Error selecting image: $e";
      });
    }
  }

  /// Uploads and analyzes the image using Gemini API
  Future<void> _uploadAndAnalyzeImage() async {
    try {
      if (_selectedImage == null) return;

      final imageBytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": "Analyze this scene for emotions in keywords only."},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 512,
        }
      };

      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['candidates'] != null &&
            result['candidates'].isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null) {
          final parts = result['candidates'][0]['content']['parts'] as List<dynamic>;

          final textResponse = parts
              .where((part) => part['text'] != null && part['text'] is String)
              .map((part) => part['text'] as String)
              .join('\n');

          setState(() {
            _response = textResponse;
            _isLoading = false;
          });
        } else {
          setState(() {
            _response = 'No valid response received.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _response = 'Error ${response.statusCode}: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step 1 Title
            const Text(
              'Step 1',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Placeholder Image (Fixed Graphic)
            Container(
              width: 150,
              height: 100,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Text("Graphic Here", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 15),

            // Upload Scenery Image Text
            const Text(
              'Enter Scenery Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            // Dotted Border for Upload
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: DottedBorder(
                color: Colors.grey, // Border color
                strokeWidth: 2,
                dashPattern: [6, 4], // Dotted pattern
                borderType: BorderType.RRect,
                radius: const Radius.circular(10),
                child: Container(
                  width: 200,
                  height: 150,
                  alignment: Alignment.center,
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload, size: 40, color: Colors.black54),
                      SizedBox(height: 5),
                      Text('Tap to Upload', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gemini AI Response Section (Loading + Generated Keywords)
            if (_selectedImage != null) ...[
              const Text(
                'Gemini Generated Keywords:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50], // Light background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                  _response,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  onPressed: _selectedImage != null
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelectEmotionScreen()),
                    );
                  }
                      : null, // Disabled if no image
                  child: const Text('Next →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
