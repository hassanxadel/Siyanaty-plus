import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), AppConstants.databaseName);
      
      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      AppLogger.error('Failed to initialize database', error: e);
      rethrow;
    }
  }
  
  static Future<void> _createTables(Database db, int version) async {
    // Cars table
    await db.execute('''
      CREATE TABLE ${AppConstants.carsTable} (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        vin TEXT,
        licensePlate TEXT,
        color TEXT,
        mileage REAL NOT NULL DEFAULT 0,
        fuelType TEXT,
        engineSize TEXT,
        transmission TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    
    // Repairs table
    await db.execute('''
      CREATE TABLE ${AppConstants.repairsTable} (
        id TEXT PRIMARY KEY,
        carId TEXT NOT NULL,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        cost REAL NOT NULL DEFAULT 0,
        mileage REAL NOT NULL DEFAULT 0,
        serviceCenter TEXT,
        category TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        scheduledDate TEXT,
        completedDate TEXT,
        receipts TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (carId) REFERENCES ${AppConstants.carsTable} (id) ON DELETE CASCADE
      )
    ''');
    
    // Reminders table
    await db.execute('''
      CREATE TABLE ${AppConstants.remindersTable} (
        id TEXT PRIMARY KEY,
        carId TEXT NOT NULL,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        reminderType TEXT NOT NULL,
        targetMileage REAL,
        targetDate TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (carId) REFERENCES ${AppConstants.carsTable} (id) ON DELETE CASCADE
      )
    ''');
    
    // Maintenance records table
    await db.execute('''
      CREATE TABLE ${AppConstants.maintenanceTable} (
        id TEXT PRIMARY KEY,
        carId TEXT NOT NULL,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        cost REAL NOT NULL DEFAULT 0,
        mileage REAL NOT NULL DEFAULT 0,
        serviceCenter TEXT,
        nextServiceMileage REAL,
        nextServiceDate TEXT,
        parts TEXT,
        laborCost REAL,
        partsCost REAL,
        warranty TEXT,
        receipts TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (carId) REFERENCES ${AppConstants.carsTable} (id) ON DELETE CASCADE
      )
    ''');
    
    // Fuel logs table
    await db.execute('''
      CREATE TABLE ${AppConstants.fuelLogsTable} (
        id TEXT PRIMARY KEY,
        carId TEXT NOT NULL,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        cost REAL NOT NULL,
        pricePerUnit REAL NOT NULL,
        mileage REAL NOT NULL,
        fuelType TEXT,
        location TEXT,
        isFullTank INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (carId) REFERENCES ${AppConstants.carsTable} (id) ON DELETE CASCADE
      )
    ''');
    
    AppLogger.info('Database tables created successfully');
  }
  
  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database from version $oldVersion to $newVersion');
    // Handle database upgrades here
  }
  
  // Generic CRUD operations
  static Future<int> insert(String table, Map<String, dynamic> values) async {
    try {
      final db = await database;
      return await db.insert(table, values);
    } catch (e) {
      AppLogger.error('Failed to insert into $table', error: e);
      rethrow;
    }
  }
  
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error('Failed to query $table', error: e);
      rethrow;
    }
  }
  
  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(table, values, where: where, whereArgs: whereArgs);
    } catch (e) {
      AppLogger.error('Failed to update $table', error: e);
      rethrow;
    }
  }
  
  static Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      AppLogger.error('Failed to delete from $table', error: e);
      rethrow;
    }
  }
  
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.info('Database closed');
    }
  }
}
