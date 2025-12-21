import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode)
/// Persists theme preference in device storage and notifies UI of changes
class ThemeProvider extends ChangeNotifier {
  /// Current theme state (true = dark, false = light)
  /// Default is dark mode for new installations
  bool _isDarkMode = true;
  /// Storage key for persisting theme preference
  static const String _themeKey = 'isDarkMode';
  /// Key to track if user has ever set a theme preference
  static const String _hasSetThemeKey = 'hasSetThemePreference';

  /// Getter for current theme state
  bool get isDarkMode => _isDarkMode;
  
  /// Getter for Flutter ThemeMode enum based on current state
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Constructor loads saved theme preference from device storage
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Toggle between light and dark themes
  /// Automatically saves preference and notifies UI
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  /// Set theme to specific mode (light or dark)
  /// Automatically saves preference and notifies UI
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }

  /// Load theme preference from device storage
  /// Sets default to DARK theme for new installations
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has ever set a theme preference
      final hasSetTheme = prefs.getBool(_hasSetThemeKey) ?? false;
      
      if (hasSetTheme) {
        // User has set a preference before, use their saved preference
        _isDarkMode = prefs.getBool(_themeKey) ?? true;
      } else {
        // First time user - default to dark mode
        _isDarkMode = true;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Default to dark mode on error
      _isDarkMode = true;
    }
  }

  /// Save current theme preference to device storage
  /// Persists user's theme choice across app sessions
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      // Mark that user has set a theme preference
      await prefs.setBool(_hasSetThemeKey, true);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}