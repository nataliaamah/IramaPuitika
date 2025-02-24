import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Image Analysis',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  String _response = '';
  final ImagePicker _picker = ImagePicker();

  final String apiKey = 'AIzaSyDFz86K4YfUtIuYsaIP-aMUME0uMSGg3oM'; // Replace with your API key
  final String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

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
                {
                  "text":
                  "Analyze the feelings and context of this scene (e.g., happy, sad, calm, warm, cold, lost, lonely) in keywords without explanation."
                },
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
          headers: {
            'Content-Type': 'application/json',
          },
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
            });
          } else {
            setState(() {
              _response = 'No valid response content received. Full response: $result';
            });
          }
        } else {
          setState(() {
            _response =
            'Error ${response.statusCode}: ${response.reasonPhrase}\n${response.body}';
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
      appBar: AppBar(
        title: const Text('Gemini Image Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(),
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
            else
              const Text('No image selected.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadAndAnalyzeImage,
              child: const Text('Upload and Analyze Image'),
            ),
            const SizedBox(height: 20),
            Text(
              _response,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
