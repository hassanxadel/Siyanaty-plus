import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Custom styled snackbar utility
class CustomSnackbar {
  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppTheme.primaryGreen,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFFD32F2F),
      icon: Icons.error_outline,
    );
  }

  /// Show an info snackbar
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFF1976D2),
      icon: Icons.info_outline,
    );
  }

  /// Show a warning snackbar
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFFF57C00),
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Internal method to show snackbar with custom styling
  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  /// Show a custom snackbar with gradient background
  static void showGradient(
    BuildContext context,
    String message, {
    List<Color>? gradientColors,
    IconData? icon,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final colors = gradientColors ?? [
      AppTheme.primaryGreen,
      AppTheme.darkAccentGreen,
    ];

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: duration ?? const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
