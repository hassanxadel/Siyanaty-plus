import 'package:flutter/material.dart';
import '../../shared/constants/app_theme.dart';

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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF062117) : Colors.white,
      ),
      child: SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBarItem(
                    icon: Icons.home,
                    label: 'Home',
                    isActive: widget.currentIndex == 0,
                    onTap: () => _handleTap(0),
                  ),
                  _NavBarItem(
                    icon: Icons.alarm,
                    label: 'Reminders',
                    isActive: widget.currentIndex == 1,
                    onTap: () => _handleTap(1),
                  ),
                  // Empty space for center button
                  const SizedBox(width: 60),
                  _NavBarItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    isActive: widget.currentIndex == 3,
                    onTap: () => _handleTap(3),
                  ),
                  _NavBarItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    isActive: widget.currentIndex == 4,
                    onTap: () => _handleTap(4),
                  ),
                ],
              ),
            ),
            // Center floating button with black circular background
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 30,
              top: -15,
              child: GestureDetector(
                onTap: () => _handleTap(2),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.developer_board,
                    color: Colors.white,
                    size: 30,
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
      widget.onTap(index);
      switch (index) {
        case 0:
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          break;
        case 1:
          Navigator.of(context).pushNamed('/reminders');
          break;
        case 2:
          Navigator.of(context).pushNamed('/obd');
          break;
        case 3:
          Navigator.of(context).pushNamed('/location');
          break;
        case 4:
          Navigator.of(context).pushNamed('/settings');
          break;
      }
    });
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isBlue;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
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
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                                 Icon(
                   widget.icon,
                   color: widget.isBlue 
                       ? Colors.blue 
                       : (Theme.of(context).brightness == Brightness.dark 
                           ? const Color(0xFF0c3c24)  // Dark green when dark mode ON
                           : Colors.white),            // White when dark mode OFF
                   size: 24,
                 ),
                 const SizedBox(height: 8),
                 Text(
                   widget.label,
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.w500,
                     color: widget.isBlue 
                         ? Colors.blue 
                         : (Theme.of(context).brightness == Brightness.dark 
                             ? const Color(0xFF0c3c24)  // Dark green when dark mode ON
                             : Colors.white),            // White when dark mode OFF
                   ),
                 ),
              ],
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
          ? Colors.white              // White when dark mode is ON
          : const Color(0xFF0c3c24)  // Dark green when dark mode is OFF
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