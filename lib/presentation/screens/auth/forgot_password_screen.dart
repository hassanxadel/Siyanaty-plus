import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';

/// Email format check shared by the field validator and the button-enable gate.
bool isValidEmailFormat(String email) =>
    RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email.trim());

/// Friendly messages for the real errors we DO surface. These never reveal
/// whether an account exists (user-not-found is treated as success upstream),
/// so showing them is safe under Firebase Email Enumeration Protection.
String friendlyResetError(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'missing-email':
      return 'Enter your email address.';
    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    default:
      return "Couldn't send the reset link. Please try again.";
  }
}

/// Reset Password screen. Sends a Firebase password-reset email and — because
/// Email Enumeration Protection is on — shows a neutral message that never
/// reveals whether the address is registered.
class ModernForgotPasswordScreen extends StatefulWidget {
  /// Called after a reset email is (attempted to be) sent.
  final VoidCallback? onPasswordReset;

  /// Pre-fills the email (e.g. carried over from the Sign-In screen).
  final String? initialEmail;

  const ModernForgotPasswordScreen({
    super.key,
    this.onPasswordReset,
    this.initialEmail,
  });

  @override
  State<ModernForgotPasswordScreen> createState() =>
      _ModernForgotPasswordScreenState();
}

class _ModernForgotPasswordScreenState extends State<ModernForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isEmailValid = false;
  String? _errorText;
  String _sentToEmail = '';

  static const int _cooldown = 60;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _emailController.text = widget.initialEmail ?? '';
    _isEmailValid = isValidEmailFormat(_emailController.text);
    _emailController.addListener(_onEmailChanged);

    _fadeController.forward();
    _slideController.forward();
  }

  void _onEmailChanged() {
    final valid = isValidEmailFormat(_emailController.text);
    if (valid != _isEmailValid) setState(() => _isEmailValid = valid);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _resendTimer?.cancel();
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
        onTap: () => FocusScope.of(context).unfocus(), // tap outside dismisses
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shortest = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  final logoH = (shortest * 0.16).clamp(64.0, 110.0).toDouble();

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 22,
                      right: 22,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: logoH,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 20, top: 22),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildHeader(),
                                SizedBox(
                                    height: ResponsiveUtils.spacing(context, 40)),
                                if (!_isSuccess) ...[
                                  _buildEmailField(),
                                  if (_errorText != null) ...[
                                    SizedBox(
                                        height: ResponsiveUtils.spacing(
                                            context, 12)),
                                    _buildErrorMessage(),
                                  ],
                                  SizedBox(
                                      height:
                                          ResponsiveUtils.spacing(context, 40)),
                                  _buildResetButton(),
                                ] else ...[
                                  _buildSuccessMessage(),
                                  SizedBox(
                                      height:
                                          ResponsiveUtils.spacing(context, 24)),
                                  _buildResendButton(),
                                  SizedBox(
                                      height:
                                          ResponsiveUtils.spacing(context, 16)),
                                  _buildBackToLoginButton(),
                                ],
                                SizedBox(
                                    height: ResponsiveUtils.spacing(context, 20)),
                                _buildBackToLoginLink(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Reset Your Password',
            maxLines: 1,
            style: context.responsiveTextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your email and we'll send you a reset link",
          style: context.responsiveTextStyle(
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
        Text(
          'Email address',
          style: context.responsiveTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        SizedBox(height: context.r(12)),
        Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(context.responsiveBorderRadius(16)),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            onFieldSubmitted: (_) => _handlePasswordReset(),
            style: context.responsiveTextStyle(
              color: AppTheme.lightBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(
                color: AppTheme.lightBackground.withOpacity(0.6),
                fontSize: context.responsiveFontSize(16),
                fontFamily: 'Orbitron',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.r(20)),
            ),
            // Inline footnote validation (iOS style) — no popups.
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Enter your email address';
              if (!isValidEmailFormat(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: context.r(16), vertical: context.r(12)),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(context.responsiveBorderRadius(12)),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_circle,
              color: AppTheme.errorColor, size: context.responsiveIconSize(20)),
          SizedBox(width: context.r(8)),
          Expanded(
            child: Text(
              _errorText!,
              style: context.responsiveTextStyle(
                fontSize: 14,
                color: AppTheme.errorColor,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    final enabled = _isEmailValid && !_isLoading;
    return Semantics(
      button: true,
      label: 'Send reset link',
      child: Container(
        width: double.infinity,
        height: context.responsiveButtonHeight(56),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(context.responsiveBorderRadius(16)),
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : AppTheme.lightBackground.withOpacity(0.3),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(context.responsiveBorderRadius(16)),
            onTap: enabled ? _handlePasswordReset : null,
            child: Center(
              child: _isLoading
                  ? const CupertinoActivityIndicator(
                      radius: 12, color: AppTheme.backgroundGreen)
                  : Text(
                      'Send Reset Link',
                      style: context.responsiveTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.backgroundGreen,
                        fontFamily: 'Orbitron',
                      ),
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
      padding: EdgeInsets.all(context.r(24)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
        color: AppTheme.primaryGreen.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.envelope_badge,
              color: AppTheme.lightBackground,
              size: context.responsiveIconSize(44)),
          SizedBox(height: context.r(16)),
          Text(
            'Check your email',
            style: context.responsiveTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.r(8)),
          // Neutral message — never confirms whether the account exists.
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'If an account exists for '),
                TextSpan(
                  text: _sentToEmail,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                    text:
                        ", you'll receive a password reset link shortly. Don't forget to check your spam folder."),
              ],
            ),
            textAlign: TextAlign.center,
            style: context.responsiveTextStyle(
              fontSize: 14,
              color: AppTheme.lightBackground.withOpacity(0.85),
              fontFamily: 'Orbitron',
            ),
          ),
          SizedBox(height: context.r(14)),
          Text(
            'Signed up with Google or Apple? You don’t have a password — go back and use that sign-in option instead.',
            textAlign: TextAlign.center,
            style: context.responsiveTextStyle(
              fontSize: 12,
              color: AppTheme.lightBackground.withOpacity(0.6),
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton() {
    final waiting = _resendSeconds > 0;
    final label = waiting
        ? 'Resend in 0:${_resendSeconds.toString().padLeft(2, '0')}'
        : 'Resend link';
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: context.responsiveButtonHeight(52),
        child: OutlinedButton(
          onPressed: (waiting || _isLoading) ? null : _resend,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: AppTheme.lightBackground
                    .withOpacity(waiting ? 0.25 : 0.6)),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(context.responsiveBorderRadius(16)),
            ),
          ),
          child: _isLoading
              ? const CupertinoActivityIndicator(
                  radius: 11, color: AppTheme.lightBackground)
              : Text(
                  label,
                  style: context.responsiveTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightBackground
                        .withOpacity(waiting ? 0.5 : 1),
                    fontFamily: 'Orbitron',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: context.responsiveButtonHeight(56),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
          gradient: const LinearGradient(
            colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(context.responsiveBorderRadius(16)),
            onTap: _backToSignIn,
            child: Center(
              child: Text(
                'Back to Sign In',
                style: context.responsiveTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.backgroundGreen,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    // Wrap (not Row) so the wide Orbitron text + button reflow on narrow
    // screens instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: context.responsiveTextStyle(
            color: AppTheme.lightBackground.withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Orbitron',
          ),
        ),
        TextButton(
          onPressed: _backToSignIn,
          child: Text(
            'Sign In',
            style: context.responsiveTextStyle(
              color: AppTheme.secondaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// Returns to Sign-In, handing back the typed email so it can be pre-filled.
  void _backToSignIn() {
    Navigator.pop(context, _emailController.text.trim());
  }

  Future<void> _handlePasswordReset() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    await _send(_emailController.text.trim().toLowerCase());
  }

  Future<void> _resend() async {
    if (_isLoading || _resendSeconds > 0 || _sentToEmail.isEmpty) return;
    setState(() => _isLoading = true);
    await _send(_sentToEmail);
  }

  /// Sends the reset email. Treats user-not-found as success so we never reveal
  /// whether the address is registered (Email Enumeration Protection).
  Future<void> _send(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _onSent(email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _onSent(email); // never disclose
        return;
      }
      _showError(friendlyResetError(e.code));
    } catch (_) {
      _showError("Couldn't send the reset link. Please try again.");
    }
  }

  void _onSent(String email) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = false;
      _isSuccess = true;
      _sentToEmail = email;
    });
    _startCooldown();
    widget.onPasswordReset?.call();
  }

  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = false;
      _errorText = message;
    });
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _cooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }
}
