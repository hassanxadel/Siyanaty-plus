import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import '../../shared/utils/app_logger.dart';
import '../../shared/utils/firebase_debug.dart';

// Main authentication manager for the entire app
class AuthProvider extends ChangeNotifier {
  // Core authentication data
  User? _firebaseUser;           // Firebase user object
  AppUser? _appUser;             // Custom app user profile
  bool _isLoading = false;       // Loading state for UI
  String? _errorMessage;         // Error messages for user
  
  // Public getters for UI access
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null && _appUser != null;
  
  // Initialize authentication listener when provider is created
  AuthProvider() {
    _initializeAuthState();
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
      notifyListeners();
    });
  }

  // Load user profile data from Firestore database
  Future<void> _loadUserProfile() async {
    try {
      if (_firebaseUser?.uid != null) {
        await FirebaseDebugUtils.debugCurrentUserState();
        
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

  // Login user with Google account
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

  // Logout user and clear all authentication data
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
