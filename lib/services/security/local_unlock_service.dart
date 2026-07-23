import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'secure_storage_service.dart';

/// Service for handling biometric and PIN-based local authentication
class LocalUnlockService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final SecureStorageService _secureStorage = SecureStorageService();

  // Maximum failed attempts before requiring full re-authentication
  static const int maxFailedAttempts = 5;
  
  // Auto-lock timeout (in minutes)
  static const int autoLockTimeoutMinutes = 5;

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometrics are enrolled
  Future<bool> areBiometricsEnrolled() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult.notAvailable;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please verify your identity to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await _secureStorage.clearFailedAttempts();
        await _secureStorage.updateLastUnlockTime();
        return BiometricAuthResult.success;
      } else {
        return BiometricAuthResult.failed;
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          return BiometricAuthResult.notAvailable;
        case 'NotEnrolled':
          return BiometricAuthResult.notEnrolled;
        case 'LockedOut':
          return BiometricAuthResult.lockedOut;
        case 'PermanentlyLockedOut':
          return BiometricAuthResult.permanentlyLockedOut;
        default:
          return BiometricAuthResult.error;
      }
    } catch (e) {
      return BiometricAuthResult.error;
    }
  }

  /// Authenticate using PIN
  Future<PinAuthResult> authenticateWithPin(String pin) async {
    try {
      final hasPin = await _secureStorage.hasPinSet();
      if (!hasPin) {
        return PinAuthResult.notSet;
      }

      final failedAttempts = await _secureStorage.getFailedAttempts();
      if (failedAttempts >= maxFailedAttempts) {
        return PinAuthResult.lockedOut;
      }

      final isValid = await _secureStorage.verifyPin(pin);
      if (isValid) {
        await _secureStorage.clearFailedAttempts();
        await _secureStorage.updateLastUnlockTime();
        return PinAuthResult.success;
      } else {
        await _secureStorage.incrementFailedAttempts();
        final newFailedAttempts = await _secureStorage.getFailedAttempts();
        
        if (newFailedAttempts >= maxFailedAttempts) {
          return PinAuthResult.lockedOut;
        } else {
          return PinAuthResult.failed;
        }
      }
    } catch (e) {
      return PinAuthResult.error;
    }
  }

  /// Set up a new PIN
  Future<bool> setupPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        return false; // PIN must be 4-6 digits
      }

      // Validate PIN contains only digits
      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        return false;
      }

      await _secureStorage.storePinHash(pin);
      await _secureStorage.clearFailedAttempts();
      // Setting a PIN proves the user is present, so start the auto-lock
      // window now. Without this the app can immediately demand the PIN
      // that was just created (and, after a reset, still expect the old one
      // because the lock screen was built before the change).
      await _secureStorage.updateLastUnlockTime();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change existing PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final isOldPinValid = await _secureStorage.verifyPin(oldPin);
      if (!isOldPinValid) {
        return false;
      }

      return await setupPin(newPin);
    } catch (e) {
      return false;
    }
  }

  /// Remove PIN authentication
  Future<void> removePin() async {
    await _secureStorage.clearPin();
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.setBiometricEnabled(enabled);
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    return await _secureStorage.isBiometricEnabled();
  }

  /// Check if PIN is set up
  Future<bool> isPinSet() async {
    return await _secureStorage.hasPinSet();
  }

  /// Length of the stored PIN, or null for PINs saved before length
  /// tracking existed (backfilled automatically on successful verification)
  Future<int?> getPinLength() async {
    return await _secureStorage.getPinLength();
  }

  /// Check if any local unlock method is available
  Future<bool> isLocalUnlockAvailable() async {
    final hasBiometric = await isBiometricAvailable() && await isBiometricEnabled();
    final hasPin = await isPinSet();
    return hasBiometric || hasPin;
  }

  /// Check if the app should be locked (based on time since last unlock)
  Future<bool> shouldLockApp() async {
    final lastUnlockTime = await _secureStorage.getLastUnlockTime();
    if (lastUnlockTime == null) {
      return true; // Never unlocked, should be locked
    }

    final now = DateTime.now();
    final timeDifference = now.difference(lastUnlockTime);
    return timeDifference.inMinutes >= autoLockTimeoutMinutes;
  }

  /// Get remaining failed attempts before lockout
  Future<int> getRemainingAttempts() async {
    final failedAttempts = await _secureStorage.getFailedAttempts();
    return maxFailedAttempts - failedAttempts;
  }

  /// Check if user is currently locked out
  Future<bool> isLockedOut() async {
    final failedAttempts = await _secureStorage.getFailedAttempts();
    return failedAttempts >= maxFailedAttempts;
  }

  /// Reset lockout (requires full re-authentication)
  Future<void> resetLockout() async {
    await _secureStorage.clearFailedAttempts();
  }

  /// Perform complete local authentication (biometric first, then PIN fallback)
  Future<LocalAuthResult> performLocalAuthentication() async {
    try {
      // Check if locked out
      if (await isLockedOut()) {
        return LocalAuthResult(
          success: false,
          method: AuthMethod.none,
          error: 'Too many failed attempts. Please sign in again.',
        );
      }

      // Try biometric first if available and enabled
      final biometricEnabled = await isBiometricEnabled();
      final biometricAvailable = await isBiometricAvailable();
      
      if (biometricEnabled && biometricAvailable) {
        final biometricResult = await authenticateWithBiometrics();
        
        switch (biometricResult) {
          case BiometricAuthResult.success:
            return LocalAuthResult(
              success: true,
              method: AuthMethod.biometric,
            );
          case BiometricAuthResult.notAvailable:
          case BiometricAuthResult.notEnrolled:
            // Fall back to PIN
            break;
          case BiometricAuthResult.failed:
            return LocalAuthResult(
              success: false,
              method: AuthMethod.biometric,
              error: 'Biometric authentication failed',
            );
          case BiometricAuthResult.lockedOut:
          case BiometricAuthResult.permanentlyLockedOut:
            return LocalAuthResult(
              success: false,
              method: AuthMethod.biometric,
              error: 'Biometric authentication is locked out',
            );
          case BiometricAuthResult.error:
            return LocalAuthResult(
              success: false,
              method: AuthMethod.biometric,
              error: 'Biometric authentication error',
            );
        }
      }

      // Check if PIN is available
      final hasPinSet = await isPinSet();
      if (!hasPinSet) {
        return LocalAuthResult(
          success: false,
          method: AuthMethod.none,
          error: 'No authentication method configured',
        );
      }

      // PIN authentication will be handled by the UI
      return LocalAuthResult(
        success: false,
        method: AuthMethod.pin,
        requiresPinInput: true,
      );

    } catch (e) {
      return LocalAuthResult(
        success: false,
        method: AuthMethod.none,
        error: 'Authentication error: ${e.toString()}',
      );
    }
  }

  /// Validate security configuration
  Future<SecurityValidationResult> validateSecurityConfiguration() async {
    final issues = <String>[];
    
    // Check if any unlock method is configured
    final hasLocalUnlock = await isLocalUnlockAvailable();
    if (!hasLocalUnlock) {
      issues.add('No local unlock method configured');
    }

    // Check biometric enrollment if enabled
    final biometricEnabled = await isBiometricEnabled();
    if (biometricEnabled) {
      final biometricAvailable = await isBiometricAvailable();
      if (!biometricAvailable) {
        issues.add('Biometric authentication enabled but not available');
      }
    }

    // Check for lockout status
    if (await isLockedOut()) {
      issues.add('Account is locked due to too many failed attempts');
    }

    return SecurityValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
}

/// Result of biometric authentication
enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error,
}

/// Result of PIN authentication
enum PinAuthResult {
  success,
  failed,
  notSet,
  lockedOut,
  error,
}

/// Authentication method used
enum AuthMethod {
  biometric,
  pin,
  none,
}

/// Result of local authentication attempt
class LocalAuthResult {
  final bool success;
  final AuthMethod method;
  final String? error;
  final bool requiresPinInput;

  LocalAuthResult({
    required this.success,
    required this.method,
    this.error,
    this.requiresPinInput = false,
  });
}

/// Result of security validation
class SecurityValidationResult {
  final bool isValid;
  final List<String> issues;

  SecurityValidationResult({
    required this.isValid,
    required this.issues,
  });
}
