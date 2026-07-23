import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../services/security/otp_service.dart';
import 'pin_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final OtpService _otpService = OtpService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  String? _errorMessage;
  int _remainingSeconds = 300; // 5 minutes
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
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
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _remainingSeconds = _otpService.getRemainingSeconds();
        });
        return _remainingSeconds > 0;
      }
      return false;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (_otpService.verifyOtp(otp)) {
      _otpService.clearOtp();
      
      if (mounted) {
        // Navigate to PIN setup screen with reset mode (skip current PIN verification)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PinSetupScreen(
              isChangingPin: true,
              isResettingPin: true, // Skip current PIN verification since user forgot it
            ),
          ),
        );
      }
    } else {
      _showError(_remainingSeconds > 0 ? 'Invalid OTP code' : 'OTP expired');
      _performShakeAnimation();
      _clearOtpFields();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearOtpFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
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

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _otpService.sendOtpToEmail(widget.email);

    if (mounted) {
      if (success) {
        setState(() {
          _remainingSeconds = 300;
        });
        _startTimer();
        _clearOtpFields();
        
        AppSnackbar.show(context, 
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OTP sent to ${widget.email}',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        _showError('Failed to send OTP');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: context.r(32)),
              Expanded(
                // Center gives the scroll view its natural height so the
                // content sits in the middle of the free space (a Column's
                // mainAxisAlignment cannot centre inside a scroll view).
                child: Center(
                  child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildOtpInfo(),
                      SizedBox(height: context.r(32)),
                      _buildOtpFields(),
                      if (_errorMessage != null) ...[
                        SizedBox(height: context.r(16)),
                        _buildErrorMessage(),
                      ],
                      SizedBox(height: context.r(32)),
                      _buildTimer(),
                      SizedBox(height: context.r(24)),
                      _buildResendButton(),
                    ],
                  ),
                  ),
                ),
              ),
              _buildVerifyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryGreen,
            size: context.responsiveIconSize(20),
          ),
        ),
        Expanded(
          child: Text(
            'Verify OTP',
            textAlign: TextAlign.center,
            style: context.responsiveTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              color: AppTheme.getThemeAwareTextColor(context),
            ),
          ),
        ),
        SizedBox(width: context.r(48)),
      ],
    );
  }

  Widget _buildOtpInfo() {
    return Column(
      children: [
        Container(
          width: context.r(80),
          height: context.r(80),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: context.r(20),
                offset: Offset(0, context.r(8)),
              ),
            ],
          ),
          child: Icon(
            Icons.mail_outline,
            color: Colors.white,
            size: context.responsiveIconSize(40),
          ),
        ),
        SizedBox(height: context.r(24)),
        Text(
          'Enter Verification Code',
          style: context.responsiveTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            color: AppTheme.getThemeAwareTextColor(context),
          ),
        ),
        SizedBox(height: context.r(12)),
        Text(
          'We sent a 6-digit code to',
          textAlign: TextAlign.center,
          style: context.responsiveTextStyle(
            fontSize: 14,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            fontFamily: 'Orbitron',
          ),
        ),
        SizedBox(height: context.r(4)),
        Text(
          widget.email,
          textAlign: TextAlign.center,
          style: context.responsiveTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      // Expanded children share the available width, so the six boxes can
      // never overflow regardless of screen size or text scale.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final isFilled = _controllers[index].text.isNotEmpty;
          return Expanded(
            child: Container(
              height: context.r(60),
              margin: EdgeInsets.symmetric(horizontal: context.r(3)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundGreen,
                    AppTheme.darkAccentGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(16)),
                border: Border.all(
                  color: isFilled
                      ? AppTheme.secondaryGreen
                      : AppTheme.secondaryGreen.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryGreen
                        .withOpacity(isFilled ? 0.35 : 0.2),
                    blurRadius: context.r(18),
                  ),
                ],
              ),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: context.responsiveTextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightBackground,
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
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                } else if (value.isNotEmpty && index == 5) {
                  _focusNodes[index].unfocus();
                  _verifyOtp();
                }
                setState(() {});
              },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(context.r(12)),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(8)),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
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
                fontSize: 13,
                color: Colors.red,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    return Column(
      children: [
        Text(
          'Code expires in',
          style: context.responsiveTextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
            fontFamily: 'Orbitron',
          ),
        ),
        SizedBox(height: context.r(4)),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: context.responsiveTextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _remainingSeconds < 60 ? Colors.red : AppTheme.primaryGreen,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  Widget _buildResendButton() {
    final waiting = _remainingSeconds > 0;

    return GestureDetector(
      onTap: waiting ? null : _resendOtp,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.r(20),
          vertical: context.r(10),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundGreen,
              AppTheme.darkAccentGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(20)),
          border: Border.all(
            color: AppTheme.secondaryGreen.withOpacity(waiting ? 0.25 : 0.6),
            width: 1,
          ),
          boxShadow: waiting
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.secondaryGreen.withOpacity(0.3),
                    blurRadius: context.r(18),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              waiting ? Icons.timer_outlined : Icons.refresh_rounded,
              size: context.responsiveIconSize(14),
              color: waiting
                  ? AppTheme.lightBackground.withOpacity(0.4)
                  : AppTheme.secondaryGreen,
            ),
            SizedBox(width: context.r(8)),
            Text(
              waiting ? 'Resend after timeout' : 'Resend Code',
              style: context.responsiveTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: waiting
                    ? AppTheme.lightBackground.withOpacity(0.4)
                    : AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: context.responsiveButtonHeight(50),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(24)),
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: context.r(18),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(24)),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: context.r(20),
                height: context.r(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Verify & Reset PIN',
                style: context.responsiveTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                ),
              ),
      ),
    );
  }
}
