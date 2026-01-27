import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_backup_service.dart';
import 'firebase_reminder_service.dart';
import 'firebase_maintenance_service.dart';
import 'mileage_service.dart';
import 'license_service.dart';
import '../shared/utils/app_logger.dart';

/// Comprehensive backup service that handles all data types
/// This service coordinates backup operations for cars, reminders, and maintenance records
class ComprehensiveBackupService {
  static final ComprehensiveBackupService _instance = ComprehensiveBackupService._internal();
  factory ComprehensiveBackupService() => _instance;
  ComprehensiveBackupService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseBackupService _carBackupService = FirebaseBackupService();
  final FirebaseReminderService _reminderBackupService = FirebaseReminderService();
  final MileageService _mileageService = MileageService();
  final LicenseService _licenseService = LicenseService();

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  /// Backup all user data to Firebase (cars, reminders, maintenance)
  Future<ComprehensiveBackupResult> backupAllDataToFirebase() async {
    if (!isUserAuthenticated) {
      return ComprehensiveBackupResult.failure('User not authenticated. Please sign in first.');
    }

    try {
      AppLogger.info('Starting comprehensive backup for user: $_currentUserId');
      
      // Track results for each data type
      final Map<String, dynamic> results = {};
      int totalSuccessCount = 0;
      int totalFailureCount = 0;
      final List<String> allErrors = [];

      // 1. Backup Cars
      AppLogger.info('Backing up cars...');
      final carResult = await _carBackupService.backupAllCarsToFirebase();
      results['cars'] = {
        'success': carResult.isSuccess,
        'message': carResult.message,
        'count': carResult.carsProcessed,
        'errors': carResult.errors ?? [],
      };
      totalSuccessCount += carResult.carsProcessed;
      if (carResult.errors != null) {
        allErrors.addAll(carResult.errors!);
        totalFailureCount += carResult.errors!.length;
      }

      // 2. Backup Reminders
      AppLogger.info('Backing up reminders...');
      final reminderResult = await _reminderBackupService.backupAllRemindersToFirebase();
      results['reminders'] = {
        'success': reminderResult.isSuccess,
        'message': reminderResult.message,
        'count': reminderResult.isSuccess ? 1 : 0, // Simplified for now
        'errors': reminderResult.isSuccess ? [] : [reminderResult.message],
      };
      if (reminderResult.isSuccess) {
        totalSuccessCount += 1; // Simplified for now
      } else {
        allErrors.add(reminderResult.message);
        totalFailureCount += 1;
      }

      // 3. Backup Maintenance Records
      AppLogger.info('Backing up maintenance records...');
      final maintenanceResult = await FirebaseMaintenanceService.backupMaintenanceToFirestore();
      results['maintenance'] = {
        'success': maintenanceResult.success,
        'message': maintenanceResult.message,
        'count': maintenanceResult.successCount,
        'errors': maintenanceResult.failureCount > 0 ? ['$maintenanceResult.failureCount maintenance records failed'] : [],
      };
      totalSuccessCount += maintenanceResult.successCount;
      if (maintenanceResult.failureCount > 0) {
        allErrors.add('$maintenanceResult.failureCount maintenance records failed');
        totalFailureCount += maintenanceResult.failureCount;
      }

      // 4. Backup Mileage Data
      AppLogger.info('Backing up mileage data...');
      try {
        final mileageSuccess = await _mileageService.syncToFirebase();
        final localMileage = await _mileageService.getAllEntries();
        results['mileage'] = {
          'success': mileageSuccess,
          'message': mileageSuccess ? 'Mileage data synced successfully' : 'Failed to sync mileage data',
          'count': localMileage.length,
          'errors': mileageSuccess ? [] : ['Failed to sync mileage data'],
        };
        if (mileageSuccess) {
          totalSuccessCount += localMileage.length;
        } else {
          totalFailureCount += 1;
          allErrors.add('Failed to sync mileage data');
        }
      } catch (e) {
        results['mileage'] = {
          'success': false,
          'message': 'Error backing up mileage data: $e',
          'count': 0,
          'errors': ['Error: $e'],
        };
        allErrors.add('Mileage backup error: $e');
        totalFailureCount += 1;
      }

      // 5. Backup License Images
      AppLogger.info('Backing up license images...');
      final licenseResult = await _licenseService.backupLicenseImagesToFirebase();
      results['licenses'] = {
        'success': licenseResult.isSuccess,
        'message': licenseResult.message,
        'count': licenseResult.successCount,
        'errors': licenseResult.errors,
      };
      totalSuccessCount += licenseResult.successCount;
      if (licenseResult.failureCount > 0) {
        allErrors.add('${licenseResult.failureCount} license images failed');
        totalFailureCount += licenseResult.failureCount;
      }

      // Update maintenance backup timestamp
      await FirebaseMaintenanceService.updateLastBackupTime();

      AppLogger.info('Comprehensive backup completed. Success: $totalSuccessCount, Failures: $totalFailureCount');

      return ComprehensiveBackupResult.success(
        'Comprehensive backup completed successfully',
        totalSuccessCount,
        totalFailureCount,
        results,
        allErrors,
      );

    } catch (e) {
      AppLogger.error('Error during comprehensive backup', error: e);
      return ComprehensiveBackupResult.failure('Failed to backup data: $e');
    }
  }

  /// Restore all user data from Firebase (cars, reminders, maintenance)
  Future<ComprehensiveRestoreResult> restoreAllDataFromFirebase() async {
    if (!isUserAuthenticated) {
      return ComprehensiveRestoreResult.failure('User not authenticated. Please sign in first.');
    }

    try {
      AppLogger.info('Starting comprehensive restore for user: $_currentUserId');
      
      // Track results for each data type
      final Map<String, dynamic> results = {};
      int totalSuccessCount = 0;
      int totalFailureCount = 0;
      final List<String> allErrors = [];

      // 1. Restore Cars
      AppLogger.info('Restoring cars...');
      final carResult = await _carBackupService.restoreCarsFromFirebase();
      results['cars'] = {
        'success': carResult.isSuccess,
        'message': carResult.message,
        'count': carResult.isSuccess ? 1 : 0,
        'errors': carResult.errors ?? [],
      };
      if (carResult.isSuccess) {
        totalSuccessCount += 1;
      } else {
        totalFailureCount += 1;
        allErrors.add(carResult.message);
      }

      // 2. Restore Reminders
      AppLogger.info('Restoring reminders...');
      final reminderResult = await _reminderBackupService.restoreRemindersFromFirebase();
      results['reminders'] = {
        'success': reminderResult.isSuccess,
        'message': reminderResult.message,
        'count': reminderResult.isSuccess ? 1 : 0,
        'errors': reminderResult.isSuccess ? [] : [reminderResult.message],
      };
      if (reminderResult.isSuccess) {
        totalSuccessCount += 1;
      } else {
        totalFailureCount += 1;
        allErrors.add(reminderResult.message);
      }

      // 3. Restore Maintenance Records
      AppLogger.info('Restoring maintenance records...');
      final maintenanceResult = await FirebaseMaintenanceService.restoreMaintenanceFromFirestore();
      results['maintenance'] = {
        'success': maintenanceResult.success,
        'message': maintenanceResult.message,
        'count': maintenanceResult.successCount,
        'errors': maintenanceResult.failureCount > 0 ? ['$maintenanceResult.failureCount maintenance records failed'] : [],
      };
      totalSuccessCount += maintenanceResult.successCount;
      if (maintenanceResult.failureCount > 0) {
        allErrors.add('$maintenanceResult.failureCount maintenance records failed');
        totalFailureCount += maintenanceResult.failureCount;
      }

      // 4. Restore Mileage Data
      AppLogger.info('Restoring mileage data...');
      try {
        final mileageSuccess = await _mileageService.syncFromFirebase();
        final cloudMileage = await _mileageService.getEntriesFromFirebase();
        results['mileage'] = {
          'success': mileageSuccess,
          'message': mileageSuccess ? 'Mileage data synced successfully' : 'Failed to sync mileage data',
          'count': cloudMileage.length,
          'errors': mileageSuccess ? [] : ['Failed to sync mileage data'],
        };
        if (mileageSuccess) {
          totalSuccessCount += cloudMileage.length;
        } else {
          totalFailureCount += 1;
          allErrors.add('Failed to sync mileage data');
        }
      } catch (e) {
        results['mileage'] = {
          'success': false,
          'message': 'Error restoring mileage data: $e',
          'count': 0,
          'errors': ['Error: $e'],
        };
        allErrors.add('Mileage restore error: $e');
        totalFailureCount += 1;
      }

      // 5. Restore License Images
      AppLogger.info('Restoring license images...');
      final licenseResult = await _licenseService.restoreLicenseImagesFromFirebase();
      results['licenses'] = {
        'success': licenseResult.isSuccess,
        'message': licenseResult.message,
        'count': licenseResult.successCount,
        'errors': licenseResult.errors,
      };
      totalSuccessCount += licenseResult.successCount;
      if (licenseResult.failureCount > 0) {
        allErrors.add('${licenseResult.failureCount} license images failed');
        totalFailureCount += licenseResult.failureCount;
      }

      AppLogger.info('Comprehensive restore completed. Success: $totalSuccessCount, Failures: $totalFailureCount');

      return ComprehensiveRestoreResult.success(
        'Comprehensive restore completed successfully',
        totalSuccessCount,
        totalFailureCount,
        results,
        allErrors,
      );

    } catch (e) {
      AppLogger.error('Error during comprehensive restore', error: e);
      return ComprehensiveRestoreResult.failure('Failed to restore data: $e');
    }
  }

  /// Get comprehensive backup status for all data types
  Future<ComprehensiveBackupStatus> getComprehensiveBackupStatus() async {
    if (!isUserAuthenticated) {
      return const ComprehensiveBackupStatus(
        carsBackedUp: false,
        remindersBackedUp: false,
        maintenanceBackedUp: false,
        lastBackupTime: null,
        totalLocalItems: 0,
        totalCloudItems: 0,
      );
    }

    try {
      // Get maintenance backup status (only one with status method)
      final maintenanceStatus = await FirebaseMaintenanceService.getBackupStatus();

      // For now, return basic status
      // TODO: Implement status methods for cars and reminders
      return ComprehensiveBackupStatus(
        carsBackedUp: false, // TODO: Implement car backup status
        remindersBackedUp: false, // TODO: Implement reminder backup status
        maintenanceBackedUp: maintenanceStatus.isBackedUp,
        lastBackupTime: maintenanceStatus.lastBackupTime,
        totalLocalItems: maintenanceStatus.localCount,
        totalCloudItems: maintenanceStatus.cloudCount,
      );

    } catch (e) {
      AppLogger.error('Error getting comprehensive backup status', error: e);
      return const ComprehensiveBackupStatus(
        carsBackedUp: false,
        remindersBackedUp: false,
        maintenanceBackedUp: false,
        lastBackupTime: null,
        totalLocalItems: 0,
        totalCloudItems: 0,
      );
    }
  }
}

/// Result class for comprehensive backup operations
class ComprehensiveBackupResult {
  final bool success;
  final String message;
  final int totalSuccessCount;
  final int totalFailureCount;
  final Map<String, dynamic> results;
  final List<String> errors;

  const ComprehensiveBackupResult({
    required this.success,
    required this.message,
    required this.totalSuccessCount,
    required this.totalFailureCount,
    required this.results,
    required this.errors,
  });

  factory ComprehensiveBackupResult.success(
    String message,
    int totalSuccessCount,
    int totalFailureCount,
    Map<String, dynamic> results,
    List<String> errors,
  ) {
    return ComprehensiveBackupResult(
      success: true,
      message: message,
      totalSuccessCount: totalSuccessCount,
      totalFailureCount: totalFailureCount,
      results: results,
      errors: errors,
    );
  }

  factory ComprehensiveBackupResult.failure(String message) {
    return ComprehensiveBackupResult(
      success: false,
      message: message,
      totalSuccessCount: 0,
      totalFailureCount: 0,
      results: {},
      errors: [],
    );
  }
}

/// Result class for comprehensive restore operations
class ComprehensiveRestoreResult {
  final bool success;
  final String message;
  final int totalSuccessCount;
  final int totalFailureCount;
  final Map<String, dynamic> results;
  final List<String> errors;

  const ComprehensiveRestoreResult({
    required this.success,
    required this.message,
    required this.totalSuccessCount,
    required this.totalFailureCount,
    required this.results,
    required this.errors,
  });

  factory ComprehensiveRestoreResult.success(
    String message,
    int totalSuccessCount,
    int totalFailureCount,
    Map<String, dynamic> results,
    List<String> errors,
  ) {
    return ComprehensiveRestoreResult(
      success: true,
      message: message,
      totalSuccessCount: totalSuccessCount,
      totalFailureCount: totalFailureCount,
      results: results,
      errors: errors,
    );
  }

  factory ComprehensiveRestoreResult.failure(String message) {
    return ComprehensiveRestoreResult(
      success: false,
      message: message,
      totalSuccessCount: 0,
      totalFailureCount: 0,
      results: {},
      errors: [],
    );
  }
}

/// Status class for comprehensive backup information
class ComprehensiveBackupStatus {
  final bool carsBackedUp;
  final bool remindersBackedUp;
  final bool maintenanceBackedUp;
  final DateTime? lastBackupTime;
  final int totalLocalItems;
  final int totalCloudItems;

  const ComprehensiveBackupStatus({
    required this.carsBackedUp,
    required this.remindersBackedUp,
    required this.maintenanceBackedUp,
    required this.lastBackupTime,
    required this.totalLocalItems,
    required this.totalCloudItems,
  });

  bool get isFullyBackedUp => carsBackedUp && remindersBackedUp && maintenanceBackedUp;
}
