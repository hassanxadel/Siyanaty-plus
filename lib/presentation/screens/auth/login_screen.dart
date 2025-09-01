import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';

/// Modern login screen with animated entrance and form validation
/// Handles user authentication through Firebase Auth
class ModernLoginScreen extends StatefulWidget {
  /// Callback function triggered after successful login
  final VoidCallback? onLogin;
  const ModernLoginScreen({super.key, this.onLogin});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

/// State class for the modern login screen
/// Manages form state, animations, and authentication logic
class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  /// Controller for email input field
  final _emailController = TextEditingController();
  /// Controller for password input field
  final _passwordController = TextEditingController();
  /// Form validation key for input validation
  final _formKey = GlobalKey<FormState>();
  /// Toggle for password visibility
  bool _isPasswordVisible = false;
  /// Loading state during authentication
  bool _isLoading = false;
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
    _passwordController.dispose();
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
                    const SizedBox(height: 20),
                    _buildLoginForm(),
                    const SizedBox(height: 20),
                    _buildSocialLoginSection(),
                    const SizedBox(height: 20),
                    _buildNavigationButtons(),
                    const SizedBox(height: 20),
                    _buildFooterLinks(),
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
        // Left-aligned title and subtitle only
                      const Text(
          'Sign in to Siyana+',
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
          'Your smart car maintenance companion',
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

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Field
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
        _buildEmailField(),
        const SizedBox(height: 24),
        
        // Password Field
        const Text(
          'Password',
                          style: TextStyle(
                            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildPasswordField(),
        const SizedBox(height: 8),
        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _navigateToForgotPassword(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: AppTheme.secondaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Orbitron',
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.secondaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Sign In Button
        _buildSignInButton(),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
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
          hintText: 'Email address',
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
    );
  }

  Widget _buildPasswordField() {
    return Container(
                                  decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBackground.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(
          color: AppTheme.backgroundGreen,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            color: AppTheme.darkAccentGreen,
            fontSize: 16,
            fontFamily: 'Orbitron',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
                                suffixIcon: IconButton(
                                  icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  onPressed: () {
                                    setState(() {
                _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
    );
  }

  Widget _buildSignInButton() {
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
          onTap: _isLoading ? null : _handleSignIn,
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
                    'Sign in',
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

    Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppTheme.lightBackground.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: AppTheme.lightBackground.withOpacity(0.8),
                  fontSize: 16,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppTheme.lightBackground.withOpacity(0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSocialButton(
          'Sign in with Google',
          Icons.g_mobiledata,
          () => _handleGoogleSignIn(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        // Create Account Section
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppTheme.lightBackground.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'New to Siyana+?',
                style: TextStyle(
                  color: AppTheme.lightBackground.withOpacity(0.8),
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppTheme.lightBackground.withOpacity(0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Create Account Link
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No account? ',
                style: TextStyle(
                  color: AppTheme.lightBackground.withOpacity(0.8),
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToCreateAccount(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Join now',
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
          ),
        ),
        const SizedBox(height: 20),

      ],
    );
  }

    Widget _buildSocialButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBackground.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppTheme.lightBackground,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernCreateAccountScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernForgotPasswordScreen(),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        Text(
          'Returning user and problems logging in ?',
          style: TextStyle(
            color: AppTheme.lightBackground.withOpacity(0.8),
            fontSize: 14,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _showContactSupport,
          child: const Text(
            'Contact us',
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

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Show success feedback
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Welcome back to Siyana+!',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Navigate to main app
          if (widget.onLogin != null) {
            widget.onLogin!();
          }
        } else {
          // Show error message
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Sign in failed',
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

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.selectionClick();
    setState(() { _isLoading = true; });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();
      
      if (mounted) {
        setState(() { _isLoading = false; });
        
        if (success) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Successfully signed in with Google!',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: AppTheme.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
          if (widget.onLogin != null) { widget.onLogin!(); }
        } else {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Google Sign-In failed',
                style: const TextStyle(fontFamily: 'Orbitron'),
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An unexpected error occurred during Google Sign-In',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }



  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Contact Support',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w700,
            color: AppTheme.backgroundGreen,
          ),
        ),
        content: const Text(
          'Need help? Our support team is here to assist you with any login issues.',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: AppTheme.backgroundGreen,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement email or chat support
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Get Help',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
        ],
      ),
    );
  }
}