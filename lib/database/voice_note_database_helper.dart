import 'package:sqflite/sqflite.dart';
import '../models/voice_note.dart';

class VoiceNoteDatabaseHelper {
  static const String tableName = 'voice_notes';

  // Use snake_case for all column names to match VoiceNote.toMap()
  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      file_path TEXT NOT NULL,
      duration INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      user_id TEXT
    )
  ''';

  // Insert a new voice note
  static Future<int> insertVoiceNote(Database db, VoiceNote note) async {
    return await db.insert(
      tableName,
      note.toMap()..remove('id'), // Remove id for insert
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all voice notes for a user (or all if userId is null)
  static Future<List<VoiceNote>> getVoiceNotes(Database db, {String? userId}) async {
    final List<Map<String, dynamic>> maps;
    
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        orderBy: 'created_at DESC',
      );
    }

    return List.generate(maps.length, (i) {
      return VoiceNote.fromMap(maps[i]);
    });
  }

  // Get a specific voice note by ID
  static Future<VoiceNote?> getVoiceNoteById(Database db, int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return VoiceNote.fromMap(maps.first);
  }

  // Update a voice note
  static Future<int> updateVoiceNote(Database db, VoiceNote note) async {
    return await db.update(
      tableName,
      note.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Delete a voice note
  static Future<int> deleteVoiceNote(Database db, int id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all voice notes for a user
  static Future<int> deleteAllVoiceNotes(Database db, {String? userId}) async {
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

  // Search voice notes by title or description
  static Future<List<VoiceNote>> searchVoiceNotes(
    Database db,
    String query, {
    String? userId,
  }) async {
    final List<Map<String, dynamic>> maps;
    
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '(user_id = ? OR user_id IS NULL) AND (title LIKE ? OR description LIKE ?)',
        whereArgs: [userId, '%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        where: 'title LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );
    }

    return List.generate(maps.length, (i) {
      return VoiceNote.fromMap(maps[i]);
    });
  }

  // Get voice notes within a date range
  static Future<List<VoiceNote>> getVoiceNotesInRange(
    Database db,
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    final List<Map<String, dynamic>> maps;
    
    if (userId != null) {
      maps = await db.query(
        tableName,
        where: '(user_id = ? OR user_id IS NULL) AND created_at BETWEEN ? AND ?',
        whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        where: 'created_at BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );
    }

    return List.generate(maps.length, (i) {
      return VoiceNote.fromMap(maps[i]);
    });
  }

  // Get statistics for voice notes
  static Future<Map<String, dynamic>> getStatistics(Database db, {String? userId}) async {
    final List<Map<String, dynamic>> result;
    
    if (userId != null) {
      result = await db.rawQuery('''
        SELECT 
          COUNT(*) as noteCount,
          SUM(duration) as totalDuration,
          AVG(duration) as averageDuration
        FROM $tableName 
        WHERE user_id = ? OR user_id IS NULL
      ''', [userId]);
    } else {
      result = await db.rawQuery('''
        SELECT 
          COUNT(*) as noteCount,
          SUM(duration) as totalDuration,
          AVG(duration) as averageDuration
        FROM $tableName
      ''');
    }

    if (result.isEmpty) {
      return {
        'noteCount': 0,
        'totalDuration': 0,
        'averageDuration': 0,
      };
    }

    final data = result.first;
    return {
      'noteCount': (data['noteCount'] as num?)?.toInt() ?? 0,
      'totalDuration': (data['totalDuration'] as num?)?.toInt() ?? 0,
      'averageDuration': (data['averageDuration'] as num?)?.toDouble() ?? 0,
    };
  }
}
