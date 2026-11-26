import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import '../../shared/utils/app_logger.dart';
import '../../shared/utils/firebase_debug.dart';
import '../../services/security/secure_storage_service.dart';

// Main authentication manager for the entire app
class AuthProvider extends ChangeNotifier {
  // Core authentication data
  User? _firebaseUser;           // Firebase user object
  AppUser? _appUser;             // Custom app user profile
  bool _isLoading = true;        // Starts true so the splash shows at cold start
  String? _errorMessage;         // Error messages for user

  // Initial-load gate: the splash (AuthWrapper) stays up until BOTH the first
  // auth state has resolved AND the splash animation's minimum time has passed,
  // then flips exactly once. A safety timeout prevents a stalled auth stream
  // (failed init / no connectivity) from trapping the user on the splash.
  bool _initialLoadDone = false;
  bool _authResolved = false;
  bool _minSplashElapsed = false;

  // Public getters for UI access
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null && _appUser != null;
  
  // Initialize authentication listener when provider is created
  AuthProvider() {
    _initializeAuthState();
    _startInitialGate();
  }

  // Listen for Firebase authentication changes and update app state
  void _initializeAuthState() {
    AuthService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _firebaseUser = user;
        await _loadUserProfile();
      } else {
        _firebaseUser = null;
        _appUser = null;
      }
      _authResolved = true;
      _maybeFinishInitialLoad();
      notifyListeners();
    });
  }

  // Keep the splash up for at least the animation's length, and never longer
  // than the safety timeout even if the auth stream never emits.
  void _startInitialGate() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      _minSplashElapsed = true;
      _maybeFinishInitialLoad();
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (!_initialLoadDone) {
        _authResolved = true;
        _minSplashElapsed = true;
        _maybeFinishInitialLoad();
      }
    });
  }

  // Flip out of the initial loading state exactly once, when both the first
  // auth state has resolved and the minimum splash time has elapsed.
  void _maybeFinishInitialLoad() {
    if (_initialLoadDone) return;
    if (_authResolved && _minSplashElapsed) {
      _initialLoadDone = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user profile data from Firestore database
  Future<void> _loadUserProfile() async {
    try {
      if (_firebaseUser?.uid != null) {
        await FirebaseDebugUtils.debugCurrentUserState();
        
        // Ensure PIN belongs to current user (clear if it belongs to different user)
        final secureStorage = SecureStorageService();
        await secureStorage.storeUserId(_firebaseUser!.uid);
        await secureStorage.ensurePinBelongsToCurrentUser();
        
        _appUser = await AuthService.getUserProfile(_firebaseUser!.uid);
        if (_appUser == null) {
          AppLogger.warning('User profile not found for uid: ${_firebaseUser!.uid}');
          AppLogger.info('Attempting to recreate user profile from authorized_users');
          
          // Try to recreate the profile from authorized_users collection
          try {
            await AuthService.ensureUserProfileExists(_firebaseUser!);
            _appUser = await AuthService.getUserProfile(_firebaseUser!.uid);
            
            if (_appUser != null) {
              AppLogger.info('User profile successfully recreated');
            } else {
              AppLogger.warning('Failed to recreate user profile, signing out');
              await AuthService.signOut();
            }
          } catch (e) {
            AppLogger.error('Error recreating user profile', error: e);
            await AuthService.signOut();
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error loading user profile', error: e);
      _appUser = null;
    }
  }

  // Login user with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _clearError();
        AppLogger.info('Sign in successful');
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      AppLogger.error('Sign in error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create new user account with profile information
  Future<bool> createAccount({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );

      if (result.isSuccess) {
        _clearError();
        AppLogger.info('Account creation successful');
        
        // Clear any existing PIN when creating a new account
        // The new user will need to set up their own PIN
        try {
          final secureStorage = SecureStorageService();
          // Store the new user ID first
          if (_firebaseUser?.uid != null) {
            await secureStorage.storeUserId(_firebaseUser!.uid);
            // Clear any PIN that might belong to a previous user
            await secureStorage.clearPin();
          }
        } catch (e) {
          AppLogger.warning('Failed to clear PIN for new account', error: e);
          // Don't fail account creation if PIN clearing fails
        }
        
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      AppLogger.error('Create account error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Error text from the last social sign-in attempt, read by the Sign-In
  /// screen for inline display. Separate from the global [errorMessage] so a
  /// failed social sign-in does NOT swap in the full-screen auth error, and
  /// these methods don't flip the global loading state (no splash flash) —
  /// the Sign-In screen shows its own inline button spinner instead.
  String? lastSocialError;

  // Login user with Google account.
  Future<bool> signInWithGoogle() async {
    lastSocialError = null;
    try {
      final result = await AuthService.signInWithGoogle();
      if (result.isSuccess) {
        AppLogger.info('Google Sign-In successful');
        return true;
      }
      lastSocialError = result.message;
      return false;
    } catch (e) {
      lastSocialError = 'Error during Google sign-in';
      AppLogger.error('Google Sign-In error in provider', error: e);
      return false;
    }
  }

  // Login user with Apple account (iOS/macOS). Routes through
  // AuthService.signInWithApple → the shared post-sign-in path.
  Future<bool> signInWithApple() async {
    lastSocialError = null;
    try {
      final result = await AuthService.signInWithApple();
      if (result.isSuccess) {
        AppLogger.info('Apple Sign-In successful');
        return true;
      }
      lastSocialError = result.message;
      return false;
    } catch (e) {
      lastSocialError = 'Error during Apple sign-in';
      AppLogger.error('Apple Sign-In error in provider', error: e);
      return false;
    }
  }

  // Logout user and clear all authentication data
  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.signOut();

      if (result.isSuccess) {
        // Clear the local PIN, tokens and all cached secure data so the next
        // sign-in starts fresh and must create a new PIN. This is the single
        // source of truth shared by the Settings and Profile sign-out paths.
        await SecureStorageService().clearAllSecureData();
        _firebaseUser = null;
        _appUser = null;
        _clearError();
        AppLogger.info('Sign out successful');
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Error signing out');
      AppLogger.error('Sign out error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email to user
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.sendPasswordResetEmail(email);
      
      if (result.isSuccess) {
        _clearError();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Error sending password reset email');
      AppLogger.error('Password reset error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification to current user
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.sendEmailVerification();
      
      if (result.isSuccess) {
        _clearError();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Error sending email verification');
      AppLogger.error('Email verification error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data and check verification status
  Future<bool> reloadUser() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.reloadUser();
      
      if (result.isSuccess) {
        await _loadUserProfile();
        _clearError();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Error reloading user data');
      AppLogger.error('User reload error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile information in database
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await AuthService.updateUserProfile(updates);
      
      if (success) {
        await _loadUserProfile();
        _clearError();
        return true;
      } else {
        _setError('Failed to update profile');
        return false;
      }
    } catch (e) {
      _setError('Error updating profile');
      AppLogger.error('Update profile error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Manually refresh user data from database
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      await _loadUserProfile();
      notifyListeners();
    }
  }

  // Helper methods for managing UI state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}
