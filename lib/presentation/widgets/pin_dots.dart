import 'package:flutter/material.dart';
import '../../shared/constants/app_theme.dart';

/// The app's single PIN-dot indicator — reused by the unlock screen, PIN setup
/// and the License gate so the dots can never drift apart.
///
/// Filled dots fill with the app yellow ([AppTheme.lightBackground]) and pop in
/// with a small scale animation; empty dots are outlined. Digits always read
/// left-to-right, even in an RTL (Arabic) layout, exactly like the iOS passcode
/// screen. The pop is skipped when the OS "reduce motion" setting is on.
class PinDots extends StatelessWidget {
  /// Total number of dots to show (the expected PIN length).
  final int length;

  /// How many dots are currently filled (digits entered so far).
  final int filledCount;

  /// Diameter of a single dot; scales with the surrounding layout.
  final double dotSize;

  const PinDots({
    super.key,
    required this.length,
    required this.filledCount,
    this.dotSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'PIN, $filledCount of $length digits entered',
      child: Directionality(
        // PIN digits always fill left-to-right, even in RTL layouts.
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final filled = i < filledCount;
            return AnimatedContainer(
              duration:
                  reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: dotSize * 0.45),
              width: dotSize,
              height: dotSize,
              transformAlignment: Alignment.center,
              // Empty dots sit slightly smaller so filling one "pops" it in.
              transform: Matrix4.diagonal3Values(
                filled ? 1.0 : 0.82,
                filled ? 1.0 : 0.82,
                1.0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppTheme.lightBackground : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? AppTheme.lightBackground
                      : AppTheme.lightBackground.withOpacity(0.35),
                  width: 2,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
