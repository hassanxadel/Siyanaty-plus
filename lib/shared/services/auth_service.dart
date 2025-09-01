import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_logger.dart';
import '../../domain/entities/app_user.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  static User? get currentUser => _auth.currentUser;
  
  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  /// **SIGN IN PROCESS**
  /// 1. Authenticate with Firebase Auth
  /// 2. Check if user is in authorized users list
  /// 3. Update last login timestamp
  static Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting sign in for email: $email');
      
      // Step 1: Authenticate with Firebase
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Authentication failed - no user returned');
      }

      // Step 2: Ensure user profile exists (creates if missing)
      await _ensureUserProfileExists(credential.user!);

      // Step 3: Check if user is authorized
      final bool isAuthorized = await _checkUserAuthorization(credential.user!.uid);
      
      if (!isAuthorized) {
        // Sign out unauthorized user
        await _auth.signOut();
        AppLogger.warning('Unauthorized access attempt by: $email');
        return AuthResult.failure('Access denied. You are not authorized to use this app.');
      }

      // Step 4: Update user activity
      await _updateUserActivity(credential.user!.uid);
      
      AppLogger.info('Successful sign in for: $email');
      return AuthResult.success('Welcome back!', credential.user);
      
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error during sign in', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      // Handle known Firebase Auth plugin casting error
      if (e.toString().contains('PigeonUserDetails')) {
        AppLogger.warning('Firebase Auth plugin casting error - ignoring', error: e);
        // The user is actually signed in, just continue
        if (_auth.currentUser != null) {
          // Check if user profile exists, create if missing
          await _ensureUserProfileExists(_auth.currentUser!);
          await _updateUserActivity(_auth.currentUser!.uid);
          return AuthResult.success('Welcome back!', _auth.currentUser);
        }
      }
      
      AppLogger.error('Unexpected error during sign in', error: e);
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// **REGISTRATION PROCESS**
  /// 1. Validate input requirements
  /// 2. Create Firebase Auth account
  /// 3. Add user to authorized users list
  /// 4. Set up user profile
  static Future<AuthResult> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      AppLogger.info('Attempting registration for email: $email');
      
      // Step 1: Validate input
      final validation = _validateRegistrationInput(email, password, fullName);
      if (!validation.isValid) {
        return AuthResult.failure(validation.errorMessage!);
      }

      // Step 2: Create Firebase Auth account
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Account creation failed');
      }

      // Step 3: Update user profile
      await credential.user!.updateDisplayName(fullName);

      // Step 4: Send email verification
      try {
        await credential.user!.sendEmailVerification();
        AppLogger.info('Email verification sent to: $email');
      } catch (e) {
        AppLogger.warning('Failed to send email verification', error: e);
        // Continue with registration even if verification email fails
      }

      // Step 5: Add to authorized users and create profile
      try {
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email.trim().toLowerCase(),
          fullName: fullName,
          phoneNumber: phoneNumber,
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: emergencyContactPhone,
        );
        AppLogger.info('Successful registration for: $email');
        return AuthResult.success('Account created successfully! Please check your email to verify your account.', credential.user);
      } catch (profileError) {
        // If profile creation fails, delete the Firebase Auth user
        AppLogger.error('Profile creation failed, cleaning up Firebase Auth user', error: profileError);
        try {
          await credential.user!.delete();
        } catch (deleteError) {
          AppLogger.error('Failed to cleanup Firebase Auth user', error: deleteError);
        }
        return AuthResult.failure('Failed to create user profile. Please try again.');
      }
      
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error during registration', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      // Handle known Firebase Auth plugin casting error
      if (e.toString().contains('PigeonUserDetails')) {
        AppLogger.warning('Firebase Auth plugin casting error during registration - ignoring', error: e);
        // The user is actually created, check if current user exists
        if (_auth.currentUser != null) {
          try {
            await _createUserProfile(
              uid: _auth.currentUser!.uid,
              email: email.trim().toLowerCase(),
              fullName: fullName,
              phoneNumber: phoneNumber,
            );
            AppLogger.info('Successful registration for: $email (recovered from plugin error)');
            return AuthResult.success('Account created successfully! Welcome to Siyana+', _auth.currentUser);
          } catch (profileError) {
            AppLogger.error('Profile creation failed after plugin error recovery', error: profileError);
            return AuthResult.failure('Account created but profile setup failed. Please contact support.');
          }
        }
      }
      
      AppLogger.error('Unexpected error during registration', error: e);
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// **GOOGLE SIGN-IN PROCESS**
  static Future<AuthResult> signInWithGoogle() async {
    try {
      AppLogger.info('Starting Google Sign-In process');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        AppLogger.info('Google Sign-In cancelled by user');
        return AuthResult.failure('Sign-in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        return AuthResult.failure('Google Sign-In failed');
      }

      // Ensure user profile exists (creates if missing)
      await _ensureUserProfileExists(userCredential.user!);

      // Check if user is authorized
      final bool isAuthorized = await _checkUserAuthorization(userCredential.user!.uid);
      
      if (!isAuthorized) {
        // Sign out unauthorized user
        await signOut();
        AppLogger.warning('Unauthorized Google Sign-In attempt by: ${userCredential.user!.email}');
        return AuthResult.failure('Access denied. You are not authorized to use this app.');
      }

      // Update last login activity
      await _updateUserActivity(userCredential.user!.uid);
      
      AppLogger.info('Successful Google Sign-In for: ${userCredential.user!.email}');
      return AuthResult.success('Welcome!', userCredential.user);
      
    } catch (e) {
      AppLogger.error('Error during Google Sign-In', error: e);
      
      // Handle specific Google Sign-In errors
      if (e.toString().contains('sign_in_failed')) {
        if (e.toString().contains('10:')) {
          return AuthResult.failure('Google Sign-In configuration error. Please contact support.');
        } else if (e.toString().contains('7:')) {
          return AuthResult.failure('Network error. Please check your internet connection.');
        }
      }
      
      return AuthResult.failure('Google Sign-In failed. Please try again.');
    }
  }

  /// **SIGN OUT PROCESS**
  static Future<AuthResult> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      AppLogger.info('User signed out successfully');
      return AuthResult.success('Signed out successfully');
    } catch (e) {
      AppLogger.error('Error during sign out', error: e);
      return AuthResult.failure('Error signing out. Please try again.');
    }
  }

  /// **PASSWORD RESET**
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      AppLogger.info('Password reset email sent to: $email');
      return AuthResult.success('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Error sending password reset email', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Unexpected error sending password reset email', error: e);
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// **EMAIL VERIFICATION**
  static Future<AuthResult> sendEmailVerification() async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No user is currently signed in');
      }
      
      if (currentUser!.emailVerified) {
        return AuthResult.failure('Email is already verified');
      }
      
      await currentUser!.sendEmailVerification();
      AppLogger.info('Email verification sent to: ${currentUser!.email}');
      return AuthResult.success('Verification email sent. Check your inbox and click the link to verify your account.');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Error sending email verification', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Unexpected error sending email verification', error: e);
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// **RELOAD USER TO CHECK VERIFICATION STATUS**
  static Future<AuthResult> reloadUser() async {
    try {
      if (currentUser == null) {
        return AuthResult.failure('No user is currently signed in');
      }
      
      await currentUser!.reload();
      AppLogger.info('User reloaded successfully');
      return AuthResult.success('User data refreshed successfully');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Error reloading user', error: e);
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.error('Unexpected error reloading user', error: e);
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// **USER AUTHORIZATION CHECK**
  /// Checks if user exists in authorized users collection
  static Future<bool> _checkUserAuthorization(String uid) async {
    try {
      final doc = await _firestore.collection('authorized_users').doc(uid).get();
      final isAuthorized = doc.exists && (doc.data()?['isActive'] ?? false);
      
      AppLogger.debug('Authorization check for $uid: $isAuthorized');
      return isAuthorized;
    } catch (e) {
      AppLogger.error('Error checking user authorization', error: e);
      // In case of error, deny access for security
      return false;
    }
  }

  /// **CREATE USER PROFILE**
  /// Creates user profile and adds to authorized users
  static Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      AppLogger.info('Creating user profile for uid: $uid, email: $email');
      final now = FieldValue.serverTimestamp();
      
      // Create authorized user record first
      AppLogger.debug('Creating authorized_users document');
      await _firestore.collection('authorized_users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'isActive': true,
        'role': 'user', // Default role
        'createdAt': now,
        'lastLoginAt': now,
        'registrationMethod': 'email',
      });
      AppLogger.debug('authorized_users document created successfully');

      // Create user profile record
      AppLogger.debug('Creating users document');
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'profileImageUrl': null,
        'preferences': {
          'theme': 'dark',
          'notifications': true,
          'language': 'en',
        },
        'stats': {
          'totalCars': 0,
          'totalMaintenanceRecords': 0,
          'totalReminders': 0,
        },
        'createdAt': now,
        'updatedAt': now,
      });
      AppLogger.debug('users document created successfully');

      AppLogger.info('User profile created successfully for: $email');
    } catch (e) {
      AppLogger.error('Error creating user profile for $uid', error: e);
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  /// **ENSURE USER PROFILE EXISTS**
  /// Creates missing user profile for existing Firebase Auth users
  static Future<void> _ensureUserProfileExists(User user) async {
    try {
      // Check if authorized_users document exists
      final authDoc = await _firestore.collection('authorized_users').doc(user.uid).get();
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!authDoc.exists || !userDoc.exists) {
        AppLogger.info('Creating missing profile for existing user: ${user.email}');
        
        // Extract name from email or use display name
        final fullName = user.displayName ?? 
                        user.email?.split('@').first.split('.').map((s) => 
                          s[0].toUpperCase() + s.substring(1)).join(' ') ?? 
                        'User';
        
        await _createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          fullName: fullName,
          phoneNumber: user.phoneNumber,
        );
        
        AppLogger.info('Missing profile created successfully for: ${user.email}');
      }
    } catch (e) {
      AppLogger.error('Error ensuring user profile exists', error: e);
      // Don't throw - allow sign-in to continue
    }
  }

  /// **UPDATE USER ACTIVITY**
  /// Updates last login timestamp (creates document if it doesn't exist)
  static Future<void> _updateUserActivity(String uid) async {
    try {
      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('authorized_users').doc(uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.warning('Failed to update user activity', error: e);
      // Non-critical error, don't throw
    }
  }

  /// **INPUT VALIDATION**
  static ValidationResult _validateRegistrationInput(String email, String password, String fullName) {
    // Email validation
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return ValidationResult(false, 'Please enter a valid email address');
    }

    // Password validation
    if (password.length < 8) {
      return ValidationResult(false, 'Password must be at least 8 characters long');
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return ValidationResult(false, 'Password must contain at least one uppercase letter, one lowercase letter, and one number');
    }

    // Full name validation
    if (fullName.trim().length < 2) {
      return ValidationResult(false, 'Please enter your full name (at least 2 characters)');
    }

    return ValidationResult(true);
  }

  /// **ERROR MESSAGE MAPPING**
  static String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }

  /// **GET USER PROFILE**
  static Future<AppUser?> getUserProfile([String? uid]) async {
    try {
      final userId = uid ?? currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return AppUser.fromFirestore(doc.data()!);
    } catch (e) {
      AppLogger.error('Error fetching user profile', error: e);
      return null;
    }
  }

  /// **UPDATE USER PROFILE**
  static Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      final now = FieldValue.serverTimestamp();
      
      // Update users collection
      final userUpdates = Map<String, dynamic>.from(updates);
      userUpdates['updatedAt'] = now;
      await _firestore.collection('users').doc(uid).update(userUpdates);
      
      // Update authorized_users collection (only for relevant fields)
      final authUpdates = <String, dynamic>{};
      if (updates.containsKey('fullName')) {
        authUpdates['fullName'] = updates['fullName'];
      }
      if (updates.containsKey('phoneNumber')) {
        authUpdates['phoneNumber'] = updates['phoneNumber'];
      }
      if (updates.containsKey('emergencyContactName')) {
        authUpdates['emergencyContactName'] = updates['emergencyContactName'];
      }
      if (updates.containsKey('emergencyContactPhone')) {
        authUpdates['emergencyContactPhone'] = updates['emergencyContactPhone'];
      }
      if (authUpdates.isNotEmpty) {
        await _firestore.collection('authorized_users').doc(uid).update(authUpdates);
      }
      
      AppLogger.info('User profile updated');
      return true;
    } catch (e) {
      AppLogger.error('Error updating user profile', error: e);
      return false;
    }
  }
}

/// **AUTHENTICATION RESULT CLASS**
class AuthResult {
  final bool isSuccess;
  final String message;
  final User? user;

  AuthResult._({required this.isSuccess, required this.message, this.user});

  factory AuthResult.success(String message, [User? user]) {
    return AuthResult._(isSuccess: true, message: message, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, message: message);
  }
}

/// **VALIDATION RESULT CLASS**
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult(this.isValid, [this.errorMessage]);
}
