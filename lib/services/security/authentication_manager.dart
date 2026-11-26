import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'secure_storage_service.dart';
import '../../shared/utils/app_logger.dart';

/// Manages authentication, token refresh, and session/device state.
///
/// The app's only second factor is a local PIN (see [LocalUnlockService] and
/// `SecurityWrapper`): there is no email/SMS OTP or MFA gate. Every successful
/// sign-in completes immediately and the PIN flow guards access to the app.
class AuthenticationManager {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SecureStorageService _secureStorage = SecureStorageService();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Token expiration times
  static const int accessTokenExpiryMinutes = 60; // 1 hour
  static const int refreshTokenExpiryDays = 30; // 30 days

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

      // No MFA/OTP gate — complete authentication straight away. The PIN flow
      // (SecurityWrapper) is what guards the app after sign-in.
      return await _completeAuthentication(user, deviceId, deviceName);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      // Handle known Firebase Auth plugin casting errors (PigeonUserDetails, etc.)
      // These are benign errors that don't affect authentication.
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type \'List<Object?>\'') ||
          e.toString().contains('type cast') ||
          e.toString().contains('_JsonQuerySnapshot')) {
        // Check if user is actually authenticated despite the error
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          try {
            final deviceId = await _getDeviceId();
            final deviceName = await _getDeviceName();
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

  Future<AuthResult> _completeAuthentication(
      User user, String deviceId, String deviceName) async {
    try {
      // Get ID token
      final idToken = await user.getIdToken();

      if (idToken == null) {
        return AuthResult.failure('Failed to get ID token');
      }

      // Generate refresh token (in a real app, this would come from your backend)
      final refreshToken = _generateRefreshToken();

      // Store tokens and user info
      AppLogger.info('Storing authentication tokens...');
      await _secureStorage.storeAccessToken(idToken);
      await _secureStorage.storeRefreshToken(refreshToken);
      await _secureStorage.storeUserId(user.uid);
      await _secureStorage.storeDeviceId(deviceId);

      // Verify tokens are stored correctly with retry
      bool tokensVerified = false;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final storedAccessToken = await _secureStorage.getAccessToken();
        final storedRefreshToken = await _secureStorage.getRefreshToken();
        if (storedAccessToken != null && storedRefreshToken != null) {
          tokensVerified = true;
          AppLogger.info('Tokens verified as stored (attempt ${i + 1})');
          break;
        }
        AppLogger.info('Waiting for tokens to be stored (attempt ${i + 1})...');
      }

      if (!tokensVerified) {
        AppLogger.warning('Could not verify tokens were stored, but continuing...');
      }

      // Ensure PIN belongs to current user (clear if it belongs to different user)
      await _secureStorage.ensurePinBelongsToCurrentUser();

      // Generate database encryption key if not exists
      final existingKey = await _secureStorage.getDatabaseKey();
      if (existingKey == null) {
        await _secureStorage.generateDatabaseKey();
      }

      // Without an MFA gate, a successful sign-in makes this device trusted.
      // `secure_database` records this flag on the device entry.
      await _secureStorage.setTrustedDevice(true);

      // Update device info in Firestore
      await _updateDeviceInfo(user.uid, deviceId, deviceName);

      // Final verification that isAuthenticated returns true
      final isAuth = await isAuthenticated();
      AppLogger.info('Final isAuthenticated check after storing tokens: $isAuth');

      // Best-effort user refresh. NOTE: on this firebase_auth version this
      // reliably throws "type 'List<Object?>' is not a subtype of type
      // 'PigeonUserInfo'", so callers must NOT depend on it to trigger
      // authStateChanges — screens explicitly notify SecurityWrapper instead.
      try {
        await user.reload();
      } catch (e) {
        // Known plugin casting bug; authentication itself already succeeded
        AppLogger.warning('User reload failed (ignored, see note above)', error: e);
      }

      return AuthResult.success(user.uid);
    } catch (e) {
      return AuthResult.failure('Authentication completion failed: ${e.toString()}');
    }
  }

  Future<String> _getDeviceId() async {
    // Check if we already have a stored device ID
    final existingDeviceId = await _secureStorage.getDeviceId();
    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      AppLogger.info('Using existing device ID: $existingDeviceId');
      return existingDeviceId;
    }

    // Generate new device ID based on device info
    try {
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID which is unique per device and app installation
        deviceId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor which is unique per device and vendor
        deviceId = 'ios_${iosInfo.identifierForVendor}';
      } else {
        // Fallback for other platforms - generate a random but persistent ID
        final random = Random.secure();
        deviceId = 'device_${random.nextInt(1000000000)}';
      }

      // Store the device ID for future use (persistent across app restarts)
      await _secureStorage.storeDeviceId(deviceId);
      AppLogger.info('Generated and stored new device ID: $deviceId');

      return deviceId;
    } catch (e) {
      AppLogger.error('Error generating device ID', error: e);
      // Fallback to random ID
      final random = Random.secure();
      final fallbackId = 'device_${random.nextInt(1000000000)}';
      await _secureStorage.storeDeviceId(fallbackId);
      return fallbackId;
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

  Future<void> _updateDeviceInfo(
      String userId, String deviceId, String deviceName) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
    } catch (e) {
      // Continue even if Firestore update fails
    }
  }

  String _generateRefreshToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
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
  final String? error;

  AuthResult._({
    required this.success,
    this.userId,
    this.error,
  });

  factory AuthResult.success(String userId) {
    return AuthResult._(success: true, userId: userId);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
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
