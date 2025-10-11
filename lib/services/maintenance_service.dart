import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';
import '../models/backup_maintenance.dart';
import '../models/backup_reminder.dart';
import '../shared/utils/app_logger.dart';
import 'firebase_maintenance_service.dart';

/// Service class for managing maintenance records
/// Handles business logic, validation, and database operations for maintenance
class MaintenanceService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add a new maintenance record
  Future<MaintenanceOperationResult> addMaintenance({
    required int reminderId,
    required String title,
    required String description,
    required double cost,
    required DateTime maintenanceDate,
    required MaintenanceType type,
    String? mechanicName,
    String? invoiceNumber,
  }) async {
    try {
      if (!isUserAuthenticated) {
        return MaintenanceOperationResult.failure('User not authenticated');
      }

      final userId = _currentUserId!;

      // Validate inputs
      if (title.trim().isEmpty) {
        return MaintenanceOperationResult.failure('Title is required');
      }

      if (description.trim().isEmpty) {
        return MaintenanceOperationResult.failure('Description is required');
      }

      if (cost < 0) {
        return MaintenanceOperationResult.failure('Cost cannot be negative');
      }

      // Check if reminder exists and belongs to user
      final reminder = await _databaseHelper.getReminderById(reminderId, userId);
      if (reminder == null) {
        return MaintenanceOperationResult.failure('Reminder not found or access denied');
      }

      final maintenance = BackupMaintenance(
        id: null, // Let database auto-generate
        reminderId: reminderId,
        title: title.trim(),
        description: description.trim(),
        cost: cost,
        maintenanceDate: maintenanceDate,
        type: type,
        mechanicName: mechanicName?.trim(),
        invoiceNumber: invoiceNumber?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _databaseHelper.insertMaintenance(maintenance);
      AppLogger.info('Maintenance record added successfully with ID: $id');

      // Backup to Firebase if user is authenticated
      if (isUserAuthenticated) {
        try {
          await FirebaseMaintenanceService.backupMaintenanceToFirestore();
          AppLogger.info('Maintenance record backed up to Firebase');
        } catch (e) {
          AppLogger.error('Failed to backup maintenance record to Firebase', error: e);
          // Don't fail the operation if backup fails
        }
      }

      return MaintenanceOperationResult.success('Maintenance record added successfully');
    } catch (e) {
      AppLogger.error('Error adding maintenance record', error: e);
      return MaintenanceOperationResult.failure('Failed to add maintenance record: $e');
    }
  }

  /// Get all maintenance records for the current user
  Future<List<BackupMaintenance>> getAllMaintenance() async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final userId = _currentUserId!;
      return await _databaseHelper.getAllMaintenance(userId);
    } catch (e) {
      AppLogger.error('Error getting all maintenance records', error: e);
      return [];
    }
  }

  /// Get maintenance records by type
  Future<List<BackupMaintenance>> getMaintenanceByType(MaintenanceType type) async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final userId = _currentUserId!;
      return await _databaseHelper.getMaintenanceByType(userId, type);
    } catch (e) {
      AppLogger.error('Error getting maintenance records by type', error: e);
      return [];
    }
  }

  /// Get maintenance records by reminder ID
  Future<List<BackupMaintenance>> getMaintenanceByReminder(int reminderId) async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final userId = _currentUserId!;
      return await _databaseHelper.getMaintenanceByReminder(reminderId, userId);
    } catch (e) {
      AppLogger.error('Error getting maintenance records by reminder', error: e);
      return [];
    }
  }

  /// Get maintenance records with full info (maintenance + reminder + car details)
  Future<List<MaintenanceWithInfo>> getAllMaintenanceWithInfo() async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final userId = _currentUserId!;
      final maintenanceMaps = await _databaseHelper.getAllMaintenanceWithInfo(userId);
      return maintenanceMaps.map((map) => MaintenanceWithInfo.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting maintenance records with info', error: e);
      return [];
    }
  }

  /// Update maintenance record
  Future<MaintenanceOperationResult> updateMaintenance({
    required String maintenanceId,
    required String title,
    required String description,
    required double cost,
    required DateTime maintenanceDate,
    required MaintenanceType type,
    String? mechanicName,
    String? invoiceNumber,
  }) async {
    try {
      if (!isUserAuthenticated) {
        return MaintenanceOperationResult.failure('User not authenticated');
      }

      final userId = _currentUserId!;

      // Validate inputs
      if (title.trim().isEmpty) {
        return MaintenanceOperationResult.failure('Title is required');
      }

      if (description.trim().isEmpty) {
        return MaintenanceOperationResult.failure('Description is required');
      }

      if (cost < 0) {
        return MaintenanceOperationResult.failure('Cost cannot be negative');
      }

      // Get existing maintenance record
      final existingMaintenance = await _databaseHelper.getMaintenanceById(int.parse(maintenanceId), userId);
      if (existingMaintenance == null) {
        return MaintenanceOperationResult.failure('Maintenance record not found or access denied');
      }

      final updatedMaintenance = existingMaintenance.copyWith(
        title: title.trim(),
        description: description.trim(),
        cost: cost,
        maintenanceDate: maintenanceDate,
        type: type,
        mechanicName: mechanicName?.trim(),
        invoiceNumber: invoiceNumber?.trim(),
        updatedAt: DateTime.now(),
      );

      final rowsUpdated = await _databaseHelper.updateMaintenance(updatedMaintenance, userId);
      if (rowsUpdated > 0) {
        AppLogger.info('Maintenance record updated successfully');
        
        // Backup to Firebase if user is authenticated
        if (isUserAuthenticated) {
          try {
            await FirebaseMaintenanceService.backupMaintenanceToFirestore();
            AppLogger.info('Updated maintenance record backed up to Firebase');
          } catch (e) {
            AppLogger.error('Failed to backup updated maintenance record to Firebase', error: e);
            // Don't fail the operation if backup fails
          }
        }
        
        return MaintenanceOperationResult.success('Maintenance record updated successfully');
      } else {
        return MaintenanceOperationResult.failure('Failed to update maintenance record');
      }
    } catch (e) {
      AppLogger.error('Error updating maintenance record', error: e);
      return MaintenanceOperationResult.failure('Failed to update maintenance record: $e');
    }
  }

  /// Delete maintenance record
  Future<MaintenanceOperationResult> deleteMaintenance(int maintenanceId) async {
    try {
      if (!isUserAuthenticated) {
        return MaintenanceOperationResult.failure('User not authenticated');
      }

      final userId = _currentUserId!;
      final rowsDeleted = await _databaseHelper.deleteMaintenance(maintenanceId, userId);

      if (rowsDeleted > 0) {
        AppLogger.info('Maintenance record deleted successfully');
        
        // Backup to Firebase if user is authenticated
        if (isUserAuthenticated) {
          try {
            await FirebaseMaintenanceService.backupMaintenanceToFirestore();
            AppLogger.info('Maintenance record deletion backed up to Firebase');
          } catch (e) {
            AppLogger.error('Failed to backup maintenance record deletion to Firebase', error: e);
            // Don't fail the operation if backup fails
          }
        }
        
        return MaintenanceOperationResult.success('Maintenance record deleted successfully');
      } else {
        return MaintenanceOperationResult.failure('Maintenance record not found or access denied');
      }
    } catch (e) {
      AppLogger.error('Error deleting maintenance record', error: e);
      return MaintenanceOperationResult.failure('Failed to delete maintenance record: $e');
    }
  }

  /// Search maintenance records
  Future<List<BackupMaintenance>> searchMaintenance(String query) async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final userId = _currentUserId!;
      return await _databaseHelper.searchMaintenance(userId, query);
    } catch (e) {
      AppLogger.error('Error searching maintenance records', error: e);
      return [];
    }
  }

  /// Get maintenance count for current user
  Future<int> getMaintenanceCount() async {
    try {
      if (!isUserAuthenticated) {
        return 0;
      }

      final userId = _currentUserId!;
      return await _databaseHelper.getMaintenanceCount(userId);
    } catch (e) {
      AppLogger.error('Error getting maintenance count', error: e);
      return 0;
    }
  }

  /// Get total maintenance cost for current user
  Future<double> getTotalMaintenanceCost() async {
    try {
      if (!isUserAuthenticated) {
        return 0.0;
      }

      final userId = _currentUserId!;
      return await _databaseHelper.getTotalMaintenanceCost(userId);
    } catch (e) {
      AppLogger.error('Error getting total maintenance cost', error: e);
      return 0.0;
    }
  }

  /// Get available reminders for maintenance assignment
  Future<List<BackupReminder>> getAvailableReminders() async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }

      final userId = _currentUserId!;
      // Get all reminders for the user
      return await _databaseHelper.getAllReminders(userId);
    } catch (e) {
      AppLogger.error('Error getting available reminders', error: e);
      return [];
    }
  }


  /// Clear all maintenance records (use with caution)
  Future<MaintenanceOperationResult> clearAllMaintenance() async {
    try {
      if (!isUserAuthenticated) {
        return MaintenanceOperationResult.failure('User not authenticated');
      }

      final userId = _currentUserId!;
      final rowsDeleted = await _databaseHelper.clearAllMaintenance(userId);
      AppLogger.info('Cleared $rowsDeleted maintenance records');

      return MaintenanceOperationResult.success('All maintenance records cleared successfully');
    } catch (e) {
      AppLogger.error('Error clearing maintenance records', error: e);
      return MaintenanceOperationResult.failure('Failed to clear maintenance records: $e');
    }
  }
}

/// Result class for maintenance operations
class MaintenanceOperationResult {
  final bool success;
  final String message;

  const MaintenanceOperationResult({
    required this.success,
    required this.message,
  });

  factory MaintenanceOperationResult.success(String message) {
    return MaintenanceOperationResult(success: true, message: message);
  }

  factory MaintenanceOperationResult.failure(String message) {
    return MaintenanceOperationResult(success: false, message: message);
  }
}
