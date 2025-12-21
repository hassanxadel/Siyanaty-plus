import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/security/local_unlock_service.dart';
import '../../../services/security/authentication_manager.dart';
import '../auth/login_screen.dart';

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
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 60),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_showBiometricPrompt)
                        _buildBiometricPrompt()
                      else ...[
                        _buildPinDisplay(),
                        const SizedBox(height: 40),
                        _buildNumericKeypad(),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: AppTheme.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _showBiometricPrompt 
              ? 'Use your fingerprint or PIN to unlock'
              : 'Enter your PIN to unlock the app',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            fontFamily: 'Orbitron',
          ),
          textAlign: TextAlign.center,
        ),
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
            children: List.generate(6, (index) {
              bool isFilled = index < _pin.length;
              bool isActive = index == _pin.length;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 20,
                height: 20,
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
                    ? const Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 12,
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
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildKeypadRow(['biometric', '0', 'backspace']),
        const SizedBox(height: 24),
        // Verify button for 4-5 digit PINs
        if (_pin.length >= 4 && _pin.length < 6)
          _buildVerifyButton(),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.darkAccentGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _verifyPin,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify PIN',
                    style: TextStyle(
                      fontSize: 16,
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
    if (key == 'biometric') {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
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
            borderRadius: BorderRadius.circular(40),
            child: Center(
              child: Icon(
                Icons.fingerprint,
                color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                size: 32,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
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
        borderRadius: BorderRadius.circular(40),
        boxShadow: key == 'backspace'
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onKeypadTap(key),
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: key == 'backspace'
                ? Icon(
                    Icons.backspace_outlined,
                    color: AppTheme.getThemeAwareTextColor(context),
                    size: 24,
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 24,
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
      children: [
        if (_remainingAttempts < 5)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              '$_remainingAttempts attempts remaining',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _showSignOutDialog,
          child: const Text(
            'Sign out and use different account',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontFamily: 'Orbitron',
              fontSize: 12,
            ),
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

    // Auto-verify when PIN reaches 6 digits (full PIN length)
    // Don't auto-verify at 4 digits as user may have set a 5 or 6 digit PIN
    if (_pin.length == 6) {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Account Locked',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Too many failed attempts. Please sign in with your email and password to reset your PIN.',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOutAndNavigateToLogin();
            },
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to sign in again with your email and password.',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOutAndNavigateToLogin();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
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
