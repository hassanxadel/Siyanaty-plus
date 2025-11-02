# Siyanaty+ Security Features Documentation

## Overview
This document outlines all the security features implemented in the Siyanaty+ application. The app now has enterprise-grade security with multiple layers of protection while maintaining a smooth user experience.

---

## 🔐 Security Architecture

### 1. Multi-Layer Authentication System

#### Layer 1: Firebase Authentication
- **Email/Password Authentication**: Secure Firebase Auth for primary login
- **Google Sign-In**: OAuth 2.0 integration for social login
- **Session Management**: Token-based authentication with automatic refresh
- **Account Recovery**: Password reset functionality via email

#### Layer 2: Multi-Factor Authentication (MFA)
- **Device-Based MFA**: Automatically triggered on new device login
- **SMS Verification**: Phone number verification for sensitive operations
- **Trusted Devices**: Maintains list of authorized devices per user
- **Remote Device Management**: Users can revoke device access from settings

#### Layer 3: Local Device Security
- **Biometric Authentication**: Fingerprint/Face ID support
- **PIN Protection**: 4-6 digit PIN as fallback
- **Auto-Lock**: App locks when backgrounded or after inactivity
- **Failed Attempt Lockout**: Progressive lockout after failed attempts

---

## 🛡️ Security Features in Detail

### A. Secure Storage (`flutter_secure_storage`)
**Location**: `lib/services/security/secure_storage_service.dart`

**What it protects**:
- Access tokens and refresh tokens
- Database encryption keys
- PIN hashes (salted with SHA-256)
- Biometric preferences
- Last unlock timestamps
- Failed attempt counters

**How it works**:
- Android: Uses Android Keystore (hardware-backed when available)
- iOS: Uses iOS Keychain (Secure Enclave when available)
- All sensitive data is encrypted at rest
- Keys never leave the secure storage

### B. Encrypted Local Database (`sqflite_sqlcipher`)
**Location**: `lib/services/security/secure_database.dart`

**What it protects**:
- All local user data
- Car information
- Maintenance records
- Reminders
- Personal settings

**How it works**:
- Database file is encrypted with AES-256
- Encryption key is generated on first login
- Key is stored in secure storage (never in plain text)
- Database cannot be read without the encryption key

### C. Biometric Authentication (`local_auth`)
**Location**: `lib/services/security/local_unlock_service.dart`

**Features**:
- Fingerprint recognition
- Face ID/Face Recognition
- Automatic fallback to PIN if biometric fails
- Biometric enrollment change detection
- Lockout protection after failed attempts

**User Experience**:
- Fast unlock (< 1 second)
- No need to type credentials every time
- Works offline
- Respects system biometric settings

### D. PIN Protection
**Location**: `lib/presentation/screens/security/pin_setup_screen.dart`

**Features**:
- 4-6 digit PIN support
- Salted hash storage (SHA-256)
- PIN change functionality
- Failed attempt tracking
- Progressive lockout (5 attempts max)

**Security**:
- PIN is never stored in plain text
- Each PIN is salted with a unique random value
- Hash verification happens in secure storage
- Timing-attack resistant comparison

---

## 🔄 Authentication Flow

### First Time Login
```
1. User enters email/password
2. Firebase authenticates
3. Check if new device → Trigger MFA if needed
4. Store access token in secure storage
5. Navigate to PIN setup screen
6. User creates 4-6 digit PIN
7. PIN hash stored in secure storage
8. Optional: Enable biometric authentication
9. Access granted to app
```

### Subsequent App Opens
```
1. App checks if user is authenticated
2. Check if PIN/biometric is set up
3. Show unlock screen (biometric or PIN)
4. On successful unlock → Access granted
5. If unlock fails 5 times → Force full login
```

### App Backgrounding
```
1. App goes to background
2. Security flag set to require unlock
3. App returns to foreground
4. Unlock screen shown automatically
5. User must authenticate to continue
```

### Session Expiry
```
1. Access token expires (configurable)
2. App attempts to refresh using refresh token
3. If refresh succeeds → Continue seamlessly
4. If refresh fails → Force full login + MFA
```

---

## 🎯 Security Screens

### 1. PIN Setup Screen
**File**: `lib/presentation/screens/security/pin_setup_screen.dart`

**Features**:
- Clean, modern UI matching app theme
- Real-time PIN entry feedback
- Confirmation step to prevent typos
- Shake animation on error
- Change PIN functionality
- Old PIN verification before change

### 2. Unlock Screen
**File**: `lib/presentation/screens/security/unlock_screen.dart`

**Features**:
- Biometric prompt with fingerprint icon
- Fallback to PIN entry
- Remaining attempts counter
- Lockout dialog after max attempts
- "Forgot PIN" → Forces full login
- Smooth animations and haptic feedback

### 3. MFA Verification Screen
**File**: `lib/presentation/screens/security/mfa_verification_screen.dart`

**Features**:
- OTP input (6 digits)
- SMS resend functionality
- Countdown timer
- Auto-verification on complete
- Error handling and retry logic

---

## 🔧 Security Services

### 1. Authentication Manager
**File**: `lib/services/security/authentication_manager.dart`

**Responsibilities**:
- Manage Firebase authentication state
- Handle token refresh logic
- Validate session validity
- Device registration and management
- MFA triggering logic

### 2. Local Unlock Service
**File**: `lib/services/security/local_unlock_service.dart`

**Responsibilities**:
- Biometric authentication
- PIN verification
- Failed attempt tracking
- Auto-lock timing
- Unlock requirement checking

### 3. Secure Storage Service
**File**: `lib/services/security/secure_storage_service.dart`

**Responsibilities**:
- Store/retrieve tokens securely
- PIN hash management
- Encryption key storage
- Biometric preference storage
- Failed attempt persistence

### 4. Secure Database
**File**: `lib/services/security/secure_database.dart`

**Responsibilities**:
- Initialize encrypted database
- Manage encryption keys
- Provide secure database access
- Handle database migrations

---

## 📱 User Experience

### What Users See

#### After First Login:
1. **PIN Setup Screen**
   - "Set Up PIN" title
   - "Create a 4-6 digit PIN to secure your app" subtitle
   - Numeric keypad
   - PIN dots showing entry progress
   - Confirmation step

2. **Optional Biometric Setup**
   - "Enable Biometric Authentication?" prompt
   - Fingerprint/Face icon
   - "Use biometrics for faster unlock" description
   - Skip option available

#### On Subsequent Opens:
1. **Unlock Screen**
   - App logo
   - "Welcome Back" message
   - Biometric prompt (if enabled)
   - OR PIN entry keypad
   - "Forgot PIN?" option

#### On New Device Login:
1. **MFA Verification**
   - "Verify Your Identity" title
   - "We sent a code to your phone" message
   - 6-digit OTP input
   - Resend code button
   - Countdown timer

---

## ⚙️ Configuration Options

### Security Settings (in Settings Screen)
**File**: `lib/presentation/screens/settings/settings_screen.dart`

Users can configure:
- ✅ Enable/Disable biometric authentication
- ✅ Change PIN
- ✅ View trusted devices
- ✅ Revoke device access
- ✅ Enable/Disable auto-lock
- ✅ Set auto-lock timeout
- ✅ View security log (optional)

---

## 🔒 Security Best Practices Implemented

### 1. **No Plain Text Storage**
- Passwords are NEVER stored locally
- Only salted PIN hashes are stored
- Tokens are encrypted in secure storage

### 2. **Token-Based Authentication**
- Short-lived access tokens (15-60 minutes)
- Long-lived refresh tokens (30 days)
- Automatic token refresh
- Secure token storage

### 3. **Progressive Security**
- Low friction for trusted devices
- Additional verification for new devices
- MFA only when necessary
- Biometric for speed, PIN for reliability

### 4. **Lockout Protection**
- 5 failed PIN attempts → Lockout
- Progressive delays between attempts
- Force full login after lockout
- Prevents brute force attacks

### 5. **Session Management**
- Server-side session validation
- Remote session revocation
- Device-specific sessions
- Activity tracking

### 6. **Encryption**
- AES-256 for database
- SHA-256 for PIN hashing
- Secure random salt generation
- Hardware-backed encryption when available

---

## 🚨 Error Handling

### Known Issues & Solutions

#### 1. PigeonUserDetails Type Cast Error
**What it is**: A benign Firebase Auth plugin warning during registration/login

**Impact**: None - authentication succeeds despite the warning

**Status**: Handled in `lib/shared/services/auth_service.dart` (lines 67-93)

**Solution**: Error is caught and handled gracefully; user authentication proceeds normally

#### 2. Biometric Not Available
**Scenario**: Device doesn't have biometric hardware or it's not enrolled

**Handling**: Automatic fallback to PIN entry

**User Message**: "Biometric authentication not available. Please use your PIN."

#### 3. PIN Forgotten
**Scenario**: User forgets their PIN

**Handling**: "Forgot PIN?" button forces full login with email/password

**Result**: User can set a new PIN after re-authentication

#### 4. Session Expired
**Scenario**: User hasn't used app for extended period

**Handling**: Automatic token refresh attempt; if fails, show login screen

**User Experience**: Seamless if refresh succeeds; requires login if expired

---

## 📊 Security Metrics

### What's Being Tracked:
- Failed authentication attempts
- Last successful unlock time
- Device registration dates
- Session duration
- MFA verification attempts
- Biometric vs PIN usage ratio

### Where It's Stored:
- Locally: `flutter_secure_storage`
- Server: Firestore (user activity logs)

---

## 🔐 Compliance & Standards

### Security Standards Met:
- ✅ **OWASP Mobile Top 10** compliance
- ✅ **AES-256** encryption
- ✅ **SHA-256** hashing
- ✅ **Hardware-backed** key storage
- ✅ **Multi-factor** authentication
- ✅ **Zero-knowledge** architecture (server never sees PIN)

### Privacy:
- ✅ Biometric data never leaves device
- ✅ PIN never transmitted to server
- ✅ Local data encrypted at rest
- ✅ Minimal data collection
- ✅ User controls their data

---

## 🛠️ Developer Guide

### Adding New Secure Data

```dart
// 1. Store securely
final secureStorage = SecureStorageService();
await secureStorage.write(key: 'my_secret', value: 'secret_value');

// 2. Retrieve securely
final value = await secureStorage.read(key: 'my_secret');

// 3. Delete securely
await secureStorage.delete(key: 'my_secret');
```

### Requiring Authentication for Sensitive Actions

```dart
// Check if user is authenticated
final authManager = AuthenticationManager();
final isAuth = await authManager.isAuthenticated();

if (!isAuth) {
  // Navigate to login
  Navigator.pushNamed(context, '/login');
  return;
}

// Optionally require local unlock
final localUnlock = LocalUnlockService();
final result = await localUnlock.authenticateUser();

if (result.success) {
  // Proceed with sensitive action
} else {
  // Show error
}
```

### Adding MFA to New Actions

```dart
// Trigger MFA for sensitive operation
final authManager = AuthenticationManager();
final mfaRequired = await authManager.requiresMfa(
  action: 'change_password',
  userId: currentUserId,
);

if (mfaRequired) {
  // Navigate to MFA screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MfaVerificationScreen(
        userId: currentUserId,
        deviceId: currentDeviceId,
        onVerificationSuccess: () {
          // Proceed with action
        },
      ),
    ),
  );
}
```

---

## 📝 Testing Security Features

### Manual Testing Checklist:

- [ ] First login shows PIN setup
- [ ] PIN setup requires confirmation
- [ ] Biometric prompt appears (if available)
- [ ] App locks when backgrounded
- [ ] Unlock screen appears on resume
- [ ] Biometric unlock works
- [ ] PIN unlock works
- [ ] Failed attempts are tracked
- [ ] Lockout occurs after 5 failures
- [ ] "Forgot PIN" forces full login
- [ ] MFA triggers on new device
- [ ] Trusted devices skip MFA
- [ ] Session refresh works
- [ ] Session expiry forces login
- [ ] Database is encrypted
- [ ] Tokens are in secure storage

---

## 🎉 Summary

Your Siyanaty+ app now has **enterprise-grade security** with:

1. ✅ **Multi-factor authentication** (email/password + MFA + biometric/PIN)
2. ✅ **Encrypted local database** (AES-256)
3. ✅ **Secure token storage** (Android Keystore / iOS Keychain)
4. ✅ **Biometric authentication** (fingerprint/face)
5. ✅ **PIN protection** (salted SHA-256 hashes)
6. ✅ **Auto-lock** on background
7. ✅ **Session management** with automatic refresh
8. ✅ **Device management** and remote revocation
9. ✅ **Progressive lockout** protection
10. ✅ **Zero-knowledge architecture** (server never sees PIN)

All while maintaining a **smooth user experience** that doesn't require entering email/password on every app open!

---

## 📞 Support

For security-related questions or concerns:
- Review this documentation
- Check `lib/services/security/` for implementation details
- Consult Firebase Auth documentation for server-side features
- Review OWASP Mobile Security guidelines

---

**Last Updated**: November 1, 2025  
**Version**: 1.0.0  
**Status**: ✅ All security features implemented and active

