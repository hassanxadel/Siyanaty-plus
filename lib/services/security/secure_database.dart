import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'secure_storage_service.dart';
import '../../shared/utils/app_logger.dart';

/// Secure database wrapper using SQLCipher for encryption
class SecureDatabase {
  static Database? _database;
  static final SecureStorageService _secureStorage = SecureStorageService();
  
  // Database configuration
  static const String _databaseName = 'siyanaty_secure.db';
  static const int _databaseVersion = 10; // Incremented for mileage_entries schema fix

  /// Get the secure database instance
  static Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the encrypted database
  static Future<Database> _initDatabase() async {
    try {
      // Get the database encryption key
      String? encryptionKey = await _secureStorage.getDatabaseKey();
      
      encryptionKey ??= await _secureStorage.generateDatabaseKey();

      // Get database path
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      // Check if we need to migrate from unencrypted database
      await _migrateFromUnencryptedDatabase(path, encryptionKey);

      // Open encrypted database
      final database = await openDatabase(
        path,
        version: _databaseVersion,
        password: encryptionKey,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );

      return database;
    } catch (e) {
      throw Exception('Failed to initialize secure database: ${e.toString()}');
    }
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  /// Upgrade database schema
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades
    if (oldVersion < 9) {
      // Add any new security-related tables or columns
      await _createSecurityTables(db);
    }
    
    // Version 10: Fix mileage_entries schema (add missing columns and fix column names)
    if (oldVersion < 10) {
      await _upgradeMileageEntriesTable(db);
    }
    
    // Add other version-specific upgrades as needed
  }
  
  /// Upgrade mileage_entries table to version 10
  static Future<void> _upgradeMileageEntriesTable(Database db) async {
    try {
      // Check if table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='mileage_entries'"
      );
      
      if (tables.isEmpty) {
        // Table doesn't exist, will be created by _createAllTables
        return;
      }
      
      // Get existing columns
      final columns = await db.rawQuery('PRAGMA table_info(mileage_entries)');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      // Check if we need to migrate
      final needsMigration = !columnNames.contains('fuel') || 
                             !columnNames.contains('cost') ||
                             columnNames.contains('userId'); // Old camelCase column
      
      if (!needsMigration) {
        return; // Already up to date
      }
      
      AppLogger.info('🔄 Migrating mileage_entries table to version 10...');
      
      // Create new table with correct schema
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mileage_entries_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          car_id INTEGER,
          entry_name TEXT,
          mileage REAL NOT NULL,
          fuel REAL NOT NULL DEFAULT 0,
          cost REAL NOT NULL DEFAULT 0,
          date TEXT NOT NULL,
          location TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE
        )
      ''');
      
      // Copy data from old table, handling both old and new column names
      await db.execute('''
        INSERT INTO mileage_entries_new (
          id, user_id, car_id, entry_name, mileage, fuel, cost, 
          date, location, notes, created_at, updated_at
        )
        SELECT 
          id,
          COALESCE(user_id, userId) as user_id,
          car_id,
          COALESCE(entry_name, entryName) as entry_name,
          mileage,
          COALESCE(fuel, 0) as fuel,
          COALESCE(cost, 0) as cost,
          date,
          location,
          notes,
          COALESCE(created_at, createdAt, datetime('now')) as created_at,
          COALESCE(updated_at, updatedAt, datetime('now')) as updated_at
        FROM mileage_entries
      ''');
      
      // Drop old table
      await db.execute('DROP TABLE mileage_entries');
      
      // Rename new table
      await db.execute('ALTER TABLE mileage_entries_new RENAME TO mileage_entries');
      
      AppLogger.info('✅ Mileage entries table migrated successfully');
    } catch (e) {
      AppLogger.warning('⚠️ Mileage entries migration error (may be expected): $e');
      // If migration fails, try to recreate the table
      try {
        await db.execute('DROP TABLE IF EXISTS mileage_entries');
        await db.execute('''
          CREATE TABLE mileage_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            car_id INTEGER,
            entry_name TEXT,
            mileage REAL NOT NULL,
            fuel REAL NOT NULL,
            cost REAL NOT NULL,
            date TEXT NOT NULL,
            location TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE
          )
        ''');
        AppLogger.info('✅ Mileage entries table recreated');
      } catch (recreateError) {
        AppLogger.error('❌ Failed to recreate mileage_entries table', error: recreateError);
      }
    }
  }

  /// Configure database on open
  static Future<void> _onOpen(Database db) async {
    try {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys = ON');
      
      // Set journal mode for better security
      await db.execute('PRAGMA journal_mode = WAL');
      
      // Note: secure_delete pragma is not needed with SQLCipher as it's encrypted by default
    } catch (e) {
      // Ignore PRAGMA errors during initialization
    }
  }

  /// Create all database tables
  static Future<void> _createAllTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT,
        phone_number TEXT,
        profile_image_url TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        preferences TEXT,
        stats TEXT,
        last_backup_time INTEGER,
        last_backup_success_count INTEGER DEFAULT 0,
        last_backup_failure_count INTEGER DEFAULT 0,
        last_maintenance_backup_time INTEGER,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT
      )
    ''');

    // Cars table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        mileage INTEGER DEFAULT 0,
        color TEXT,
        fuel_type TEXT,
        engine_cc TEXT,
        turbo INTEGER DEFAULT 0,
        license_plate TEXT,
        vin TEXT,
        image_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        car_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        target_date INTEGER,
        target_mileage INTEGER,
        is_completed INTEGER DEFAULT 0,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE
      )
    ''');

    // Maintenance records table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS maintenance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        car_id INTEGER NOT NULL,
        reminder_id INTEGER,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        cost REAL NOT NULL,
        maintenance_date INTEGER NOT NULL,
        mechanic_name TEXT,
        invoice_number TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE,
        FOREIGN KEY (reminder_id) REFERENCES reminders (id) ON DELETE SET NULL
      )
    ''');

    // Mileage entries table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mileage_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        car_id INTEGER,
        entry_name TEXT,
        mileage REAL NOT NULL,
        fuel REAL NOT NULL,
        cost REAL NOT NULL,
        date TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE
      )
    ''');

    // License images table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS license_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        car_id INTEGER NOT NULL,
        license_type TEXT NOT NULL,
        image_path TEXT NOT NULL,
        image_url TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE,
        UNIQUE(car_id, license_type)
      )
    ''');

    // Create security-specific tables
    await _createSecurityTables(db);

    // Create indexes for better performance
    await _createIndexes(db);
  }

  /// Create security-specific tables
  static Future<void> _createSecurityTables(Database db) async {
    // Security events log
    await db.execute('''
      CREATE TABLE IF NOT EXISTS security_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        event_data TEXT,
        device_id TEXT,
        ip_address TEXT,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Device sessions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        device_name TEXT,
        is_trusted INTEGER DEFAULT 0,
        last_activity INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create database indexes
  static Future<void> _createIndexes(Database db) async {
    // User-related indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cars_user_id ON cars (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON reminders (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_car_id ON reminders (car_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_maintenance_user_id ON maintenance_records (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_maintenance_car_id ON maintenance_records (car_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mileage_user_id ON mileage_entries (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mileage_car_id ON mileage_entries (car_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_license_user_id ON license_images (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_license_car_id ON license_images (car_id)');
    
    // Security indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON security_events (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_security_events_timestamp ON security_events (timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_device_sessions_user_id ON device_sessions (user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_device_sessions_device_id ON device_sessions (device_id)');
  }

  /// Migrate from unencrypted database if it exists
  static Future<void> _migrateFromUnencryptedDatabase(String encryptedPath, String encryptionKey) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final oldPath = join(documentsDirectory.path, 'siyanaty_database.db');
      final oldFile = File(oldPath);

      if (await oldFile.exists()) {
        // Open old unencrypted database
        final oldDb = await openDatabase(oldPath);
        
        // Create new encrypted database
        final newDb = await openDatabase(
          encryptedPath,
          version: _databaseVersion,
          password: encryptionKey,
          onCreate: _onCreate,
        );

        // Migrate data from old to new database
        await _migrateData(oldDb, newDb);

        // Close databases
        await oldDb.close();
        await newDb.close();

        // Delete old unencrypted database
        await oldFile.delete();

        // Log security event
        await _logSecurityEvent('database_migration', 'Migrated from unencrypted to encrypted database');
      }
    } catch (e) {
      // Log migration error but don't fail the initialization
      await _logSecurityEvent('database_migration_error', 'Failed to migrate database: ${e.toString()}');
    }
  }

  /// Migrate data between databases
  static Future<void> _migrateData(Database oldDb, Database newDb) async {
    final tables = ['users', 'cars', 'reminders', 'maintenance_records', 'mileage_entries', 'license_images'];
    
    for (final table in tables) {
      try {
        final data = await oldDb.query(table);
        for (final row in data) {
          await newDb.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        // Continue with other tables if one fails
        continue;
      }
    }
  }

  /// Log security events
  static Future<void> _logSecurityEvent(String eventType, String eventData) async {
    try {
      final userId = await _secureStorage.getUserId();
      final deviceId = await _secureStorage.getDeviceId();
      
      if (userId != null) {
        final db = await database;
        await db.insert('security_events', {
          'user_id': userId,
          'event_type': eventType,
          'event_data': eventData,
          'device_id': deviceId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      // Fail silently to avoid breaking app functionality
    }
  }

  /// Update device session
  static Future<void> updateDeviceSession(String userId, String deviceId, String deviceName) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert(
        'device_sessions',
        {
          'user_id': userId,
          'device_id': deviceId,
          'device_name': deviceName,
          'is_trusted': await _secureStorage.isTrustedDevice() ? 1 : 0,
          'last_activity': now,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Fail silently
    }
  }

  /// Get security events for user
  static Future<List<Map<String, dynamic>>> getSecurityEvents(String userId, {int limit = 50}) async {
    try {
      final db = await database;
      return await db.query(
        'security_events',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  /// Get device sessions for user
  static Future<List<Map<String, dynamic>>> getDeviceSessions(String userId) async {
    try {
      final db = await database;
      return await db.query(
        'device_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'last_activity DESC',
      );
    } catch (e) {
      return [];
    }
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Backup database (encrypted)
  static Future<String?> backupDatabase() async {
    try {
      final db = await database;
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupPath = join(documentsDirectory.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.db');
      
      // Close current connection
      await db.close();
      
      // Copy database file
      final dbPath = join(documentsDirectory.path, _databaseName);
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);
      
      // Reopen database
      _database = await _initDatabase();
      
      return backupPath;
    } catch (e) {
      return null;
    }
  }

  /// Restore database from backup
  static Future<bool> restoreDatabase(String backupPath) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, _databaseName);
      
      // Close current database
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      
      // Replace current database with backup
      final backupFile = File(backupPath);
      await backupFile.copy(dbPath);
      
      // Reinitialize database
      _database = await _initDatabase();
      
      await _logSecurityEvent('database_restore', 'Database restored from backup');
      return true;
    } catch (e) {
      await _logSecurityEvent('database_restore_error', 'Failed to restore database: ${e.toString()}');
      return false;
    }
  }

  /// Verify database integrity
  static Future<bool> verifyIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.isNotEmpty && result.first['integrity_check'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Get database size
  static Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, _databaseName);
      final dbFile = File(dbPath);
      return await dbFile.length();
    } catch (e) {
      return 0;
    }
  }

  /// Vacuum database (optimize storage)
  static Future<void> vacuumDatabase() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      await _logSecurityEvent('database_vacuum', 'Database optimized');
    } catch (e) {
      await _logSecurityEvent('database_vacuum_error', 'Failed to optimize database: ${e.toString()}');
    }
  }
}
