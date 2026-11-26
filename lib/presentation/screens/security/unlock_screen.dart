import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../services/security/local_unlock_service.dart';
import '../../../services/security/authentication_manager.dart';
import '../auth/login_screen.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/pin_pad_body.dart';

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
      backgroundColor: AppTheme.backgroundGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _showBiometricPrompt
              ? _buildBiometricPrompt()
              : PinPadBody(
                  icon: CupertinoIcons.lock_fill,
                  title: 'Enter your PIN',
                  subtitle: 'Your PIN keeps your car data private',
                  pinLength: _storedPinLength ?? 6,
                  filledCount: _pin.length,
                  shake: _shakeAnimation,
                  errorText: _errorMessage,
                  keypadEnabled: !_isLoading,
                  showBackspace: _pin.isNotEmpty,
                  onDigit: _onKeypadTap,
                  onBackspace: () => _onKeypadTap('backspace'),
                  onBiometric: () {
                    setState(() => _showBiometricPrompt = true);
                    _attemptBiometricAuth();
                  },
                  aboveKeypad: (_storedPinLength == null &&
                          _pin.length >= 4 &&
                          _pin.length < 6)
                      ? _buildVerifyButton()
                      : null,
                  footer: _footer(),
                ),
        ),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.lightBackground.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.lightBackground.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _attemptBiometricAuth,
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint,
                      color: AppTheme.lightBackground,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unlock with biometrics',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Orbitron',
                color: AppTheme.lightBackground,
              ),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                setState(() {
                  _showBiometricPrompt = false;
                });
              },
              child: Text(
                'Use PIN instead',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
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


  Widget _footer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_remainingAttempts < LocalUnlockService.maxFailedAttempts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '$_remainingAttempts ${_remainingAttempts == 1 ? 'attempt' : 'attempts'} remaining',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.lightBackground.withOpacity(0.8),
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        // Bottom links, iPhone passcode style: Forgot PIN in the app yellow,
        // Sign Out in red.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text(
                'Forgot PIN?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            TextButton(
              onPressed: _showSignOutDialog,
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.errorColor,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
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
        HapticFeedback.heavyImpact();
        _showError(
            'Wrong PIN · $_remainingAttempts ${_remainingAttempts == 1 ? 'attempt' : 'attempts'} left');
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
    // Respect the OS "reduce motion" accessibility setting.
    if (MediaQuery.of(context).disableAnimations) return;
    _shakeController.forward(from: 0).then((_) {
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
          'You will be signed out. Sign in again with your email, Google or Apple account to set a new PIN.',
      icon: Icons.lock_reset_rounded,
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      _signOutAndNavigateToLogin();
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
