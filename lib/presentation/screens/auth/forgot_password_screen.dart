import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';

/// Modern forgot password screen with animated entrance and form validation
/// Handles password reset through Firebase Auth
class ModernForgotPasswordScreen extends StatefulWidget {
  /// Callback function triggered after successful password reset
  final VoidCallback? onPasswordReset;
  const ModernForgotPasswordScreen({super.key, this.onPasswordReset});

  @override
  State<ModernForgotPasswordScreen> createState() => _ModernForgotPasswordScreenState();
}

/// State class for the modern forgot password screen
/// Manages form state, animations, and password reset logic
class _ModernForgotPasswordScreenState extends State<ModernForgotPasswordScreen>
    with TickerProviderStateMixin {
  /// Controller for email input field
  final _emailController = TextEditingController();
  /// Form validation key for input validation
  final _formKey = GlobalKey<FormState>();
  /// Loading state during password reset
  bool _isLoading = false;
  /// Success state after password reset
  bool _isSuccess = false;
  
  /// Controller for fade-in animation
  late AnimationController _fadeController;
  /// Controller for slide-up animation
  late AnimationController _slideController;
  /// Fade animation for smooth entrance
  late Animation<double> _fadeAnimation;
  /// Slide animation for content movement
  late Animation<Offset> _slideAnimation;

  /// Initialize animation controllers and start entrance animations
  @override
  void initState() {
    super.initState();
    /// Create fade controller for smooth opacity transition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    /// Create slide controller for content movement
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    /// Configure fade animation for form elements
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    /// Configure slide animation for content entrance
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    /// Start both animations for smooth entrance
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo at top
                    SizedBox(
                      height: 100,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 22),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    if (!_isSuccess) ...[
                      _buildEmailField(),
                      const SizedBox(height: 40),
                      _buildResetButton(),
                    ] else ...[
                      _buildSuccessMessage(),
                      const SizedBox(height: 40),
                      _buildBackToLoginButton(),
                    ],
                    const SizedBox(height: 20),
                    _buildBackToLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Your Password',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email and we\'ll send you a reset link',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.lightBackground.withOpacity(0.8),
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.3),
              width: 1.5,
            ),
            color: Colors.transparent,
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: AppTheme.backgroundGreen,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
            decoration: const InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(
                color: AppTheme.darkAccentGreen,
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isLoading 
            ? null 
            : const LinearGradient(
                colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isLoading ? AppTheme.lightBackground.withOpacity(0.3) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _handlePasswordReset,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundGreen),
                    ),
                  )
                : const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.backgroundGreen,
                      fontFamily: 'Orbitron',
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
        color: AppTheme.primaryGreen.withOpacity(0.1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryGreen,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Reset Link Sent!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your email inbox and click the reset link to set a new password.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryGreen.withOpacity(0.8),
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context),
          child: const Center(
            child: Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.backgroundGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: TextStyle(
            color: AppTheme.lightBackground.withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Orbitron',
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppTheme.secondaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.secondaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        // Show success feedback
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Password reset email sent! Check your inbox.',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Trigger callback if provided
        if (widget.onPasswordReset != null) {
          widget.onPasswordReset!();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.message ?? 'Password reset failed'}',
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'An unexpected error occurred. Please try again.',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
