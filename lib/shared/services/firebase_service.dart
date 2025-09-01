import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_logger.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
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
