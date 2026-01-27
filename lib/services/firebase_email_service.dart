import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/app_logger.dart';

/// Firebase Email Service for sending OTP codes via email
/// 
/// This service uses Firebase Firestore's 'mail' collection to send emails.
/// 
/// SETUP REQUIRED:
/// 1. Install Firebase Extension "Trigger Email" from Firebase Console
///    - Go to Firebase Console > Extensions
///    - Install "Trigger Email" extension
///    - Configure your email service (SendGrid, Mailgun, etc.)
/// 
/// 2. Alternative: Use Firebase Cloud Functions
///    - Deploy a Cloud Function that sends emails
///    - Update the service to call your Cloud Function
/// 
/// The mail collection format:
/// {
///   'to': 'user@example.com',
///   'message': {
///     'subject': 'Email Subject',
///     'html': '<html>...</html>',
///     'text': 'Plain text version'
///   }
/// }
class FirebaseEmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send OTP verification code via email using Firebase
  /// 
  /// Returns true if email was queued successfully in Firestore
  static Future<bool> sendOTPEmail({
    required String toEmail,
    required String code,
    String? userName,
  }) async {
    try {
      if (toEmail.isEmpty) {
        AppLogger.error('Email address is empty');
        return false;
      }

      AppLogger.info('Sending OTP email to $toEmail via Firebase');

      // Create email message with HTML and plain text versions
      final emailData = {
        'to': toEmail,
        'message': {
          'subject': 'Siyanaty+ - Your Verification Code',
          'html': _buildOTPEmailHtml(code: code, userName: userName ?? 'User'),
          'text': _buildOTPEmailText(code: code, userName: userName ?? 'User'),
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add to Firestore mail collection
      // The Firebase Extension "Trigger Email" will process this
      await _firestore.collection('mail').add(emailData);

      AppLogger.info('✅ OTP email queued successfully in Firebase for $toEmail');
      AppLogger.info('📧 Verification code: $code (expires in 5 minutes)');
      
      return true;
    } catch (e) {
      AppLogger.error('Failed to send OTP email via Firebase', error: e);
      // Log the code for testing/fallback
      AppLogger.info('📧 Verification code for $toEmail: $code (expires in 5 minutes)');
      return false;
    }
  }

  /// Build HTML email template for OTP code
  static String _buildOTPEmailHtml({
    required String code,
    required String userName,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 20px;
    }
    .container {
      background-color: white;
      border-radius: 10px;
      padding: 30px;
      max-width: 600px;
      margin: 0 auto;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header {
      background-color: #062117;
      color: white;
      padding: 20px;
      text-align: center;
      border-radius: 10px 10px 0 0;
      margin: -30px -30px 30px -30px;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
    }
    .content {
      padding: 20px 0;
    }
    .code-box {
      background-color: #062117;
      color: white;
      font-size: 36px;
      font-weight: bold;
      text-align: center;
      padding: 25px;
      border-radius: 8px;
      letter-spacing: 12px;
      margin: 30px 0;
      font-family: 'Courier New', monospace;
    }
    .footer {
      color: #666;
      font-size: 14px;
      text-align: center;
      margin-top: 30px;
      border-top: 1px solid #eee;
      padding-top: 20px;
    }
    .warning {
      color: #ff6b6b;
      font-size: 12px;
      text-align: center;
      margin-top: 10px;
      font-weight: bold;
    }
    .expiry {
      color: #999;
      font-size: 14px;
      text-align: center;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚗 Siyanaty+</h1>
    </div>
    <div class="content">
      <p>Hello $userName,</p>
      <p>Your verification code for Siyanaty+ is:</p>
      <div class="code-box">$code</div>
      <p class="expiry">⏰ This code will expire in <strong>5 minutes</strong>.</p>
      <p>If you didn't request this code, please ignore this email.</p>
      <div class="footer">
        <p>© ${DateTime.now().year} Siyanaty+ - Your Car Maintenance Companion</p>
        <p class="warning">⚠️ Never share this code with anyone.</p>
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Build plain text email template for OTP code
  static String _buildOTPEmailText({
    required String code,
    required String userName,
  }) {
    return '''
Hello $userName,

Your verification code for Siyanaty+ is: $code

⏰ This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

© ${DateTime.now().year} Siyanaty+ - Your Car Maintenance Companion

⚠️ Never share this code with anyone.
    ''';
  }

  /// Send welcome email to new users
  static Future<bool> sendWelcomeEmail({
    required String toEmail,
    required String userName,
  }) async {
    try {
      if (toEmail.isEmpty) {
        AppLogger.error('Email address is empty');
        return false;
      }

      final emailData = {
        'to': toEmail,
        'message': {
          'subject': 'Welcome to Siyanaty+!',
          'html': _buildWelcomeEmailHtml(userName: userName),
          'text': _buildWelcomeEmailText(userName: userName),
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('mail').add(emailData);

      AppLogger.info('✅ Welcome email queued successfully in Firebase for $toEmail');
      return true;
    } catch (e) {
      AppLogger.error('Failed to send welcome email via Firebase', error: e);
      return false;
    }
  }

  /// Build HTML email template for welcome email
  static String _buildWelcomeEmailHtml({required String userName}) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 20px;
    }
    .container {
      background-color: white;
      border-radius: 10px;
      padding: 30px;
      max-width: 600px;
      margin: 0 auto;
    }
    .header {
      background-color: #062117;
      color: white;
      padding: 20px;
      text-align: center;
      border-radius: 10px 10px 0 0;
      margin: -30px -30px 30px -30px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚗 Welcome to Siyanaty+!</h1>
    </div>
    <p>Hello $userName,</p>
    <p>Thank you for joining Siyanaty+! We're excited to help you manage your vehicle maintenance.</p>
    <p>Get started by adding your first car and tracking your maintenance schedule.</p>
    <p>Happy driving!</p>
    <p>The Siyanaty+ Team</p>
  </div>
</body>
</html>
    ''';
  }

  /// Build plain text email template for welcome email
  static String _buildWelcomeEmailText({required String userName}) {
    return '''
Hello $userName,

Thank you for joining Siyanaty+! We're excited to help you manage your vehicle maintenance.

Get started by adding your first car and tracking your maintenance schedule.

Happy driving!

The Siyanaty+ Team
    ''';
  }
}

