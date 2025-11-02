import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import 'secure_database.dart';
import '../../shared/utils/app_logger.dart';

/// Service for migrating existing app data to secure storage
class MigrationService {
  static final SecureStorageService _secureStorage = SecureStorageService();
  
  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      // Check if there's existing data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final hasUserData = prefs.containsKey('user_id') || 
                         prefs.containsKey('user_email') ||
                         prefs.containsKey('firebase_uid');
      
      // Check if there's existing unencrypted database
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final oldDbPath = join(documentsDirectory.path, 'siyanaty_database.db');
      final oldDbExists = await File(oldDbPath).exists();
      
      // Check if secure storage is already configured
      final hasSecureData = await _secureStorage.isAuthenticated();
      
      return (hasUserData || oldDbExists) && !hasSecureData;
    } catch (e) {
      AppLogger.error('Error checking migration status', error: e);
      return false;
    }
  }

  /// Perform complete data migration
  static Future<MigrationResult> performMigration() async {
    try {
      AppLogger.info('Starting data migration to secure storage');
      
      final results = <String, bool>{};
      
      // Migrate SharedPreferences data
      final prefsResult = await _migrateSharedPreferences();
      results['shared_preferences'] = prefsResult;
      
      // Migrate database (handled by SecureDatabase initialization)
      final dbResult = await _migrateDatabaseData();
      results['database'] = dbResult;
      
      // Clean up old data if migration successful
      if (results.values.every((success) => success)) {
        await _cleanupOldData();
        AppLogger.info('Data migration completed successfully');
        return MigrationResult.success(results);
      } else {
        AppLogger.warning('Data migration completed with some failures');
        return MigrationResult.partial(results);
      }
      
    } catch (e) {
      AppLogger.error('Data migration failed', error: e);
      return MigrationResult.failure(e.toString());
    }
  }

  /// Migrate data from SharedPreferences to secure storage
  static Future<bool> _migrateSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Migrate user authentication data
      final userId = prefs.getString('user_id');
      final firebaseUid = prefs.getString('firebase_uid');
      
      if (userId != null) {
        await _secureStorage.storeUserId(userId);
        AppLogger.info('Migrated user ID to secure storage');
      }
      
      if (firebaseUid != null) {
        await _secureStorage.storeUserId(firebaseUid);
        AppLogger.info('Migrated Firebase UID to secure storage');
      }
      
      // Migrate app preferences
      final theme = prefs.getString('theme_mode');
      final language = prefs.getString('language');
      final notifications = prefs.getBool('notifications_enabled');
      
      // Store app preferences in a secure format
      if (theme != null || language != null || notifications != null) {
        // For now, we'll keep app preferences in SharedPreferences
        // as they're not sensitive data, but we could move them to secure storage
        AppLogger.info('App preferences migration completed');
      }
      
      return true;
    } catch (e) {
      AppLogger.error('SharedPreferences migration failed', error: e);
      return false;
    }
  }

  /// Migrate database data (handled by SecureDatabase)
  static Future<bool> _migrateDatabaseData() async {
    try {
      // Database migration is handled automatically by SecureDatabase
      // when it detects an existing unencrypted database
      await SecureDatabase.database;
      
      AppLogger.info('Database migration completed');
      return true;
    } catch (e) {
      AppLogger.error('Database migration failed', error: e);
      return false;
    }
  }

  /// Clean up old data after successful migration
  static Future<void> _cleanupOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove sensitive data from SharedPreferences
      final sensitiveKeys = [
        'user_id',
        'user_email', 
        'firebase_uid',
        'access_token',
        'refresh_token',
        'user_password', // Should never exist, but just in case
        'pin_code', // Should never exist, but just in case
      ];
      
      for (final key in sensitiveKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          AppLogger.info('Removed sensitive key from SharedPreferences: $key');
        }
      }
      
      // Note: Old database file is cleaned up by SecureDatabase during migration
      
      AppLogger.info('Old data cleanup completed');
    } catch (e) {
      AppLogger.error('Old data cleanup failed', error: e);
    }
  }

  /// Create backup before migration
  static Future<String?> createPreMigrationBackup() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory(join(documentsDirectory.path, 'migration_backup_$timestamp'));
      
      await backupDir.create(recursive: true);
      
      // Backup SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsData = <String, dynamic>{};
      
      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        prefsData[key] = value;
      }
      
      final prefsFile = File(join(backupDir.path, 'shared_preferences.json'));
      await prefsFile.writeAsString(prefsData.toString());
      
      // Backup database if exists
      final oldDbPath = join(documentsDirectory.path, 'siyanaty_database.db');
      final oldDbFile = File(oldDbPath);
      
      if (await oldDbFile.exists()) {
        final backupDbPath = join(backupDir.path, 'database_backup.db');
        await oldDbFile.copy(backupDbPath);
      }
      
      AppLogger.info('Pre-migration backup created at: ${backupDir.path}');
      return backupDir.path;
      
    } catch (e) {
      AppLogger.error('Failed to create pre-migration backup', error: e);
      return null;
    }
  }

  /// Restore from backup if migration fails
  static Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        return false;
      }
      
      // Restore database
      final backupDbFile = File(join(backupPath, 'database_backup.db'));
      if (await backupDbFile.exists()) {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final dbPath = join(documentsDirectory.path, 'siyanaty_database.db');
        await backupDbFile.copy(dbPath);
      }
      
      AppLogger.info('Data restored from backup');
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to restore from backup', error: e);
      return false;
    }
  }

  /// Get migration status information
  static Future<MigrationStatus> getMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsDirectory = await getApplicationDocumentsDirectory();
      
      // Check SharedPreferences data
      final hasPrefsData = prefs.getKeys().any((key) => 
        ['user_id', 'user_email', 'firebase_uid'].contains(key));
      
      // Check old database
      final oldDbPath = join(documentsDirectory.path, 'siyanaty_database.db');
      final hasOldDb = await File(oldDbPath).exists();
      
      // Check secure storage
      final hasSecureData = await _secureStorage.isAuthenticated();
      
      // Check secure database
      final secureDbPath = join(documentsDirectory.path, 'siyanaty_secure.db');
      final hasSecureDb = await File(secureDbPath).exists();
      
      return MigrationStatus(
        hasLegacyPreferences: hasPrefsData,
        hasLegacyDatabase: hasOldDb,
        hasSecureStorage: hasSecureData,
        hasSecureDatabase: hasSecureDb,
        migrationNeeded: (hasPrefsData || hasOldDb) && !hasSecureData,
      );
      
    } catch (e) {
      AppLogger.error('Failed to get migration status', error: e);
      return MigrationStatus(
        hasLegacyPreferences: false,
        hasLegacyDatabase: false,
        hasSecureStorage: false,
        hasSecureDatabase: false,
        migrationNeeded: false,
      );
    }
  }

  /// Validate migration integrity
  static Future<bool> validateMigration() async {
    try {
      // Check that secure storage is properly configured
      final hasSecureData = await _secureStorage.isAuthenticated();
      if (!hasSecureData) {
        return false;
      }
      
      // Check that secure database is accessible
      await SecureDatabase.database;
      final integrity = await SecureDatabase.verifyIntegrity();
      
      return integrity;
      
    } catch (e) {
      AppLogger.error('Migration validation failed', error: e);
      return false;
    }
  }
}

/// Result of migration operation
class MigrationResult {
  final bool success;
  final bool isPartial;
  final Map<String, bool>? componentResults;
  final String? error;

  MigrationResult._({
    required this.success,
    this.isPartial = false,
    this.componentResults,
    this.error,
  });

  factory MigrationResult.success(Map<String, bool> results) {
    return MigrationResult._(
      success: true,
      componentResults: results,
    );
  }

  factory MigrationResult.partial(Map<String, bool> results) {
    return MigrationResult._(
      success: true,
      isPartial: true,
      componentResults: results,
    );
  }

  factory MigrationResult.failure(String error) {
    return MigrationResult._(
      success: false,
      error: error,
    );
  }
}

/// Status of migration components
class MigrationStatus {
  final bool hasLegacyPreferences;
  final bool hasLegacyDatabase;
  final bool hasSecureStorage;
  final bool hasSecureDatabase;
  final bool migrationNeeded;

  MigrationStatus({
    required this.hasLegacyPreferences,
    required this.hasLegacyDatabase,
    required this.hasSecureStorage,
    required this.hasSecureDatabase,
    required this.migrationNeeded,
  });

  @override
  String toString() {
    return 'MigrationStatus('
        'legacyPrefs: $hasLegacyPreferences, '
        'legacyDb: $hasLegacyDatabase, '
        'secureStorage: $hasSecureStorage, '
        'secureDb: $hasSecureDatabase, '
        'needsMigration: $migrationNeeded)';
  }
}
