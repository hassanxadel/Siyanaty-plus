import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Automotive Green Color Palette (New Design)
  static const Color primaryGreen = Color(0xFF467D47); // Primary Green - Buttons, headers, highlights
  static const Color darkAccentGreen = Color(0xFF1D5B37); // Dark Accent Green - Secondary buttons, icons, tiles  
  static const Color backgroundGreen = Color(0xFF062117); // Background/Shadow Green - Dark mode areas, cards
  static const Color lightBackground = Color(0xFFDBDEA6); // Light Background/Highlight - Light backgrounds, form fields
  static const Color secondaryGreen = Color(0xFF739958); // Secondary Green - Text highlights, progress indicators, badges
  
  // Legacy support colors (keeping for smooth transition)
  static const Color accentGreen = Color(0xFF467D47);
  static const Color lightGreen = Color(0xFFDBDEA6);
  static const Color darkForest = Color(0xFF062117);
  static const Color mintGreen = Color(0xFF739958);
  static const Color paleGreen = Color(0xFFDBDEA6);
  static const Color oliveAccent = Color(0xFF739958);
  static const Color darkGray = Color(0xFF1D5B37);
  
  // Light Mode Surface Colors (when dark mode is OFF)
  static const Color lightModeBackground = Colors.white; // White background for light mode
  static const Color lightModeCardBackground = Color(0xFFF5F5F5); // Light gray for cards
  static const Color lightModeSurfaceColor = Colors.white;
  static const Color lightModeTextColor = backgroundGreen; // Dark green text
  
  // Dark Mode Surface Colors (when dark mode is ON)
  static const Color darkModeBackground = backgroundGreen; // Dark green background
  static const Color darkModeCardBackground = Color(0xFF0D2D21); // Darker green for cards
  static const Color darkModeSurfaceColor = backgroundGreen;
  static const Color darkModeTextColor = lightBackground; // Light yellow text
  
  // Status Colors (Updated to automotive theme)
  static const Color successColor = primaryGreen;
  static const Color warningColor = Color(0xFFFFB02E);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color infoColor = secondaryGreen;
  
  // Health Status Colors
  static const Color goodHealth = primaryGreen;
  static const Color warningHealth = secondaryGreen;
  static const Color criticalHealth = Color(0xFFE74C3C);
  
  // Modern Automotive Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, darkAccentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryGreen, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [backgroundGreen, darkAccentGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), lightBackground],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [darkModeCardBackground, darkModeSurfaceColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Additional gradients for backward compatibility
  static const LinearGradient greenGradient = LinearGradient(
    colors: [primaryGreen, secondaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient grayGradient = LinearGradient(
    colors: [darkAccentGreen, secondaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme-aware color getters
  static Color getThemeAwareBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkModeBackground : lightModeBackground;
  }
  
  static Color getThemeAwareCardBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkModeCardBackground : lightModeCardBackground;
  }
  
  static Color getThemeAwareTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkModeTextColor : lightModeTextColor;
  }
  
  static Color getThemeAwareSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkModeSurfaceColor : lightModeSurfaceColor;
  }
  
  static Color getThemeAwareIconColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? lightBackground : primaryGreen;
  }
  
  static Color getThemeAwareBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? lightBackground.withOpacity(0.3) : primaryGreen.withOpacity(0.3);
  }

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: secondaryGreen,
          tertiary: accentGreen,
          surface: lightModeSurfaceColor,
          error: errorColor,
          onPrimary: Colors.white,
          onSecondary: backgroundGreen,
          onSurface: lightModeTextColor,
        ),
        scaffoldBackgroundColor: lightModeBackground,
        fontFamily: 'Orbitron',
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Orbitron',
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: primaryGreen.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreen,
            side: const BorderSide(color: primaryGreen, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: lightModeCardBackground,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryGreen, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: lightModeBackground,
          selectedItemColor: lightBackground,
          unselectedItemColor: secondaryGreen,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            color: lightModeTextColor,
            fontFamily: 'Orbitron',
          ),
        ),
        iconTheme: const IconThemeData(
          color: primaryGreen,
          size: 24,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        colorScheme: const ColorScheme.dark(
          primary: primaryGreen,
          secondary: secondaryGreen,
          tertiary: darkAccentGreen,
          surface: darkModeSurfaceColor,
          error: errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkModeTextColor,
        ),
        scaffoldBackgroundColor: darkModeBackground,
        fontFamily: 'Orbitron',
        appBarTheme: const AppBarTheme(
          backgroundColor: darkAccentGreen,
          foregroundColor: lightBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: lightBackground,
            letterSpacing: 0.5,
            fontFamily: 'Orbitron',
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: lightBackground,
            elevation: 4,
            shadowColor: primaryGreen.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: lightBackground,
            side: const BorderSide(color: lightBackground, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: darkModeCardBackground,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: lightBackground, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          filled: true,
          fillColor: darkModeCardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: TextStyle(
            color: lightBackground.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: lightBackground,
          foregroundColor: darkModeBackground,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkModeBackground,
          selectedItemColor: lightBackground,
          unselectedItemColor: darkAccentGreen,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            color: darkModeTextColor,
            fontFamily: 'Orbitron',
          ),
        ),
        iconTheme: const IconThemeData(
          color: lightBackground,
          size: 24,
        ),
      );

  // Helper methods for component styles
  static BoxDecoration cardDecoration({Color? color, BuildContext? context}) {
    final cardColor = color ?? (context != null ? getThemeAwareCardBackground(context) : lightModeCardBackground);
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 15,
          offset: const Offset(0, 5),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration modernCardDecoration({Color? color, bool elevated = false, BuildContext? context}) {
    final cardColor = color ?? (context != null ? getThemeAwareCardBackground(context) : lightModeCardBackground);
    final borderColor = context != null ? getThemeAwareBorderColor(context) : lightBackground.withOpacity(0.1);
    
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      boxShadow: elevated ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ] : [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 3),
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration(Gradient gradient) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static Color getHealthColor(double healthPercentage) {
    if (healthPercentage >= 80) return goodHealth;
    if (healthPercentage >= 60) return warningHealth;
    return criticalHealth;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'excellent':
      case 'completed':
        return successColor;
      case 'warning':
      case 'due':
      case 'pending':
        return warningColor;
      case 'critical':
      case 'overdue':
      case 'error':
        return errorColor;
      case 'info':
      case 'active':
        return infoColor;
      default:
        return darkForest;
    }
  }
} 