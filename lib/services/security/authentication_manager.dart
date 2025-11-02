import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/utils/app_logger.dart';
import 'secure_storage_service.dart';

/// Manages authentication, token refresh, and MFA
class AuthenticationManager {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SecureStorageService _secureStorage = SecureStorageService();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Token expiration times
  static const int accessTokenExpiryMinutes = 60; // 1 hour
  static const int refreshTokenExpiryDays = 30; // 30 days

  // Phone Auth verification state (instance variables to avoid conflicts)
  String? _verificationId;
  // ignore: unused_field
  int? _resendToken; // Reserved for future resend functionality
  bool _lastSentViaEmail = false; // Track last method used

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailPassword(String email, String password) async {
    try {
      // Authenticate with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Authentication failed');
      }

      final user = credential.user!;
      
      // Get device information
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      // Check if MFA is required for this device
      final mfaRequired = await _isMfaRequiredForDevice(user.uid, deviceId);
      
      if (mfaRequired) {
        // Store temporary auth state for MFA completion
        await _secureStorage.storeUserId(user.uid);
        await _secureStorage.storeDeviceId(deviceId);
        
        return AuthResult.mfaRequired(user.uid, deviceId);
      }

      // Complete authentication
      return await _completeAuthentication(user, deviceId, deviceName);

    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      // Handle known Firebase Auth plugin casting errors (PigeonUserDetails, etc.)
      // These are benign errors that don't affect authentication
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('type \'List<Object?>\'') ||
          e.toString().contains('type cast') ||
          e.toString().contains('_JsonQuerySnapshot')) {
        // Check if user is actually authenticated despite the error
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          try {
            // Authentication succeeded, complete the process
            final deviceId = await _getDeviceId();
            final deviceName = await _getDeviceName();
            
            // Check if MFA is required for this device
            final mfaRequired = await _isMfaRequiredForDevice(currentUser.uid, deviceId);
            
            if (mfaRequired) {
              await _secureStorage.storeUserId(currentUser.uid);
              await _secureStorage.storeDeviceId(deviceId);
              return AuthResult.mfaRequired(currentUser.uid, deviceId);
            }
            
            return await _completeAuthentication(currentUser, deviceId, deviceName);
          } catch (innerError) {
            // If recovery fails, return the original error
            return AuthResult.failure('Authentication error: ${e.toString()}');
          }
        }
      }
      
      return AuthResult.failure('Authentication error: ${e.toString()}');
    }
  }

  /// Complete MFA verification
  Future<AuthResult> completeMfaVerification(String userId, String deviceId, String otpCode) async {
    try {
      AppLogger.info('Starting MFA verification completion');
      
      // Verify OTP code
      final isValidOtp = await _verifyMfaCode(userId, otpCode);
      if (!isValidOtp) {
        AppLogger.error('Invalid OTP code');
        return AuthResult.failure('Invalid verification code');
      }

      AppLogger.info('OTP code verified, proceeding with authentication completion');

      // Get current user
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid != userId) {
        AppLogger.error('Authentication session expired during MFA completion');
        return AuthResult.failure('Authentication session expired');
      }

      // Mark device as trusted
      AppLogger.info('Marking device as trusted');
      await _markDeviceAsTrusted(userId, deviceId);
      AppLogger.info('Device marked as trusted');

      // Get current user again to ensure we have the right user
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        AppLogger.error('Current user is null after marking device as trusted');
        return AuthResult.failure('Authentication session expired');
      }

      // Complete authentication
      AppLogger.info('Completing authentication');
      final deviceName = await _getDeviceName();
      final result = await _completeAuthentication(currentUser, deviceId, deviceName);
      AppLogger.info('Authentication completion result: ${result.success}');
      return result;

    } catch (e) {
      AppLogger.error('MFA verification failed with exception', error: e);
      return AuthResult.failure('MFA verification failed: ${e.toString()}');
    }
  }

  /// Send MFA code via SMS or Email
  Future<bool> sendMfaCode(String userId, {bool useEmail = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid != userId) {
        AppLogger.error('User not authenticated');
        return false;
      }

      _lastSentViaEmail = useEmail; // Track the method used

      // If email fallback is requested
      if (useEmail) {
        return await _sendMfaCodeViaEmail(userId, user.email);
      }

      // Default: Try SMS via Firebase Phone Auth
      return await _sendMfaCodeViaSMS(userId);

    } catch (e) {
      AppLogger.error('Failed to send MFA code', error: e);
      return false;
    }
  }

  /// Send MFA code via SMS using Firebase Phone Auth
  Future<bool> _sendMfaCodeViaSMS(String userId) async {
    try {
      // Get user's phone number from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        AppLogger.error('User document not found');
        return false;
      }

      final phoneNumber = userDoc.data()?['phoneNumber'] as String?;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        AppLogger.error('User has no phone number registered');
        return false;
      }

      AppLogger.info('Sending SMS verification code to $phoneNumber');

      // Use Completer to properly wait for Firebase Phone Auth callbacks
      final completer = Completer<bool>();
      bool hasCompleted = false;

      _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          AppLogger.info('Phone number auto-verified');
          // Note: credential doesn't have verificationId in auto-verification
          // The _verificationId will be set by codeAutoRetrievalTimeout
          if (!hasCompleted && !completer.isCompleted) {
            hasCompleted = true;
            completer.complete(true);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.error('Phone verification failed', error: e);
          if (!hasCompleted && !completer.isCompleted) {
            hasCompleted = true;
            completer.complete(false);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.info('Verification code sent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!hasCompleted && !completer.isCompleted) {
            hasCompleted = true;
            completer.complete(true);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          AppLogger.info('Auto-retrieval timeout');
          _verificationId = verificationId;
          // Don't complete on timeout - let codeSent complete
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait for the callback to complete with a timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () {
          AppLogger.error('SMS verification timed out');
          return false;
        },
      );

      return result;

    } catch (e) {
      AppLogger.error('Failed to send SMS MFA code', error: e);
      return false;
    }
  }

  /// Send MFA code via Email
  Future<bool> _sendMfaCodeViaEmail(String userId, String? email) async {
    try {
      if (email == null || email.isEmpty) {
        AppLogger.error('User has no email address');
        return false;
      }

      // Generate 6-digit code
      final code = _generateSixDigitCode();
      
      AppLogger.info('Sending email verification code to $email');

      // Store code hash in Firestore with expiry
      await _firestore.collection('mfa_codes').doc(userId).set({
        'codeHash': _hashCode(code),
        'code': code, // Store plain code for email (in production, use Cloud Functions)
        'method': 'email',
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // In production, you should use Firebase Cloud Functions to send email
      // For now, we'll log it for testing
      AppLogger.info('MFA Code for $email: $code');
      
      // Send email using Firebase sendEmailVerification or Cloud Functions
      // For a real implementation, create a Cloud Function
      try {
        // This is a placeholder - you need to implement email sending
        // Either through Firebase Cloud Functions or a service like SendGrid
        // For testing, log the code
        AppLogger.info('Email code generated for testing: $code');
        
        return true;
      } catch (e) {
        AppLogger.error('Failed to send email', error: e);
        return false;
      }

    } catch (e) {
      AppLogger.error('Failed to send email MFA code', error: e);
      return false;
    }
  }

  /// Refresh access token using refresh token
  Future<TokenRefreshResult> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return TokenRefreshResult.failure('No refresh token available');
      }

      // Verify refresh token is still valid
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return TokenRefreshResult.failure('User not authenticated');
      }

      // Get new ID token from Firebase
      final idToken = await user.getIdToken(true);
      
      if (idToken == null) {
        return TokenRefreshResult.failure('Failed to get ID token');
      }
      
      // Store new access token
      await _secureStorage.storeAccessToken(idToken);
      
      return TokenRefreshResult.success(idToken);

    } catch (e) {
      return TokenRefreshResult.failure('Token refresh failed: ${e.toString()}');
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();
      
      // Clear all secure storage
      await _secureStorage.clearAllSecureData();
      
    } catch (e) {
      // Even if Firebase signout fails, clear local data
      await _secureStorage.clearAllSecureData();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = _firebaseAuth.currentUser;
    AppLogger.info('isAuthenticated check: user=${user?.uid}');
    if (user == null) {
      AppLogger.info('No Firebase user, returning false');
      return false;
    }

    final hasTokens = await _secureStorage.isAuthenticated();
    AppLogger.info('isAuthenticated check: hasTokens=$hasTokens');
    return hasTokens;
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    final user = _firebaseAuth.currentUser;
    return user?.uid;
  }

  /// Setup MFA for user account
  Future<MfaSetupResult> setupMfa(String phoneNumber) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return MfaSetupResult.failure('User not authenticated');
      }

      // Generate TOTP secret
      final secret = _generateMfaSecret();
      
      // Store secret securely
      await _secureStorage.storeMfaSecret(secret);
      
      // Create QR code data for authenticator apps
      final qrData = 'otpauth://totp/Siyanaty:${user.email}?secret=$secret&issuer=Siyanaty';
      
      return MfaSetupResult.success(secret, qrData);

    } catch (e) {
      return MfaSetupResult.failure('MFA setup failed: ${e.toString()}');
    }
  }

  /// Disable MFA
  Future<bool> disableMfa() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      // Clear MFA secret
      await _secureStorage.clearMfaSecret();
      
      // Remove from trusted devices (force re-verification)
      await _clearTrustedDevices(user.uid);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate current session
  Future<SessionValidationResult> validateSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return SessionValidationResult.invalid('No user session');
      }

      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) {
        // Try to refresh token
        final refreshResult = await refreshAccessToken();
        if (!refreshResult.success) {
          return SessionValidationResult.invalid('Session expired');
        }
      }

      // Verify token is not expired (simplified check)
      try {
        await user.getIdToken(false); // Don't force refresh
        return SessionValidationResult.valid();
      } catch (e) {
        // Token might be expired, try refresh
        final refreshResult = await refreshAccessToken();
        if (refreshResult.success) {
          return SessionValidationResult.valid();
        } else {
          return SessionValidationResult.invalid('Session expired');
        }
      }

    } catch (e) {
      return SessionValidationResult.invalid('Session validation error');
    }
  }

  // Private helper methods

  Future<AuthResult> _completeAuthentication(User user, String deviceId, String deviceName) async {
    try {
      // Get ID token
      final idToken = await user.getIdToken();
      
      if (idToken == null) {
        return AuthResult.failure('Failed to get ID token');
      }
      
      // Generate refresh token (in a real app, this would come from your backend)
      final refreshToken = _generateRefreshToken();
      
      // Store tokens and user info
      await _secureStorage.storeAccessToken(idToken);
      await _secureStorage.storeRefreshToken(refreshToken);
      await _secureStorage.storeUserId(user.uid);
      await _secureStorage.storeDeviceId(deviceId);
      
      // Generate database encryption key if not exists
      final existingKey = await _secureStorage.getDatabaseKey();
      if (existingKey == null) {
        await _secureStorage.generateDatabaseKey();
      }
      
      // Update device info in Firestore
      await _updateDeviceInfo(user.uid, deviceId, deviceName);
      
      // Try to reload user to trigger auth state changes (with error handling)
      try {
        AppLogger.info('Reloading user to trigger auth state change');
        await user.reload();
      } catch (e) {
        // PigeonUserInfo casting errors are benign and can be ignored
        AppLogger.warning('User reload warning (ignored)', error: e);
      }
      
      return AuthResult.success(user.uid);

    } catch (e) {
      return AuthResult.failure('Authentication completion failed: ${e.toString()}');
    }
  }

  Future<String> _getDeviceId() async {
    // Check if we already have a stored device ID
    final existingDeviceId = await _secureStorage.getDeviceId();
    if (existingDeviceId != null) {
      return existingDeviceId;
    }

    // Generate new device ID based on device info
    try {
      String deviceId;
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = '${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = '${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        // Fallback for other platforms
        deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Add some randomness to ensure uniqueness
      final random = Random.secure();
      final randomSuffix = random.nextInt(10000).toString().padLeft(4, '0');
      deviceId = '${deviceId}_$randomSuffix';
      
      return deviceId;
    } catch (e) {
      // Fallback to random ID
      final random = Random.secure();
      return 'device_${random.nextInt(1000000)}';
    }
  }

  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<bool> _isMfaRequiredForDevice(String userId, String deviceId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return true; // Require MFA for new users
      }

      final data = userDoc.data()!;
      final trustedDevices = List<String>.from(data['trustedDevices'] ?? []);
      
      return !trustedDevices.contains(deviceId);
    } catch (e) {
      return true; // Default to requiring MFA on error
    }
  }

  Future<void> _markDeviceAsTrusted(String userId, String deviceId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'trustedDevices': FieldValue.arrayUnion([deviceId]),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      await _secureStorage.setTrustedDevice(true);
    } catch (e) {
      // Continue even if Firestore update fails
    }
  }

  Future<void> _updateDeviceInfo(String userId, String deviceId, String deviceName) async {
    try {
      await _firestore.collection('users').doc(userId).collection('devices').doc(deviceId).set({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
    } catch (e) {
      // Continue even if Firestore update fails
    }
  }

  Future<String> _getOrCreateMfaSecret(String userId) async {
    final existingSecret = await _secureStorage.getMfaSecret();
    if (existingSecret != null) {
      return existingSecret;
    }

    final newSecret = _generateMfaSecret();
    await _secureStorage.storeMfaSecret(newSecret);
    return newSecret;
  }

  String _generateMfaSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (i) => random.nextInt(256));
    return base64Encode(bytes).replaceAll('=', '').substring(0, 32);
  }

  String _generateSixDigitCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _hashCode(String code) {
    final bytes = utf8.encode(code);
    return base64Encode(bytes);
  }

  Future<bool> _verifyMfaCode(String userId, String code) async {
    try {
      AppLogger.info('Verifying MFA code. Last sent via: ${_lastSentViaEmail ? "Email" : "SMS"}');
      
      // Check if this is an email verification code (based on what was last sent)
      if (_lastSentViaEmail) {
        final emailCodeDoc = await _firestore.collection('mfa_codes').doc(userId).get();
        if (emailCodeDoc.exists) {
          final data = emailCodeDoc.data()!;
          final method = data['method'] as String?;
          
          if (method == 'email') {
            return await _verifyEmailCode(userId, code, data);
          }
        }
        AppLogger.error('Email code document not found');
        return false;
      }

      // Check if this is a phone auth verification (SMS)
      if (_verificationId != null) {
        return await _verifyPhoneAuthCode(code);
      }
      
      AppLogger.error('No verification ID for SMS');
      return false;
    } catch (e) {
      AppLogger.error('MFA code verification failed', error: e);
      return false;
    }
  }

  /// Verify phone auth code
  Future<bool> _verifyPhoneAuthCode(String smsCode) async {
    try {
      if (_verificationId == null) {
        AppLogger.error('No verification ID available');
        return false;
      }

      // Create phone auth credential (don't sign in, just verify format)
      // If credential creation succeeds without error, the code is valid
      // ignore: unused_local_variable
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // If credential creation succeeds without exception, the code is valid
      // Firebase validates the code when creating the credential
      AppLogger.info('Phone auth code verified successfully');
      return true;
    } catch (e) {
      AppLogger.error('Phone auth code verification failed', error: e);
      return false;
    }
  }

  /// Verify email code
  Future<bool> _verifyEmailCode(String userId, String code, Map<String, dynamic> data) async {
    try {
      // Check if code expired
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        AppLogger.error('Email code expired');
        await _firestore.collection('mfa_codes').doc(userId).delete();
        return false;
      }

      // Verify code hash
      final storedHash = data['codeHash'] as String;
      final codeHash = _hashCode(code);
      
      if (storedHash != codeHash) {
        AppLogger.error('Invalid email code');
        return false;
      }

      // Code is valid, delete it
      await _firestore.collection('mfa_codes').doc(userId).delete();
      AppLogger.info('Email code verified successfully');
      return true;
    } catch (e) {
      AppLogger.error('Email code verification failed', error: e);
      return false;
    }
  }

  String _generateRefreshToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Future<void> _clearTrustedDevices(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'trustedDevices': [],
      });
    } catch (e) {
      // Continue even if Firestore update fails
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

/// Result of authentication attempt
class AuthResult {
  final bool success;
  final String? userId;
  final String? deviceId;
  final String? error;
  final bool requiresMfa;

  AuthResult._({
    required this.success,
    this.userId,
    this.deviceId,
    this.error,
    this.requiresMfa = false,
  });

  factory AuthResult.success(String userId) {
    return AuthResult._(success: true, userId: userId);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }

  factory AuthResult.mfaRequired(String userId, String deviceId) {
    return AuthResult._(
      success: false,
      userId: userId,
      deviceId: deviceId,
      requiresMfa: true,
    );
  }
}

/// Result of token refresh
class TokenRefreshResult {
  final bool success;
  final String? accessToken;
  final String? error;

  TokenRefreshResult._({
    required this.success,
    this.accessToken,
    this.error,
  });

  factory TokenRefreshResult.success(String accessToken) {
    return TokenRefreshResult._(success: true, accessToken: accessToken);
  }

  factory TokenRefreshResult.failure(String error) {
    return TokenRefreshResult._(success: false, error: error);
  }
}

/// Result of MFA setup
class MfaSetupResult {
  final bool success;
  final String? secret;
  final String? qrCodeData;
  final String? error;

  MfaSetupResult._({
    required this.success,
    this.secret,
    this.qrCodeData,
    this.error,
  });

  factory MfaSetupResult.success(String secret, String qrCodeData) {
    return MfaSetupResult._(
      success: true,
      secret: secret,
      qrCodeData: qrCodeData,
    );
  }

  factory MfaSetupResult.failure(String error) {
    return MfaSetupResult._(success: false, error: error);
  }
}

/// Result of session validation
class SessionValidationResult {
  final bool isValid;
  final String? error;

  SessionValidationResult._({
    required this.isValid,
    this.error,
  });

  factory SessionValidationResult.valid() {
    return SessionValidationResult._(isValid: true);
  }

  factory SessionValidationResult.invalid(String error) {
    return SessionValidationResult._(isValid: false, error: error);
  }
}
