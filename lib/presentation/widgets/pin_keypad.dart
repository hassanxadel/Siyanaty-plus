import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../shared/constants/app_theme.dart';

/// The app's single numeric PIN keypad — a 3×4 grid (1-9, then an optional
/// biometric key, 0 and backspace).
///
/// Presentation only: it renders the keys and routes taps to callbacks, so each
/// call site keeps its own tap logic (and its own haptic). This is deliberately
/// the *only* keypad in the app — the unlock screen, PIN setup and the License
/// gate all render through it, which is why the keypad can never drift apart.
///
/// Size is driven by [keySize] rather than a fixed value so the full-screen PIN
/// pages pass their responsive size while the License bottom sheet can clamp a
/// `LayoutBuilder`-derived size. Everything else (radius, glyph size, spacing)
/// is derived from [keySize], so one number keeps a key perfectly round at any
/// scale.
class PinKeypad extends StatelessWidget {
  /// Width/height of a single round key, in logical pixels.
  final double keySize;

  /// When false every key is inert (used while a PIN is being verified).
  final bool enabled;

  /// Called with the tapped digit ('0'–'9').
  final ValueChanged<String> onDigit;

  /// Called when the backspace key is tapped.
  final VoidCallback onBackspace;

  /// When non-null a fingerprint key is shown in the bottom-left slot; when
  /// null that slot is an empty spacer (PIN setup / License gate have no
  /// biometric entry point).
  final VoidCallback? onBiometric;

  /// When false the delete key slot is left empty — iOS shows the delete key
  /// only once at least one digit has been entered.
  final bool showBackspace;

  const PinKeypad({
    super.key,
    required this.keySize,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
    this.showBackspace = true,
  });

  /// The single source of truth for keypad sizing. Derives the round-key
  /// diameter from BOTH the available width and height so the 3×4 grid always
  /// fits — on a 320px phone, in landscape, or at a large text scale — and
  /// clamps it to a comfortable touch-target range. Every call site (the two
  /// full-screen PIN pages and the License bottom sheet) sizes through this, so
  /// the keypad is identical everywhere and can never overflow.
  static double responsiveSize(BoxConstraints c) {
    final byWidth = c.maxWidth / 4.2;
    final byHeight = c.maxHeight.isFinite ? c.maxHeight / 7.5 : double.infinity;
    return math.min(byWidth, byHeight).clamp(56.0, 80.0);
  }

  @override
  Widget build(BuildContext context) {
    final gap = keySize * 0.18;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, const ['1', '2', '3']),
        SizedBox(height: gap),
        _row(context, const ['4', '5', '6']),
        SizedBox(height: gap),
        _row(context, const ['7', '8', '9']),
        SizedBox(height: gap),
        _row(context, [
          onBiometric != null ? 'biometric' : '',
          '0',
          showBackspace ? 'backspace' : '',
        ]),
      ],
    );
  }

  Widget _row(BuildContext context, List<String> keys) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) => _key(context, k)).toList(),
      );

  Widget _key(BuildContext context, String key) {
    final radius = keySize / 2;
    if (key.isEmpty) return SizedBox(width: keySize, height: keySize);

    final isDigit = key != 'backspace' && key != 'biometric';
    final VoidCallback? onTap = !enabled
        ? null
        : key == 'backspace'
            ? onBackspace
            : key == 'biometric'
                ? onBiometric
                : () => onDigit(key);

    final semanticLabel = key == 'backspace'
        ? 'Delete'
        : key == 'biometric'
            ? 'Use fingerprint'
            : 'Key $key';

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
      width: keySize,
      height: keySize,
      decoration: BoxDecoration(
        gradient: isDigit
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDigit
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: keySize * 0.13,
                  offset: Offset(0, keySize * 0.06),
                ),
                BoxShadow(
                  color: AppTheme.secondaryGreen.withOpacity(0.3),
                  blurRadius: keySize * 0.23,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppTheme.primaryGreen.withOpacity(0.3),
          highlightColor: AppTheme.primaryGreen.withOpacity(0.1),
          child: Center(child: _label(context, key)),
        ),
      ),
      ),
    );
  }

  Widget _label(BuildContext context, String key) {
    final color = AppTheme.getThemeAwareTextColor(context);
    if (key == 'backspace') {
      return Icon(Icons.backspace_outlined, color: color, size: keySize * 0.3);
    }
    if (key == 'biometric') {
      return Icon(Icons.fingerprint,
          color: color.withOpacity(0.7), size: keySize * 0.36);
    }
    return Text(
      key,
      style: TextStyle(
        fontSize: keySize * 0.36,
        fontWeight: FontWeight.w500,
        color: color,
        fontFamily: 'Orbitron',
      ),
    );
  }
}
