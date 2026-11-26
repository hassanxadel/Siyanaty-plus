import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../services/security/local_unlock_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/pin_pad_body.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangingPin;
  final bool isResettingPin; // When true, skip current PIN verification (forgot PIN flow)
  final VoidCallback? onPinSetup;

  const PinSetupScreen({
    super.key,
    this.isChangingPin = false,
    this.isResettingPin = false,
    this.onPinSetup,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with TickerProviderStateMixin {
  final LocalUnlockService _localUnlockService = LocalUnlockService();
  
  String _currentPin = '';
  String _confirmPin = '';
  String _oldPin = '';
  bool _isConfirmingPin = false;
  bool _isChangingPin = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _pinLength = 4; // User-selected length for the new PIN (4 or 6)
  int? _storedPinLength; // Length of the existing PIN when changing (null if unknown)

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    _isChangingPin = widget.isChangingPin;
    
    // If resetting PIN (forgot PIN flow), skip current PIN verification
    // by setting _oldPin to a placeholder value
    if (widget.isResettingPin) {
      _oldPin = 'RESET_MODE';
    }

    // Load the stored PIN length so the "Enter Current PIN" step shows
    // the right number of dots and can auto-verify
    if (widget.isChangingPin) {
      _localUnlockService.getPinLength().then((length) {
        if (mounted && length != null) {
          setState(() => _storedPinLength = length);
        }
      });
    }

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      resizeToAvoidBottomInset: false, // Don't resize when keyboard appears
      body: SafeArea(
        child: PinPadBody(
          icon: _modeIcon,
          title: _modeTitle,
          subtitle: _modeSubtitle,
          pinLength: _targetLength,
          filledCount: _getCurrentPin().length,
          shake: _shakeAnimation,
          errorText: _errorMessage,
          keypadEnabled: !_isLoading,
          showBackspace: _getCurrentPin().isNotEmpty,
          onDigit: _onKeypadTap,
          onBackspace: () => _onKeypadTap('backspace'),
          topLeft: canPop
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.back,
                      color: AppTheme.lightBackground),
                )
              : null,
          topRight: (_isChangingPin && _oldPin.isNotEmpty)
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _resetPinSetup,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppTheme.lightBackground,
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                    ),
                  ),
                )
              : null,
          aboveKeypad: _aboveKeypad(),
          footer: _footer(),
        ),
      ),
    );
  }

  IconData get _modeIcon {
    if (_isEnteringOldPin) return CupertinoIcons.lock_fill;
    if (_isConfirmingPin) return CupertinoIcons.checkmark_shield;
    return (_isChangingPin || widget.isResettingPin)
        ? CupertinoIcons.lock_rotation
        : CupertinoIcons.lock_shield;
  }

  String get _modeTitle {
    if (_isEnteringOldPin) return 'Enter current PIN';
    if (_isConfirmingPin) return 'Confirm your PIN';
    return (_isChangingPin || widget.isResettingPin)
        ? 'Set a new PIN'
        : 'Create your PIN';
  }

  String get _modeSubtitle {
    if (_isEnteringOldPin) return 'Confirm it’s you before changing your PIN';
    if (_isConfirmingPin) return 'Re-enter the same digits to confirm';
    return 'Your PIN keeps your car data private';
  }

  /// Widget shown directly above the keypad for the current step.
  Widget? _aboveKeypad() {
    // First step of create/new PIN: let the user pick a 4- or 6-digit PIN.
    if (!_isConfirmingPin && !_isEnteringOldPin) return _buildLengthSelector();
    // Legacy only: an old PIN of unknown length can't auto-submit, so a
    // button is offered once at least 4 digits are entered.
    if (_isEnteringOldPin &&
        _storedPinLength == null &&
        _getCurrentPin().length >= 4) {
      return _buildLegacyContinueButton();
    }
    return null;
  }

  /// Whether the user is on the "Enter Current PIN" step of the change flow
  bool get _isEnteringOldPin =>
      _isChangingPin && _oldPin.isEmpty && !widget.isResettingPin;

  /// Number of digits expected for the PIN currently being entered
  int get _targetLength =>
      _isEnteringOldPin ? (_storedPinLength ?? 6) : _pinLength;

  Widget _buildLengthSelector() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [4, 6].map((length) {
        final isSelected = _pinLength == length;
        return GestureDetector(
          onTap: () {
            if (_pinLength == length) return;
            HapticFeedback.lightImpact();
            setState(() {
              _pinLength = length;
              _currentPin = '';
              _confirmPin = '';
              _errorMessage = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: context.r(8)),
            padding: EdgeInsets.symmetric(
              horizontal: context.r(20),
              vertical: context.r(10),
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundGreen,
                        AppTheme.darkAccentGreen,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.secondaryGreen.withOpacity(0.6)
                    : AppTheme.primaryGreen.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.secondaryGreen.withOpacity(0.3),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$length Digits',
              style: context.responsiveTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.lightBackground
                    : Colors.white.withOpacity(0.6),
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        );
        }).toList(),
      ),
    );
  }

  Widget _buildLegacyContinueButton() => GradientButton(
        label: _getButtonText(),
        onPressed: _onContinue,
      );

  Widget _footer() {
    return Text(
      'Your PIN is stored securely on this device',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.5),
        fontFamily: 'Orbitron',
      ),
    );
  }

  String _getCurrentPin() {
    if (_isChangingPin && _oldPin.isEmpty) {
      return _currentPin;
    } else if (_isConfirmingPin) {
      return _confirmPin;
    } else {
      return _currentPin;
    }
  }

  String _getButtonText() {
    if (_isChangingPin && _oldPin.isEmpty) {
      return 'Continue';
    } else if (_isConfirmingPin) {
      return 'Confirm PIN';
    } else {
      return 'Set PIN';
    }
  }

  void _onKeypadTap(String key) {
    HapticFeedback.lightImpact();
    
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
    });

    if (key == 'backspace') {
      _removeLastDigit();
    } else {
      _addDigit(key);
    }
  }

  void _addDigit(String digit) {
    final currentPin = _getCurrentPin();
    if (currentPin.length >= _targetLength) return;

    setState(() {
      if (_isChangingPin && _oldPin.isEmpty) {
        _currentPin += digit;
      } else if (_isConfirmingPin) {
        _confirmPin += digit;
      } else {
        _currentPin += digit;
      }
    });

    // Auto-advance once the expected number of digits is entered.
    // Legacy exception: when changing a PIN whose length is unknown,
    // the footer button is used instead of auto-advancing.
    if (_getCurrentPin().length == _targetLength &&
        (!_isEnteringOldPin || _storedPinLength != null)) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _onContinue();
      });
    }
  }

  void _removeLastDigit() {
    setState(() {
      if (_isChangingPin && _oldPin.isEmpty) {
        if (_currentPin.isNotEmpty) {
          _currentPin = _currentPin.substring(0, _currentPin.length - 1);
        }
      } else if (_isConfirmingPin) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_currentPin.isNotEmpty) {
          _currentPin = _currentPin.substring(0, _currentPin.length - 1);
        }
      }
    });
  }

  void _onContinue() async {
    if (_isLoading) return;

    final currentPin = _getCurrentPin();
    if (currentPin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we're in reset mode (forgot PIN flow) - skip current PIN verification
      final isResetMode = widget.isResettingPin;
      
      if (_isChangingPin && _oldPin.isEmpty && !isResetMode) {
        // Verify old PIN first (only when not in reset mode)
        final isValid = await _localUnlockService.authenticateWithPin(_currentPin);
        if (isValid == PinAuthResult.success) {
          setState(() {
            _oldPin = _currentPin;
            _currentPin = '';
            _isLoading = false;
          });
        } else {
          _showError('Incorrect current PIN');
          setState(() {
            _currentPin = '';
            _isLoading = false;
          });
        }
      } else if (_isConfirmingPin) {
        // Confirm PIN matches
        if (_currentPin == _confirmPin) {
          bool success;
          
          if (isResetMode) {
            // For reset mode, directly set up new PIN (overwrite)
            success = await _localUnlockService.setupPin(_currentPin);
          } else if (_isChangingPin) {
            success = await _localUnlockService.changePin(_oldPin, _currentPin);
          } else {
            success = await _localUnlockService.setupPin(_currentPin);
          }

          if (success) {
            _showSuccessAndNavigate();
          } else {
            _showError('Failed to set PIN. Please try again.');
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          _showError('PINs do not match. Please try again.');
          setState(() {
            _confirmPin = '';
            _isLoading = false;
          });
        }
      } else {
        // First PIN entry — reject obviously guessable PINs before confirm.
        if (_isTrivialPin(_currentPin)) {
          _showError('Choose a less predictable PIN — avoid 1234, 0000 or repeated digits.');
          setState(() {
            _currentPin = '';
            _isLoading = false;
          });
          return;
        }
        // When changing an existing PIN, the new one must be different.
        if (_isChangingPin && !isResetMode && _currentPin == _oldPin) {
          _showError('New PIN must be different from your current PIN.');
          setState(() {
            _currentPin = '';
            _isLoading = false;
          });
          return;
        }
        // Move to confirmation
        setState(() {
          _isConfirmingPin = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('An error occurred. Please try again.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Rejects obviously guessable PINs: all-same-digit (0000, 1111…) and
  /// ascending/descending runs (1234, 4321). Length-agnostic, so it covers
  /// both 4- and 6-digit PINs.
  bool _isTrivialPin(String pin) {
    if (pin.length < 4) return true;
    if (pin.split('').toSet().length == 1) return true; // all identical
    bool asc = true, desc = true;
    for (var i = 1; i < pin.length; i++) {
      final diff = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      if (diff != 1) asc = false;
      if (diff != -1) desc = false;
    }
    return asc || desc;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _performShakeAnimation();
  }

  void _performShakeAnimation() {
    // Respect the OS "reduce motion" accessibility setting.
    if (MediaQuery.of(context).disableAnimations) return;
    _shakeController.forward(from: 0).then((_) {
      _shakeController.reverse();
    });
  }

  void _resetPinSetup() {
    setState(() {
      _currentPin = '';
      _confirmPin = '';
      _oldPin = '';
      _isConfirmingPin = false;
      _errorMessage = null;
    });
  }

  void _showSuccessAndNavigate() {
    // For resetting PIN (forgot PIN flow), navigate to home
    if (widget.isResettingPin) {
      AppSnackbar.show(context, 
        const SnackBar(
          content: Text(
            'PIN reset successfully',
            style: TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // There is no '/home' named route — MaterialApp uses `home:` with no
      // routes table, so pushNamedAndRemoveUntil('/home') threw "Could not
      // find a generator for route", was swallowed by the caller's catch as
      // "An error occurred", and left the user stranded here even though the
      // new PIN had already been saved. Pop back to the root instead and let
      // SecurityWrapper decide what comes next.
      widget.onPinSetup?.call();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // For changing PIN from settings, navigate back with success result
    if (_isChangingPin) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context, true);
      } else {
        widget.onPinSetup?.call();
      }
      return;
    }
    
    // For initial PIN setup, show success message
    AppSnackbar.show(context, 
      const SnackBar(
        content: Text(
          'PIN set up successfully',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Call callback if provided - SecurityWrapper will handle navigation
    if (widget.onPinSetup != null) {
      widget.onPinSetup!();
    }
  }
}
