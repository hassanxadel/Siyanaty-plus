import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/backup_reminder.dart';
import '../database/database_helper.dart';

/// Service for handling Firebase Firestore backup and restore operations for reminders
/// This service handles Firestore operations only - no Firebase Storage
class FirebaseReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static const String usersCollection = 'users';
  static const String remindersCollection = 'reminders';

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _currentUserId != null;

  /// Get user-specific reminders collection reference
  CollectionReference get _userRemindersCollection {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection(usersCollection)
        .doc(_currentUserId!)
        .collection(remindersCollection);
  }

  /// Backup a single reminder to Firebase
  Future<ReminderBackupResult> backupReminderToFirebase(BackupReminder reminder) async {
    try {
      if (!isUserAuthenticated) {
        return ReminderBackupResult.error('User not authenticated. Please sign in first.');
      }

      // Prepare reminder data for Firestore
      final reminderData = reminder.toFirebaseMap();
      reminderData['local_id'] = reminder.id;
      reminderData['backup_timestamp'] = FieldValue.serverTimestamp();

      await _userRemindersCollection.add(reminderData);

      return ReminderBackupResult.success('Reminder backed up successfully!');

    } catch (e) {
      return ReminderBackupResult.error('Failed to backup reminder: ${e.toString()}');
    }
  }

  /// Backup all reminders to Firebase
  Future<ReminderBackupResult> backupAllRemindersToFirebase() async {
    try {
      if (!isUserAuthenticated) {
        return ReminderBackupResult.error('User not authenticated. Please sign in first.');
      }
      // Get all local reminders for the user
      final localReminders = await _databaseHelper.getAllRemindersForBackup(_currentUserId!);
      
      if (localReminders.isEmpty) {
        return ReminderBackupResult.success('No reminders to backup.');
      }

      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];

      // Batch write for better performance
      WriteBatch batch = _firestore.batch();
      
      for (final reminderMap in localReminders) {
        try {
          final reminder = BackupReminder.fromMap(reminderMap);
          final reminderData = reminder.toFirebaseMap();
          reminderData['local_id'] = reminder.id;
          reminderData['backup_timestamp'] = FieldValue.serverTimestamp();

          final docRef = _userRemindersCollection.doc();
          batch.set(docRef, reminderData);
          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Failed to prepare reminder ${reminderMap['title']}: ${e.toString()}');
        }
      }

      if (successCount > 0) {
        await batch.commit();
      }

      if (failureCount > 0) {
        return ReminderBackupResult.error(
          'Backup completed with errors. $successCount reminders backed up successfully, $failureCount failed. Errors: ${errors.join(', ')}'
        );
      }

      return ReminderBackupResult.success(
        'All $successCount reminders backed up successfully!'
      );

    } catch (e) {
      return ReminderBackupResult.error('Failed to backup reminders: ${e.toString()}');
    }
  }

  /// Restore reminders from Firebase
  Future<ReminderRestoreResult> restoreRemindersFromFirebase() async {
    try {
      if (!isUserAuthenticated) {
        return ReminderRestoreResult.error('User not authenticated. Please sign in first.');
      }

      // Get reminders from Firestore
      final QuerySnapshot snapshot = await _userRemindersCollection.get();
      
      if (snapshot.docs.isEmpty) {
        return ReminderRestoreResult.success('No reminders found in cloud backup.');
      }

      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final reminder = BackupReminder.fromFirebaseMap(data);
          
          // Insert into local database
          await _databaseHelper.insertReminder(reminder);
          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Failed to restore reminder: ${e.toString()}');
        }
      }

      if (failureCount > 0) {
        return ReminderRestoreResult.error(
          'Restore completed with errors. $successCount reminders restored successfully, $failureCount failed. Errors: ${errors.join(', ')}'
        );
      }

      return ReminderRestoreResult.success(
        'All $successCount reminders restored successfully!'
      );

    } catch (e) {
      return ReminderRestoreResult.error('Failed to restore reminders: ${e.toString()}');
    }
  }

  /// Get backup status comparing local and cloud reminder counts
  Future<ReminderBackupStatus> getBackupStatus() async {
    try {
      if (!isUserAuthenticated) {
        return ReminderBackupStatus(
          localRemindersCount: 0,
          cloudRemindersCount: 0,
          lastBackupTime: null,
          isInSync: false,
        );
      }
      final userId = _currentUserId!;

      // Get local reminders count
      final localCount = await _databaseHelper.getRemindersCount(userId);

      // Get cloud reminders count
      final QuerySnapshot snapshot = await _userRemindersCollection.get();
      final cloudCount = snapshot.docs.length;

      // Get last backup time (from most recent backup_timestamp)
      DateTime? lastBackupTime;
      if (snapshot.docs.isNotEmpty) {
        final sortedDocs = snapshot.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['backup_timestamp'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['backup_timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
        
        final latestBackup = (sortedDocs.first.data() as Map<String, dynamic>)['backup_timestamp'] as Timestamp?;
        if (latestBackup != null) {
          lastBackupTime = latestBackup.toDate();
        }
      }

      return ReminderBackupStatus(
        localRemindersCount: localCount,
        cloudRemindersCount: cloudCount,
        lastBackupTime: lastBackupTime,
        isInSync: localCount == cloudCount,
      );

    } catch (e) {
      return ReminderBackupStatus(
        localRemindersCount: 0,
        cloudRemindersCount: 0,
        lastBackupTime: null,
        isInSync: false,
      );
    }
  }

  /// Clear all cloud reminders (use with caution)
  Future<ReminderBackupResult> clearCloudReminders() async {
    try {
      if (!isUserAuthenticated) {
        return ReminderBackupResult.error('User not authenticated. Please sign in first.');
      }

      final QuerySnapshot snapshot = await _userRemindersCollection.get();
      
      if (snapshot.docs.isEmpty) {
        return ReminderBackupResult.success('No cloud reminders to clear.');
      }

      WriteBatch batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();

      return ReminderBackupResult.success('All cloud reminders cleared successfully!');

    } catch (e) {
      return ReminderBackupResult.error('Failed to clear cloud reminders: ${e.toString()}');
    }
  }
}

/// Result classes for reminder backup operations

class ReminderBackupResult {
  final bool isSuccess;
  final String message;

  ReminderBackupResult._({required this.isSuccess, required this.message});

  factory ReminderBackupResult.success(String message) {
    return ReminderBackupResult._(isSuccess: true, message: message);
  }

  factory ReminderBackupResult.error(String message) {
    return ReminderBackupResult._(isSuccess: false, message: message);
  }

  bool get isFailure => !isSuccess;
}

class ReminderRestoreResult {
  final bool isSuccess;
  final String message;

  ReminderRestoreResult._({required this.isSuccess, required this.message});

  factory ReminderRestoreResult.success(String message) {
    return ReminderRestoreResult._(isSuccess: true, message: message);
  }

  factory ReminderRestoreResult.error(String message) {
    return ReminderRestoreResult._(isSuccess: false, message: message);
  }

  bool get isFailure => !isSuccess;
}

class ReminderBackupStatus {
  final int localRemindersCount;
  final int cloudRemindersCount;
  final DateTime? lastBackupTime;
  final bool isInSync;

  ReminderBackupStatus({
    required this.localRemindersCount,
    required this.cloudRemindersCount,
    required this.lastBackupTime,
    required this.isInSync,
  });

  String get statusMessage {
    if (isInSync) {
      return 'In sync - $localRemindersCount reminders';
    } else {
      return 'Out of sync - Local: $localRemindersCount, Cloud: $cloudRemindersCount';
    }
  }
}
