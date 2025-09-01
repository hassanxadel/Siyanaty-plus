import 'package:flutter/material.dart';
import 'dart:async';
import '../../../shared/constants/app_theme.dart';


/// Splash screen displayed during app initialization
/// Features animated logo, text, and automatic transition to main app
class SplashScreen extends StatefulWidget {
  /// Callback function triggered when splash animation completes
  final VoidCallback? onFinish;
  const SplashScreen({super.key, this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State class for the splash screen
/// Manages entrance animations and automatic transition timing
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  /// Controller for logo scale and fade animation
  late AnimationController _logoController;
  /// Controller for text entrance animation
  late AnimationController _textController;
  /// Logo animation combining scale and opacity
  late Animation<double> _logoAnimation;
  /// Text fade-in animation
  late Animation<double> _textAnimation;
  /// Text slide-up animation for entrance
  late Animation<Offset> _slideAnimation;

  /// Initialize animation controllers and start entrance sequence
  @override
  void initState() {
    super.initState();
    
    /// Create logo controller with elastic bounce effect
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    /// Create text controller for delayed text entrance
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    /// Configure logo animation with elastic bounce curve
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    /// Configure text fade-in animation
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    /// Configure text slide-up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    /// Start logo animation immediately
    _logoController.forward();
    
    /// Delay text animation by 800ms for staggered effect
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });

    /// Auto-transition to main app after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onFinish?.call();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B4332),
              Color(0xFF2D5A47),
              Color(0xFF40916C),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Enhanced Background Pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: CustomPaint(
                    painter: ModernPatternPainter(),
                  ),
                ),
              ),
              
              // Floating Elements
              Positioned(
                top: 80,
                right: 30,
                child: FadeTransition(
                  opacity: _textAnimation,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white.withOpacity(0.1),
                    ),
                                         child: const Icon(
                       IconData(0xe800, fontFamily: 'MyFlutterApp'),
                       color: Colors.white,
                       size: 30,
                     ),
                  ),
                ),
              ),
              
              Positioned(
                top: 200,
                left: 20,
                child: FadeTransition(
                  opacity: _textAnimation,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
              
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: ScaleTransition(
                        scale: _logoAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Enhanced Logo Container
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(45),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                    spreadRadius: -5,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.secondaryGreen.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 140,
                                  height: 140,
                                    decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF52B788),
                                        Color(0xFF40916C),
                                        Color(0xFF2D5A47),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            FadeTransition(
                              opacity: _textAnimation,
                              child: Column(
                                children: [
                                  Text(
                                'siyanaty+',
                                style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                      letterSpacing: 3.0,
                                      fontFamily: 'Orbitron',
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 4),
                                          blurRadius: 12,
                                          color: Colors.black.withOpacity(0.4),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Smart Car Maintenance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 1.5,
                                      fontFamily: 'Orbitron',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    flex: 2,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _textAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Feature Icons Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                                                 _buildFeatureIcon(const IconData(0xe800, fontFamily: 'MyFlutterApp'), 'Maintenance'),
                                _buildFeatureIcon(Icons.location_on_rounded, 'Location'),
                                _buildFeatureIcon(Icons.scanner_rounded, 'Scan'),
                                _buildFeatureIcon(Icons.schedule_rounded, 'Reminders'),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppTheme.secondaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Track • Maintain • Optimize • Thrive',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 50),
                            
                            // Enhanced Loading Indicator
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 5,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.secondaryGreen,
                                    ),
                                    backgroundColor: AppTheme.getThemeAwareBackground(context).withOpacity(0.2),
                                  ),
                                ),
                                                                 Container(
                                   width: 40,
                                   height: 40,
                                   decoration: BoxDecoration(
                                     color: AppTheme.secondaryGreen,
                                     borderRadius: BorderRadius.circular(20),
                                     boxShadow: [
                                       BoxShadow(
                                         color: AppTheme.secondaryGreen.withOpacity(0.3),
                                         blurRadius: 10,
                                         offset: const Offset(0, 3),
                                       ),
                                     ],
                                   ),
                                   child: Icon(
                                     const IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                     size: 24,
                                     color: AppTheme.getThemeAwareBackground(context),
                                   ),
                                 ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            Text(
                              'Preparing your smart journey...',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getThemeAwareBackground(context).withOpacity(0.85),
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.getThemeAwareBackground(context).withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.getThemeAwareBackground(context).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.getThemeAwareBackground(context),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareBackground(context).withOpacity(0.8),
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    
    // Draw modern geometric pattern
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw hexagonal pattern
        final center = Offset(x, y);
        
        // Small decorative circle
        canvas.drawCircle(center, 2, paint);
        
        // Connecting lines creating a subtle geometric pattern
        if (x + spacing < size.width) {
          canvas.drawLine(
            Offset(x + 15, y),
            Offset(x + spacing - 15, y),
            paint,
          );
        }
        
        if (y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y + 15),
            Offset(x, y + spacing - 15),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 