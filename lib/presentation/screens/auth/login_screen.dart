import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/security/authentication_manager.dart';
import '../security/mfa_verification_screen.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'create_account_screen.dart';
import '../../../shared/utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthenticationComplete;
  
  const LoginScreen({
    super.key,
    this.onAuthenticationComplete,
  });

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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: Form(
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
                    SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                    _buildEmailField(),
                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                    _buildPasswordField(),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    _buildForgotPasswordLink(),
                    if (_errorMessage != null) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      _buildErrorMessage(),
                    ],
                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                    _buildSignInButton(),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    _buildOrDivider(),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    _buildGoogleSignInButton(),
                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                    _buildNewUserSection(),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightBackground.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.backgroundGreen,
                size: 28,
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            const Expanded(
              child: Text(
                'Sign in to Siyanaty+',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.lightBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppTheme.lightBackground,
                size: 20,
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Expanded(
                child: Text(
                  'Your smart car maintenance companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightBackground.withOpacity(0.9),
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email address',
          style: context.responsiveTextStyle(
            fontSize: 16,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.r(8)),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.3),
              width: 1.5,
            ),
            color: Colors.transparent,
          ),
          child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: context.responsiveTextStyle(
          fontSize: 16,
          color: AppTheme.lightBackground,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
                fontSize: context.responsiveFontSize(16),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.r(16), 
                vertical: context.r(16),
              ),
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
        Text(
          'Password',
          style: context.responsiveTextStyle(
            fontSize: 16,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.r(8)),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
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
            style: context.responsiveTextStyle(
              fontSize: 16,
              color: AppTheme.lightBackground,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
                fontSize: context.responsiveFontSize(16),
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
                  size: context.responsiveIconSize(24),
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.r(16), 
                vertical: context.r(16),
              ),
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
        child: Text(
          'Forgot Password?',
          style: context.responsiveTextStyle(
            fontSize: 14,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.r(16), 
        vertical: context.r(12),
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(12)),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: context.responsiveIconSize(20),
          ),
          SizedBox(width: context.r(8)),
          Expanded(
            child: Text(
              _errorMessage!,
              style: context.responsiveTextStyle(
                fontSize: 14,
                color: Colors.red,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: context.responsiveButtonHeight(58),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
        gradient: _isLoading 
            ? null 
            : const LinearGradient(
                colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isLoading ? AppTheme.lightBackground.withOpacity(0.3) : null,
        boxShadow: _isLoading ? null : [
          BoxShadow(
            color: AppTheme.lightBackground.withOpacity(0.4),
            blurRadius: context.r(16),
            offset: Offset(0, context.r(8)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
          onTap: _isLoading ? null : _signIn,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: context.r(24),
                    height: context.r(24),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundGreen),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: context.responsiveTextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.backgroundGreen,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      SizedBox(width: context.r(12)),
                      Container(
                        padding: EdgeInsets.all(context.r(6)),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(20)),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.backgroundGreen,
                          size: context.responsiveIconSize(18),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.lightBackground,)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.r(16)),
          child: Text(
            'or',
            style: context.responsiveTextStyle(
              fontSize: 14,
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.lightBackground,)),
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
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(12)),
          ),
          padding: EdgeInsets.symmetric(vertical: context.r(16)),
        ),
        icon: SvgPicture.asset(
          'assets/images/google-icon-logo-svgrepo-com.svg',
          width: context.r(24),
          height: context.r(24),
        ),
        label: Text(
          'Sign In with Google',
          style: context.responsiveTextStyle(
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
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.lightBackground,)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.r(16)),
              child: Text(
                'New to Siyana+?',
                style: context.responsiveTextStyle(
                  fontSize: 14,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.lightBackground,)),
          ],
        ),
        SizedBox(height: context.r(8)),
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
            text: TextSpan(
              text: 'No account? ',
              style: context.responsiveTextStyle(
                fontSize: 14,
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
              children: [
                TextSpan(
                  text: 'Join now',
                  style: context.responsiveTextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Orbitron',
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
    if (!mounted) return;

    // SecurityWrapper renders this screen as a ROOT route, so there is
    // usually nothing to pop — popping the last route leaves an empty
    // navigator, which shows as a black screen. Ask the wrapper to
    // re-evaluate auth state instead (it decides PIN setup vs. home), and
    // only pop when this screen really was pushed on top of something.
    //
    // This must not rely on Firebase's authStateChanges alone: on this
    // plugin version `user.reload()` throws a PigeonUserInfo cast error,
    // so the state change never fires and the UI would never advance.
    widget.onAuthenticationComplete?.call();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToMfaVerification(String userId, String deviceId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MfaVerificationScreen(
          userId: userId,
          deviceId: deviceId,
          // No callback - let MFA screen handle its own navigation
        ),
      ),
    );
    
    // If MFA was successful (result == true), notify parent and reset state
    // The SecurityWrapper will re-check authentication and navigate appropriately
    if (result == true && mounted) {
      // MFA completed successfully - notify parent to re-check auth
      widget.onAuthenticationComplete?.call();
      // Reset loading state so user can try again if needed
      setState(() {
        _isLoading = false;
      });
    } else if (mounted) {
      // MFA was cancelled or failed - reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }
}