import 'package:flutter/material.dart';

/// Global navigation service that provides navigation to main app screens from anywhere
/// This allows the bottom navigation bar to work from any screen in the app
class GlobalNavigationService {
  static final GlobalNavigationService _instance = GlobalNavigationService._internal();
  factory GlobalNavigationService() => _instance;
  GlobalNavigationService._internal();

  /// Global key for accessing the main app navigator
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Callback to navigate to a specific tab in the main app
  static Function(int)? onNavigateToTab;

  /// Navigate to Home screen (index 0)
  static void navigateToHome() {
    if (onNavigateToTab != null) {
      onNavigateToTab!(0);
    }
  }

  /// Navigate to Reminders screen (index 1)
  static void navigateToReminders() {
    if (onNavigateToTab != null) {
      onNavigateToTab!(1);
    }
  }

  /// Navigate to OBD screen (index 2)
  static void navigateToOBD() {
    if (onNavigateToTab != null) {
      onNavigateToTab!(2);
    }
  }

  /// Navigate to Service Centers screen (index 3)
  static void navigateToServiceCenters() {
    if (onNavigateToTab != null) {
      onNavigateToTab!(3);
    }
  }

  /// Navigate to Settings screen (index 4)
  static void navigateToSettings() {
    if (onNavigateToTab != null) {
      onNavigateToTab!(4);
    }
  }

  /// Pop all routes until reaching the main app with bottom nav bar
  static void popToRoot() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Pop until we can't pop anymore (back to root)
      navigator.popUntil((route) => route.isFirst);
    }
  }

  /// Navigate to a specific tab by pushing the screen onto the stack
  /// This preserves navigation history so back button works
  static void navigateToTab(int index) {
    if (onNavigateToTab != null) {
      onNavigateToTab!(index);
    }
  }

  /// Navigate to a specific tab and pop all routes (old behavior, kept for compatibility)
  static void navigateToTabAndClearStack(int index) {
    popToRoot();
    if (onNavigateToTab != null) {
      onNavigateToTab!(index);
    }
  }
}
