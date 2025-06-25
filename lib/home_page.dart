import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  double _elementsOpacity = 1.0; 
  final Duration _fadeOutDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      duration: const Duration(seconds: 8), // Even slower for more elegance
      vsync: this,
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(begin: -0.003, end: 0.003).animate(
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
        _elementsOpacity = 0.0;
      });
    }

    Future.delayed(_fadeOutDuration, () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        ).then((_) {
          if (mounted) {
            setState(() {
              _pageKey = UniqueKey();
              _elementsOpacity = 1.0;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    
    const Color goldText = Color(0xFFEAD7A6); // Even better contrast
    const Color buttonColor = Color(0xFF003E4C); // Refined button color
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // More refined responsive sizing
    final double titleSize = screenWidth < 360 ? 64 : screenWidth < 400 ? 50 : 74;
    final double subtitleSize = screenWidth < 360 ? 15 : 17;
    final double welcomeSize = screenWidth < 360 ? 17 : 19;

    return Scaffold(
      key: _pageKey,
      backgroundColor: const Color.fromARGB(255, 37, 112, 81), // Set solid blue as background behind image
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Add the background image first, scaled to device
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Ultra-subtle batik elements
                Positioned( 
                  top: -100,
                  right: -140,
                  child: AnimatedOpacity( 
                    opacity: 1, // Even more subtle
                    duration: _fadeOutDuration,
                    child: FadeInRight(
                      delay: const Duration(milliseconds: 1400),
                      duration: const Duration(milliseconds: 1200),
                      child: RotationTransition(
                        turns: _swayAnimation,
                        child: Image.asset(
                          'assets/images/batik_element_top_right.png',
                          width: screenWidth * 0.85,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: screenWidth * 0.4, 
                                height: screenWidth * 0.35, 
                                color: Colors.transparent,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned( 
                  bottom: -80,
                  left: -180,
                  child: AnimatedOpacity( 
                    opacity: 1, // Even more subtle
                    duration: _fadeOutDuration,
                    child: FadeInLeft(
                      delay: const Duration(milliseconds: 1400),
                      duration: const Duration(milliseconds: 1200),
                      child: RotationTransition(
                        turns: _swayAnimation,
                        child: Image.asset(
                          'assets/images/batik_element_bottom_left.png',
                          width: screenWidth * 0.95,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: screenWidth * 0.45, 
                                height: screenWidth * 0.4, 
                                color: Colors.transparent,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Premium content layout
                AnimatedOpacity(
                  opacity: _elementsOpacity,
                  duration: _fadeOutDuration,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.07,
                    ),
                    child: Column(
                      children: [
                        // Top spacer for better vertical distribution
                        SizedBox(height: screenHeight * 0.15),
                        
                        // Main content area
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Welcome section with improved spacing
                              Column(
                                children: [
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 300),
                                    child: Semantics(
                                      label: 'Welcome to Irama Puitika app',
                                      child: Text(
                                        'welcome to',
                                        style: GoogleFonts.poppins(
                                          fontSize: welcomeSize,
                                          color: goldText.withOpacity(0.85),
                                          letterSpacing: 2.0, // More elegant spacing
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12), // Slightly more breathing room
                                  
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 500),
                                    child: Semantics(
                                      label: 'Irama Puitika',
                                      child: Text(
                                        'Irama\nPuitika',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: titleSize,
                                          color: goldText,
                                          fontWeight: FontWeight.normal,
                                          height: 1.0,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 1.5, // Added letter spacing for elegance
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 3),
                                              blurRadius: 6,
                                              color: Colors.black.withOpacity(0.25),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: screenHeight * 0.05), // More generous spacing
                              
                              // Description with better positioning
                              FadeInDown(
                                delay: const Duration(milliseconds: 700),
                                child: Semantics(
                                  label: 'Create beautiful pantun recommendations based on your emotions and scenery',
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: screenWidth * 0.85,
                                    ),
                                    child: Text(
                                      'Create beautiful pantun recommendations\nbased on your emotions and scenery.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: subtitleSize,
                                        color: goldText.withOpacity(0.95),
                                        height: 1.6, // More generous line height
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Button section with optimal positioning
                        Column(
                          children: [
                            // Move the hint text above the button
                            FadeInUp(
                              delay: const Duration(milliseconds: 1100),
                              child: Text(
                                'Tap to begin your poetic journey',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: goldText.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeInUp(
                              delay: const Duration(milliseconds: 900),
                              child: Semantics(
                                label: 'Start',
                                hint: 'Tap to start creating pantun poetry',
                                button: true,
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    if (mounted) {
                                      setState(() => _isButtonPressed = true);
                                    }
                                    HapticFeedback.mediumImpact(); // Slightly stronger feedback
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
                                    duration: const Duration(milliseconds: 200),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: _isButtonPressed 
                                          ? [
                                              BoxShadow(
                                                offset: const Offset(0, 3),
                                                blurRadius: 12,
                                                color: buttonColor.withOpacity(0.35),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                offset: const Offset(0, 6),
                                                blurRadius: 20,
                                                color: buttonColor.withOpacity(0.4),
                                              ),
                                              BoxShadow(
                                                offset: const Offset(0, 2),
                                                blurRadius: 8,
                                                color: Colors.black.withOpacity(0.1),
                                              ),
                                            ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _triggerFadeOutAndNavigate,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: buttonColor,
                                          foregroundColor: goldText,
                                          minimumSize: const Size(240, 56), // Slightly larger
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 36, 
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Start',
                                              style: GoogleFonts.poppins(
                                                fontSize: 20, // Slightly larger
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            AnimatedRotation(
                                              turns: _isButtonPressed ? 0.1 : 0,
                                              duration: const Duration(milliseconds: 200),
                                              child: AnimatedScale(
                                                scale: _isButtonPressed ? 1.1 : 1.0,
                                                duration: const Duration(milliseconds: 200),
                                                child: const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                        
                        // Bottom spacer for better balance
                        SizedBox(height: screenHeight * 0.08),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}