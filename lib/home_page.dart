import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart'; // Re-added for animations

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isButtonPressed = false; // Restored for button animation
  Key _pageKey = UniqueKey(); // Restored for page rebuild logic

  @override
  Widget build(BuildContext context) {
    const LinearGradient maroonGradientBackground = LinearGradient(
      colors: [Color(0xFF8A1D37), Color(0xFFAB5D5D)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    const Color goldText = Color(0xFFE6C68A);
    const Color darkTealButton = Color(0xFF004D40);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _pageKey, // Apply key to the Scaffold
      backgroundColor: Colors.transparent, // Make Scaffold background transparent for the gradient
      body: SafeArea(
        child: Container( // Wrap Stack with a Container for the gradient
          decoration: const BoxDecoration(
            gradient: maroonGradientBackground, // Apply gradient here
          ),
          child: Stack(
            fit: StackFit.expand,
            // clipBehavior: Clip.none, // Uncomment if elements are still clipped
            children: [
              // Top-right batik element
              Positioned(
                top: -80, // Adjusted for overflow
                right: -150, // Adjusted for overflow
                child: FadeInRight(
                  delay: const Duration(milliseconds: 1100),
                  duration: const Duration(milliseconds: 800),
                  child: Image.asset(
                    'assets/images/batik_element_top_right.png', // Corrected: Flower for top right
                    width: screenWidth * 0.9,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: screenWidth * 0.45, height: screenWidth * 0.4, color: Colors.transparent, child: const Icon(Icons.broken_image, color: goldText, size: 50)),
                  ),
                ),
              ),

              // Bottom-left batik element
              Positioned(
                bottom: -50, // Adjusted for overflow
                left: -140, // Adjusted for overflow
                child: FadeInLeft(
                  delay: const Duration(milliseconds: 1100),
                  duration: const Duration(milliseconds: 800),
                  child: Image.asset(
                    'assets/images/batik_element_bottom_left.png', // Corrected: BranchCorrected: Bttom left
                    width: screenWidth * 1,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: screenWidth * 0.55, height: screenWidth * 0.5, color: Colors.transparent, child: const Icon(Icons.broken_image, color: goldText, size: 50)),
                  ),
                ),
              ),

              // Centered content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FadeInDown(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'welcome to',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: goldText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInDown(
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          'Irama\nPuitika',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.greatVibes(
                          fontSize: 60,
                          color: goldText,
                          fontWeight: FontWeight.normal,
                          height: 0.9, // Reduced line height
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      FadeInDown(
                        delay: const Duration(milliseconds: 700),
                        child: Text(
                          'Create beautiful pantun recommendations\nbased on your emotions and scenery.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: goldText.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                      FadeInUp(
                        delay: const Duration(milliseconds: 900),
                        child: GestureDetector(
                          onTapDown: (_) {
                            if (mounted) {
                              setState(() => _isButtonPressed = true);
                            }
                            HapticFeedback.lightImpact();
                          },
                          onTapUp: (_) {
                            if (mounted) {
                              setState(() => _isButtonPressed = false);
                            }
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                                ).then((_) {
                                  if (mounted) {
                                    setState(() {
                                      _pageKey = UniqueKey(); // Rebuild to restart animations
                                      // Reset any other state if needed
                                    });
                                  }
                                });
                              }
                            });
                          },
                          onTapCancel: () {
                            if (mounted) {
                              setState(() => _isButtonPressed = false);
                            }
                          },
                          child: AnimatedScale(
                            scale: _isButtonPressed ? 0.95 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: ElevatedButton(
                              onPressed: () {
                                // This onPressed is technically overridden by GestureDetector's onTapUp
                                // but it's good practice to have it for accessibility or if GestureDetector is removed.
                                // The actual navigation is handled in onTapUp.
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkTealButton,
                                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                foregroundColor: goldText,
                                elevation: _isButtonPressed ? 2 : 8,
                                shadowColor: darkTealButton.withOpacity(0.5),
                              ),
                              child: Text(
                                'Generate Pantun',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}