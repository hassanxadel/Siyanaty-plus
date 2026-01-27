import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../models/backup_maintenance.dart';
import '../models/backup_reminder.dart';
import '../shared/utils/app_logger.dart';

/// Firebase service for backing up and restoring maintenance records
class FirebaseMaintenanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  static bool get isUserAuthenticated => _auth.currentUser != null;

  /// Backup maintenance records to Firestore
  static Future<MaintenanceBackupResult> backupMaintenanceToFirestore() async {
    if (!isUserAuthenticated) {
      return MaintenanceBackupResult.failure('User not authenticated');
    }

    try {
      final userId = _currentUserId!;
      AppLogger.info('Starting maintenance backup for user: $userId');

      // Get all maintenance records from local database
      final maintenanceRecords = await _databaseHelper.getAllMaintenanceForBackup(userId);
      AppLogger.info('Found ${maintenanceRecords.length} maintenance records to backup');

      if (maintenanceRecords.isEmpty) {
        return MaintenanceBackupResult.success('No maintenance records to backup', 0, 0);
      }

      int successCount = 0;
      int failureCount = 0;
      final batch = _firestore.batch();

      for (final maintenanceMap in maintenanceRecords) {
        try {
          final maintenance = BackupMaintenance.fromMap(maintenanceMap);
          
          // Get reminder info to store for restore matching
          BackupReminder? reminder;
          if (maintenance.reminderId != null) {
            reminder = await _databaseHelper.getReminderById(maintenance.reminderId!, userId);
          }
          final reminderTitle = reminder?.title ?? '';
          final carId = reminder?.carId ?? 0;
          final car = carId > 0 ? await _databaseHelper.getCarById(carId, userId) : null;
          final carVin = car?.vin ?? '';
          
          final maintenanceData = maintenance.toFirebaseMap();
          maintenanceData['reminder_title'] = reminderTitle; // Store for restore matching
          maintenanceData['car_vin'] = carVin; // Store for restore matching
          maintenanceData['local_id'] = maintenance.id; // Store local ID
          
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('maintenance')
              .doc(maintenance.id?.toString());

          batch.set(docRef, maintenanceData, SetOptions(merge: true));
          successCount++;
        } catch (e) {
          AppLogger.error('Failed to prepare maintenance record for backup', error: e);
          failureCount++;
        }
      }

      // Commit batch
      await batch.commit();
      AppLogger.info('Maintenance backup completed: $successCount success, $failureCount failed');

      return MaintenanceBackupResult.success(
        'Maintenance backup completed successfully',
        successCount,
        failureCount,
      );
    } catch (e) {
      AppLogger.error('Error during maintenance backup', error: e);
      return MaintenanceBackupResult.failure('Failed to backup maintenance records: $e');
    }
  }

  /// Restore maintenance records from Firestore
  static Future<MaintenanceRestoreResult> restoreMaintenanceFromFirestore() async {
    if (!isUserAuthenticated) {
      return MaintenanceRestoreResult.failure('User not authenticated');
    }

    try {
      final userId = _currentUserId!;
      AppLogger.info('Starting maintenance restore for user: $userId');

      // Get maintenance records from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('maintenance')
          .get();

      AppLogger.info('Found ${snapshot.docs.length} maintenance records in cloud');

      if (snapshot.docs.isEmpty) {
        return MaintenanceRestoreResult.success('No maintenance records found in cloud', 0, 0);
      }

      int successCount = 0;
      int failureCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final maintenanceData = doc.data();
          final maintenance = BackupMaintenance.fromFirebaseMap(maintenanceData);

          // Try to find reminder by multiple methods with fallbacks
          BackupReminder? reminder;
          final reminderTitle = maintenanceData['reminder_title'] as String?;
          final carVin = maintenanceData['car_vin'] as String?;
          
          // Method 1: Find by title and car VIN (if stored in backup)
          if (reminderTitle != null && reminderTitle.isNotEmpty && carVin != null && carVin.isNotEmpty && carVin != 'Not specified' && !carVin.startsWith('VIN')) {
            final car = await _databaseHelper.getCarByVin(carVin, userId);
            if (car != null) {
              final allReminders = await _databaseHelper.getRemindersByCar(car.id!, userId);
              try {
                reminder = allReminders.firstWhere((r) => r.title == reminderTitle);
              } catch (e) {
                // Title doesn't match, continue to next method
              }
            }
          }
          
          // Method 2: Find by reminder title across all reminders (if title is available)
          if (reminder == null && reminderTitle != null && reminderTitle.isNotEmpty) {
            final allReminders = await _databaseHelper.getAllReminders(userId);
            try {
              reminder = allReminders.firstWhere((r) => r.title == reminderTitle);
            } catch (e) {
              // Title doesn't match, continue to next method
            }
          }
          
          // Method 3: Find by old reminderId (for backward compatibility)
          if (maintenance.reminderId != null) {
            reminder ??= await _databaseHelper.getReminderById(maintenance.reminderId!, userId);
          }
          
          // Method 4: Fallback - if user has only one reminder, use that one
          // This handles cases where old backups don't have reminder_title
          if (reminder == null) {
            final allReminders = await _databaseHelper.getAllReminders(userId);
            if (allReminders.length == 1) {
              reminder = allReminders.first;
            } else if (allReminders.isNotEmpty) {
              // Try fuzzy matching by reminder title (if available)
              if (reminderTitle != null && reminderTitle.isNotEmpty) {
                try {
                  reminder = allReminders.firstWhere(
                    (r) => r.title.toLowerCase().contains(reminderTitle.toLowerCase()) || 
                           reminderTitle.toLowerCase().contains(r.title.toLowerCase()),
                  );
                } catch (e) {
                  // No fuzzy match found
                }
              }
              
              // If still no match, try matching maintenance title to reminder title
              // (sometimes maintenance title is similar to reminder title)
              if (reminder == null && maintenance.title.isNotEmpty) {
                try {
                  reminder = allReminders.firstWhere(
                    (r) => r.title.toLowerCase().contains(maintenance.title.toLowerCase()) || 
                           maintenance.title.toLowerCase().contains(r.title.toLowerCase()),
                  );
                } catch (e) {
                  // No match found
                }
              }
            }
          }
          
          if (reminder == null) {
            AppLogger.warning('Maintenance "${maintenance.title}" skipped: associated reminder not found. Please restore reminders first.');
            failureCount++;
            continue;
          }

          // Update maintenance with the new local reminder ID
          final maintenanceWithUpdatedReminderId = maintenance.copyWith(reminderId: reminder.id!);

          // Check if maintenance record already exists (by id if available)
          BackupMaintenance? existingMaintenance;
          final localId = maintenanceData['local_id'] as int?;
          if (localId != null) {
            existingMaintenance = await _databaseHelper.getMaintenanceById(localId, userId);
          } else if (maintenance.id != null) {
            existingMaintenance = await _databaseHelper.getMaintenanceById(maintenance.id!, userId);
          }

          if (existingMaintenance == null) {
            // Insert new maintenance record with updated reminder ID
            await _databaseHelper.insertMaintenance(maintenanceWithUpdatedReminderId);
            successCount++;
            AppLogger.info('Restored maintenance record: ${maintenance.title}');
          } else {
            // Update existing maintenance record if cloud version is newer
            if (maintenance.updatedAt.isAfter(existingMaintenance.updatedAt)) {
              final updatedMaintenance = maintenanceWithUpdatedReminderId.copyWith(id: existingMaintenance.id);
              await _databaseHelper.updateMaintenance(updatedMaintenance, userId);
              successCount++;
              AppLogger.info('Updated maintenance record: ${maintenance.title}');
            }
          }
        } catch (e) {
          AppLogger.error('Failed to restore maintenance record: ${doc.id}', error: e);
          failureCount++;
        }
      }

      AppLogger.info('Maintenance restore completed: $successCount success, $failureCount failed');

      return MaintenanceRestoreResult.success(
        'Maintenance restore completed successfully',
        successCount,
        failureCount,
      );
    } catch (e) {
      AppLogger.error('Error during maintenance restore', error: e);
      return MaintenanceRestoreResult.failure('Failed to restore maintenance records: $e');
    }
  }

  /// Get backup status for maintenance records
  static Future<MaintenanceBackupStatus> getBackupStatus() async {
    if (!isUserAuthenticated) {
      return const MaintenanceBackupStatus(
        localCount: 0,
        cloudCount: 0,
        lastBackupTime: null,
        isBackedUp: false,
      );
    }

    try {
      final userId = _currentUserId!;

      // Get local count
      final localCount = await _databaseHelper.getMaintenanceCount(userId);

      // Get cloud count
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('maintenance')
          .get();
      final cloudCount = snapshot.docs.length;

      // Get last backup time from user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final lastBackupTime = userData?['last_maintenance_backup_time'] != null
          ? (userData!['last_maintenance_backup_time'] as Timestamp).toDate()
          : null;

      return MaintenanceBackupStatus(
        localCount: localCount,
        cloudCount: cloudCount,
        lastBackupTime: lastBackupTime,
        isBackedUp: localCount == cloudCount && cloudCount > 0,
      );
    } catch (e) {
      AppLogger.error('Error getting maintenance backup status', error: e);
      return const MaintenanceBackupStatus(
        localCount: 0,
        cloudCount: 0,
        lastBackupTime: null,
        isBackedUp: false,
      );
    }
  }

  /// Update last backup time in user document
  static Future<void> updateLastBackupTime() async {
    if (!isUserAuthenticated) return;

    try {
      final userId = _currentUserId!;
      await _firestore.collection('users').doc(userId).update({
        'last_maintenance_backup_time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error updating last maintenance backup time', error: e);
    }
  }

  /// Delete all maintenance records from Firestore (use with caution)
  static Future<bool> clearCloudMaintenance() async {
    if (!isUserAuthenticated) return false;

    try {
      final userId = _currentUserId!;
      AppLogger.info('Clearing all maintenance records from cloud for user: $userId');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('maintenance')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info('Cleared ${snapshot.docs.length} maintenance records from cloud');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing cloud maintenance records', error: e);
      return false;
    }
  }

  /// Get maintenance records count by type from cloud
  static Future<Map<MaintenanceType, int>> getCloudMaintenanceCountByType() async {
    if (!isUserAuthenticated) {
      return {
        MaintenanceType.mechanics: 0,
        MaintenanceType.electrical: 0,
        MaintenanceType.suspension: 0,
        MaintenanceType.others: 0,
      };
    }

    try {
      final userId = _currentUserId!;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('maintenance')
          .get();

      final counts = <MaintenanceType, int>{
        MaintenanceType.mechanics: 0,
        MaintenanceType.electrical: 0,
        MaintenanceType.suspension: 0,
        MaintenanceType.others: 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final typeString = data['type'] as String?;
        final type = MaintenanceType.values.firstWhere(
          (e) => e.name == typeString,
          orElse: () => MaintenanceType.mechanics,
        );
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      AppLogger.error('Error getting cloud maintenance count by type', error: e);
      return {
        MaintenanceType.mechanics: 0,
        MaintenanceType.electrical: 0,
        MaintenanceType.suspension: 0,
        MaintenanceType.others: 0,
      };
    }
  }
}

/// Result class for maintenance backup operations
class MaintenanceBackupResult {
  final bool success;
  final String message;
  final int successCount;
  final int failureCount;

  const MaintenanceBackupResult({
    required this.success,
    required this.message,
    required this.successCount,
    required this.failureCount,
  });

  factory MaintenanceBackupResult.success(String message, int successCount, int failureCount) {
    return MaintenanceBackupResult(
      success: true,
      message: message,
      successCount: successCount,
      failureCount: failureCount,
    );
  }

  factory MaintenanceBackupResult.failure(String message) {
    return MaintenanceBackupResult(
      success: false,
      message: message,
      successCount: 0,
      failureCount: 0,
    );
  }
}

/// Result class for maintenance restore operations
class MaintenanceRestoreResult {
  final bool success;
  final String message;
  final int successCount;
  final int failureCount;

  const MaintenanceRestoreResult({
    required this.success,
    required this.message,
    required this.successCount,
    required this.failureCount,
  });

  factory MaintenanceRestoreResult.success(String message, int successCount, int failureCount) {
    return MaintenanceRestoreResult(
      success: true,
      message: message,
      successCount: successCount,
      failureCount: failureCount,
    );
  }

  factory MaintenanceRestoreResult.failure(String message) {
    return MaintenanceRestoreResult(
      success: false,
      message: message,
      successCount: 0,
      failureCount: 0,
    );
  }
}

/// Status class for maintenance backup information
class MaintenanceBackupStatus {
  final int localCount;
  final int cloudCount;
  final DateTime? lastBackupTime;
  final bool isBackedUp;

  const MaintenanceBackupStatus({
    required this.localCount,
    required this.cloudCount,
    required this.lastBackupTime,
    required this.isBackedUp,
  });
}
