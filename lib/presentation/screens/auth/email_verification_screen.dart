import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../services/security/email_verification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends StatefulWidget {
  final bool skipInitialEmail;
  final VoidCallback? onVerificationComplete;
  
  const EmailVerificationScreen({
    super.key,
    this.skipInitialEmail = false,
    this.onVerificationComplete,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final EmailVerificationService _verificationService = EmailVerificationService();
  
  bool _isChecking = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  Timer? _verificationPollTimer; // Timer for automatic verification checking
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    
    // Only send initial verification email if not skipped
    // (skip if user just completed MFA and already received an email)
    if (!widget.skipInitialEmail) {
      _sendVerificationEmail();
    } else {
      AppLogger.info('Skipping initial verification email (user just completed MFA)');
      setState(() {
        _successMessage = 'Verification email already sent during login.';
      });
    }
    
    // Start automatic polling to check verification status
    // Poll every 5 seconds to detect when user clicks verification link
    _startVerificationPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _verificationPollTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  /// Start automatic polling to check if email is verified
  void _startVerificationPolling() {
    _verificationPollTimer?.cancel();
    
    // Poll every 5 seconds to check verification status
    _verificationPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Only check if not already checking and user is still not verified
      if (!_isChecking) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          // Silently check verification status
          try {
            await user.reload();
            final refreshedUser = FirebaseAuth.instance.currentUser;
            if (refreshedUser?.emailVerified ?? false) {
              timer.cancel();
              if (mounted) {
                _onVerificationSuccess();
              }
            }
          } catch (e) {
            // Silently ignore polling errors
            AppLogger.warning('Polling check warning (ignored)', error: e);
          }
        } else if (user?.emailVerified ?? false) {
          // Already verified, stop polling
          timer.cancel();
          if (mounted) {
            _onVerificationSuccess();
          }
        }
      }
    });
  }

  Future<void> _sendVerificationEmail({bool showErrors = false}) async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final success = await _verificationService.sendVerificationEmail();
    
    if (success && mounted) {
      setState(() {
        _successMessage = 'Verification email sent! Check your inbox.';
      });
      _startResendCountdown();
    } else if (mounted && showErrors) {
      // Only show errors if explicitly requested (e.g., from resend button)
      setState(() {
        _errorMessage = 'Failed to send verification email. Please try again.';
      });
    }
  }

  void _startResendCountdown() {
    // Reduced countdown from 60 to 30 seconds for faster resends
    setState(() {
      _resendCountdown = 30;
    });
    
    _countdownTimer?.cancel(); // Cancel any existing timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _resendCountdown--;
      });
      
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_isResending || _resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Resend verification email - show errors if it fails
      final success = await _verificationService.resendVerificationEmail();
      
      if (success && mounted) {
        setState(() {
          _successMessage = 'Verification email resent! Check your inbox.';
          _isResending = false;
        });
        _startResendCountdown();
        HapticFeedback.lightImpact();
      } else if (mounted) {
        // Provide helpful error message
        setState(() {
          _errorMessage = 'Unable to resend email. This may be due to rate limiting. Please wait a moment and try again.';
          _isResending = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error in _resendEmail', error: e);
      
      // Check for specific Firebase Auth errors
      String errorMsg = 'Unable to resend email. ';
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('too-many-requests') || 
          errorString.contains('too_many_requests')) {
        errorMsg += 'Please wait 1-2 minutes before requesting another email.';
      } else if (errorString.contains('network') || 
                 errorString.contains('connection')) {
        errorMsg += 'Please check your internet connection and try again.';
      } else {
        errorMsg += 'Please try again in a moment.';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Session expired. Please log in again.';
            _isChecking = false;
          });
        }
        return;
      }

      // Force token refresh to get latest verification status
      try {
        await user.getIdToken(true); // Force refresh
      } catch (e) {
        AppLogger.warning('Token refresh warning', error: e);
      }

      // Reload user to check verification status
      try {
        await user.reload();
      } catch (reloadError) {
        // Ignore reload errors (Firebase plugin issue)
        AppLogger.warning('User reload warning (ignored)', error: reloadError);
      }

      // Get refreshed user
      final refreshedUser = FirebaseAuth.instance.currentUser;
      final isVerified = refreshedUser?.emailVerified ?? false;
      
      if (!mounted) return;
      
      if (isVerified) {
        AppLogger.info('Email verified successfully!');
        _onVerificationSuccess();
      } else {
        setState(() {
          _errorMessage = 'Email not verified yet. Please check your inbox and click the verification link.';
          _isChecking = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error checking verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking verification status. Please try again.';
          _isChecking = false;
        });
      }
    }
  }

  void _onVerificationSuccess() {
    HapticFeedback.mediumImpact();
    AppLogger.info('Email verification successful');
    
    if (mounted) {
      // Call the callback to trigger re-initialization in main.dart
      // This is safer than trying to pop when the screen is returned directly
      widget.onVerificationComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundGreen,
              AppTheme.getThemeAwareBackground(context),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      size: 60,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'We sent a verification link to:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Orbitron',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Email address
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  Text(
                    'Click the link in the email to verify your account.\nThe verification link is valid for up to 3 days.\nThis screen will automatically detect when you verify.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Orbitron',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Success/Error messages
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Check verification button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'I\'ve Verified My Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Resend email button
                  TextButton(
                    onPressed: (_isResending || _resendCountdown > 0) ? null : _resendEmail,
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          )
                        : Text(
                            _resendCountdown > 0
                                ? 'Resend email in ${_resendCountdown}s'
                                : 'Resend verification email',
                            style: TextStyle(
                              color: _resendCountdown > 0
                                  ? Colors.white.withOpacity(0.5)
                                  : AppTheme.primaryGreen,
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign out option
                  TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pop(false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                    label: const Text(
                      'Sign out',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Orbitron',
                        fontSize: 14,
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
}

