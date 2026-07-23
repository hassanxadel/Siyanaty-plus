import 'package:sqflite/sqflite.dart';
import '../models/mileage_entry.dart';

class MileageDatabaseHelper {
  static const String tableName = 'mileage_entries';

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mileage REAL NOT NULL,
      fuel REAL NOT NULL,
      cost REAL NOT NULL,
      date TEXT NOT NULL,
      notes TEXT,
      entry_name TEXT,
      user_id TEXT,
      car_id TEXT,
      trip_frequency TEXT DEFAULT 'oneTime',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      last_applied_at TEXT
    )
  ''';

  /// Record that a recurring entry's mileage has been credited up to [when].
  /// Written directly (not via [updateEntry]) so it doesn't disturb
  /// `updated_at` or rewrite the whole row from the background isolate.
  static Future<int> markApplied(Database db, int id, DateTime when) async {
    return await db.update(
      tableName,
      {'last_applied_at': when.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insert a new mileage entry
  static Future<int> insertEntry(Database db, MileageEntry entry) async {
    return await db.insert(
      tableName,
      entry.toMap()..remove('id'), // Remove id for insert
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all mileage entries for a user (or all if userId is null)
  static Future<List<MileageEntry>> getEntries(Database db, {String? userId}) async {
    final List<Map<String, dynamic>> maps;
    
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'date DESC, created_at DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        orderBy: 'date DESC, created_at DESC',
      );
    }

    return List.generate(maps.length, (i) {
      return MileageEntry.fromMap(maps[i]);
    });
  }

  // Get a specific mileage entry by ID
  static Future<MileageEntry?> getEntryById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MileageEntry.fromMap(maps.first);
  }

  // Update a mileage entry
  static Future<int> updateEntry(Database db, MileageEntry entry) async {
    return await db.update(
      tableName,
      entry.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete a mileage entry
  static Future<int> deleteEntry(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all entries for a user
  static Future<int> deleteAllEntries(Database db, {String? userId}) async {
    if (userId != null) {
      return await db.delete(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      return await db.delete(tableName);
    }
  }

  // Get entries within a date range
  static Future<List<MileageEntry>> getEntriesInRange(
    Database db,
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    final List<Map<String, dynamic>> maps;
    
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '(user_id = ? OR user_id IS NULL) AND date BETWEEN ? AND ?',
        whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'date DESC, created_at DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'date DESC, created_at DESC',
      );
    }

    return List.generate(maps.length, (i) {
      return MileageEntry.fromMap(maps[i]);
    });
  }

  // Get statistics for mileage entries
  static Future<Map<String, double>> getStatistics(Database db, {String? userId}) async {
    final List<Map<String, dynamic>> result;
    
    if (userId != null) {
      result = await db.rawQuery('''
        SELECT 
          COUNT(*) as entryCount,
          SUM(fuel) as totalFuel,
          SUM(cost) as totalCost,
          MAX(mileage) as maxMileage,
          MIN(mileage) as minMileage
        FROM $tableName 
        WHERE user_id = ? OR user_id IS NULL
      ''', [userId]);
    } else {
      result = await db.rawQuery('''
        SELECT 
          COUNT(*) as entryCount,
          SUM(fuel) as totalFuel,
          SUM(cost) as totalCost,
          MAX(mileage) as maxMileage,
          MIN(mileage) as minMileage
        FROM $tableName
      ''');
    }

    if (result.isEmpty) {
      return {
        'entryCount': 0,
        'totalFuel': 0,
        'totalCost': 0,
        'totalDistance': 0,
        'averageEfficiency': 0,
      };
    }

    final data = result.first;
    final maxMileage = (data['maxMileage'] as num?)?.toDouble() ?? 0;
    final minMileage = (data['minMileage'] as num?)?.toDouble() ?? 0;
    final totalDistance = maxMileage - minMileage;
    final totalFuel = (data['totalFuel'] as num?)?.toDouble() ?? 0;
    final averageEfficiency = totalDistance > 0 && totalFuel > 0 
        ? (totalFuel / totalDistance) * 100 
        : 0;

    return {
      'entryCount': (data['entryCount'] as num?)?.toDouble() ?? 0,
      'totalFuel': totalFuel,
      'totalCost': (data['totalCost'] as num?)?.toDouble() ?? 0,
      'totalDistance': totalDistance,
      'averageEfficiency': averageEfficiency.toDouble(),
    };
  }
}
