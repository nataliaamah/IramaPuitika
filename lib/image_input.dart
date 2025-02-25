import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  File? _selectedImage;
  String _response = 'No response yet.';
  String _geminiVersion = 'Checking...';
  int _usedTokens = 0;
  final int _totalTokensAllowed = 2000000;
  final ImagePicker _picker = ImagePicker();

  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM'; // Replace with your valid API key
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

  @override
  void initState() {
    super.initState();
    _fetchGeminiVersion();
    _loadTokenUsage();
  }

  /// Loads previously used token count
  Future<void> _loadTokenUsage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _usedTokens = prefs.getInt('usedTokens') ?? 0;
    });
  }

  /// Saves token count persistently
  Future<void> _saveTokenUsage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usedTokens', _usedTokens);
  }

  /// Fetches the Gemini model version dynamically
  Future<void> _fetchGeminiVersion() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _geminiVersion = result['name'] ?? 'Unknown Model';
        });
      } else {
        setState(() {
          _geminiVersion = 'Error ${response.statusCode}: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _geminiVersion = 'Error: $e';
      });
    }
  }

  /// Handles image selection and sends request to Gemini API
  Future<void> _uploadAndAnalyzeImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _response = 'Processing...';
        });

        final imageBytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final requestBody = {
          "contents": [
            {
              "parts": [
                {"text": "Analyze this scene for emotions and context in keywords only."},
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
          print(result);

          if (result.containsKey('usageMetadata') &&
              result['usageMetadata'].containsKey('totalTokenCount')) {
            setState(() {
              _usedTokens += (result['usageMetadata']['totalTokenCount'] as int?) ?? 0;
            });
            _saveTokenUsage();
          }

          if (result.containsKey('usageMetadata') &&
              result['usageMetadata'].containsKey('modelVersion')) {
            setState(() {
              _geminiVersion = result['usageMetadata']['modelVersion'];
            });
          }

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
            });
          } else {
            setState(() {
              _response = 'No valid response received. Full response: $result';
            });
          }
        } else if (response.statusCode == 429) {
          setState(() {
            _response = 'Error: Too Many Requests. You have reached the rate limit. Try again later.';
          });
        } else if (response.statusCode == 403) {
          setState(() {
            _response = 'Error: Quota Exceeded. You have reached your daily or monthly limit.';
          });
        } else {
          setState(() {
            _response = 'Error ${response.statusCode}: ${response.reasonPhrase}\n${response.body}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
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
            Text('Gemini Model: $_geminiVersion'),
            Text('Tokens Used: $_usedTokens / $_totalTokensAllowed'),
            if (_selectedImage != null) Image.file(_selectedImage!, height: 200, width: 200, fit: BoxFit.cover),
            ElevatedButton(onPressed: _uploadAndAnalyzeImage, child: const Text('Upload and Analyze Image')),
            Text(_response),
          ],
        ),
      ),
    );
  }
}
