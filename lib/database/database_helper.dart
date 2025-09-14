import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/backup_car.dart';
import '../models/backup_reminder.dart';
import '../models/backup_maintenance.dart';

/// Database helper class for managing SQLite database operations
/// Handles car data storage with CRUD operations
class DatabaseHelper {
  static const String _databaseName = 'syanaty.db';
  static const int _databaseVersion = 4;
  
  static const String tableCars = 'cars';
  static const String tableReminders = 'reminders';
  static const String tableMaintenance = 'maintenance';
  
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
          reminder_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          cost REAL NOT NULL DEFAULT 0.0,
          maintenance_date TEXT NOT NULL,
          type TEXT NOT NULL,
          mechanic_name TEXT,
          invoice_number TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (reminder_id) REFERENCES $tableReminders (id) ON DELETE CASCADE
        )
      ''');
      
      // Create indexes for maintenance
      await db.execute('CREATE INDEX idx_maintenance_reminder_id ON $tableMaintenance (reminder_id)');
      await db.execute('CREATE INDEX idx_maintenance_type ON $tableMaintenance (type)');
      await db.execute('CREATE INDEX idx_maintenance_date ON $tableMaintenance (maintenance_date)');
      await db.execute('CREATE INDEX idx_maintenance_cost ON $tableMaintenance (cost)');
      
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
            reminder_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            cost REAL NOT NULL DEFAULT 0.0,
            maintenance_date TEXT NOT NULL,
            type TEXT NOT NULL,
            mechanic_name TEXT,
            invoice_number TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (reminder_id) REFERENCES $tableReminders (id) ON DELETE CASCADE
          )
        ''');
        
        // Create indexes for maintenance
        await db.execute('CREATE INDEX idx_maintenance_reminder_id ON $tableMaintenance (reminder_id)');
        await db.execute('CREATE INDEX idx_maintenance_type ON $tableMaintenance (type)');
        await db.execute('CREATE INDEX idx_maintenance_date ON $tableMaintenance (maintenance_date)');
        await db.execute('CREATE INDEX idx_maintenance_cost ON $tableMaintenance (cost)');
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
  Future<BackupMaintenance?> getMaintenanceById(int id, String userId) async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE m.id = ? AND c.user_id = ?
      ''', [id, userId]);
      
      if (maps.isNotEmpty) {
        return BackupMaintenance.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get maintenance by ID: $e');
    }
  }

  /// Get all maintenance records for a specific user
  Future<List<BackupMaintenance>> getAllMaintenance(String userId) async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
        ORDER BY m.maintenance_date DESC
      ''', [userId]);
      
      return List.generate(maps.length, (i) {
        return BackupMaintenance.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to get all maintenance: $e');
    }
  }

  /// Get maintenance records by type
  Future<List<BackupMaintenance>> getMaintenanceByType(String userId, MaintenanceType type) async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ? AND m.type = ?
        ORDER BY m.maintenance_date DESC
      ''', [userId, type.name]);
      
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
  Future<int> updateMaintenance(BackupMaintenance maintenance, String userId) async {
    try {
      final db = await database;
      return await db.rawUpdate('''
        UPDATE $tableMaintenance 
        SET title = ?, description = ?, cost = ?, maintenance_date = ?, type = ?, 
            mechanic_name = ?, invoice_number = ?, updated_at = ?
        WHERE id = ? AND reminder_id IN (
          SELECT r.id FROM $tableReminders r
          INNER JOIN $tableCars c ON r.car_id = c.id
          WHERE c.user_id = ?
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
      ]);
    } catch (e) {
      throw DatabaseException('Failed to update maintenance: $e');
    }
  }

  /// Delete maintenance record
  Future<int> deleteMaintenance(int id, String userId) async {
    try {
      final db = await database;
      return await db.rawDelete('''
        DELETE FROM $tableMaintenance 
        WHERE id = ? AND reminder_id IN (
          SELECT r.id FROM $tableReminders r
          INNER JOIN $tableCars c ON r.car_id = c.id
          WHERE c.user_id = ?
        )
      ''', [id, userId]);
    } catch (e) {
      throw DatabaseException('Failed to delete maintenance: $e');
    }
  }

  /// Search maintenance records
  Future<List<BackupMaintenance>> searchMaintenance(String userId, String query) async {
    try {
      final db = await database;
      final searchQuery = '%$query%';
      final maps = await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ? AND (
          m.title LIKE ? OR 
          m.description LIKE ? OR 
          m.mechanic_name LIKE ? OR
          m.invoice_number LIKE ?
        )
        ORDER BY m.maintenance_date DESC
      ''', [userId, searchQuery, searchQuery, searchQuery, searchQuery]);
      
      return List.generate(maps.length, (i) {
        return BackupMaintenance.fromMap(maps[i]);
      });
    } catch (e) {
      throw DatabaseException('Failed to search maintenance: $e');
    }
  }

  /// Get maintenance count for a specific user
  Future<int> getMaintenanceCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
      ''', [userId]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get maintenance count: $e');
    }
  }

  /// Get total maintenance cost for a specific user
  Future<double> getTotalMaintenanceCost(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(m.cost) as total FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
      ''', [userId]);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw DatabaseException('Failed to get total maintenance cost: $e');
    }
  }

  /// Get maintenance records with full info (maintenance + reminder + car details)
  Future<List<Map<String, dynamic>>> getAllMaintenanceWithInfo(String userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT 
          m.*,
          r.title as reminder_title,
          c.brand as car_brand,
          c.model as car_model,
          c.year as car_year,
          c.license_plate as car_license_plate
        FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
        ORDER BY m.maintenance_date DESC
      ''', [userId]);
    } catch (e) {
      throw DatabaseException('Failed to get maintenance with info: $e');
    }
  }

  /// Get all maintenance for backup (used by backup service)
  Future<List<Map<String, dynamic>>> getAllMaintenanceForBackup(String userId) async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT m.* FROM $tableMaintenance m
        INNER JOIN $tableReminders r ON m.reminder_id = r.id
        INNER JOIN $tableCars c ON r.car_id = c.id
        WHERE c.user_id = ?
      ''', [userId]);
    } catch (e) {
      throw DatabaseException('Failed to get maintenance for backup: $e');
    }
  }

  /// Clear all maintenance for a specific user (use with caution)
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
      ''', [userId]);
    } catch (e) {
      throw DatabaseException('Failed to clear maintenance: $e');
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
