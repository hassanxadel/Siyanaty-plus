import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/backup_car.dart';
import '../models/backup_reminder.dart';
import '../models/backup_maintenance.dart';
import '../models/license_image.dart';
import 'ocr_database_helper.dart';
import 'mileage_database_helper.dart';
import 'voice_note_database_helper.dart';

/// Database helper class for managing SQLite database operations
/// Handles car data storage with CRUD operations
class DatabaseHelper {
  static const String _databaseName = 'syanaty.db';
  static const int _databaseVersion = 15; // Add car_id to maintenance table for standalone maintenance
  
  static const String tableCars = 'cars';
  static const String tableReminders = 'reminders';
  static const String tableMaintenance = 'maintenance';
  static const String tableScans = 'scans'; // OCR scans table
  static const String tableLicenseImages = 'license_images'; // License images table
  static const String tableOBDScans = 'obd_scans'; // OBD-II scans table
  static const String tableExpenses = 'expenses'; // Car expenses table
  static const String tableTrips = 'trips'; // Trip logger table
  static const String tableBudgets = 'budgets'; // Budget tracking table
  
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  
  static Database? _database;
  
  /// Get database instance, create if doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Initialize database and create tables
  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _databaseName);
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }
  
  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $tableCars (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          brand TEXT NOT NULL,
          model TEXT NOT NULL,
          year INTEGER NOT NULL,
          mileage INTEGER NOT NULL,
          color TEXT NOT NULL,
          fuel_type TEXT NOT NULL,
          engine_cc TEXT NOT NULL,
          turbo INTEGER NOT NULL DEFAULT 0,
          license_plate TEXT NOT NULL,
          vin TEXT NOT NULL,
          image_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(user_id, license_plate),
          UNIQUE(user_id, vin)
        )
      ''');
      
      // Create indexes for better performance
      await db.execute('CREATE INDEX idx_cars_user_id ON $tableCars (user_id)');
      await db.execute('CREATE INDEX idx_cars_brand ON $tableCars (brand)');
      await db.execute('CREATE INDEX idx_cars_model ON $tableCars (model)');
      await db.execute('CREATE INDEX idx_cars_license_plate ON $tableCars (license_plate)');
      await db.execute('CREATE INDEX idx_cars_vin ON $tableCars (vin)');
      
      // Create reminders table
      await db.execute('''
        CREATE TABLE $tableReminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          car_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          type TEXT NOT NULL,
          priority TEXT NOT NULL,
          target_date TEXT,
          target_mileage INTEGER,
          status TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for reminders
      await db.execute('CREATE INDEX idx_reminders_car_id ON $tableReminders (car_id)');
      await db.execute('CREATE INDEX idx_reminders_status ON $tableReminders (status)');
      await db.execute('CREATE INDEX idx_reminders_target_date ON $tableReminders (target_date)');
      
      // Create maintenance table
      await db.execute('''
        CREATE TABLE $tableMaintenance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reminder_id INTEGER,
          car_id INTEGER,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          cost REAL NOT NULL DEFAULT 0.0,
          maintenance_date TEXT NOT NULL,
          type TEXT NOT NULL,
          mechanic_name TEXT,
          invoice_number TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (reminder_id) REFERENCES $tableReminders (id) ON DELETE CASCADE,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for maintenance
      await db.execute('CREATE INDEX idx_maintenance_reminder_id ON $tableMaintenance (reminder_id)');
      await db.execute('CREATE INDEX idx_maintenance_car_id ON $tableMaintenance (car_id)');
      await db.execute('CREATE INDEX idx_maintenance_type ON $tableMaintenance (type)');
      await db.execute('CREATE INDEX idx_maintenance_date ON $tableMaintenance (maintenance_date)');
      await db.execute('CREATE INDEX idx_maintenance_cost ON $tableMaintenance (cost)');
      
      // Create OCR scans table
      await db.execute(OcrDatabaseHelper.createTableSql);
      
      // Create indexes for scans
      await db.execute('CREATE INDEX idx_scans_user_id ON ${OcrDatabaseHelper.tableName} (user_id)');
      await db.execute('CREATE INDEX idx_scans_timestamp ON ${OcrDatabaseHelper.tableName} (timestamp)');
      await db.execute('CREATE INDEX idx_scans_source ON ${OcrDatabaseHelper.tableName} (source)');
      
      // Create mileage entries table
      await db.execute(MileageDatabaseHelper.createTableQuery);
      
      // Create indexes for mileage entries
      await db.execute('CREATE INDEX idx_mileage_user_id ON ${MileageDatabaseHelper.tableName} (user_id)');
      await db.execute('CREATE INDEX idx_mileage_date ON ${MileageDatabaseHelper.tableName} (date)');
      await db.execute('CREATE INDEX idx_mileage_mileage ON ${MileageDatabaseHelper.tableName} (mileage)');
      
      // Create voice notes table
      await db.execute(VoiceNoteDatabaseHelper.createTableQuery);
      
      // Create indexes for voice notes
      await db.execute('CREATE INDEX idx_voice_notes_user_id ON ${VoiceNoteDatabaseHelper.tableName} (user_id)');
      await db.execute('CREATE INDEX idx_voice_notes_created_at ON ${VoiceNoteDatabaseHelper.tableName} (created_at)');
      await db.execute('CREATE INDEX idx_voice_notes_title ON ${VoiceNoteDatabaseHelper.tableName} (title)');
      
      // Create license images table
      await db.execute('''
        CREATE TABLE $tableLicenseImages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          car_id INTEGER NOT NULL,
          license_type TEXT NOT NULL,
          image_path TEXT NOT NULL,
          image_url TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          user_id TEXT NOT NULL,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE,
          UNIQUE(car_id, license_type)
        )
      ''');
      
      // Create indexes for license images
      await db.execute('CREATE INDEX idx_license_images_car_id ON $tableLicenseImages (car_id)');
      await db.execute('CREATE INDEX idx_license_images_user_id ON $tableLicenseImages (user_id)');
      await db.execute('CREATE INDEX idx_license_images_type ON $tableLicenseImages (license_type)');
      
      // Create OBD scans table
      await db.execute('''
        CREATE TABLE $tableOBDScans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          car_id INTEGER NOT NULL,
          scan_date INTEGER NOT NULL,
          rpm REAL,
          speed REAL,
          coolant_temp REAL,
          fuel_level REAL,
          throttle_position REAL,
          engine_load REAL,
          error_codes TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for OBD scans
      await db.execute('CREATE INDEX idx_obd_scans_car_id ON $tableOBDScans (car_id)');
      await db.execute('CREATE INDEX idx_obd_scans_scan_date ON $tableOBDScans (scan_date)');
      await db.execute('CREATE INDEX idx_obd_scans_created_at ON $tableOBDScans (created_at)');
      
      // Create expenses table
      await db.execute('''
        CREATE TABLE $tableExpenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          car_id INTEGER NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          date INTEGER NOT NULL,
          description TEXT,
          receipt_image TEXT,
          created_at INTEGER NOT NULL,
          user_id TEXT NOT NULL,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for expenses
      await db.execute('CREATE INDEX idx_expenses_car_id ON $tableExpenses (car_id)');
      await db.execute('CREATE INDEX idx_expenses_category ON $tableExpenses (category)');
      await db.execute('CREATE INDEX idx_expenses_date ON $tableExpenses (date)');
      await db.execute('CREATE INDEX idx_expenses_user_id ON $tableExpenses (user_id)');
      
      // Create trips table
      await db.execute('''
        CREATE TABLE $tableTrips (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          car_id INTEGER NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          start_location TEXT,
          end_location TEXT,
          distance REAL,
          trip_type TEXT,
          purpose TEXT,
          route_data TEXT,
          created_at INTEGER NOT NULL,
          user_id TEXT NOT NULL,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for trips
      await db.execute('CREATE INDEX idx_trips_car_id ON $tableTrips (car_id)');
      await db.execute('CREATE INDEX idx_trips_start_time ON $tableTrips (start_time)');
      await db.execute('CREATE INDEX idx_trips_trip_type ON $tableTrips (trip_type)');
      await db.execute('CREATE INDEX idx_trips_user_id ON $tableTrips (user_id)');
      
      // Create budgets table
      await db.execute('''
        CREATE TABLE $tableBudgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          car_id INTEGER NOT NULL,
          category TEXT NOT NULL,
          monthly_limit REAL NOT NULL,
          alert_threshold REAL,
          created_at INTEGER NOT NULL,
          user_id TEXT NOT NULL,
          FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for budgets
      await db.execute('CREATE INDEX idx_budgets_car_id ON $tableBudgets (car_id)');
      await db.execute('CREATE INDEX idx_budgets_category ON $tableBudgets (category)');
      await db.execute('CREATE INDEX idx_budgets_user_id ON $tableBudgets (user_id)');
      
    } catch (e) {
      throw DatabaseException('Failed to create tables: $e');
    }
  }
  
  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        // Add reminders table for version 2
        await db.execute('''
          CREATE TABLE $tableReminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            car_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            priority TEXT NOT NULL,
            target_date TEXT,
            target_mileage INTEGER,
            status TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
          )
        ''');
        
        // Create indexes for reminders
        await db.execute('CREATE INDEX idx_reminders_user_id ON $tableReminders (user_id)');
        await db.execute('CREATE INDEX idx_reminders_car_id ON $tableReminders (car_id)');
        await db.execute('CREATE INDEX idx_reminders_status ON $tableReminders (status)');
        await db.execute('CREATE INDEX idx_reminders_target_date ON $tableReminders (target_date)');
      }
      
      if (oldVersion < 3) {
        // Version 3: Remove user_id from reminders table (proper ERD relationship)
        // Create new table without user_id
        await db.execute('''
          CREATE TABLE ${tableReminders}_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            car_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            type TEXT NOT NULL,
            priority TEXT NOT NULL,
            target_date TEXT,
            target_mileage INTEGER,
            status TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
          )
        ''');
        
        // Copy data from old table (excluding user_id)
        await db.execute('''
          INSERT INTO ${tableReminders}_new (id, car_id, title, description, type, priority, target_date, target_mileage, status, is_completed, completed_at, created_at, updated_at)
          SELECT id, car_id, title, description, type, priority, target_date, target_mileage, status, is_completed, completed_at, created_at, updated_at
          FROM $tableReminders
        ''');
        
        // Drop old table and rename new one
        await db.execute('DROP TABLE $tableReminders');
        await db.execute('ALTER TABLE ${tableReminders}_new RENAME TO $tableReminders');
        
        // Recreate indexes without user_id
        await db.execute('CREATE INDEX idx_reminders_car_id ON $tableReminders (car_id)');
        await db.execute('CREATE INDEX idx_reminders_status ON $tableReminders (status)');
        await db.execute('CREATE INDEX idx_reminders_target_date ON $tableReminders (target_date)');
      }
      
      if (oldVersion < 4) {
        // Version 4: Add maintenance table
        await db.execute('''
          CREATE TABLE $tableMaintenance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reminder_id INTEGER,
            car_id INTEGER,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            cost REAL NOT NULL DEFAULT 0.0,
            maintenance_date TEXT NOT NULL,
            type TEXT NOT NULL,
            mechanic_name TEXT,
            invoice_number TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (reminder_id) REFERENCES $tableReminders (id) ON DELETE CASCADE,
            FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
          )
        ''');
        
        // Create indexes for maintenance
        await db.execute('CREATE INDEX idx_maintenance_reminder_id ON $tableMaintenance (reminder_id)');
        await db.execute('CREATE INDEX idx_maintenance_car_id ON $tableMaintenance (car_id)');
        await db.execute('CREATE INDEX idx_maintenance_type ON $tableMaintenance (type)');
        await db.execute('CREATE INDEX idx_maintenance_date ON $tableMaintenance (maintenance_date)');
        await db.execute('CREATE INDEX idx_maintenance_cost ON $tableMaintenance (cost)');
      }
      
      if (oldVersion < 5) {
        // Version 5: Add OCR scans table
        await db.execute(OcrDatabaseHelper.createTableSql);
        
        // Create indexes for scans
        await db.execute('CREATE INDEX idx_scans_user_id ON ${OcrDatabaseHelper.tableName} (user_id)');
        await db.execute('CREATE INDEX idx_scans_timestamp ON ${OcrDatabaseHelper.tableName} (timestamp)');
        await db.execute('CREATE INDEX idx_scans_source ON ${OcrDatabaseHelper.tableName} (source)');
      }
      
      if (oldVersion < 6) {
        // Version 6: Add mileage entries table
        await db.execute(MileageDatabaseHelper.createTableQuery);
        
        // Create indexes for mileage entries
        await db.execute('CREATE INDEX idx_mileage_user_id ON ${MileageDatabaseHelper.tableName} (user_id)');
        await db.execute('CREATE INDEX idx_mileage_date ON ${MileageDatabaseHelper.tableName} (date)');
        await db.execute('CREATE INDEX idx_mileage_mileage ON ${MileageDatabaseHelper.tableName} (mileage)');
      }
      
      if (oldVersion < 7) {
        // Version 7: Add voice notes table
        await db.execute(VoiceNoteDatabaseHelper.createTableQuery);
        
        // Create indexes for voice notes
        await db.execute('CREATE INDEX idx_voice_notes_user_id ON ${VoiceNoteDatabaseHelper.tableName} (user_id)');
        await db.execute('CREATE INDEX idx_voice_notes_created_at ON ${VoiceNoteDatabaseHelper.tableName} (created_at)');
        await db.execute('CREATE INDEX idx_voice_notes_title ON ${VoiceNoteDatabaseHelper.tableName} (title)');
      }
      
      if (oldVersion < 8) {
        // Version 8: Add license images table
        await db.execute('''
          CREATE TABLE $tableLicenseImages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            car_id INTEGER NOT NULL,
            license_type TEXT NOT NULL,
            image_path TEXT NOT NULL,
            image_url TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            user_id TEXT NOT NULL,
            FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE,
            UNIQUE(car_id, license_type)
          )
        ''');
        
        // Create indexes for license images
        await db.execute('CREATE INDEX idx_license_images_car_id ON $tableLicenseImages (car_id)');
        await db.execute('CREATE INDEX idx_license_images_user_id ON $tableLicenseImages (user_id)');
        await db.execute('CREATE INDEX idx_license_images_type ON $tableLicenseImages (license_type)');
      }
      
      if (oldVersion < 9) {
        // Version 9: Add car_id and trip_frequency to mileage_entries table
        await db.execute('ALTER TABLE ${MileageDatabaseHelper.tableName} ADD COLUMN car_id TEXT');
        await db.execute('ALTER TABLE ${MileageDatabaseHelper.tableName} ADD COLUMN trip_frequency TEXT DEFAULT "oneTime"');
        
        // Create indexes for new fields
        await db.execute('CREATE INDEX idx_mileage_car_id ON ${MileageDatabaseHelper.tableName} (car_id)');
        await db.execute('CREATE INDEX idx_mileage_trip_frequency ON ${MileageDatabaseHelper.tableName} (trip_frequency)');
      }
      
      if (oldVersion < 10) {
        // Version 10: Fix voice_notes table column names from camelCase to snake_case
        // Check if the table exists and needs migration
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='${VoiceNoteDatabaseHelper.tableName}'"
        );
        
        if (tables.isNotEmpty) {
          // Check if old columns exist
          final tableInfo = await db.rawQuery('PRAGMA table_info(${VoiceNoteDatabaseHelper.tableName})');
          final columnNames = tableInfo.map((col) => col['name'] as String).toList();
          
          // If we have camelCase columns, we need to migrate
          if (columnNames.contains('filePath') || columnNames.contains('createdAt')) {
            // Create new table with correct column names
            await db.execute('''
              CREATE TABLE ${VoiceNoteDatabaseHelper.tableName}_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT,
                file_path TEXT NOT NULL,
                duration INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                user_id TEXT
              )
            ''');
            
            // Copy data from old table to new table, using the actual camelCase column names
            await db.execute('''
              INSERT INTO ${VoiceNoteDatabaseHelper.tableName}_new 
                (id, title, description, file_path, duration, created_at, updated_at, user_id)
              SELECT 
                id, 
                title, 
                description, 
                filePath as file_path,
                duration,
                createdAt as created_at,
                updatedAt as updated_at,
                userId as user_id
              FROM ${VoiceNoteDatabaseHelper.tableName}
            ''');
            
            // Drop old table
            await db.execute('DROP TABLE ${VoiceNoteDatabaseHelper.tableName}');
            
            // Rename new table
            await db.execute('ALTER TABLE ${VoiceNoteDatabaseHelper.tableName}_new RENAME TO ${VoiceNoteDatabaseHelper.tableName}');
            
            // Recreate indexes
            await db.execute('CREATE INDEX idx_voice_notes_user_id ON ${VoiceNoteDatabaseHelper.tableName} (user_id)');
            await db.execute('CREATE INDEX idx_voice_notes_created_at ON ${VoiceNoteDatabaseHelper.tableName} (created_at)');
            await db.execute('CREATE INDEX idx_voice_notes_title ON ${VoiceNoteDatabaseHelper.tableName} (title)');
          }
        }
      }
      
      if (oldVersion < 11) {
        // Version 11: Force recreate voice_notes table with correct schema
        try {
          // Drop the old table completely
          await db.execute('DROP TABLE IF EXISTS ${VoiceNoteDatabaseHelper.tableName}');
          
          // Create new table with correct column names
          await db.execute(VoiceNoteDatabaseHelper.createTableQuery);
          
          // Create indexes
          await db.execute('CREATE INDEX idx_voice_notes_user_id ON ${VoiceNoteDatabaseHelper.tableName} (user_id)');
          await db.execute('CREATE INDEX idx_voice_notes_created_at ON ${VoiceNoteDatabaseHelper.tableName} (created_at)');
          await db.execute('CREATE INDEX idx_voice_notes_title ON ${VoiceNoteDatabaseHelper.tableName} (title)');
        } catch (e) {
          print('Error recreating voice_notes table: $e');
        }
      }
      
      if (oldVersion < 12) {
        // Version 12: Final fix for voice_notes table - ensure file_path column exists
        try {
          // Check if table exists and has correct columns
          final tableInfo = await db.rawQuery('PRAGMA table_info(${VoiceNoteDatabaseHelper.tableName})');
          final columnNames = tableInfo.map((col) => col['name'] as String).toList();
          
          // If file_path column doesn't exist, recreate the table
          if (!columnNames.contains('file_path')) {
            print('Recreating voice_notes table with correct schema...');
            
            // Drop the old table
            await db.execute('DROP TABLE IF EXISTS ${VoiceNoteDatabaseHelper.tableName}');
            
            // Create new table with correct column names (snake_case)
            await db.execute(VoiceNoteDatabaseHelper.createTableQuery);
            
            // Recreate indexes
            try {
              await db.execute('CREATE INDEX IF NOT EXISTS idx_voice_notes_user_id ON ${VoiceNoteDatabaseHelper.tableName} (user_id)');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_voice_notes_created_at ON ${VoiceNoteDatabaseHelper.tableName} (created_at)');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_voice_notes_title ON ${VoiceNoteDatabaseHelper.tableName} (title)');
            } catch (indexError) {
              print('Index creation warning: $indexError');
            }
            
            print('Voice notes table recreated successfully');
          }
        } catch (e) {
          print('Error fixing voice_notes table: $e');
          // Try to create the table if it doesn't exist at all
          try {
            await db.execute(VoiceNoteDatabaseHelper.createTableQuery);
          } catch (createError) {
            print('Table creation error (may already exist): $createError');
          }
        }
      }
      
      if (oldVersion < 13) {
        // Version 13: Add OBD scans table
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableOBDScans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              car_id INTEGER NOT NULL,
              scan_date INTEGER NOT NULL,
              rpm REAL,
              speed REAL,
              coolant_temp REAL,
              fuel_level REAL,
              throttle_position REAL,
              engine_load REAL,
              error_codes TEXT,
              notes TEXT,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
            )
          ''');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_obd_scans_car_id ON $tableOBDScans (car_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_obd_scans_scan_date ON $tableOBDScans (scan_date)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_obd_scans_created_at ON $tableOBDScans (created_at)');
          
          print('OBD scans table created successfully');
        } catch (e) {
          print('Error creating OBD scans table: $e');
        }
      }
      
      if (oldVersion < 14) {
        // Version 14: Add Car Health Dashboard tables
        try {
          // Create expenses table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableExpenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              car_id INTEGER NOT NULL,
              category TEXT NOT NULL,
              amount REAL NOT NULL,
              date INTEGER NOT NULL,
              description TEXT,
              receipt_image TEXT,
              created_at INTEGER NOT NULL,
              user_id TEXT NOT NULL,
              FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
            )
          ''');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_car_id ON $tableExpenses (car_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_category ON $tableExpenses (category)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON $tableExpenses (date)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON $tableExpenses (user_id)');
          
          // Create trips table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableTrips (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              car_id INTEGER NOT NULL,
              start_time INTEGER NOT NULL,
              end_time INTEGER,
              start_location TEXT,
              end_location TEXT,
              distance REAL,
              trip_type TEXT,
              purpose TEXT,
              route_data TEXT,
              created_at INTEGER NOT NULL,
              user_id TEXT NOT NULL,
              FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
            )
          ''');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_car_id ON $tableTrips (car_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_start_time ON $tableTrips (start_time)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_trip_type ON $tableTrips (trip_type)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_user_id ON $tableTrips (user_id)');
          
          // Create budgets table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableBudgets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              car_id INTEGER NOT NULL,
              category TEXT NOT NULL,
              monthly_limit REAL NOT NULL,
              alert_threshold REAL,
              created_at INTEGER NOT NULL,
              user_id TEXT NOT NULL,
              FOREIGN KEY (car_id) REFERENCES $tableCars (id) ON DELETE CASCADE
            )
          ''');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_car_id ON $tableBudgets (car_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_category ON $tableBudgets (category)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON $tableBudgets (user_id)');
          
          print('Car Health Dashboard tables created successfully');
        } catch (e) {
          print('Error creating Car Health Dashboard tables: $e');
        }
      }
      
      if (oldVersion < 15) {
        // Version 15: Add car_id column to maintenance table for standalone maintenance
        try {
          // Check if car_id column already exists
          final tableInfo = await db.rawQuery('PRAGMA table_info($tableMaintenance)');
          final columnNames = tableInfo.map((col) => col['name'] as String).toList();
          
          if (!columnNames.contains('car_id')) {
            // Add car_id column to maintenance table
            await db.execute('ALTER TABLE $tableMaintenance ADD COLUMN car_id INTEGER');
            
            // Create index for car_id
            await db.execute('CREATE INDEX IF NOT EXISTS idx_maintenance_car_id ON $tableMaintenance (car_id)');
            
            print('Added car_id column to maintenance table');
          }
          
          // Make reminder_id nullable (can't alter column type in SQLite, but new records can have NULL)
          // Existing data with reminder_id will still work, new standalone maintenance can have car_id only
          
          print('Maintenance table updated for standalone maintenance support');
        } catch (e) {
          print('Error updating maintenance table: $e');
        }
      }
    } catch (e) {
      throw DatabaseException('Failed to upgrade database: $e');
    }
  }
  
  /// Insert a new car into the database
  Future<int> insertCar(BackupCar car) async {
    try {
      final db = await database;
      return await db.insert(
        tableCars,
        car.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw const DatabaseException('Car with this license plate or VIN already exists');
      }
      throw DatabaseException('Failed to insert car: $e');
    }
  }
  
  /// Retrieve all cars for a specific user from the database
  Future<List<BackupCar>> getAllCars(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'updated_at DESC',
      );
      
      return List.generate(maps.length, (i) => BackupCar.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Failed to retrieve cars: $e');
    }
  }
  
  /// Retrieve a specific car by ID for a specific user
  Future<BackupCar?> getCarById(int id, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return BackupCar.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to retrieve car: $e');
    }
  }
  
  /// Retrieve a car by VIN for a specific user
  Future<BackupCar?> getCarByVin(String vin, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: 'vin = ? AND user_id = ?',
        whereArgs: [vin, userId],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return BackupCar.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to retrieve car by VIN: $e');
    }
  }
  
  /// Retrieve a car by license plate for a specific user
  Future<BackupCar?> getCarByLicensePlate(String licensePlate, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: 'license_plate = ? AND user_id = ?',
        whereArgs: [licensePlate, userId],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return BackupCar.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to retrieve car by license plate: $e');
    }
  }
  
  /// Update an existing car in the database
  Future<int> updateCar(BackupCar car) async {
    try {
      final db = await database;
      return await db.update(
        tableCars,
        car.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [car.id, car.userId],
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw const DatabaseException('Car with this license plate or VIN already exists for this user');
      }
      throw DatabaseException('Failed to update car: $e');
    }
  }
  
  /// Delete a car from the database for a specific user
  Future<int> deleteCar(int id, String userId) async {
    try {
      final db = await database;
      return await db.delete(
        tableCars,
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete car: $e');
    }
  }
  
  /// Search cars by brand or model for a specific user
  Future<List<BackupCar>> searchCars(String query, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: 'user_id = ? AND (brand LIKE ? OR model LIKE ?)',
        whereArgs: [userId, '%$query%', '%$query%'],
        orderBy: 'updated_at DESC',
      );
      
      return List.generate(maps.length, (i) => BackupCar.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Failed to search cars: $e');
    }
  }
  
  /// Get cars count for a specific user
  Future<int> getCarsCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $tableCars WHERE user_id = ?', [userId]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get cars count: $e');
    }
  }
  
  /// Check if a VIN already exists for a specific user
  Future<bool> vinExists(String vin, String userId, {int? excludeId}) async {
    try {
      final db = await database;
      String whereClause = 'vin = ? AND user_id = ?';
      List<dynamic> whereArgs = [vin, userId];
      
      if (excludeId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeId);
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      throw DatabaseException('Failed to check VIN existence: $e');
    }
  }
  
  /// Check if a license plate already exists for a specific user
  Future<bool> licensePlateExists(String licensePlate, String userId, {int? excludeId}) async {
    try {
      final db = await database;
      String whereClause = 'license_plate = ? AND user_id = ?';
      List<dynamic> whereArgs = [licensePlate, userId];
      
      if (excludeId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeId);
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableCars,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      throw DatabaseException('Failed to check license plate existence: $e');
    }
  }
  
  /// Get all cars for backup for a specific user (returns raw data)
  Future<List<Map<String, dynamic>>> getAllCarsForBackup(String userId) async {
    try {
      final db = await database;
      return await db.query(tableCars, where: 'user_id = ?', whereArgs: [userId]);
    } catch (e) {
      throw DatabaseException('Failed to get cars for backup: $e');
    }
  }
  
  /// Clear all cars for a specific user (use with caution)
  Future<int> clearAllCars(String userId) async {
    try {
      final db = await database;
      return await db.delete(tableCars, where: 'user_id = ?', whereArgs: [userId]);
    } catch (e) {
      throw DatabaseException('Failed to clear all cars: $e');
    }
  }
  
  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ===================== REMINDER OPERATIONS =====================

  /// Insert a new reminder
  Future<int> insertReminder(BackupReminder reminder) async {
    try {
      final db = await database;
      return await db.insert(tableReminders, reminder.toMap());
    } catch (e) {
      throw DatabaseException('Failed to insert reminder: $e');
    }
  }

  /// Get reminder by ID for a specific user (through car ownership)
  Future<BackupReminder?> getReminderById(int id, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE r.id = ? AND c.user_id = ?
      ''', [id, userId]);

      if (maps.isNotEmpty) {
        return BackupReminder.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get reminder: $e');
    }
  }

  /// Get all reminders for a specific user (through car ownership)
  Future<List<BackupReminder>> getAllReminders(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
        ORDER BY r.created_at DESC
      ''', [userId]);

      return List.generate(maps.length, (i) {
        return BackupReminder.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get reminders: $e');
    }
  }

  /// Get all reminders with car information for a specific user
  Future<List<Map<String, dynamic>>> getAllRemindersWithCarInfo(String userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT 
          r.*,
          c.brand as car_brand,
          c.model as car_model,
          c.year as car_year,
          c.license_plate as car_license_plate
        FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
        ORDER BY r.created_at DESC
      ''', [userId]);
    } catch (e) {
      throw DatabaseException('Failed to get reminders with car info: $e');
    }
  }

  /// Get reminders for a specific car and user
  Future<List<BackupReminder>> getRemindersByCar(int carId, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE r.car_id = ? AND c.user_id = ?
        ORDER BY r.created_at DESC
      ''', [carId, userId]);

      return List.generate(maps.length, (i) {
        return BackupReminder.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get reminders for car: $e');
    }
  }

  /// Get reminders by status for a specific user (through car ownership)
  Future<List<BackupReminder>> getRemindersByStatus(ReminderStatus status, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE r.status = ? AND c.user_id = ?
        ORDER BY r.created_at DESC
      ''', [status.name, userId]);

      return List.generate(maps.length, (i) {
        return BackupReminder.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get reminders by status: $e');
    }
  }

  /// Update a reminder
  Future<int> updateReminder(BackupReminder reminder) async {
    try {
      final db = await database;
      return await db.update(
        tableReminders,
        reminder.toMap(),
        where: 'id = ?',
        whereArgs: [reminder.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update reminder: $e');
    }
  }

  /// Delete a reminder (only if user owns the car)
  Future<int> deleteReminder(int id, String userId) async {
    try {
      final db = await database;
      // First verify the user owns the car that the reminder belongs to
      final List<Map<String, dynamic>> checkMaps = await db.rawQuery('''
        SELECT r.id FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE r.id = ? AND c.user_id = ?
      ''', [id, userId]);
      
      if (checkMaps.isEmpty) {
        return 0; // Reminder doesn't exist or doesn't belong to user
      }
      
      return await db.delete(
        tableReminders,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete reminder: $e');
    }
  }

  /// Mark reminder as completed (only if user owns the car)
  Future<int> markReminderCompleted(int id, String userId) async {
    try {
      final db = await database;
      // First verify the user owns the car that the reminder belongs to
      final List<Map<String, dynamic>> checkMaps = await db.rawQuery('''
        SELECT r.id FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE r.id = ? AND c.user_id = ?
      ''', [id, userId]);
      
      if (checkMaps.isEmpty) {
        return 0; // Reminder doesn't exist or doesn't belong to user
      }
      
      return await db.update(
        tableReminders,
        {
          'is_completed': 1,
          'completed_at': DateTime.now().toIso8601String(),
          'status': ReminderStatus.completed.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to mark reminder as completed: $e');
    }
  }

  /// Get overdue reminders for a specific user (through car ownership)
  Future<List<BackupReminder>> getOverdueReminders(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ? AND r.is_completed = 0 AND r.target_date IS NOT NULL AND r.target_date < ?
        ORDER BY r.target_date ASC
      ''', [userId, now]);

      return List.generate(maps.length, (i) {
        return BackupReminder.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get overdue reminders: $e');
    }
  }

  /// Update overdue reminders status
  Future<int> updateOverdueRemindersStatus(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      return await db.update(
        tableReminders,
        {
          'status': ReminderStatus.overdue.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id IN (SELECT r.id FROM $tableReminders r INNER JOIN $tableCars c ON r.car_id = c.id WHERE c.user_id = ? AND r.is_completed = 0 AND r.target_date IS NOT NULL AND r.target_date < ? AND r.status != ?)',
        whereArgs: [userId, now, ReminderStatus.overdue.name],
      );
    } catch (e) {
      throw DatabaseException('Failed to update overdue reminders: $e');
    }
  }

  /// Search reminders by title or description
  Future<List<BackupReminder>> searchReminders(String query, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ? AND (r.title LIKE ? OR r.description LIKE ?)
        ORDER BY r.created_at DESC
      ''', [userId, '%$query%', '%$query%']);

      return List.generate(maps.length, (i) {
        return BackupReminder.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to search reminders: $e');
    }
  }

  /// Get reminders count for a specific user
  Future<int> getRemindersCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
      ''', [userId]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get reminders count: $e');
    }
  }

  /// Get all reminders for backup (used by backup service)
  Future<List<Map<String, dynamic>>> getAllRemindersForBackup(String userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT r.* FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
      ''', [userId]);
    } catch (e) {
      throw DatabaseException('Failed to get reminders for backup: $e');
    }
  }

  /// Clear all reminders for a specific user (use with caution)
  Future<int> clearAllReminders(String userId) async {
    try {
      final db = await database;
      // Delete reminders that belong to cars owned by the user
      return await db.rawDelete('''
        DELETE FROM $tableReminders 
        WHERE car_id IN (
          SELECT id FROM $tableCars WHERE user_id = ?
        )
      ''', [userId]);
    } catch (e) {
      throw DatabaseException('Failed to clear reminders: $e');
    }
  }

  // ==================== MAINTENANCE OPERATIONS ====================

  /// Insert a new maintenance record into the database
  Future<int> insertMaintenance(BackupMaintenance maintenance) async {
    try {
      final db = await database;
      return await db.insert(tableMaintenance, maintenance.toMap());
    } catch (e) {
      throw DatabaseException('Failed to insert maintenance: $e');
    }
  }

  /// Get maintenance by ID
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<BackupMaintenance?> getMaintenanceById(int id, String userId) async {
    try {
      final db = await database;
      // Use UNION to support both reminder-linked and standalone maintenance
      final maps = await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE m.id = ? AND (c1.user_id = ? OR c2.user_id = ?)
      ''', [id, userId, userId]);
      
      if (maps.isNotEmpty) {
        return BackupMaintenance.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get maintenance by ID: $e');
    }
  }

  /// Get all maintenance records for a specific user
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<List<BackupMaintenance>> getAllMaintenance(String userId) async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT DISTINCT m.* FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE c1.user_id = ? OR c2.user_id = ?
        ORDER BY m.maintenance_date DESC
      ''', [userId, userId]);
      
      return List.generate(maps.length, (i) {
        return BackupMaintenance.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get all maintenance: $e');
    }
  }

  /// Get maintenance records by type
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<List<BackupMaintenance>> getMaintenanceByType(String userId, MaintenanceType type) async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT DISTINCT m.* FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE (c1.user_id = ? OR c2.user_id = ?) AND m.type = ?
        ORDER BY m.maintenance_date DESC
      ''', [userId, userId, type.name]);
      
      return List.generate(maps.length, (i) {
        return BackupMaintenance.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get maintenance by type: $e');
    }
  }

  /// Get maintenance records by reminder ID
  Future<List<BackupMaintenance>> getMaintenanceByReminder(int reminderId, String userId) async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE m.reminder_id = ? AND c.user_id = ?
        ORDER BY m.maintenance_date DESC
      ''', [reminderId, userId]);
      
      return List.generate(maps.length, (i) {
        return BackupMaintenance.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get maintenance by reminder: $e');
    }
  }

  /// Update maintenance record
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<int> updateMaintenance(BackupMaintenance maintenance, String userId) async {
    try {
      final db = await database;
      return await db.rawUpdate('''
        UPDATE $tableMaintenance 
        SET title = ?, description = ?, cost = ?, maintenance_date = ?, type = ?, 
            mechanic_name = ?, invoice_number = ?, updated_at = ?
        WHERE id = ? AND (
          reminder_id IN (
            SELECT r.id FROM $tableReminders r
            INNER JOIN $tableCars c ON r.car_id = c.id
            WHERE c.user_id = ?
          )
          OR car_id IN (
            SELECT id FROM $tableCars WHERE user_id = ?
          )
        )
      ''', [
        maintenance.title,
        maintenance.description,
        maintenance.cost,
        maintenance.maintenanceDate.toIso8601String(),
        maintenance.type.name,
        maintenance.mechanicName,
        maintenance.invoiceNumber,
        maintenance.updatedAt.toIso8601String(),
        maintenance.id,
        userId,
        userId,
      ]);
    } catch (e) {
      throw DatabaseException('Failed to update maintenance: $e');
    }
  }

  /// Delete maintenance record
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<int> deleteMaintenance(int id, String userId) async {
    try {
      final db = await database;
      return await db.rawDelete('''
        DELETE FROM $tableMaintenance 
        WHERE id = ? AND (
          reminder_id IN (
            SELECT r.id FROM $tableReminders r
            INNER JOIN $tableCars c ON r.car_id = c.id
            WHERE c.user_id = ?
          )
          OR car_id IN (
            SELECT id FROM $tableCars WHERE user_id = ?
          )
        )
      ''', [id, userId, userId]);
    } catch (e) {
      throw DatabaseException('Failed to delete maintenance: $e');
    }
  }

  /// Search maintenance records
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<List<BackupMaintenance>> searchMaintenance(String userId, String query) async {
    try {
      final db = await database;
      final searchQuery = '%$query%';
      final maps = await db.rawQuery('''
        SELECT DISTINCT m.* FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE (c1.user_id = ? OR c2.user_id = ?) AND (
          m.title LIKE ? OR 
          m.description LIKE ? OR 
          m.mechanic_name LIKE ? OR
          m.invoice_number LIKE ?
        )
        ORDER BY m.maintenance_date DESC
      ''', [userId, userId, searchQuery, searchQuery, searchQuery, searchQuery]);
      
      return List.generate(maps.length, (i) {
        return BackupMaintenance.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to search maintenance: $e');
    }
  }

  /// Get maintenance count for a specific user
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<int> getMaintenanceCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT m.id) as count FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE c1.user_id = ? OR c2.user_id = ?
      ''', [userId, userId]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get maintenance count: $e');
    }
  }

  /// Get maintenance count for a specific car
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<int> getMaintenanceCountByCarId(int carId, String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT m.id) as count FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE (c1.user_id = ? OR c2.user_id = ?)
          AND (r.car_id = ? OR m.car_id = ?)
      ''', [userId, userId, carId, carId]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get maintenance count by car: $e');
    }
  }

  /// Get total maintenance cost for a specific user
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<double> getTotalMaintenanceCost(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(m.cost) as total FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE c1.user_id = ? OR c2.user_id = ?
      ''', [userId, userId]);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw DatabaseException('Failed to get total maintenance cost: $e');
    }
  }

  /// Get maintenance records with full info (maintenance + reminder + car details)
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<List<Map<String, dynamic>>> getAllMaintenanceWithInfo(String userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT DISTINCT
          m.*,
          COALESCE(r.title, 'Standalone Maintenance') as reminder_title,
          COALESCE(c1.brand, c2.brand) as car_brand,
          COALESCE(c1.model, c2.model) as car_model,
          COALESCE(c1.year, c2.year) as car_year,
          COALESCE(c1.license_plate, c2.license_plate) as car_license_plate
        FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE c1.user_id = ? OR c2.user_id = ?
        ORDER BY m.maintenance_date DESC
      ''', [userId, userId]);
    } catch (e) {
      throw DatabaseException('Failed to get maintenance with info: $e');
    }
  }

  /// Get all maintenance for backup (used by backup service)
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<List<Map<String, dynamic>>> getAllMaintenanceForBackup(String userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT DISTINCT m.* FROM $tableMaintenance m
        LEFT JOIN $tableReminders r ON m.reminder_id = r.id
        LEFT JOIN $tableCars c1 ON r.car_id = c1.id
        LEFT JOIN $tableCars c2 ON m.car_id = c2.id
        WHERE c1.user_id = ? OR c2.user_id = ?
      ''', [userId, userId]);
    } catch (e) {
      throw DatabaseException('Failed to get maintenance for backup: $e');
    }
  }

  /// Clear all maintenance for a specific user (use with caution)
  /// Supports both reminder-linked maintenance (via reminder_id) and standalone maintenance (via car_id)
  Future<int> clearAllMaintenance(String userId) async {
    try {
      final db = await database;
      return await db.rawDelete('''
        DELETE FROM $tableMaintenance 
        WHERE reminder_id IN (
          SELECT r.id FROM $tableReminders r
          INNER JOIN $tableCars c ON r.car_id = c.id
          WHERE c.user_id = ?
        )
        OR car_id IN (
          SELECT id FROM $tableCars WHERE user_id = ?
        )
      ''', [userId, userId]);
    } catch (e) {
      throw DatabaseException('Failed to clear maintenance: $e');
    }
  }

  /// Get overdue reminders with car information for a specific user
  Future<List<Map<String, dynamic>>> getOverdueRemindersWithCarInfo(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      return await db.rawQuery('''
        SELECT 
          r.*,
          c.brand as car_brand,
          c.model as car_model,
          c.year as car_year,
          c.license_plate as car_license_plate
        FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ? AND r.is_completed = 0 AND r.target_date IS NOT NULL AND r.target_date < ?
        ORDER BY r.target_date ASC
      ''', [userId, now]);
    } catch (e) {
      throw DatabaseException('Failed to get overdue reminders with car info: $e');
    }
  }

  /// Get upcoming reminders with car information for a specific user
  Future<List<Map<String, dynamic>>> getUpcomingRemindersWithCarInfo(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      return await db.rawQuery('''
        SELECT 
          r.*,
          c.brand as car_brand,
          c.model as car_model,
          c.year as car_year,
          c.license_plate as car_license_plate
        FROM $tableReminders r
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ? AND r.is_completed = 0 AND r.target_date IS NOT NULL AND r.target_date >= ?
        ORDER BY r.target_date ASC
      ''', [userId, now]);
    } catch (e) {
      throw DatabaseException('Failed to get upcoming reminders with car info: $e');
    }
  }

  // ==================== LICENSE IMAGES METHODS ====================

  /// Insert a new license image
  Future<int> insertLicenseImage(LicenseImage licenseImage) async {
    try {
      final db = await database;
      return await db.insert(
        tableLicenseImages,
        licenseImage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert license image: $e');
    }
  }

  /// Get license image by ID for a specific user
  Future<LicenseImage?> getLicenseImageById(int id, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableLicenseImages,
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      
      if (maps.isNotEmpty) {
        return LicenseImage.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get license image by ID: $e');
    }
  }

  /// Get all license images for a specific car
  Future<List<LicenseImage>> getLicenseImagesForCar(int carId, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableLicenseImages,
        where: 'car_id = ? AND user_id = ?',
        whereArgs: [carId, userId],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) => LicenseImage.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Failed to get license images for car: $e');
    }
  }

  /// Get license image by type for a specific car
  Future<LicenseImage?> getLicenseImageByType(int carId, String licenseType, String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableLicenseImages,
        where: 'car_id = ? AND license_type = ? AND user_id = ?',
        whereArgs: [carId, licenseType, userId],
      );
      
      if (maps.isNotEmpty) {
        return LicenseImage.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get license image by type: $e');
    }
  }

  /// Get all license images for a specific user
  Future<List<LicenseImage>> getAllLicenseImages(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableLicenseImages,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) => LicenseImage.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Failed to get all license images: $e');
    }
  }

  /// Update an existing license image
  Future<int> updateLicenseImage(LicenseImage licenseImage) async {
    try {
      final db = await database;
      return await db.update(
        tableLicenseImages,
        licenseImage.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [licenseImage.id, licenseImage.userId],
      );
    } catch (e) {
      throw DatabaseException('Failed to update license image: $e');
    }
  }

  /// Delete a license image
  Future<int> deleteLicenseImage(int id, String userId) async {
    try {
      final db = await database;
      return await db.delete(
        tableLicenseImages,
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete license image: $e');
    }
  }

  /// Get license images count for a specific user
  Future<int> getLicenseImagesCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM $tableLicenseImages WHERE user_id = ?',
        [userId]
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get license images count: $e');
    }
  }

  /// Clear all license images for a specific user (use with caution)
  Future<int> clearAllLicenseImages(String userId) async {
    try {
      final db = await database;
      return await db.delete(tableLicenseImages, where: 'user_id = ?', whereArgs: [userId]);
    } catch (e) {
      throw DatabaseException('Failed to clear license images: $e');
    }
  }

  // ==================== OBD SCANS METHODS ====================

  /// Insert a new OBD scan
  Future<int> insertOBDScan(Map<String, dynamic> obdScan) async {
    try {
      final db = await database;
      return await db.insert(tableOBDScans, obdScan);
    } catch (e) {
      throw DatabaseException('Failed to insert OBD scan: $e');
    }
  }

  /// Get all OBD scans for a specific car
  Future<List<Map<String, dynamic>>> getOBDScansByCar(int carId) async {
    try {
      final db = await database;
      return await db.query(
        tableOBDScans,
        where: 'car_id = ?',
        whereArgs: [carId],
        orderBy: 'scan_date DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get OBD scans: $e');
    }
  }

  /// Get all OBD scans
  Future<List<Map<String, dynamic>>> getAllOBDScans() async {
    try {
      final db = await database;
      return await db.query(
        tableOBDScans,
        orderBy: 'scan_date DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get all OBD scans: $e');
    }
  }

  /// Get a specific OBD scan by ID
  Future<Map<String, dynamic>?> getOBDScanById(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        tableOBDScans,
        where: 'id = ?',
        whereArgs: [id],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException('Failed to get OBD scan: $e');
    }
  }

  /// Update an existing OBD scan
  Future<int> updateOBDScan(int id, Map<String, dynamic> obdScan) async {
    try {
      final db = await database;
      return await db.update(
        tableOBDScans,
        obdScan,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update OBD scan: $e');
    }
  }

  /// Delete an OBD scan
  Future<int> deleteOBDScan(int id) async {
    try {
      final db = await database;
      return await db.delete(
        tableOBDScans,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete OBD scan: $e');
    }
  }

  /// Delete all OBD scans for a specific car
  Future<int> deleteOBDScansByCar(int carId) async {
    try {
      final db = await database;
      return await db.delete(
        tableOBDScans,
        where: 'car_id = ?',
        whereArgs: [carId],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete OBD scans: $e');
    }
  }

  /// Get OBD scans count for a specific car
  Future<int> getOBDScansCount(int carId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM $tableOBDScans WHERE car_id = ?',
        [carId]
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get OBD scans count: $e');
    }
  }

  /// Get latest OBD scan for a specific car
  Future<Map<String, dynamic>?> getLatestOBDScan(int carId) async {
    try {
      final db = await database;
      final results = await db.query(
        tableOBDScans,
        where: 'car_id = ?',
        whereArgs: [carId],
        orderBy: 'scan_date DESC',
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException('Failed to get latest OBD scan: $e');
    }
  }

  /// Clear all OBD scans (use with caution)
  Future<int> clearAllOBDScans() async {
    try {
      final db = await database;
      return await db.delete(tableOBDScans);
    } catch (e) {
      throw DatabaseException('Failed to clear OBD scans: $e');
    }
  }

  // ==================== EXPENSES METHODS ====================

  /// Insert a new expense
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    try {
      final db = await database;
      return await db.insert(tableExpenses, expense);
    } catch (e) {
      throw DatabaseException('Failed to insert expense: $e');
    }
  }

  /// Get all expenses for a specific car
  Future<List<Map<String, dynamic>>> getExpensesByCar(int carId) async {
    try {
      final db = await database;
      return await db.query(
        tableExpenses,
        where: 'car_id = ?',
        whereArgs: [carId],
        orderBy: 'date DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get expenses: $e');
    }
  }

  /// Get all expenses
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    try {
      final db = await database;
      return await db.query(tableExpenses, orderBy: 'date DESC');
    } catch (e) {
      throw DatabaseException('Failed to get all expenses: $e');
    }
  }

  /// Get expenses by category
  Future<List<Map<String, dynamic>>> getExpensesByCategory(int carId, String category) async {
    try {
      final db = await database;
      return await db.query(
        tableExpenses,
        where: 'car_id = ? AND category = ?',
        whereArgs: [carId, category],
        orderBy: 'date DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get expenses by category: $e');
    }
  }

  /// Get expenses in date range
  Future<List<Map<String, dynamic>>> getExpensesInRange(int carId, int startDate, int endDate) async {
    try {
      final db = await database;
      return await db.query(
        tableExpenses,
        where: 'car_id = ? AND date >= ? AND date <= ?',
        whereArgs: [carId, startDate, endDate],
        orderBy: 'date DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get expenses in range: $e');
    }
  }

  /// Update an expense
  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    try {
      final db = await database;
      return await db.update(tableExpenses, expense, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<int> deleteExpense(int id) async {
    try {
      final db = await database;
      return await db.delete(tableExpenses, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete expense: $e');
    }
  }

  /// Get total expenses for a car
  Future<double> getTotalExpenses(int carId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $tableExpenses WHERE car_id = ?',
        [carId]
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw DatabaseException('Failed to get total expenses: $e');
    }
  }

  // ==================== TRIPS METHODS ====================

  /// Insert a new trip
  Future<int> insertTrip(Map<String, dynamic> trip) async {
    try {
      final db = await database;
      return await db.insert(tableTrips, trip);
    } catch (e) {
      throw DatabaseException('Failed to insert trip: $e');
    }
  }

  /// Get all trips for a specific car
  Future<List<Map<String, dynamic>>> getTripsByCar(int carId) async {
    try {
      final db = await database;
      return await db.query(
        tableTrips,
        where: 'car_id = ?',
        whereArgs: [carId],
        orderBy: 'start_time DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get trips: $e');
    }
  }

  /// Get all trips
  Future<List<Map<String, dynamic>>> getAllTrips() async {
    try {
      final db = await database;
      return await db.query(tableTrips, orderBy: 'start_time DESC');
    } catch (e) {
      throw DatabaseException('Failed to get all trips: $e');
    }
  }

  /// Get trips by type
  Future<List<Map<String, dynamic>>> getTripsByType(int carId, String tripType) async {
    try {
      final db = await database;
      return await db.query(
        tableTrips,
        where: 'car_id = ? AND trip_type = ?',
        whereArgs: [carId, tripType],
        orderBy: 'start_time DESC',
      );
    } catch (e) {
      throw DatabaseException('Failed to get trips by type: $e');
    }
  }

  /// Update a trip
  Future<int> updateTrip(int id, Map<String, dynamic> trip) async {
    try {
      final db = await database;
      return await db.update(tableTrips, trip, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to update trip: $e');
    }
  }

  /// Delete a trip
  Future<int> deleteTrip(int id) async {
    try {
      final db = await database;
      return await db.delete(tableTrips, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete trip: $e');
    }
  }

  /// Get total distance for a car
  Future<double> getTotalDistance(int carId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(distance) as total FROM $tableTrips WHERE car_id = ?',
        [carId]
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw DatabaseException('Failed to get total distance: $e');
    }
  }

  // ==================== BUDGETS METHODS ====================

  /// Insert a new budget
  Future<int> insertBudget(Map<String, dynamic> budget) async {
    try {
      final db = await database;
      return await db.insert(tableBudgets, budget);
    } catch (e) {
      throw DatabaseException('Failed to insert budget: $e');
    }
  }

  /// Get all budgets for a specific car
  Future<List<Map<String, dynamic>>> getBudgetsByCar(int carId) async {
    try {
      final db = await database;
      return await db.query(
        tableBudgets,
        where: 'car_id = ?',
        whereArgs: [carId],
      );
    } catch (e) {
      throw DatabaseException('Failed to get budgets: $e');
    }
  }

  /// Get budget by category
  Future<Map<String, dynamic>?> getBudgetByCategory(int carId, String category) async {
    try {
      final db = await database;
      final results = await db.query(
        tableBudgets,
        where: 'car_id = ? AND category = ?',
        whereArgs: [carId, category],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException('Failed to get budget by category: $e');
    }
  }

  /// Update a budget
  Future<int> updateBudget(int id, Map<String, dynamic> budget) async {
    try {
      final db = await database;
      return await db.update(tableBudgets, budget, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to update budget: $e');
    }
  }

  /// Delete a budget
  Future<int> deleteBudget(int id) async {
    try {
      final db = await database;
      return await db.delete(tableBudgets, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete budget: $e');
    }
  }
}

/// Custom exception for database operations
class DatabaseException implements Exception {
  final String message;
  
  const DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}
