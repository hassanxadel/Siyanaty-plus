import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/security/authentication_manager.dart';
import '../security/mfa_verification_screen.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthenticationManager _authManager = AuthenticationManager();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 40),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildForgotPasswordLink(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                    const SizedBox(height: 32),
                    _buildSignInButton(),
                    const SizedBox(height: 24),
                    _buildOrDivider(),
                    const SizedBox(height: 24),
                    _buildGoogleSignInButton(),
                    const SizedBox(height: 32),
                    _buildNewUserSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 60,
        width: 180,
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Sign in to Siyana+',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppTheme.lightBackground,
        fontFamily: 'Orbitron',
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Your smart car maintenance companion',
      style: TextStyle(
        fontSize: 16,
        color: AppTheme.lightBackground,
        fontFamily: 'Orbitron',
      ),
      textAlign: TextAlign.left,
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
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
          color: AppTheme.lightBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
            decoration: const InputDecoration(
              hintText: 'Email address',
              hintStyle: TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.3),
              width: 1.5,
            ),
            color: Colors.transparent,
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(
              color: AppTheme.lightBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: const TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.lightBackground,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernForgotPasswordScreen(),
            ),
          );
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            fontSize: 14,
            decoration: TextDecoration.underline,
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
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: _isLoading 
            ? null 
            : const LinearGradient(
                colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                    color: AppTheme.backgroundGreen,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppTheme.lightBackground,)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.lightBackground,)),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: SvgPicture.asset(
          'assets/images/google-icon-logo-svgrepo-com.svg',
          width: 24,
          height: 24,
        ),
        label: Text(
          'Sign In with Google',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Orbitron',
            color: AppTheme.lightBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildNewUserSection() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: AppTheme.lightBackground,)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'New to Siyana+?',
                style: TextStyle(
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.lightBackground,)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModernCreateAccountScreen(),
              ),
            );
          },
          child: RichText(
            text: const TextSpan(
              text: 'No account? ',
              style: TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: 'Join now',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the new security system for authentication
      final result = await _authManager.signInWithEmailPassword(email, password);

      if (result.success) {
        // Check if PIN is set up, if not, navigate to PIN setup
        _navigateToNextScreen();
      } else if (result.requiresMfa) {
        // Navigate to MFA verification
        _navigateToMfaVerification(result.userId!, result.deviceId!);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Sign in failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during sign in';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use AuthProvider for Google sign-in
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();
      
      if (success) {
        _navigateToNextScreen();
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Google sign in failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during Google sign in';
        _isLoading = false;
      });
    }
  }

  void _navigateToNextScreen() {
    // Authentication successful - just pop (for non-MFA flows)
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToMfaVerification(String userId, String deviceId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MfaVerificationScreen(
          userId: userId,
          deviceId: deviceId,
          // No callback - let MFA screen handle its own navigation
        ),
      ),
    );
  }
}