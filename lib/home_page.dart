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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _isButtonPressed = false;
  Key _pageKey = UniqueKey();

  late AnimationController _swayController;
  late Animation<double> _swayAnimation;

  double _elementsOpacity = 1.0; // For controlling fade-out
  final Duration _fadeOutDuration = const Duration(milliseconds: 300); // Duration for fade-out

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(begin: -0.01, end: 0.01).animate( // Sway angle in radians (approx -0.57 to 0.57 degrees)
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  void _triggerFadeOutAndNavigate() {
    if (mounted) {
      setState(() {
        _elementsOpacity = 0.0; // Start fade-out
      });
    }

    Future.delayed(_fadeOutDuration, () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        ).then((_) {
          // When returning from OnboardingScreen
          if (mounted) {
            setState(() {
              _pageKey = UniqueKey(); // Rebuild to restart entrance animations
              _elementsOpacity = 1.0; // Reset opacity for next view
            });
          }
        });
      }
    });
  }

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
      key: _pageKey,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: maroonGradientBackground,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Top-right batik element
              Positioned( 
                top: -80,
                right: -130,
                child: AnimatedOpacity( 
                  opacity: _elementsOpacity,
                  duration: _fadeOutDuration,
                  child: FadeInRight(
                    delay: const Duration(milliseconds: 1100),
                    duration: const Duration(milliseconds: 800),
                    child: RotationTransition(
                      turns: _swayAnimation,
                      child: Image.asset(
                        'assets/images/batik_element_top_right.png',
                        width: screenWidth * 0.9,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: screenWidth * 0.45, height: screenWidth * 0.4, color: Colors.transparent, child: const Icon(Icons.broken_image, color: goldText, size: 50)),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom-left batik element
              Positioned( 
                bottom: -50,
                left: -140,
                child: AnimatedOpacity( 
                  opacity: _elementsOpacity,
                  duration: _fadeOutDuration,
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 1100),
                    duration: const Duration(milliseconds: 800),
                    child: RotationTransition(
                      turns: _swayAnimation,
                      child: Image.asset(
                        'assets/images/batik_element_bottom_left.png',
                        width: screenWidth * 1,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: screenWidth * 0.55, height: screenWidth * 0.5, color: Colors.transparent, child: const Icon(Icons.broken_image, color: goldText, size: 50)),
                      ),
                    ),
                  ),
                ),
              ),

              // Centered content
              AnimatedOpacity(
                opacity: _elementsOpacity,
                duration: _fadeOutDuration,
                child: Center(
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
                              height: 0.9,
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
                                onPressed: () { // MODIFIED: Call the navigation logic here
                                  _triggerFadeOutAndNavigate();
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}