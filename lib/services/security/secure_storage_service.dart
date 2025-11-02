import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage of sensitive data using Android Keystore / iOS Keychain
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _deviceIdKey = 'device_id';
  static const String _databaseKeyKey = 'database_encryption_key';
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _mfaSecretKey = 'mfa_secret';
  static const String _trustedDeviceKey = 'trusted_device';
  static const String _lastUnlockTimeKey = 'last_unlock_time';
  static const String _failedAttemptsKey = 'failed_attempts';

  // Token Management
  Future<void> storeAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // User & Device Management
  Future<void> storeUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> storeDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  // Database Encryption Key
  Future<void> storeDatabaseKey(String key) async {
    await _storage.write(key: _databaseKeyKey, value: key);
  }

  Future<String?> getDatabaseKey() async {
    return await _storage.read(key: _databaseKeyKey);
  }

  Future<String> generateDatabaseKey() async {
    final random = Random.secure();
    final keyBytes = Uint8List(32); // 256-bit key
    for (int i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    final key = base64Encode(keyBytes);
    await storeDatabaseKey(key);
    return key;
  }

  // PIN Management
  Future<void> storePinHash(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    
    if (storedHash == null || salt == null) {
      return false;
    }

    final inputHash = _hashPin(pin, salt);
    return storedHash == inputHash;
  }

  Future<bool> hasPinSet() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  // Biometric Settings
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // MFA Secret (for TOTP)
  Future<void> storeMfaSecret(String secret) async {
    await _storage.write(key: _mfaSecretKey, value: secret);
  }

  Future<String?> getMfaSecret() async {
    return await _storage.read(key: _mfaSecretKey);
  }

  Future<void> clearMfaSecret() async {
    await _storage.delete(key: _mfaSecretKey);
  }

  // Trusted Device Status
  Future<void> setTrustedDevice(bool trusted) async {
    await _storage.write(key: _trustedDeviceKey, value: trusted.toString());
  }

  Future<bool> isTrustedDevice() async {
    final value = await _storage.read(key: _trustedDeviceKey);
    return value == 'true';
  }

  // Security Tracking
  Future<void> updateLastUnlockTime() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _lastUnlockTimeKey, value: timestamp);
  }

  Future<DateTime?> getLastUnlockTime() async {
    final timestamp = await _storage.read(key: _lastUnlockTimeKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    }
    return null;
  }

  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    await _storage.write(key: _failedAttemptsKey, value: (current + 1).toString());
  }

  Future<int> getFailedAttempts() async {
    final value = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(value ?? '0') ?? 0;
  }

  Future<void> clearFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
  }

  // Complete Wipe (for security breach or user logout)
  Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
  }

  // Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null || refreshToken != null;
  }

  // Check if local unlock is configured
  Future<bool> isLocalUnlockConfigured() async {
    final hasPin = await hasPinSet();
    final biometricEnabled = await isBiometricEnabled();
    return hasPin || biometricEnabled;
  }

  // Private helper methods
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(32);
    for (int i = 0; i < saltBytes.length; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  String _hashPin(String pin, String salt) {
    final saltBytes = base64Decode(salt);
    final pinBytes = utf8.encode(pin);
    final combined = Uint8List.fromList([...saltBytes, ...pinBytes]);
    final digest = sha256.convert(combined);
    return digest.toString();
  }

  // Security validation
  Future<bool> validateSecurityState() async {
    try {
      // Check if critical security data exists
      final hasTokens = await isAuthenticated();
      final hasLocalUnlock = await isLocalUnlockConfigured();
      final hasDatabaseKey = await getDatabaseKey() != null;
      
      return hasTokens && hasLocalUnlock && hasDatabaseKey;
    } catch (e) {
      return false;
    }
  }

  // Migration helper for existing data
  Future<void> migrateFromSharedPreferences() async {
    // This method can be used to migrate existing user data
    // from SharedPreferences to secure storage
    // Implementation depends on your current data structure
  }
}
