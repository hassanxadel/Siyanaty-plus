import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../services/security/authentication_manager.dart';

class MfaVerificationScreen extends StatefulWidget {
  final String userId;
  final String deviceId;
  final VoidCallback? onVerificationSuccess;

  const MfaVerificationScreen({
    super.key,
    required this.userId,
    required this.deviceId,
    this.onVerificationSuccess,
  });

  @override
  State<MfaVerificationScreen> createState() => _MfaVerificationScreenState();
}

class _MfaVerificationScreenState extends State<MfaVerificationScreen>
    with TickerProviderStateMixin {
  final AuthenticationManager _authManager = AuthenticationManager();
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  bool _useEmail = false; // Track whether to use email or SMS
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
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

    _fadeController.forward();
    _sendInitialCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _fadeController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _sendInitialCode() async {
    final success = await _authManager.sendMfaCode(widget.userId, useEmail: _useEmail);
    if (success) {
      _startResendCountdown();
    } else {
      _showError('Failed to send verification code. Please try again.');
    }
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
      });
      
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildCodeInput(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                  const SizedBox(height: 32),
                  _buildResendSection(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        // App Logo
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify Your Identity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: AppTheme.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit verification code sent to your registered phone number',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            fontFamily: 'Orbitron',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkAccentGreen,
                      AppTheme.backgroundGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNodes[index].hasFocus
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) => _onCodeChanged(index, value),
                ),
              );
            }),
          ),
        );
      },
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

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          'Didn\'t receive the code?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 8),
        
        // Toggle button to switch between SMS and Email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isResending ? null : _toggleVerificationMethod,
              icon: Icon(
                _useEmail ? Icons.phone : Icons.email,
                color: AppTheme.primaryGreen,
                size: 18,
              ),
              label: Text(
                _useEmail ? 'Try SMS Instead' : 'Try Email Instead',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        ),
        
        if (_resendCountdown > 0)
          Text(
            'Resend code in ${_resendCountdown}s',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.5),
              fontFamily: 'Orbitron',
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.darkAccentGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isResending ? null : _resendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Resend ${_useEmail ? "Email" : "SMS"} Code',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron',
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        if (_isLoading)
          const CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isCodeComplete()
                    ? [
                        AppTheme.primaryGreen,
                        AppTheme.darkAccentGreen,
                      ]
                    : [
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isCodeComplete()
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _isCodeComplete() ? _verifyCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'This helps us keep your account secure',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.5),
            fontFamily: 'Orbitron',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _onCodeChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, remove focus
        _focusNodes[index].unfocus();
      }
    } else {
      // Move to previous field if current is empty
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Auto-verify when all fields are filled
    if (_isCodeComplete()) {
      _verifyCode();
    }
  }

  bool _isCodeComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getEnteredCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    if (_isLoading || !_isCodeComplete()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AppLogger.info('Verifying MFA code');
    final code = _getEnteredCode();
    final result = await _authManager.completeMfaVerification(
      widget.userId,
      widget.deviceId,
      code,
    );

    AppLogger.info('MFA verification result: ${result.success}');

    if (result.success) {
      AppLogger.info('MFA verification success, calling onVerificationSuccess');
      _onVerificationSuccess();
    } else {
      AppLogger.error('MFA verification failed: ${result.error}');
      _showError(result.error ?? 'Invalid verification code');
      _clearCode();
      _performShakeAnimation();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final success = await _authManager.sendMfaCode(widget.userId, useEmail: _useEmail);
    
    if (success) {
      _startResendCountdown();
      _showSuccessMessage('Verification code sent successfully');
    } else {
      _showError('Failed to resend code. Please try again.');
    }

    setState(() {
      _isResending = false;
    });
  }

  void _toggleVerificationMethod() {
    setState(() {
      _useEmail = !_useEmail;
      _errorMessage = null;
    });
    _sendInitialCode();
  }

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _performShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _onVerificationSuccess() {
    AppLogger.info('_onVerificationSuccess called');
    if (!mounted) {
      AppLogger.warning('_onVerificationSuccess called but widget not mounted');
      return;
    }
    
    AppLogger.info('Widget is mounted, proceeding with success flow');
    HapticFeedback.mediumImpact();
    
    _showSuccessMessage('Verification successful!');
    
    if (widget.onVerificationSuccess != null) {
      AppLogger.info('Calling onVerificationSuccess callback');
      widget.onVerificationSuccess!();
    }
    
    // Pop back to login screen to allow SecurityWrapper to re-initialize
    // The authStateChanges listener is a fallback if reload works
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        AppLogger.info('Popping MFA screen after verification success');
        Navigator.of(context).pop();
      }
    });
  }
}
