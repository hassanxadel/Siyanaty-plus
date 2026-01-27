import '../shared/utils/app_logger.dart';
import 'firebase_email_service.dart';

/// Service for sending emails using Firebase
/// 
/// This service uses Firebase Firestore's 'mail' collection to send emails.
/// 
/// SETUP REQUIRED:
/// Install Firebase Extension "Trigger Email" from Firebase Console
/// - Go to Firebase Console > Extensions
/// - Install "Trigger Email" extension
/// - Configure your email service (SendGrid, Mailgun, etc.)
class EmailService {
  /// Send verification code via email using Firebase
  /// 
  /// Returns true if email was queued successfully in Firestore
  static Future<bool> sendVerificationEmail({
    required String email,
    required String code,
    String? userName,
  }) async {
    try {
      // Use Firebase Email Service to send OTP code
      return await FirebaseEmailService.sendOTPEmail(
        toEmail: email,
        code: code,
        userName: userName,
      );
    } catch (e) {
      AppLogger.error('Error sending verification email', error: e);
      return false;
    }
  }
  
  /// Send a test email (for debugging)
  static Future<bool> sendTestEmail(String email) async {
    return await sendVerificationEmail(
      email: email,
      code: '123456',
      userName: 'Test User',
    );
  }
}

/// Email template for verification code
class EmailTemplate {
  static String verificationEmailHtml({
    required String code,
    required String userName,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }
    .container { background-color: white; border-radius: 10px; padding: 30px; max-width: 600px; margin: 0 auto; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { text-align: center; color: #062117; margin-bottom: 30px; }
    .code-box { background-color: #062117; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin: 30px 0; }
    .footer { color: #666; font-size: 14px; text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; }
    .warning { color: #ff6b6b; font-size: 12px; text-align: center; margin-top: 10px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚗 Siyanaty</h1>
      <h2>Verification Code</h2>
    </div>
    <p>Hello $userName,</p>
    <p>Your verification code for Siyanaty is:</p>
    <div class="code-box">$code</div>
    <p>This code will expire in <strong>5 minutes</strong>.</p>
    <p>If you didn't request this code, please ignore this email.</p>
    <div class="footer">
      <p>© ${DateTime.now().year} Siyanaty - Your Car Maintenance Companion</p>
      <p class="warning">Never share this code with anyone.</p>
    </div>
  </div>
</body>
</html>
    ''';
  }
  
  static String verificationEmailPlainText({
    required String code,
    required String userName,
  }) {
    return '''
Hello $userName,

Your verification code for Siyanaty is: $code

This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

© ${DateTime.now().year} Siyanaty
Never share this code with anyone.
    ''';
  }
}

