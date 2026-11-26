import 'package:flutter/material.dart';
import '../../shared/constants/app_theme.dart';
import 'pin_dots.dart';
import 'pin_keypad.dart';

/// Shared, responsive body for every full-screen PIN page (Enter / Set /
/// Confirm / Change). It owns the one piece that used to be duplicated and
/// sized wrong in each screen: the layout that fits a header, PIN dots and the
/// 3×4 keypad into the available space without ever overflowing.
///
/// It is NOT a [Scaffold] — the screen supplies the `backgroundGreen` scaffold
/// and [SafeArea] — so it can be dropped into either flow while each screen
/// keeps its own state machine. Sizing flows through [PinKeypad.responsiveSize]
/// (width AND height aware), the column centres when it fits and scrolls when
/// it does not, and the header icon shrinks then hides on very short screens.
class PinPadBody extends StatelessWidget {
  final IconData icon;

  /// Title — rendered in the app yellow ([AppTheme.lightBackground]).
  final String title;

  /// One-line subtitle in white; the only secondary text on the screen.
  final String subtitle;

  final int pinLength;
  final int filledCount;

  /// Drives the horizontal "wrong PIN" shake of the dots; null = no shake.
  final Animation<double>? shake;

  final String? errorText;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  /// When false the keypad is inert and dimmed (verifying / locked out).
  final bool keypadEnabled;

  /// Hide the delete key until a digit has been entered (iOS behaviour).
  final bool showBackspace;

  /// Optional top-bar widgets (back button, Cancel, Reset).
  final Widget? topLeft;
  final Widget? topRight;

  /// Optional widget shown directly above the keypad (e.g. the 4/6-digit
  /// length selector, or the legacy verify button).
  final Widget? aboveKeypad;

  /// Optional footer (attempts banner, links, security hint).
  final Widget? footer;

  const PinPadBody({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pinLength,
    required this.filledCount,
    required this.onDigit,
    required this.onBackspace,
    this.shake,
    this.errorText,
    this.onBiometric,
    this.keypadEnabled = true,
    this.showBackspace = true,
    this.topLeft,
    this.topRight,
    this.aboveKeypad,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keySize = PinKeypad.responsiveSize(constraints);
        final h = constraints.maxHeight;
        final showIcon = h >= 440; // hidden in landscape / very short screens
        final iconSize = h < 620 ? 56.0 : 72.0;
        final titleSize = h < 620 ? 22.0 : 26.0;
        final dotSize = (keySize * 0.22).clamp(12.0, 18.0);

        Widget dots = PinDots(
          length: pinLength,
          filledCount: filledCount,
          dotSize: dotSize,
        );
        if (shake != null) {
          dots = AnimatedBuilder(
            animation: shake!,
            builder: (_, child) =>
                Transform.translate(offset: Offset(shake!.value, 0), child: child),
            child: dots,
          );
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          topLeft ?? const SizedBox(width: 44),
                          const Spacer(),
                          topRight ?? const SizedBox(width: 44),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    if (showIcon) ...[
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: AppTheme.lightBackground.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: AppTheme.lightBackground,
                          size: iconSize * 0.46,
                        ),
                      ),
                      SizedBox(height: h < 620 ? 12 : 18),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          color: AppTheme.lightBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontFamily: 'Orbitron',
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: h < 620 ? 18 : 24),
                    dots,
                    // Fixed-height slot so showing/hiding the error never
                    // shifts the keypad.
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: errorText == null
                            ? null
                            : Text(
                                errorText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.errorColor,
                                  fontFamily: 'Orbitron',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    if (aboveKeypad != null) ...[
                      aboveKeypad!,
                      const SizedBox(height: 16),
                    ],
                    Opacity(
                      opacity: keypadEnabled ? 1.0 : 0.4,
                      child: PinKeypad(
                        keySize: keySize,
                        enabled: keypadEnabled,
                        showBackspace: showBackspace,
                        onDigit: onDigit,
                        onBackspace: onBackspace,
                        onBiometric: onBiometric,
                      ),
                    ),
                    const Spacer(flex: 2),
                    if (footer != null) footer!,
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
