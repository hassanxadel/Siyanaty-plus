import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../services/security/local_unlock_service.dart';
import '../../../services/security/authentication_manager.dart';
import '../../../services/security/otp_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/app_dialog.dart';
import 'otp_verification_screen.dart';

class UnlockScreen extends StatefulWidget {
  final VoidCallback? onUnlockSuccess;

  const UnlockScreen({
    super.key,
    this.onUnlockSuccess,
  });

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final LocalUnlockService _localUnlockService = LocalUnlockService();
  final AuthenticationManager _authManager = AuthenticationManager();
  
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showBiometricPrompt = true;
  int _remainingAttempts = 5;
  int? _storedPinLength; // Known PIN length; null for PINs saved before length tracking

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load the stored PIN length so the dots match and entry auto-verifies
    _localUnlockService.getPinLength().then((length) {
      if (mounted && length != null) {
        setState(() => _storedPinLength = length);
      }
    });

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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _initializeUnlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _showBiometricPrompt) {
      // Re-attempt biometric authentication when app resumes
      _attemptBiometricAuth();
    }
  }

  Future<void> _initializeUnlock() async {
    _fadeController.forward();
    
    // Check remaining attempts
    _remainingAttempts = await _localUnlockService.getRemainingAttempts();
    
    // Check if locked out
    final isLockedOut = await _localUnlockService.isLockedOut();
    if (isLockedOut) {
      _showLockedOutDialog();
      return;
    }

    // Attempt biometric authentication first
    await _attemptBiometricAuth();
  }

  Future<void> _attemptBiometricAuth() async {
    if (!_showBiometricPrompt) return;

    final biometricEnabled = await _localUnlockService.isBiometricEnabled();
    final biometricAvailable = await _localUnlockService.isBiometricAvailable();
    
    if (biometricEnabled && biometricAvailable) {
      final result = await _localUnlockService.authenticateWithBiometrics();
      
      switch (result) {
        case BiometricAuthResult.success:
          _onUnlockSuccess();
          break;
        case BiometricAuthResult.failed:
          setState(() {
            _showBiometricPrompt = false;
          });
          break;
        case BiometricAuthResult.notAvailable:
        case BiometricAuthResult.notEnrolled:
          setState(() {
            _showBiometricPrompt = false;
          });
          break;
        case BiometricAuthResult.lockedOut:
        case BiometricAuthResult.permanentlyLockedOut:
          _showError('Biometric authentication is locked out. Please use your PIN.');
          setState(() {
            _showBiometricPrompt = false;
          });
          break;
        case BiometricAuthResult.error:
          setState(() {
            _showBiometricPrompt = false;
          });
          break;
      }
    } else {
      setState(() {
        _showBiometricPrompt = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: context.responsivePadding(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                SizedBox(height: context.responsiveSpacing(24)),
                _buildHeader(),
                SizedBox(height: context.responsiveSpacing(16)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_showBiometricPrompt)
                        _buildBiometricPrompt()
                      else
                        _buildNumericKeypad(),
                      if (_errorMessage != null) ...[
                        SizedBox(height: context.r(10)),
                        _buildErrorMessage(),
                      ],
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: context.r(90),
          height: context.r(90),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(45)),
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
            size: context.responsiveIconSize(44),
          ),
        ),
        SizedBox(height: context.r(16)),
        Text(
          'Enter PIN',
          style: context.responsiveTextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: AppTheme.getThemeAwareTextColor(context),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.r(16)),
        // PIN dots directly under the title
        _buildPinDisplay(),
      ],
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.1),
                AppTheme.darkAccentGreen.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _attemptBiometricAuth,
              borderRadius: BorderRadius.circular(60),
              child: const Center(
                child: Icon(
                  Icons.fingerprint,
                  color: AppTheme.primaryGreen,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Touch the fingerprint sensor',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Orbitron',
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            setState(() {
              _showBiometricPrompt = false;
            });
          },
          child: const Text(
            'Use PIN instead',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_storedPinLength ?? 6, (index) {
              bool isFilled = index < _pin.length;
              bool isActive = index == _pin.length;
              
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
        SizedBox(height: context.r(14)),
        _buildKeypadRow(['4', '5', '6']),
        SizedBox(height: context.r(14)),
        _buildKeypadRow(['7', '8', '9']),
        SizedBox(height: context.r(14)),
        _buildKeypadRow(['biometric', '0', 'backspace']),
        SizedBox(height: context.r(12)),
        // Legacy fallback only: PINs saved before length tracking may be
        // 4-5 digits, so manual verification is needed until the length
        // is learned on the first successful unlock
        if (_storedPinLength == null && _pin.length >= 4 && _pin.length < 6)
          _buildVerifyButton(),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: context.r(160),
      height: context.responsiveButtonHeight(42),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.darkAccentGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: context.r(10),
            offset: Offset(0, context.r(5)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _verifyPin,
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(24)),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: context.r(24),
                    height: context.r(24),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Verify PIN',
                    style: context.responsiveTextStyle(
                      fontSize: 15,
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

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final buttonSize = context.r(78);
    final borderRadius = context.responsiveBorderRadius(39);
    
    if (key == 'biometric') {
      return Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _showBiometricPrompt = true;
              });
              _attemptBiometricAuth();
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(
              child: Icon(
                Icons.fingerprint,
                color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                size: context.responsiveIconSize(28),
              ),
            ),
          ),
        ),
      );
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
                BoxShadow(
                  color: AppTheme.secondaryGreen.withOpacity(0.3),
                  blurRadius: context.r(18),
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
                      fontSize: 30,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_remainingAttempts < 5)
          Padding(
            padding: EdgeInsets.only(bottom: context.r(12)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.r(16), vertical: context.r(8)),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(8)),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '$_remainingAttempts attempts remaining',
                style: context.responsiveTextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ),
        // Bottom links placed at the screen corners, iPhone passcode style
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.r(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _showForgotPinDialog,
                child: Text(
                  'Forgot PIN?',
                  style: context.responsiveTextStyle(
                    fontSize: 14,
                    color: AppTheme.getThemeAwareTextColor(context),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              TextButton(
                onPressed: _showSignOutDialog,
                child: Text(
                  'Sign Out',
                  style: context.responsiveTextStyle(
                    fontSize: 14,
                    color: AppTheme.getThemeAwareTextColor(context),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    if (_pin.length >= 6) return;

    setState(() {
      _pin += digit;
    });

    // Auto-verify once the PIN reaches its stored length
    // (6 is the fallback for PINs saved before length tracking)
    if (_pin.length == (_storedPinLength ?? 6)) {
      _verifyPin();
    }
  }

  void _removeLastDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _localUnlockService.authenticateWithPin(_pin);
    
    switch (result) {
      case PinAuthResult.success:
        _onUnlockSuccess();
        break;
      case PinAuthResult.failed:
        _remainingAttempts = await _localUnlockService.getRemainingAttempts();
        _showError('Incorrect PIN. $_remainingAttempts attempts remaining.');
        _performShakeAnimation();
        setState(() {
          _pin = '';
          _isLoading = false;
        });
        break;
      case PinAuthResult.lockedOut:
        _showLockedOutDialog();
        break;
      case PinAuthResult.notSet:
        _showError('PIN not configured. Please sign in again.');
        setState(() {
          _isLoading = false;
        });
        break;
      case PinAuthResult.error:
        _showError('Authentication error. Please try again.');
        setState(() {
          _pin = '';
          _isLoading = false;
        });
        break;
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _performShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _onUnlockSuccess() {
    HapticFeedback.mediumImpact();
    
    if (widget.onUnlockSuccess != null) {
      widget.onUnlockSuccess!();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _showLockedOutDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: 'Account Locked',
        message:
            'Too many failed attempts. Please sign in with your email and password to reset your PIN.',
        icon: Icons.lock_clock,
        accent: AppDialog.destructive,
        actions: [
          AppDialogAction(
            label: 'Sign In',
            accent: AppDialog.destructive,
            filled: true,
            onTap: () {
              Navigator.of(dialogContext).pop();
              _signOutAndNavigateToLogin();
            },
          ),
        ],
      ),
    );
  }

  void _showForgotPinDialog() async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Forgot PIN?',
      message:
          'We will email a verification code to your registered address so you can set a new PIN.',
      icon: Icons.lock_reset_rounded,
      confirmLabel: 'Send Code',
    );

    if (confirmed == true && mounted) {
      _initiateEmailVerificationForPinReset();
    }
  }

  Future<void> _initiateEmailVerificationForPinReset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user email from Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showError('No user found. Please sign in again.');
        setState(() => _isLoading = false);
        return;
      }

      final email = user.email!;
      final otpService = OtpService();

      // Send OTP to email
      final success = await otpService.sendOtpToEmail(email);

      if (mounted) {
        if (success) {
          // Show success message with OTP for development
          final otp = otpService.currentOtpForTesting;
          
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(email: email),
            ),
          );

          // Show development OTP in snackbar (remove in production)
          AppSnackbar.show(context, 
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OTP sent successfully!',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Development OTP: $otp',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent to: $email',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          _showError('Failed to send verification code. Please try again.');
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showError('An error occurred: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSignOutDialog() async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Sign Out',
      message:
          'You will need to sign in again with your email and password to continue.',
      icon: Icons.logout_rounded,
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      _signOutAndNavigateToLogin();
    }
  }

  Future<void> _signOutAndNavigateToLogin() async {
    await _authManager.signOut();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
