import 'package:flutter/material.dart';
import '../../shared/constants/app_theme.dart';

/// App-wide pop-up card styled in the "backlit HUD" language:
/// dark green gradient card, glowing accent rim, icon chip, and a pair of
/// pill actions.
///
/// **Every dialog, confirmation and pop-up card in the app should come from
/// here** — never a stock [AlertDialog] — so they all look identical.
///
/// Three entry points cover the cases in this app:
/// * [show]    — a two-action confirmation. Returns `true`/`false`/`null`.
/// * [message] — a single-action notice (info, error, "no results"). Returns when dismissed.
/// * [custom]  — the same shell wrapped around arbitrary [content] (forms, lists, progress).
///
/// For a pop-up built entirely by hand, use [AppDialogPanel] directly so it
/// still gets the same chrome.
class AppDialog {
  /// Accent used for destructive actions (sign out, delete, ...)
  static const Color destructive = Color(0xFFE57373);

  /// Accent used for warnings / partial-success notices.
  static const Color warning = Color(0xFFFFB02E);

  /// Two-action confirmation dialog.
  ///
  /// Returns `true` when the confirm action is tapped, `false` on cancel, and
  /// `null` if dismissed by tapping outside.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    bool isDestructive = false,

    /// Tints the cancel action — use when *cancelling* is the destructive
    /// choice (e.g. "Discard" next to "Save").
    Color? cancelAccent,

    /// Set false when the choice must not be dismissed by tapping outside.
    bool barrierDismissible = true,
  }) {
    final accent = isDestructive ? destructive : AppTheme.secondaryGreen;

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: title,
        message: message,
        icon: icon,
        accent: accent,
        actions: [
          AppDialogAction(
            label: cancelLabel,
            accent: cancelAccent,
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction(
            label: confirmLabel,
            accent: accent,
            filled: true,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }

  /// Single-action notice — information, an error, or an empty result.
  ///
  /// Pass [isError] for the red treatment or [isWarning] for amber.
  static Future<void> message(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    String buttonLabel = 'OK',
    bool isError = false,
    bool isWarning = false,
    bool barrierDismissible = true,
  }) {
    final accent = isError
        ? destructive
        : isWarning
            ? warning
            : AppTheme.secondaryGreen;

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: title,
        message: message,
        icon: icon,
        accent: accent,
        actions: [
          AppDialogAction(
            label: buttonLabel,
            accent: accent,
            filled: true,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// The same card shell wrapped around arbitrary [content] — use for forms,
  /// selection lists and progress pop-ups.
  ///
  /// [actionsBuilder] receives the dialog's own context so actions can pop it.
  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    String? message,
    required IconData icon,
    required Widget content,
    Color? accent,
    List<Widget> Function(BuildContext dialogContext)? actionsBuilder,

    /// Label for the default single dismiss action (ignored when
    /// [actionsBuilder] is supplied).
    String closeLabel = 'Close',
    bool barrierDismissible = true,
    double maxWidth = 420,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: title,
        message: message,
        icon: icon,
        accent: accent ?? AppTheme.secondaryGreen,
        maxWidth: maxWidth,
        content: content,
        actions: actionsBuilder?.call(dialogContext) ??
            [
              AppDialogAction(
                label: closeLabel,
                accent: accent ?? AppTheme.secondaryGreen,
                filled: true,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ],
      ),
    );
  }
}

/// The pop-up card itself: gradient panel, glowing rim, icon chip, title,
/// optional message, optional [content], and a row of pill [actions].
///
/// Exposed so screens that need a bespoke pop-up still get identical chrome.
class AppDialogPanel extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color accent;
  final Widget? content;
  final List<Widget> actions;
  final double maxWidth;

  const AppDialogPanel({
    super.key,
    required this.title,
    required this.icon,
    this.message,
    this.accent = AppTheme.secondaryGreen,
    this.content,
    this.actions = const [],
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.secondaryGreen.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: AppTheme.glowShadow(elevated: true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon chip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppTheme.lightBackground,
                  letterSpacing: 0.5,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.lightBackground.withOpacity(0.7),
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: 20),
                // Flexible + scroll so long forms and lists never overflow.
                Flexible(
                  child: SingleChildScrollView(child: content!),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Actions are laid out as equal-width pills so the pair is always centred.
  Widget _buildActions() {
    if (actions.length == 1) {
      return SizedBox(width: double.infinity, child: actions.first);
    }
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }
}

/// A single pill action inside an [AppDialogPanel].
class AppDialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool filled;
  final IconData? icon;

  const AppDialogAction({
    super.key,
    required this.label,
    required this.onTap,
    this.accent,
    this.filled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.secondaryGreen;

    // Decoration on the Container, Material inside: an Ink decoration would be
    // clipped to the Material's bounds and the glow would render as a square.
    return Container(
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.18) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(filled ? 0.7 : 0.5),
          width: 1,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: (filled || accent != null)
                        ? color
                        : AppTheme.lightBackground,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: filled ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      // An explicitly-passed accent tints the label even when
                      // unfilled, so a destructive "Discard" still reads red.
                      color: (filled || accent != null)
                          ? color
                          : AppTheme.lightBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text field styled to match [AppDialogPanel] — use for any input inside a
/// pop-up so forms look the same everywhere.
class AppDialogField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppDialogField({
    super.key,
    this.controller,
    this.initialValue,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        // Shadow on a wrapper because the field paints its own fill.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.glowShadow(),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.lightBackground.withOpacity(0.4),
                fontFamily: 'Orbitron',
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color: AppTheme.secondaryGreen.withOpacity(0.8),
                size: 20,
              ),
              filled: true,
              fillColor: AppTheme.backgroundGreen.withOpacity(0.7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.secondaryGreen.withOpacity(0.35),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.secondaryGreen.withOpacity(0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.secondaryGreen,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
