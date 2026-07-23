import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/utils/app_logger.dart';
import '../firebase_email_service.dart';

/// Service for generating and verifying OTP codes
class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Store OTP temporarily (in production, use secure storage or backend)
  String? _currentOtp;
  DateTime? _otpExpiryTime;
  String? _otpEmail;

  /// Generate a 6-digit OTP code
  String generateOtp() {
    final random = Random.secure();
    final otp = (100000 + random.nextInt(900000)).toString();
    _currentOtp = otp;
    _otpExpiryTime = DateTime.now().add(const Duration(minutes: 5));
    // Never log the code itself — device logs are readable via adb logcat
    // and by crash/analytics SDKs, which would defeat the second factor.
    AppLogger.info('OTP generated (expires in 5 minutes)');
    return otp;
  }

  /// Send OTP to user's email
  Future<bool> sendOtpToEmail(String email) async {
    try {
      // Check if user exists
      final user = _auth.currentUser;
      if (user == null || user.email != email) {
        AppLogger.error('User not found or email mismatch');
        return false;
      }

      _otpEmail = email;
      final otp = generateOtp();

      // Get user's display name for personalized email
      final userName = user.displayName ?? 'User';

      // Send OTP via Firebase Email Service
      AppLogger.info('Sending OTP to user email via Firebase');

      final emailSent = await FirebaseEmailService.sendOTPEmail(
        toEmail: email,
        code: otp,
        userName: userName,
      );
      
      if (emailSent) {
        AppLogger.info('OTP email sent successfully to $email');
      } else {
        // Email failed to send, but OTP is still generated for fallback
        AppLogger.warning('Email sending failed, but OTP is still available for development');
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Failed to send OTP', error: e);
      return false;
    }
  }

  /// Verify OTP code
  bool verifyOtp(String enteredOtp) {
    if (_currentOtp == null || _otpExpiryTime == null) {
      AppLogger.error('No OTP generated');
      return false;
    }

    if (DateTime.now().isAfter(_otpExpiryTime!)) {
      AppLogger.error('OTP expired');
      clearOtp();
      return false;
    }

    if (enteredOtp == _currentOtp) {
      AppLogger.info('OTP verified successfully');
      return true;
    }

    AppLogger.error('Invalid OTP');
    return false;
  }

  /// Check if OTP is still valid
  bool isOtpValid() {
    if (_currentOtp == null || _otpExpiryTime == null) {
      return false;
    }
    return DateTime.now().isBefore(_otpExpiryTime!);
  }

  /// Get remaining OTP validity time in seconds
  int getRemainingSeconds() {
    if (_otpExpiryTime == null) return 0;
    final remaining = _otpExpiryTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Clear OTP data
  void clearOtp() {
    _currentOtp = null;
    _otpExpiryTime = null;
    _otpEmail = null;
    AppLogger.info('OTP cleared');
  }

  /// Get current OTP email
  String? get otpEmail => _otpEmail;

  /// For development/testing: Get current OTP
  String? get currentOtpForTesting => _currentOtp;
}
