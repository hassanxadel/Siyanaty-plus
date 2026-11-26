import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/constants/app_theme.dart';
import '../../services/security/local_unlock_service.dart';
import 'gradient_button.dart';
import 'pin_dots.dart';
import 'pin_keypad.dart';

/// Outcome of the License PIN gate. The caller only opens the License screen
/// for [success]; both [cancelled] and a swipe-dismiss keep it closed.
enum LicensePinResult { success, cancelled, forgotPin }

/// iOS-style modal bottom sheet that gates the License screen behind the app's
/// PIN. Verification goes through the shared [LocalUnlockService] (the same
/// lockout the unlock screen uses) — there is no separate PIN check here.
///
/// Returns [LicensePinResult.success] only after a correct PIN; dismissing the
/// sheet (Cancel, swipe-down or the scrim) returns [LicensePinResult.cancelled]
/// and never opens the License.
Future<LicensePinResult> showLicensePinSheet(
  BuildContext context, {
  required String carLabel,
}) async {
  final result = await showModalBottomSheet<LicensePinResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => _LicensePinSheet(carLabel: carLabel),
  );
  return result ?? LicensePinResult.cancelled;
}

class _LicensePinSheet extends StatefulWidget {
  final String carLabel;
  const _LicensePinSheet({required this.carLabel});

  @override
  State<_LicensePinSheet> createState() => _LicensePinSheetState();
}

class _LicensePinSheetState extends State<_LicensePinSheet>
    with SingleTickerProviderStateMixin {
  final LocalUnlockService _unlock = LocalUnlockService();

  String _pin = '';
  String? _error;
  bool _verifying = false;
  bool _locked = false;

  /// How many dots to show. Backfilled from the stored PIN length; falls back
  /// to 6 for PINs saved before length tracking existed.
  int _targetLen = 6;

  /// True when the stored length is unknown (legacy PIN): a 4–5 digit PIN then
  /// needs an explicit confirm since it can't auto-submit at a known length.
  bool _legacyLength = false;

  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final len = await _unlock.getPinLength();
    final locked = await _unlock.isLockedOut();
    if (!mounted) return;
    setState(() {
      _targetLen = (len ?? 6).clamp(4, 6);
      _legacyLength = len == null;
      if (locked) {
        _locked = true;
        _error = 'Too many attempts. Reset your PIN to continue.';
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_verifying || _locked || _pin.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += d;
      _error = null;
    });
    // Auto-verify once the known length is reached (or at the 6-digit max).
    if (_pin.length == _targetLen || _pin.length == 6) _verify();
  }

  void _onBackspace() {
    if (_verifying || _locked || _pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    if (_pin.length < 4) return;
    setState(() => _verifying = true);
    final result = await _unlock.authenticateWithPin(_pin);
    if (!mounted) return;

    switch (result) {
      case PinAuthResult.success:
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(LicensePinResult.success);
        return;
      case PinAuthResult.lockedOut:
        HapticFeedback.heavyImpact();
        setState(() {
          _error = 'Too many attempts. Reset your PIN to continue.';
          _pin = '';
          _verifying = false;
          _locked = true;
        });
        return;
      default:
        HapticFeedback.heavyImpact();
        final left = await _unlock.getRemainingAttempts();
        if (!mounted) return;
        _shake();
        setState(() {
          _error =
              'Wrong PIN · $left ${left == 1 ? 'attempt' : 'attempts'} left';
          _pin = '';
          _verifying = false;
        });
    }
  }

  void _shake() {
    // Respect the OS "reduce motion" setting.
    if (MediaQuery.of(context).disableAnimations) return;
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Round key sized from the available width and clamped so it never
    // overflows on a 320px phone nor balloons on a tablet.
    final showLegacyConfirm =
        _legacyLength && _pin.length >= 4 && _pin.length < 6 && !_locked;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.backgroundGreen.withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                  color: AppTheme.lightBackground.withOpacity(0.25), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 16 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // Grabber.
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Cancel (top-left).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      onPressed: () => Navigator.of(context)
                          .pop(LicensePinResult.cancelled),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.lightBackground,
                          fontFamily: 'Orbitron',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _header(),
                  const SizedBox(height: 20),
                  _dots(),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 20,
                    child: _error != null
                        ? Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontFamily: 'Orbitron',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return PinKeypad(
                          keySize: PinKeypad.responsiveSize(c),
                          enabled: !_verifying && !_locked,
                          showBackspace: _pin.isNotEmpty,
                          onDigit: _onDigit,
                          onBackspace: _onBackspace,
                        );
                      },
                    ),
                  ),
                  if (showLegacyConfirm) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: GradientButton(
                        label: 'Unlock',
                        isLoading: _verifying,
                        onPressed: _verify,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  CupertinoButton(
                    onPressed: () => Navigator.of(context)
                        .pop(LicensePinResult.forgotPin),
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.lightBackground.withOpacity(0.14),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(CupertinoIcons.lock_shield,
              color: AppTheme.lightBackground, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter PIN to view license',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: Colors.white,
          ),
        ),
        if (widget.carLabel.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.carLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Orbitron',
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dots() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        // Decaying sine gives an iOS-style side-to-side shake.
        final dx = _shakeCtrl.isAnimating
            ? 12 *
                (1 - _shakeCtrl.value) *
                math.sin(_shakeCtrl.value * math.pi * 6)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: PinDots(length: _targetLen, filledCount: _pin.length, dotSize: 15),
    );
  }
}
