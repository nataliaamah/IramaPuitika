import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isButtonPressed = false;
  Key _pageKey = UniqueKey(); // Key to force widget rebuild

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade100, Colors.indigo.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            key: _pageKey, // Apply the key here to rebuild this part
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // Welcome Text (Animated)
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'Welcome to IramaPuitika',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Description Text (Animated)
                FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    'Create beautiful pantun recommendations\nbased on your emotions and scenery.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Generate Button (Animated and Interactive)
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _isButtonPressed = true);
                      HapticFeedback.lightImpact(); // Subtle feedback
                    },
                    onTapUp: (_) {
                      setState(() => _isButtonPressed = false);
                      // Navigate after a short delay to let animation play
                      Future.delayed(const Duration(milliseconds: 100), () {
                        // Add mounted check before using context for Navigator.push
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          ).then((_) {
                            // This mounted check is for when returning from OnboardingScreen
                            if (mounted) {
                              setState(() {
                                _pageKey = UniqueKey(); // Change the key to force rebuild
                              });
                            }
                          });
                        }
                      });
                    },
                    onTapCancel: () {
                      setState(() => _isButtonPressed = false);
                    },
                    child: AnimatedScale(
                      scale: _isButtonPressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: _isButtonPressed ? 4 : 8, // Dynamic elevation
                          shadowColor: Colors.indigo.withOpacity(0.4),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 24),
                        label: Text(
                          'Generate Pantun',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(), // Pushes footer to bottom

                // Footer (Animated)
                FadeInUp(
                  delay: const Duration(milliseconds: 900),
                  child: Text(
                    'Powered by Gemini AI',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Padding at the very bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}