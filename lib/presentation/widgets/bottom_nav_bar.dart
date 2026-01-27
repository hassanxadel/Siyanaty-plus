import 'package:flutter/material.dart';
import '../screens/services/reminders_screen.dart';
import '../screens/services/obd_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../../shared/utils/responsive_utils.dart';

/// Custom bottom navigation bar with animated tab items and curved design
/// Provides navigation between main app sections with visual feedback
class BottomNavBar extends StatefulWidget {
  /// Index of currently selected tab
  final int currentIndex;
  /// Callback function when tab is tapped
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

/// State class for bottom navigation bar
/// Manages animations and tab interactions
class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  /// Controller for tab tap animations
  late AnimationController _animationController;
  /// Scale animation for tab press feedback
  

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive sizing using the new scaling system
    final navBarHeight = context.r(70);
    final centerButtonSize = context.r(56);
    final centerButtonTop = context.r(-12);
    final iconSize = context.responsiveIconSize(24);
    final fontSize = context.responsiveFontSize(11);
    final horizontalPadding = context.responsiveSpacing(16);
    final verticalPadding = context.responsiveSpacing(8);
    
    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF062117) : Colors.transparent,
      ),
      child: SafeArea(
        bottom: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Two-tone background with curved separator
            Positioned.fill(
              child: CustomPaint(
                painter: _CurvedBackgroundPainter(isDarkMode: isDarkMode),
              ),
            ),
            // Navigation items
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: _NavBarItem(
                      icon: Icons.home,
                      label: 'Home',
                      isActive: widget.currentIndex == 0,
                      onTap: () => _handleTap(0),
                      iconSize: iconSize,
                      fontSize: fontSize,
                    ),
                  ),
                  Flexible(
                    child: _NavBarItem(
                      icon: Icons.alarm,
                      label: 'Reminders',
                      isActive: widget.currentIndex == 1,
                      onTap: () => _handleTap(1),
                      iconSize: iconSize,
                      fontSize: fontSize,
                    ),
                  ),
                  // Empty space for center button
                  SizedBox(width: centerButtonSize),
                  Flexible(
                    child: _NavBarItem(
                      icon: Icons.location_on,
                      label: 'Location',
                      isActive: widget.currentIndex == 3,
                      onTap: () => _handleTap(3),
                      iconSize: iconSize,
                      fontSize: fontSize,
                    ),
                  ),
                  Flexible(
                    child: _NavBarItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      isActive: widget.currentIndex == 4,
                      onTap: () => _handleTap(4),
                      iconSize: iconSize,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
            // Center floating button with black circular background
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - (centerButtonSize / 2),
              top: centerButtonTop,
              child: GestureDetector(
                onTap: () {
                  // Navigate to OBD screen by pushing it onto the stack
                  _navigateToScreen(context, 2);
                },
                child: Container(
                  width: centerButtonSize,
                  height: centerButtonSize,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.developer_board,
                    color: Colors.white,
                    size: centerButtonSize * 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(int index) {
    _animationController.forward().then((_) {
      _animationController.reverse();
      // Navigate to the screen by pushing it onto the stack
      // This preserves navigation history so back button works
      _navigateToScreen(context, index);
    });
  }

  void _navigateToScreen(BuildContext context, int index) {
    Widget? screen;
    
    switch (index) {
      case 0:
        // For home, pop until we reach the root (which has the nav bar)
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 1:
        screen = const SmartRemindersScreen();
        break;
      case 2:
        screen = const OBDDashboardScreen();
        break;
      case 3:
        screen = const ServiceCentersScreen();
        break;
      case 4:
        screen = const SettingsScreen();
        break;
    }
    
    if (screen != null) {
      // Check if we're already on this screen to avoid duplicate navigation
      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null && currentRoute.settings.name == screen.runtimeType.toString()) {
        return; // Already on this screen
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.iconSize = 24,
    this.fontSize = 12,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.r(3); // Responsive spacing
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF062117)  // Dark green in dark mode
                        : Colors.white,             // White in light mode
                    size: widget.iconSize,
                  ),
                  SizedBox(height: spacing),
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF062117)  // Dark green in dark mode
                            : Colors.white,             // White in light mode
                        height: 1.0, // Tight line height to reduce space
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CurvedBackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  
  const _CurvedBackgroundPainter({required this.isDarkMode});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode 
          ? Colors.white           // White when dark mode is ON
          : const Color(0xFF062117)  // Dark green when dark mode is OFF
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);  // Start at top-left corner

    // Left edge straight - goes to the start of the curve
    path.lineTo(size.width * 0.32, 0);

    // Left curve down into notch - curve to go under the button
    path.cubicTo(
      size.width * 0.36, 0,                    // First control point: slight horizontal movement
      size.width * 0.40, size.height * 0.25,  // Second control point: deeper descent
      size.width * 0.43, size.height * 0.55,  // End point: left side of the notch
    );

    // Bottom of notch - create a curve that goes under the button
    path.cubicTo(
      size.width * 0.46, size.height * 0.8,   // First control point: slightly deeper for perfect curve
      size.width * 0.54, size.height * 0.8,   // Second control point: symmetric depth under button
      size.width * 0.57, size.height * 0.55,  // End point: right side of the notch
    );

    // Right curve back up - mirror of the left curve
    path.cubicTo(
      size.width * 0.60, size.height * 0.25,  // First control point: deeper ascent
      size.width * 0.64, 0,                   // Second control point: slight horizontal movement
      size.width * 0.68, 0,                   // End point: back to top edge
    );

    // Right edge straight - completes the top edge
    path.lineTo(size.width, 0);               // Go to top-right corner
    path.lineTo(size.width, size.height);    // Go to bottom-right corner
    path.lineTo(0, size.height);              // Go to bottom-left corner
    path.close();                             // Close the path

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}