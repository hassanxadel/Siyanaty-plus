import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_logger.dart';

class FirebaseDebugUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Debug current user state
  static Future<void> debugCurrentUserState() async {
    try {
      final user = _auth.currentUser;
      AppLogger.info('=== FIREBASE DEBUG ===');
      
      if (user == null) {
        AppLogger.info('No current user authenticated');
        return;
      }

      AppLogger.info('Current user UID: ${user.uid}');
      AppLogger.info('Current user email: ${user.email}');
      AppLogger.info('Current user displayName: ${user.displayName}');
      AppLogger.info('Current user emailVerified: ${user.emailVerified}');

      // Check authorized_users document
      final authDoc = await _firestore.collection('authorized_users').doc(user.uid).get();
      if (authDoc.exists) {
        AppLogger.info('authorized_users document exists: ${authDoc.data()}');
      } else {
        AppLogger.warning('authorized_users document MISSING for uid: ${user.uid}');
      }

      // Check users document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        AppLogger.info('users document exists: ${userDoc.data()}');
      } else {
        AppLogger.warning('users document MISSING for uid: ${user.uid}');
      }

      AppLogger.info('=== END DEBUG ===');
    } catch (e) {
      AppLogger.error('Error in debug utils', error: e);
    }
  }

  /// Create missing user profile for existing Firebase Auth user
  static Future<void> createMissingUserProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('No current user to create profile for');
        return;
      }

      AppLogger.info('Creating missing profile for user: ${user.uid}');
      
      final now = FieldValue.serverTimestamp();
      
      // Create authorized user record
      await _firestore.collection('authorized_users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'isActive': true,
        'role': 'user',
        'createdAt': now,
        'lastLoginAt': now,
        'registrationMethod': 'manual_fix',
      });

      // Create user profile record
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': fullName,
        'phoneNumber': phoneNumber,
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

      AppLogger.info('Missing user profile created successfully');
    } catch (e) {
      AppLogger.error('Error creating missing user profile', error: e);
    }
  }

  /// Delete Firebase Auth user (for cleanup)
  static Future<void> deleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.info('No current user to delete');
        return;
      }

      AppLogger.info('Deleting Firebase Auth user: ${user.uid}');
      await user.delete();
      AppLogger.info('Firebase Auth user deleted');
    } catch (e) {
      AppLogger.error('Error deleting Firebase Auth user', error: e);
    }
  }

  /// List all users in authorized_users collection
  static Future<void> listAllAuthorizedUsers() async {
    try {
      final snapshot = await _firestore.collection('authorized_users').get();
      AppLogger.info('=== ALL AUTHORIZED USERS ===');
      
      for (final doc in snapshot.docs) {
        AppLogger.info('User ${doc.id}: ${doc.data()}');
      }
      
      if (snapshot.docs.isEmpty) {
        AppLogger.info('No authorized users found');
      }
      
      AppLogger.info('=== END AUTHORIZED USERS ===');
    } catch (e) {
      AppLogger.error('Error listing authorized users', error: e);
    }
  }
}
