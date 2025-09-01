import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import '../../shared/utils/app_logger.dart';
import '../../shared/utils/firebase_debug.dart';

/// Provider for managing authentication state throughout the app
/// Handles user login, logout, profile management, and authentication state
class AuthProvider extends ChangeNotifier {
  /// Firebase user object for authentication
  User? _firebaseUser;
  /// Custom app user object with extended profile information
  AppUser? _appUser;
  /// Loading state indicator for async operations
  bool _isLoading = false;
  /// Error message for failed authentication operations
  String? _errorMessage;
  
  /// Getter for Firebase user object
  User? get firebaseUser => _firebaseUser;
  /// Getter for app user profile
  AppUser? get appUser => _appUser;
  /// Getter for loading state
  bool get isLoading => _isLoading;
  /// Getter for error messages
  String? get errorMessage => _errorMessage;
  /// Getter for authentication status (both Firebase and app user must exist)
  bool get isAuthenticated => _firebaseUser != null && _appUser != null;
  
  /// Constructor initializes authentication state listener
  AuthProvider() {
    _initializeAuthState();
  }

  /// Initialize Firebase authentication state listener
  /// Automatically handles user sign-in and sign-out events
  void _initializeAuthState() {
    AuthService.authStateChanges.listen((User? user) async {
      if (user != null) {
        /// User successfully signed in - load profile data
        _firebaseUser = user;
        await _loadUserProfile();
      } else {
        /// User signed out - clear all user data
        _firebaseUser = null;
        _appUser = null;
      }
      notifyListeners();
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      if (_firebaseUser?.uid != null) {
        // Debug current state
        await FirebaseDebugUtils.debugCurrentUserState();
        
        _appUser = await AuthService.getUserProfile(_firebaseUser!.uid);
        if (_appUser == null) {
          AppLogger.warning('User profile not found for uid: ${_firebaseUser!.uid}');
          // For now, sign out the user if no profile exists
          // This prevents the user from being stuck in a bad state
          AppLogger.info('Signing out user due to missing profile');
          await AuthService.signOut();
        }
      }
    } catch (e) {
      AppLogger.error('Error loading user profile', error: e);
      _appUser = null;
    }
  }

  /// Sign in with email and password
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

  /// Create account with email and password
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

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.signInWithGoogle();
      
      if (result.isSuccess) {
        _clearError();
        AppLogger.info('Google Sign-In successful');
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Error during Google sign-in');
      AppLogger.error('Google Sign-In error in provider', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.signOut();
      
      if (result.isSuccess) {
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

  /// Send password reset email
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

  /// Send email verification
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

  /// Reload user to check verification status
  Future<bool> reloadUser() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.reloadUser();
      
      if (result.isSuccess) {
        // Reload the user profile after successful reload
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

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await AuthService.updateUserProfile(updates);
      
      if (success) {
        // Reload user profile
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

  /// Refresh user data
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      await _loadUserProfile();
      notifyListeners();
    }
  }

  // Helper methods
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
