import 'package:sqflite/sqflite.dart';
import '../models/scan_model.dart';

class OcrDatabaseHelper {
  static const String tableName = 'scans';
  
  // Create table SQL
  static const String createTableSql = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      imagePath TEXT,
      source TEXT NOT NULL DEFAULT 'mlkit',
      timestamp INTEGER NOT NULL,
      user_id TEXT
    )
  ''';

  // Insert a new scan
  static Future<int> insertScan(Database db, ScanModel scan) async {
    return await db.insert(
      tableName,
      scan.toMap()..remove('id'), // Remove id for auto-increment
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all scans ordered by timestamp (newest first)
  static Future<List<ScanModel>> getAllScans(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ScanModel.fromMap(maps[i]);
    });
  }

  // Get scans for a specific user
  static Future<List<ScanModel>> getScansByUser(Database db, String userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ScanModel.fromMap(maps[i]);
    });
  }

  // Get a specific scan by ID
  static Future<ScanModel?> getScanById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ScanModel.fromMap(maps.first);
    }
    return null;
  }

  // Update a scan
  static Future<int> updateScan(Database db, ScanModel scan) async {
    return await db.update(
      tableName,
      scan.toMap(),
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }

  // Delete a scan
  static Future<int> deleteScan(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all scans for a user
  static Future<int> deleteUserScans(Database db, String userId) async {
    return await db.delete(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Search scans by text content
  static Future<List<ScanModel>> searchScans(Database db, String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return ScanModel.fromMap(maps[i]);
    });
  }

  // Get scan count
  static Future<int> getScanCount(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get scan count for user
  static Future<int> getUserScanCount(Database db, String userId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableName WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
