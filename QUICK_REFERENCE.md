# Security Features - Quick Reference

## 🚀 Quick Start

### What Changed?
After login, users will now be prompted to set up a PIN for quick app unlock.

### User Flow:
```
Login → PIN Setup → (Optional Biometric) → Main App
```

### On Subsequent Opens:
```
App Open → Unlock Screen → Biometric/PIN → Main App
```

---

## 📁 Key Files

### Security Services:
- `lib/services/security/local_unlock_service.dart` - PIN & biometric auth
- `lib/services/security/secure_storage_service.dart` - Encrypted storage
- `lib/services/security/authentication_manager.dart` - Session management
- `lib/services/security/secure_database.dart` - Encrypted database

### UI Screens:
- `lib/presentation/screens/security/pin_setup_screen.dart` - PIN creation
- `lib/presentation/screens/security/unlock_screen.dart` - Daily unlock
- `lib/presentation/screens/security/mfa_verification_screen.dart` - 2FA

### Core Integration:
- `lib/main.dart` - SecurityWrapper (lines 144-355)

---

## 🔧 Configuration

### In `lib/services/security/local_unlock_service.dart`:
```dart
static const int maxFailedAttempts = 5;  // Max wrong PIN attempts
static const int lockoutDurationMinutes = 5;  // Lockout duration
```

### In `lib/services/security/authentication_manager.dart`:
```dart
// Token expiry times (configurable)
// Access token: 15-60 minutes
// Refresh token: 30 days
```

---

## 🎨 UI Colors

All security screens use your app's theme:
- Background: `AppTheme.backgroundGreen`
- Primary: `AppTheme.primaryGreen`
- Accent: `AppTheme.lightBackground` (yellow)
- Buttons: Gradient (lightBackground → secondaryGreen)

---

## ⚡ Testing Commands

```bash
# Analyze code
flutter analyze lib/main.dart

# Run app
flutter run

# Build release
flutter build apk --release
```

---

## 🐛 Troubleshooting

### "PigeonUserDetails" Error in Logs
**Status**: ✅ Normal, handled  
**Action**: None needed - authentication works fine

### PIN Setup Not Showing
**Check**: `_needsPinSetup` flag in SecurityWrapper  
**Fix**: Ensure `hasLocalUnlock` returns false for new users

### Biometric Not Working
**Check**: Device has biometric enrolled  
**Test**: Use real device (not emulator)  
**Fallback**: PIN entry always available

---

## 📝 Quick Code Snippets

### Require Authentication:
```dart
final localUnlock = LocalUnlockService();
final result = await localUnlock.authenticateUser();
if (result.success) {
  // Proceed
}
```

### Store Securely:
```dart
final storage = SecureStorageService();
await storage.write(key: 'key', value: 'value');
```

### Check Auth Status:
```dart
final authManager = AuthenticationManager();
final isAuth = await authManager.isAuthenticated();
```

---

## 📚 Documentation

- **Full Details**: SECURITY_FEATURES_DOCUMENTATION.md
- **User Guide**: SECURITY_USER_GUIDE.md
- **Implementation**: SECURITY_IMPLEMENTATION_SUMMARY.md

---

## ✅ Status

- **Implementation**: ✅ Complete
- **Testing**: Ready
- **Documentation**: ✅ Complete
- **Deployment**: Ready

---

**Last Updated**: November 1, 2025  
**Version**: 1.0.0 with Security

