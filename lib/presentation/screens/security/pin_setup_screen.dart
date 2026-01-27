import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../services/security/local_unlock_service.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      resizeToAvoidBottomInset: false, // Don't resize when keyboard appears
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: context.r(12)),   
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPinDisplay(),
                    SizedBox(height: context.r(16)),
                    _buildNumericKeypad(),
                    if (_errorMessage != null) ...[
                      SizedBox(height: context.r(10)),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
              _buildFooter(),
              SizedBox(height: context.r(12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    String subtitle;
    
    // Check if we're in reset mode (forgot PIN flow) - skip current PIN entry
    final isResetMode = widget.isResettingPin;
    
    if (_isChangingPin && !_isConfirmingPin && _oldPin.isEmpty && !isResetMode) {
      title = 'Enter Current PIN';
      subtitle = 'Please enter your current PIN to continue';
    } else if (_isConfirmingPin) {
      title = 'Confirm Your PIN';
      subtitle = 'Please re-enter your PIN to confirm';
    } else {
      title = (_isChangingPin || isResetMode) ? 'Set New PIN' : 'Set Up PIN';
      subtitle = isResetMode 
          ? 'Create a new 4-6 digit PIN for your app'
          : 'Create a 4-6 digit PIN to secure your app';
    }

    return Column(
      children: [
        Row(
          children: [
            if (Navigator.canPop(context))
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppTheme.primaryGreen,
                  size: context.responsiveIconSize(20),
                ),
              ),
            const Spacer(),
            if (_isChangingPin && _oldPin.isNotEmpty)
              TextButton(
                onPressed: _resetPinSetup,
                child: Text(
                  'Reset',
                  style: context.responsiveTextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.r(8)),
        Container(
          width: context.r(60),
          height: context.r(60),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(30)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: context.r(15),
                offset: Offset(0, context.r(8)),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_outline,
            color: Colors.white,
            size: context.responsiveIconSize(30),
          ),
        ),
        SizedBox(height: context.r(12)),
        Text(
          title,
          style: context.responsiveTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: AppTheme.primaryGreen,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.r(6)),
        Text(
          subtitle,
          style: context.responsiveTextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            fontFamily: 'Orbitron',
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPinDisplay() {
    final currentPinLength = _getCurrentPin().length;
    
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              bool isFilled = index < currentPinLength;
              bool isActive = index == currentPinLength;
              
              return Container(
                margin: EdgeInsets.symmetric(horizontal: context.r(6)),
                width: context.r(16),
                height: context.r(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled 
                      ? AppTheme.primaryGreen 
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive 
                        ? AppTheme.primaryGreen 
                        : AppTheme.primaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isFilled
                    ? Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: context.responsiveIconSize(10),
                      )
                    : null,
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        SizedBox(height: context.r(8)),
        _buildKeypadRow(['4', '5', '6']),
        SizedBox(height: context.r(8)),
        _buildKeypadRow(['7', '8', '9']),
        SizedBox(height: context.r(8)),
        _buildKeypadRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final buttonSize = context.r(60);
    final borderRadius = context.responsiveBorderRadius(30);
    
    if (key.isEmpty) {
      return SizedBox(width: buttonSize, height: buttonSize);
    }

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: key == 'backspace'
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkAccentGreen,
                  AppTheme.backgroundGreen,
                ],
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: key == 'backspace'
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: context.r(10),
                  offset: Offset(0, context.r(5)),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onKeypadTap(key),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: key == 'backspace'
                ? Icon(
                    Icons.backspace_outlined,
                    color: AppTheme.getThemeAwareTextColor(context),
                    size: context.responsiveIconSize(22),
                  )
                : Text(
                    key,
                    style: context.responsiveTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    return Column(
      children: [
        if (_getCurrentPin().length >= 4)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.darkAccentGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Your PIN will be stored securely on this device',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.5),
            fontFamily: 'Orbitron',
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
    if (currentPin.length >= 6) return;

    setState(() {
      if (_isChangingPin && _oldPin.isEmpty) {
        _currentPin += digit;
      } else if (_isConfirmingPin) {
        _confirmPin += digit;
      } else {
        _currentPin += digit;
      }
    });
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
          _performShakeAnimation();
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
          _performShakeAnimation();
          setState(() {
            _confirmPin = '';
            _isLoading = false;
          });
        }
      } else {
        // First PIN entry, move to confirmation
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

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _performShakeAnimation() {
    _shakeController.forward().then((_) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PIN reset successfully',
            style: TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to home and clear all previous screens
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      return;
    }
    
    // For changing PIN from settings, navigate back with success result
    if (_isChangingPin) {
      Navigator.pop(context, true);
      return;
    }
    
    // For initial PIN setup, show success message
    ScaffoldMessenger.of(context).showSnackBar(
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
