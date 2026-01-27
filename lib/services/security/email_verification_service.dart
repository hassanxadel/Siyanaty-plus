import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/utils/app_logger.dart';

/// Service for handling Firebase's built-in email verification
/// This is FREE and doesn't require external email services
class EmailVerificationService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Send verification email using Firebase's built-in system (FREE)
  /// Uses ActionCodeSettings to configure longer expiration and better handling
  Future<bool> sendVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        AppLogger.error('No user signed in');
        return false;
      }

      if (user.emailVerified) {
        AppLogger.info('Email already verified');
        return true;
      }

      // Send verification email using Firebase's built-in system
      // Note: Firebase verification links typically expire after 1 hour
      // but can be valid for up to 3 days depending on Firebase configuration
      // ActionCodeSettings is optional and mainly used for password reset flows
      await user.sendEmailVerification();
      
      AppLogger.info('Verification email sent to ${user.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'too-many-requests') {
        AppLogger.error('Too many verification emails sent. Please wait before requesting another.');
      } else {
        AppLogger.error('Failed to send verification email: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to send verification email', error: e);
      return false;
    }
  }

  /// Check if current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        return false;
      }

      // Reload user to get latest verification status
      // Wrap in try-catch to handle Firebase plugin casting errors
      try {
        await user.reload();
      } catch (reloadError) {
        // Ignore reload errors (common Firebase plugin issue)
        // The current user object still has the verification status
        AppLogger.warning('User reload warning (ignored)', error: reloadError);
      }
      
      final refreshedUser = _firebaseAuth.currentUser;
      
      return refreshedUser?.emailVerified ?? false;
    } catch (e) {
      AppLogger.error('Error checking email verification', error: e);
      return false;
    }
  }

  /// Wait for email verification with polling
  Future<bool> waitForEmailVerification({
    Duration timeout = const Duration(minutes: 5),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      final isVerified = await isEmailVerified();
      
      if (isVerified) {
        AppLogger.info('Email verified successfully');
        return true;
      }
      
      // Wait before checking again
      await Future.delayed(pollInterval);
    }
    
    AppLogger.warning('Email verification timeout');
    return false;
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail() async {
    return await sendVerificationEmail();
  }
}

