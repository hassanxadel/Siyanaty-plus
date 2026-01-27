# Authentication System

## Overview
Multi-layered authentication system with Firebase Auth, email verification, MFA (OTP), and local PIN/biometric unlock.

## Technologies Used

### 1. Firebase Authentication
- **Technology**: `firebase_auth` package
- **Why**: Industry-standard, secure, handles password hashing, session management, and email verification
- **Features**: Email/password auth, Google Sign-In, email verification

### 2. Email Verification
- **Technology**: Firebase's built-in `sendEmailVerification()`
- **Why**: Free, no external service needed, integrated with Firebase Auth
- **Implementation**: 
  - Sent automatically on account creation
  - Auto-polling every 5 seconds to detect verification
  - Resend with 30-second cooldown

### 3. MFA (Multi-Factor Authentication)
- **Technology**: Custom OTP service + Firebase Email Service
- **Why**: Adds security layer for new/unknown devices
- **Flow**:
  1. User logs in on new device
  2. System detects unknown device
  3. 6-digit OTP sent via email
  4. User enters OTP to verify device
  5. Device marked as "trusted" (stored in Firestore)
- **Storage**: OTP codes stored in Firestore with 5-minute expiration

### 4. PIN Code System
- **Technology**: `flutter_secure_storage` + SHA-256 hashing
- **Why**: Local device security, works offline, fast unlock
- **Security**:
  - PIN hashed with SHA-256 + salt (unique per user)
  - Stored in Android Keystore/iOS Keychain
  - Max 5 failed attempts → lockout
  - Auto-lock after 15 minutes of inactivity
- **Features**: 4-6 digits, setup/change/reset flows

### 5. Biometric Authentication
- **Technology**: `local_auth` package
- **Why**: Convenient, secure, uses device hardware
- **Support**: Fingerprint, Face ID, Touch ID
- **Fallback**: Falls back to PIN if biometric fails

## Authentication Flow

### Registration Flow
1. User fills registration form (email, password, name, phone, emergency contact)
2. Account created in Firebase Auth
3. Email verification sent automatically
4. User redirected to email verification screen
5. After verification → PIN setup screen
6. After PIN setup → Main app

### Login Flow
1. User enters email/password
2. Firebase authenticates
3. **Device Check**: Is this a trusted device?
   - **Yes** → Check if email verified → Check if PIN set → Show unlock screen or main app
   - **No** → Trigger MFA → Send OTP email → User enters OTP → Device marked trusted → Continue
4. Session validation
5. Check email verification status
6. Check if PIN/biometric configured
7. Show appropriate screen (unlock or main app)

### Unlock Flow (After App Reopening)
1. Check last unlock time
2. If > 15 minutes → Show unlock screen
3. User can use:
   - Biometric (if enabled)
   - PIN code
4. After successful unlock → Main app

## Key Components

### Services
- **`AuthService`**: Firebase authentication wrapper
- **`AuthenticationManager`**: Main auth orchestrator, handles MFA, device trust
- **`EmailVerificationService`**: Email verification logic
- **`OtpService`**: OTP generation and email sending
- **`LocalUnlockService`**: PIN and biometric management
- **`SecureStorageService`**: Secure storage using device keystore

### Screens
- **`LoginScreen`**: Email/password login, Google Sign-In
- **`CreateAccountScreen`**: Registration form with validation
- **`EmailVerificationScreen`**: Email verification with auto-polling
- **`MfaVerificationScreen`**: 6-digit OTP input
- **`PinSetupScreen`**: PIN creation/change
- **`UnlockScreen`**: Biometric/PIN unlock

## Security Features

1. **Password Security**: Handled by Firebase (bcrypt hashing)
2. **Session Management**: Firebase Auth tokens, automatic refresh
3. **Device Trust**: Unknown devices require MFA
4. **PIN Security**: SHA-256 hashing with user-specific salt
5. **Secure Storage**: Android Keystore / iOS Keychain
6. **Lockout Protection**: 5 failed PIN attempts → requires re-login
7. **Auto-lock**: 15-minute inactivity timeout

## Data Storage

- **Firebase Auth**: User credentials, email verification status
- **Firestore**: Trusted devices, MFA codes (temporary)
- **Secure Storage**: PIN hash, biometric settings, session tokens, device ID
