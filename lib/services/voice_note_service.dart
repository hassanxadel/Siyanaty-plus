import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../models/voice_note.dart';
import '../database/database_helper.dart';
import '../database/voice_note_database_helper.dart';

class VoiceNoteService {
  static final VoiceNoteService _instance = VoiceNoteService._internal();
  factory VoiceNoteService() => _instance;
  VoiceNoteService._internal();

  // Local database operations

  /// Add a new voice note to local database
  Future<VoiceNote> addVoiceNote(VoiceNote note) async {
    final db = await DatabaseHelper.instance.database;
    final id = await VoiceNoteDatabaseHelper.insertVoiceNote(db, note);
    return note.copyWith(id: id);
  }

  /// Get all voice notes from local database
  Future<List<VoiceNote>> getAllVoiceNotes({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    return await VoiceNoteDatabaseHelper.getVoiceNotes(db, userId: userId);
  }

  /// Get a specific voice note by ID
  Future<VoiceNote?> getVoiceNoteById(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await VoiceNoteDatabaseHelper.getVoiceNoteById(db, id);
  }

  /// Update an existing voice note
  Future<bool> updateVoiceNote(VoiceNote note) async {
    if (note.id == null) return false;
    
    final db = await DatabaseHelper.instance.database;
    final result = await VoiceNoteDatabaseHelper.updateVoiceNote(db, note);
    return result > 0;
  }

  /// Delete a voice note and its audio file
  Future<bool> deleteVoiceNote(int id) async {
    final db = await DatabaseHelper.instance.database;
    
    // Get the voice note to delete the audio file
    final note = await VoiceNoteDatabaseHelper.getVoiceNoteById(db, id);
    if (note != null) {
      try {
        // Delete the audio file
        final file = File(note.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting audio file: $e');
        // Continue with database deletion even if file deletion fails
      }
    }
    
    final result = await VoiceNoteDatabaseHelper.deleteVoiceNote(db, id);
    return result > 0;
  }

  /// Search voice notes by title or description
  Future<List<VoiceNote>> searchVoiceNotes(String query, {String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    return await VoiceNoteDatabaseHelper.searchVoiceNotes(db, query, userId: userId);
  }

  /// Get voice notes within a date range
  Future<List<VoiceNote>> getVoiceNotesInRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await VoiceNoteDatabaseHelper.getVoiceNotesInRange(
      db,
      startDate,
      endDate,
      userId: userId,
    );
  }

  /// Get statistics for voice notes
  Future<Map<String, dynamic>> getStatistics({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    return await VoiceNoteDatabaseHelper.getStatistics(db, userId: userId);
  }

  /// Clear all local voice notes and their files
  Future<void> clearAllVoiceNotes({String? userId}) async {
    // Get all notes first to delete their files
    final notes = await getAllVoiceNotes(userId: userId);
    
    // Delete all audio files
    for (final note in notes) {
      try {
        final file = File(note.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting audio file: $e');
      }
    }
    
    // Delete from database
    final db = await DatabaseHelper.instance.database;
    await VoiceNoteDatabaseHelper.deleteAllVoiceNotes(db, userId: userId);
  }

  // File management operations

  /// Get the directory for storing voice notes
  Future<Directory> getVoiceNotesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final voiceNotesDir = Directory(path.join(appDir.path, 'voice_notes'));
    
    if (!await voiceNotesDir.exists()) {
      await voiceNotesDir.create(recursive: true);
    }
    
    return voiceNotesDir;
  }

  /// Generate a unique file path for a new voice note
  Future<String> generateFilePath() async {
    final dir = await getVoiceNotesDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(dir.path, 'voice_note_$timestamp.m4a');
  }

  /// Check if microphone permission is granted
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if storage permission is granted (for older Android versions)
  Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check if a voice note file exists
  Future<bool> voiceNoteFileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Get the size of a voice note file in bytes
  Future<int> getVoiceNoteFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return 0;
  }

  /// Format file size in human readable format
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clean up orphaned audio files (files that don't have corresponding database entries)
  Future<int> cleanupOrphanedFiles({String? userId}) async {
    try {
      final dir = await getVoiceNotesDirectory();
      final files = dir.listSync().whereType<File>().toList();
      final notes = await getAllVoiceNotes(userId: userId);
      final usedPaths = notes.map((note) => note.filePath).toSet();
      
      int deletedCount = 0;
      for (final file in files) {
        if (!usedPaths.contains(file.path)) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            print('Error deleting orphaned file ${file.path}: $e');
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      print('Error cleaning up orphaned files: $e');
      return 0;
    }
  }

  /// Get total storage used by voice notes
  Future<int> getTotalStorageUsed({String? userId}) async {
    try {
      final notes = await getAllVoiceNotes(userId: userId);
      int totalSize = 0;
      
      for (final note in notes) {
        totalSize += await getVoiceNoteFileSize(note.filePath);
      }
      
      return totalSize;
    } catch (e) {
      print('Error calculating total storage: $e');
      return 0;
    }
  }

  /// Export voice notes metadata as JSON string
  Future<String> exportMetadataAsJson({String? userId}) async {
    final notes = await getAllVoiceNotes(userId: userId);
    final stats = await getStatistics(userId: userId);
    
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalNotes': notes.length,
      'statistics': stats,
      'notes': notes.map((note) => {
        'id': note.id,
        'title': note.title,
        'description': note.description,
        'duration': note.duration,
        'formattedDuration': note.formattedDuration,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'filePath': note.filePath,
        'userId': note.userId,
      }).toList(),
    };
    
    return exportData.toString();
  }
}
