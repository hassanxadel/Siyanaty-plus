import 'package:flutter/material.dart';
import '../../shared/constants/app_theme.dart';

/// The app's single "Done" capsule for a reminder: [AppTheme.lightBackground]
/// fill with a [AppTheme.backgroundGreen] label. Reused by the Home card and the
/// Reminders screen so the button can never drift between them.
///
/// Pure presentation: the caller supplies [onPressed] (and any haptic /
/// completion logic) and [busy] to show a spinner and block taps. Both screens
/// complete through the same `ReminderService.markReminderCompleted`, so the
/// recurring-reschedule behavior is shared at the service level.
class ReminderDoneButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool busy;
  final String semanticLabel;

  const ReminderDoneButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            // Vertical padding lifts the hit area to ~44pt.
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.backgroundGreen),
                      ),
                    )
                  : const Text('Done',
                      style: TextStyle(
                          color: AppTheme.backgroundGreen,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
            ),
          ),
        ),
      ),
    );
  }
}
