import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/security/authentication_manager.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'create_account_screen.dart';
import '../../../shared/utils/responsive_utils.dart';

/// Whether to show the Apple sign-in button (Apple platforms only).
bool get showAppleSignIn => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

/// Maps raw auth error codes/messages to friendly, iOS-style copy.
/// Returns an empty string when the user cancelled (caller shows nothing).
String friendlyAuthError(String? raw) {
  final r = (raw ?? '').toLowerCase();
  if (r.isEmpty) return 'Something went wrong. Please try again.';
  if (r.contains('cancel')) return '';
  if (r.contains('network') ||
      r.contains('connection') ||
      r.contains('offline') ||
      r.contains('internet')) {
    return 'No internet connection. Check your network and try again.';
  }
  if (r.contains('too many') || r.contains('too-many-requests')) {
    return 'Too many attempts. Please try again later.';
  }
  if (r.contains('wrong-password') ||
      r.contains('invalid-credential') ||
      r.contains('user-not-found') ||
      r.contains('invalid-email') ||
      r.contains('incorrect email')) {
    return 'Incorrect email or password.';
  }
  if (r.contains('user-disabled') || r.contains('disabled')) {
    return 'This account has been disabled.';
  }
  if (r.contains('different sign-in method') ||
      r.contains('different-credential')) {
    return 'This email is already registered with a different sign-in method.';
  }
  if (r.contains('access denied') || r.contains('not authorized')) {
    return 'Access denied. You are not authorized to use this app.';
  }
  // Already-friendly service messages pass through unchanged.
  return raw!;
}

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
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(), // tap outside = dismiss keyboard
        child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480), // tablet cap
                  child: AutofillGroup(
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
                    if (showAppleSignIn) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      _buildAppleSignInButton(),
                    ],
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
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        textCapitalization: TextCapitalization.none,
        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
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
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _signIn(),
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
                  _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  color: AppTheme.lightBackground,
                  size: context.responsiveIconSize(22),
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
        onPressed: _openForgotPassword,
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
                ? const CupertinoActivityIndicator(
                    radius: 12,
                    color: AppTheme.backgroundGreen,
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

  /// Official Apple button (Apple devices only); white style reads best on the
  /// dark green background. The logo/label are Apple's — never restyled.
  Widget _buildAppleSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: SignInWithAppleButton(
        onPressed: _signInWithApple, // guarded by _isLoading inside
        style: SignInWithAppleButtonStyle.white,
        height: context.responsiveButtonHeight(52),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(12)),
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

  /// Opens Reset Password carrying the typed email, and pre-fills on return.
  Future<void> _openForgotPassword() async {
    final returned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ModernForgotPasswordScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
    if (returned != null && returned.isNotEmpty && mounted) {
      _emailController.text = returned;
    }
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showAuthError('Please enter both your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authManager.signInWithEmailPassword(email, password);
      if (!mounted) return;
      if (result.success) {
        TextInput.finishAutofillContext(); // let the password manager offer to save
        HapticFeedback.mediumImpact();
        _navigateToNextScreen();
      } else {
        _showAuthError(result.error ?? 'Sign in failed');
      }
    } catch (e) {
      if (mounted) _showAuthError('An error occurred during sign in');
    }
  }

  /// Shows a friendly, mapped error inline (or nothing if the user cancelled).
  void _showAuthError(String? raw) {
    final msg = friendlyAuthError(raw);
    if (!mounted) return;
    if (msg.isEmpty) {
      setState(() => _isLoading = false); // user cancelled — no error
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = msg;
      _isLoading = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();
      if (!mounted) return;
      if (success) {
        HapticFeedback.mediumImpact();
        _navigateToNextScreen();
      } else {
        _showAuthError(authProvider.lastSocialError ?? 'Google sign in failed');
      }
    } catch (e) {
      if (mounted) _showAuthError('An error occurred during Google sign in');
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithApple();
      if (!mounted) return;
      if (success) {
        HapticFeedback.mediumImpact();
        _navigateToNextScreen();
      } else {
        _showAuthError(authProvider.lastSocialError ?? 'Apple sign in failed');
      }
    } catch (e) {
      if (mounted) _showAuthError('An error occurred during Apple sign in');
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

}