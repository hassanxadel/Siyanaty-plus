import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/custom_snackbar.dart';
import '../../../services/security/authentication_manager.dart';
import '../../widgets/app_dialog.dart';

class MfaVerificationScreen extends StatefulWidget {
  final String userId;
  final String deviceId;
  final VoidCallback? onVerificationSuccess;

  /// Called after the user signs out from this screen. Needed when the screen
  /// is shown as a root route (SecurityWrapper's MFA gate), where there is no
  /// route to pop back to.
  final VoidCallback? onSignOut;

  const MfaVerificationScreen({
    super.key,
    required this.userId,
    required this.deviceId,
    this.onVerificationSuccess,
    this.onSignOut,
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
  // SMS is disabled - always use email verification
  // ignore: unused_field
  final bool _useEmail = true; // Always use email (SMS is disabled)
  
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
    // Always use email verification (SMS is disabled)
    final success = await _authManager.sendMfaCode(widget.userId, useEmail: true);
    if (success) {
      _startResendCountdown();
      // Note: Email service may not be configured - code is always logged to console
      _showSuccessMessage('Verification code generated! Check your Email for the code.');
    } else {
      _showError('Failed to generate verification code. Please try again.');
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
          child: Column(
            children: [
              // Logo stays pinned at the top; everything else centers below
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (Navigator.canPop(context))
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
            ),
          Image.asset(
            'assets/images/logo.png',
            width: 160,
            height: 60,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
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
              BoxShadow(
                color: AppTheme.secondaryGreen.withOpacity(0.3),
                blurRadius: 18,
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
          'Enter the 6-digit verification code sent to your Email',
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
                    BoxShadow(
                      color: AppTheme.secondaryGreen.withOpacity(0.3),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
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
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
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
        
        // Info text about email verification
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGreen.withOpacity(0.3),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.email,
                color: AppTheme.primaryGreen,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Check your email inbox & spam folder',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
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
                BoxShadow(
                  color: AppTheme.secondaryGreen.withOpacity(0.3),
                  blurRadius: 18,
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
                  : const Text(
                      'Resend Email Code',
                      style: TextStyle(
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
                      BoxShadow(
                        color: AppTheme.secondaryGreen.withOpacity(0.3),
                        blurRadius: 18,
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
          const SizedBox(height: 24),
        // Sign out option
        TextButton.icon(
          onPressed: () async {
            // Show confirmation dialog
            final shouldSignOut = await _showSignOutDialog();

            if (shouldSignOut == true && mounted) {
              // Sign out from Firebase
              await _authManager.signOut();
              if (!mounted) return;

              // This screen is shown two ways: pushed on top of signup, and
              // as a ROOT screen by SecurityWrapper's MFA gate. In the root
              // case there is nothing to pop, which is why popping alone left
              // the user stranded here. Tell the wrapper to leave the MFA
              // gate, then pop only if this screen was actually pushed.
              widget.onSignOut?.call();

              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          },
          icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
          label: const Text(
            'Sign out and start over',
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Confirmation dialog — uses the shared app-wide pop-up card.
  Future<bool?> _showSignOutDialog() {
    return AppDialog.show(
      context,
      title: 'Sign Out?',
      message: 'You will need to log in again to continue.',
      icon: Icons.logout_rounded,
      confirmLabel: 'Sign Out',
      isDestructive: true,
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

    // Always use email verification (SMS is disabled)
    final success = await _authManager.sendMfaCode(widget.userId, useEmail: true);
    
    if (success) {
      _startResendCountdown();
      // Note: Email service may not be configured - code is always logged to console
      _showSuccessMessage('New verification code generated! Check Your Email.');
    } else {
      _showError('Failed to generate verification code. Please try again.');
    }

    setState(() {
      _isResending = false;
    });
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
    CustomSnackbar.showSuccess(context, message);
  }

  void _performShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _onVerificationSuccess() async {
    AppLogger.info('_onVerificationSuccess called');
    if (!mounted) {
      AppLogger.warning('_onVerificationSuccess called but widget not mounted');
      return;
    }
    
    AppLogger.info('Widget is mounted, proceeding with success flow');
    HapticFeedback.mediumImpact();
    
    // Wait for tokens to be stored and verified
    // The _completeAuthentication method now verifies token storage
    // We wait longer to ensure the auth state is fully propagated
    AppLogger.info('Waiting for authentication state to propagate...');
    
    // Wait 1.5 seconds to ensure tokens are fully stored and auth state is updated
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) {
      AppLogger.warning('Widget unmounted during delay');
      return;
    }
    
    // Verify authentication is complete before popping
    final isAuth = await _authManager.isAuthenticated();
    AppLogger.info('Authentication verified before pop: $isAuth');
    
    if (mounted) {
      AppLogger.info('Popping MFA screen after verification success');
      // Pop with a result to indicate success (the screen may also be shown
      // as a root screen by SecurityWrapper, where there is nothing to pop)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      
      // Call the callback AFTER popping to ensure navigation is complete
      // Use a post-frame callback to ensure it happens after the navigation completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onVerificationSuccess != null) {
          AppLogger.info('Calling onVerificationSuccess callback after navigation');
          try {
            widget.onVerificationSuccess!();
          } catch (e) {
            AppLogger.error('Error in onVerificationSuccess callback', error: e);
          }
        }
      });
    }
  }
}
