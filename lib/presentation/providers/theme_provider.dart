import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode)
/// Persists theme preference in device storage and notifies UI of changes
class ThemeProvider extends ChangeNotifier {
  /// Current theme state (false = light, true = dark)
  bool _isDarkMode = false;
  /// Storage key for persisting theme preference
  static const String _themeKey = 'isDarkMode';

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
  /// Sets default to light theme if no preference is saved
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Save current theme preference to device storage
  /// Persists user's theme choice across app sessions
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}