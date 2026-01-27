import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseService {
  static bool _isInitialized = false;
  
  static FirebaseAuth get auth {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return FirebaseAuth.instance;
  }
  
  static FirebaseFirestore get firestore {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return FirebaseFirestore.instance;
  }
  
  static FirebaseStorage get storage {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return FirebaseStorage.instance;
  }
  
  static bool get isInitialized => _isInitialized;
  
  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        AppLogger.info('Firebase already initialized');
        return;
      }
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      _isInitialized = false;
      AppLogger.error('Failed to initialize Firebase - this is expected if Firebase is not configured yet', error: e);
      // Don't rethrow - let app continue without Firebase
      throw Exception('Firebase not configured: ${e.toString()}');
    }
  }
  
  // Auth methods
  static User? get currentUser => auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  
  static Stream<User?> get authStateChanges => auth.authStateChanges();
  
  static Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      AppLogger.error('Email/Password sign in failed', error: e);
      rethrow;
    }
  }
  
  static Future<UserCredential> createUserWithEmailPassword(String email, String password) async {
    try {
      return await auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      AppLogger.error('User creation failed', error: e);
      rethrow;
    }
  }
  
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      AppLogger.info('User signed out successfully');
    } catch (e) {
      AppLogger.error('Sign out failed', error: e);
      rethrow;
    }
  }
  
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent');
    } catch (e) {
      AppLogger.error('Password reset email failed', error: e);
      rethrow;
    }
  }
}
