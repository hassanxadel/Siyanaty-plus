import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

/// Wrapper widget that adds bottom navigation bar to any screen
/// This ensures the nav bar is always functional regardless of navigation stack
class ScreenWithNavBar extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool showNavBar;

  const ScreenWithNavBar({
    super.key,
    required this.child,
    this.currentIndex = -1, // -1 means no tab is selected (for non-main screens)
    this.showNavBar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showNavBar) {
      return child;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Navigation is handled by GlobalNavigationService in BottomNavBar
          // No need to do anything here
        },
      ),
    );
  }
}
