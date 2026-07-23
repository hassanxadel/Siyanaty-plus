import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Custom styled snackbar utility
///
/// All snackbars share the app's "backlit HUD" language: dark green gradient
/// pill, glowing accent border, and an accent-tinted icon chip. The accent
/// color communicates the message type.
class CustomSnackbar {
  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      accentColor: AppTheme.secondaryGreen,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      accentColor: const Color(0xFFE57373),
      icon: Icons.error_outline,
    );
  }

  /// Show an info snackbar
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      accentColor: const Color(0xFF64B5F6),
      icon: Icons.info_outline,
    );
  }

  /// Show a warning snackbar
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      accentColor: const Color(0xFFFFB74D),
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Internal method to show snackbar with custom styling
  static void _show(
    BuildContext context,
    String message, {
    required Color accentColor,
    required IconData icon,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
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
                    fontSize: 13,
                    color: AppTheme.lightBackground,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show a custom snackbar with the standard design and an optional
  /// custom accent color and icon
  static void showGradient(
    BuildContext context,
    String message, {
    List<Color>? gradientColors,
    IconData? icon,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      accentColor: gradientColors?.first ?? AppTheme.secondaryGreen,
      icon: icon ?? Icons.notifications_none_rounded,
      duration: duration,
    );
  }
}

/// Adapter that renders any legacy [SnackBar] in the app-wide custom style.
///
/// Call sites keep building their existing `SnackBar(...)`; this adapter maps
/// its background color to a semantic accent (error/warning/info/success) and
/// re-renders the content inside the standard glow pill, so every
/// notification in the app shares one design.
class AppSnackbar {
  static void show(BuildContext context, SnackBar original) {
    if (!context.mounted) return;

    final accent = _accentFor(original.backgroundColor);
    final content = original.content;

    // Many call sites build a Row containing their own icon + text. This
    // wrapper supplies the icon chip itself, so pull out just the message
    // text — otherwise the snackbar shows two icons side by side.
    final extracted = _extractMessage(content);

    final Widget body;
    if (extracted != null) {
      body = Text(
        extracted,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppTheme.lightBackground,
          letterSpacing: 0.3,
        ),
      );
    } else {
      // Unrecognised layout: keep it as-is, just restyle its text defaults
      body = DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppTheme.lightBackground,
        ),
        child: content,
      );
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.3),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(accent),
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: body),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: original.duration,
        action: original.action,
      ),
    );
  }

  /// Find the message text inside a snackbar's content widget.
  ///
  /// Call sites commonly wrap their message in a Row with an icon, or in
  /// Expanded/Padding/Container layers. Returns the longest text found (the
  /// message rather than a short label), or null if the layout is not
  /// something we can safely unwrap.
  static String? _extractMessage(Widget widget) {
    final found = <String>[];

    void visit(Widget w, int depth) {
      if (depth > 6) return; // guard against pathological trees
      if (w is Text) {
        final data = w.data;
        if (data != null && data.trim().isNotEmpty) found.add(data);
        return;
      }
      if (w is Expanded) return visit(w.child, depth + 1);
      if (w is Flexible) return visit(w.child, depth + 1);
      if (w is Padding) {
        if (w.child != null) visit(w.child!, depth + 1);
        return;
      }
      if (w is Center) {
        if (w.child != null) visit(w.child!, depth + 1);
        return;
      }
      if (w is SizedBox && w.child != null) return visit(w.child!, depth + 1);
      if (w is Container && w.child != null) return visit(w.child!, depth + 1);
      if (w is DefaultTextStyle) return visit(w.child, depth + 1);
      if (w is Flex) {
        for (final child in w.children) {
          visit(child, depth + 1);
        }
      }
    }

    visit(widget, 0);
    if (found.isEmpty) return null;
    found.sort((a, b) => b.length.compareTo(a.length));
    return found.first;
  }

  /// Map a legacy background color onto one of the four semantic accents
  static Color _accentFor(Color? color) {
    if (color == null) return AppTheme.secondaryGreen;
    if (color.red > 170 && color.green < 130 && color.blue < 130) {
      return const Color(0xFFE57373); // error
    }
    if (color.red > 200 && color.green > 110 && color.green < 200 && color.blue < 100) {
      return const Color(0xFFFFB74D); // warning
    }
    if (color.blue > 150 && color.red < 130) {
      return const Color(0xFF64B5F6); // info
    }
    return AppTheme.secondaryGreen; // success / neutral
  }

  static IconData _iconFor(Color accent) {
    if (accent == const Color(0xFFE57373)) return Icons.error_outline;
    if (accent == const Color(0xFFFFB74D)) return Icons.warning_amber_outlined;
    if (accent == const Color(0xFF64B5F6)) return Icons.info_outline;
    return Icons.check_circle_outline;
  }
}
