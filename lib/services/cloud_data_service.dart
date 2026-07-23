import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../shared/utils/app_logger.dart';
import 'firebase_backup_service.dart';
import 'firebase_maintenance_service.dart';
import 'firebase_reminder_service.dart';
import 'license_service.dart';
import 'mileage_service.dart';

/// The distinct kinds of user data the app stores in the cloud.
///
/// Each value maps 1:1 to a Firestore sub-collection under `users/{uid}` and to
/// the local service that owns it, so a card in the Detailed Backup screen can
/// act on exactly its own data and nothing else.
enum CloudDataCategory {
  cars,
  reminders,
  maintenance,
  mileage,
  licenses,
  obdScans,
  ocrScans,
  expenses,
}

extension CloudDataCategoryInfo on CloudDataCategory {
  /// Firestore sub-collection under `users/{uid}`.
  String get collectionName {
    switch (this) {
      case CloudDataCategory.cars:
        return 'cars';
      case CloudDataCategory.reminders:
        return 'reminders';
      case CloudDataCategory.maintenance:
        return 'maintenance';
      case CloudDataCategory.mileage:
        return 'mileage_entries';
      case CloudDataCategory.licenses:
        return 'license_images';
      case CloudDataCategory.obdScans:
        return 'obd_scans';
      case CloudDataCategory.ocrScans:
        return 'scans';
      case CloudDataCategory.expenses:
        return 'expenses';
    }
  }

  String get displayName {
    switch (this) {
      case CloudDataCategory.cars:
        return 'Cars';
      case CloudDataCategory.reminders:
        return 'Reminders';
      case CloudDataCategory.maintenance:
        return 'Maintenance';
      case CloudDataCategory.mileage:
        return 'Mileage';
      case CloudDataCategory.licenses:
        return 'Licenses';
      case CloudDataCategory.obdScans:
        return 'OBD Scans';
      case CloudDataCategory.ocrScans:
        return 'OCR Scans';
      case CloudDataCategory.expenses:
        return 'Expenses';
    }
  }

  /// Whether this category has a local backup/restore implementation.
  ///
  /// OBD/OCR/expenses are cloud-only for now — they can be counted and deleted,
  /// but there is no local sync path to back them up from.
  bool get supportsBackup {
    switch (this) {
      case CloudDataCategory.cars:
      case CloudDataCategory.reminders:
      case CloudDataCategory.maintenance:
      case CloudDataCategory.mileage:
      case CloudDataCategory.licenses:
        return true;
      case CloudDataCategory.obdScans:
      case CloudDataCategory.ocrScans:
      case CloudDataCategory.expenses:
        return false;
    }
  }
}

/// Result of a single-category cloud operation.
///
/// Follows the project convention of returning result objects rather than
/// throwing: screens branch on [isSuccess] instead of wrapping in try/catch.
class CloudDataResult {
  final bool isSuccess;
  final String message;
  final int itemsAffected;

  const CloudDataResult._({
    required this.isSuccess,
    required this.message,
    this.itemsAffected = 0,
  });

  factory CloudDataResult.success(String message, {int itemsAffected = 0}) =>
      CloudDataResult._(
        isSuccess: true,
        message: message,
        itemsAffected: itemsAffected,
      );

  factory CloudDataResult.error(String message) =>
      CloudDataResult._(isSuccess: false, message: message);
}

/// Per-category cloud operations: back up, restore and delete **one** kind of
/// data at a time.
///
/// This exists because [ComprehensiveBackupService] only offered all-or-nothing
/// operations — so every per-card button in the Detailed Backup screen was
/// backing up the entire app rather than its own section. Each method here
/// touches exactly one Firestore sub-collection.
class CloudDataService {
  static final CloudDataService _instance = CloudDataService._internal();
  factory CloudDataService() => _instance;
  CloudDataService._internal();

  static CloudDataService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseBackupService _carService = FirebaseBackupService();
  final FirebaseReminderService _reminderService = FirebaseReminderService();
  final MileageService _mileageService = MileageService();
  final LicenseService _licenseService = LicenseService();

  String? get _userId => _auth.currentUser?.uid;

  bool get isAuthenticated => _auth.currentUser != null;

  /// Firestore collection reference for [category] under the current user.
  CollectionReference<Map<String, dynamic>>? _collectionFor(
    CloudDataCategory category,
  ) {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection(category.collectionName);
  }

  /// Number of documents currently stored in the cloud for [category].
  Future<int> countInCloud(CloudDataCategory category) async {
    try {
      final collection = _collectionFor(category);
      if (collection == null) return 0;
      final snapshot = await collection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.warning(
        'Could not count cloud ${category.displayName}',
        error: e,
      );
      return 0;
    }
  }

  // -------------------------------------------------------------------
  // Backup — one category only
  // -------------------------------------------------------------------

  /// Back up **only** [category] to the cloud.
  Future<CloudDataResult> backupCategory(CloudDataCategory category) async {
    if (!isAuthenticated) {
      return CloudDataResult.error('Please sign in to back up your data');
    }
    if (!category.supportsBackup) {
      return CloudDataResult.error(
        '${category.displayName} is saved to the cloud automatically',
      );
    }

    try {
      AppLogger.info('Backing up ${category.displayName} only');

      switch (category) {
        case CloudDataCategory.cars:
          final result = await _carService.backupAllCarsToFirebase();
          return result.isSuccess
              ? CloudDataResult.success(
                  result.message,
                  itemsAffected: result.carsProcessed,
                )
              : CloudDataResult.error(result.message);

        case CloudDataCategory.reminders:
          final result = await _reminderService.backupAllRemindersToFirebase();
          return result.isSuccess
              ? CloudDataResult.success(result.message)
              : CloudDataResult.error(result.message);

        case CloudDataCategory.maintenance:
          final result =
              await FirebaseMaintenanceService.backupMaintenanceToFirestore();
          await FirebaseMaintenanceService.updateLastBackupTime();
          return result.success
              ? CloudDataResult.success(
                  result.message,
                  itemsAffected: result.successCount,
                )
              : CloudDataResult.error(result.message);

        case CloudDataCategory.mileage:
          final ok = await _mileageService.syncToFirebase();
          final entries = await _mileageService.getAllEntries();
          return ok
              ? CloudDataResult.success(
                  'Mileage backed up',
                  itemsAffected: entries.length,
                )
              : CloudDataResult.error('Failed to back up mileage');

        case CloudDataCategory.licenses:
          final result = await _licenseService.backupLicenseImagesToFirebase();
          return result.isSuccess
              ? CloudDataResult.success(
                  result.message,
                  itemsAffected: result.successCount,
                )
              : CloudDataResult.error(result.message);

        case CloudDataCategory.obdScans:
        case CloudDataCategory.ocrScans:
        case CloudDataCategory.expenses:
          return CloudDataResult.error('Not supported');
      }
    } catch (e) {
      AppLogger.error('Backup failed for ${category.displayName}', error: e);
      return CloudDataResult.error('Backup failed: $e');
    }
  }

  // -------------------------------------------------------------------
  // Restore — one category only
  // -------------------------------------------------------------------

  /// Restore **only** [category] from the cloud.
  Future<CloudDataResult> restoreCategory(CloudDataCategory category) async {
    if (!isAuthenticated) {
      return CloudDataResult.error('Please sign in to restore your data');
    }
    if (!category.supportsBackup) {
      return CloudDataResult.error(
        '${category.displayName} cannot be restored separately',
      );
    }

    try {
      AppLogger.info('Restoring ${category.displayName} only');

      switch (category) {
        case CloudDataCategory.cars:
          final result = await _carService.restoreCarsFromFirebase();
          return result.isSuccess
              ? CloudDataResult.success(
                  result.message,
                  itemsAffected: result.carsProcessed,
                )
              : CloudDataResult.error(result.message);

        case CloudDataCategory.reminders:
          final result = await _reminderService.restoreRemindersFromFirebase();
          return result.isSuccess
              ? CloudDataResult.success(result.message)
              : CloudDataResult.error(result.message);

        case CloudDataCategory.maintenance:
          final result =
              await FirebaseMaintenanceService.restoreMaintenanceFromFirestore();
          return result.success
              ? CloudDataResult.success(
                  result.message,
                  itemsAffected: result.successCount,
                )
              : CloudDataResult.error(result.message);

        case CloudDataCategory.mileage:
          final ok = await _mileageService.syncFromFirebase();
          return ok
              ? CloudDataResult.success('Mileage restored')
              : CloudDataResult.error('Failed to restore mileage');

        case CloudDataCategory.licenses:
          final result =
              await _licenseService.restoreLicenseImagesFromFirebase();
          return result.isSuccess
              ? CloudDataResult.success(
                  result.message,
                  itemsAffected: result.successCount,
                )
              : CloudDataResult.error(result.message);

        case CloudDataCategory.obdScans:
        case CloudDataCategory.ocrScans:
        case CloudDataCategory.expenses:
          return CloudDataResult.error('Not supported');
      }
    } catch (e) {
      AppLogger.error('Restore failed for ${category.displayName}', error: e);
      return CloudDataResult.error('Restore failed: $e');
    }
  }

  // -------------------------------------------------------------------
  // Delete — cloud only, local data is never touched
  // -------------------------------------------------------------------

  /// Delete **only** [category] from the cloud.
  ///
  /// Local data is deliberately left untouched — this removes the cloud copy,
  /// not the user's records on the device.
  Future<CloudDataResult> deleteCategoryFromCloud(
    CloudDataCategory category,
  ) async {
    if (!isAuthenticated) {
      return CloudDataResult.error('Please sign in to manage your cloud data');
    }

    try {
      final deleted = await _deleteCollection(category);
      AppLogger.info('Deleted $deleted cloud ${category.displayName}');
      return CloudDataResult.success(
        deleted == 0
            ? 'No ${category.displayName.toLowerCase()} in the cloud'
            : 'Deleted $deleted ${category.displayName.toLowerCase()} from the cloud',
        itemsAffected: deleted,
      );
    } catch (e) {
      AppLogger.error('Cloud delete failed for ${category.displayName}',
          error: e);
      return CloudDataResult.error('Delete failed: $e');
    }
  }

  /// Delete every category from the cloud, leaving local data intact.
  Future<CloudDataResult> deleteAllCloudData() async {
    if (!isAuthenticated) {
      return CloudDataResult.error('Please sign in to manage your cloud data');
    }

    try {
      var total = 0;
      final failed = <String>[];

      for (final category in CloudDataCategory.values) {
        try {
          total += await _deleteCollection(category);
        } catch (e) {
          // One failing collection must not abort the rest.
          AppLogger.warning(
            'Could not clear ${category.displayName}',
            error: e,
          );
          failed.add(category.displayName);
        }
      }

      if (failed.isNotEmpty) {
        return CloudDataResult.error(
          'Deleted $total items, but these could not be cleared: '
          '${failed.join(', ')}',
        );
      }

      AppLogger.info('Deleted all cloud data ($total items)');
      return CloudDataResult.success(
        total == 0
            ? 'There was no cloud data to delete'
            : 'Deleted all $total items from the cloud',
        itemsAffected: total,
      );
    } catch (e) {
      AppLogger.error('Delete-all cloud data failed', error: e);
      return CloudDataResult.error('Delete failed: $e');
    }
  }

  /// Delete every document in a category's collection.
  ///
  /// Firestore caps a write batch at 500 operations, so this pages through the
  /// collection in chunks rather than assuming it fits in one batch.
  Future<int> _deleteCollection(CloudDataCategory category) async {
    final collection = _collectionFor(category);
    if (collection == null) return 0;

    const pageSize = 400;
    var deleted = 0;

    while (true) {
      final snapshot = await collection.limit(pageSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snapshot.docs.length;

      // A short page means we've reached the end of the collection.
      if (snapshot.docs.length < pageSize) break;
    }

    return deleted;
  }
}
