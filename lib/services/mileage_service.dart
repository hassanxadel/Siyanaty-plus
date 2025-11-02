import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mileage_entry.dart';
import '../database/database_helper.dart';
import '../database/mileage_database_helper.dart';

class MileageService {
  static final MileageService _instance = MileageService._internal();
  factory MileageService() => _instance;
  MileageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local database operations
  
  /// Add a new mileage entry to local database
  Future<MileageEntry> addEntry(MileageEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    final id = await MileageDatabaseHelper.insertEntry(db, entry);
    return entry.copyWith(id: id);
  }

  /// Get all mileage entries from local database
  Future<List<MileageEntry>> getAllEntries({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    return await MileageDatabaseHelper.getEntries(db, userId: userId);
  }

  /// Get a specific entry by ID
  Future<MileageEntry?> getEntryById(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await MileageDatabaseHelper.getEntryById(db, id);
  }

  /// Update an existing mileage entry
  Future<bool> updateEntry(MileageEntry entry) async {
    if (entry.id == null) return false;
    
    final db = await DatabaseHelper.instance.database;
    final result = await MileageDatabaseHelper.updateEntry(db, entry);
    return result > 0;
  }

  /// Delete a mileage entry
  Future<bool> deleteEntry(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await MileageDatabaseHelper.deleteEntry(db, id);
    return result > 0;
  }

  /// Get entries within a date range
  Future<List<MileageEntry>> getEntriesInRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await MileageDatabaseHelper.getEntriesInRange(
      db,
      startDate,
      endDate,
      userId: userId,
    );
  }

  /// Get statistics for mileage tracking
  Future<Map<String, double>> getStatistics({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    return await MileageDatabaseHelper.getStatistics(db, userId: userId);
  }

  /// Calculate fuel efficiency between entries
  Future<Map<String, double>> calculateEfficiencyStats({String? userId}) async {
    final entries = await getAllEntries(userId: userId);
    
    if (entries.length < 2) {
      return {
        'averageEfficiency': 0,
        'bestEfficiency': 0,
        'worstEfficiency': 0,
        'totalDistance': 0,
      };
    }

    // Sort entries by mileage (ascending) to calculate distances properly
    entries.sort((a, b) => a.mileage.compareTo(b.mileage));
    
    List<double> efficiencies = [];
    double totalDistance = 0;
    
    for (int i = 1; i < entries.length; i++) {
      final current = entries[i];
      final previous = entries[i - 1];
      final distance = current.mileage - previous.mileage;
      
      if (distance > 0 && current.fuel > 0) {
        final efficiency = (current.fuel / distance) * 100; // L/100km
        efficiencies.add(efficiency);
        totalDistance += distance;
      }
    }

    if (efficiencies.isEmpty) {
      return {
        'averageEfficiency': 0,
        'bestEfficiency': 0,
        'worstEfficiency': 0,
        'totalDistance': totalDistance,
      };
    }

    final averageEfficiency = efficiencies.reduce((a, b) => a + b) / efficiencies.length;
    final bestEfficiency = efficiencies.reduce((a, b) => a < b ? a : b); // Lower is better
    final worstEfficiency = efficiencies.reduce((a, b) => a > b ? a : b);

    return {
      'averageEfficiency': averageEfficiency,
      'bestEfficiency': bestEfficiency,
      'worstEfficiency': worstEfficiency,
      'totalDistance': totalDistance,
    };
  }

  // Firebase/Cloud operations

  /// Sync local entries to Firebase
  Future<bool> syncToFirebase({String? userId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null && userId == null) {
        throw Exception('No authenticated user');
      }

      final uid = userId ?? user!.uid;
      final localEntries = await getAllEntries(userId: uid);
      
      final batch = _firestore.batch();
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('mileage_entries');

      // Clear existing Firebase entries first
      final existingDocs = await collection.get();
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add all local entries to Firebase
      for (final entry in localEntries) {
        final docRef = collection.doc();
        batch.set(docRef, entry.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error syncing to Firebase: $e');
      return false;
    }
  }

  /// Load entries from Firebase and save to local database
  Future<bool> syncFromFirebase({String? userId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null && userId == null) {
        throw Exception('No authenticated user');
      }

      final uid = userId ?? user!.uid;
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('mileage_entries');

      final snapshot = await collection.orderBy('date', descending: true).get();
      
      if (snapshot.docs.isEmpty) return true;

      // Clear local entries for this user first
      final db = await DatabaseHelper.instance.database;
      await MileageDatabaseHelper.deleteAllEntries(db, userId: uid);

      // Add Firebase entries to local database
      for (final doc in snapshot.docs) {
        final entry = MileageEntry.fromFirestore(doc).copyWith(userId: uid);
        await MileageDatabaseHelper.insertEntry(db, entry);
      }

      return true;
    } catch (e) {
      print('Error syncing from Firebase: $e');
      return false;
    }
  }

  /// Get entries from Firebase without saving to local database
  Future<List<MileageEntry>> getEntriesFromFirebase({String? userId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null && userId == null) {
        return [];
      }

      final uid = userId ?? user!.uid;
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('mileage_entries');

      final snapshot = await collection.orderBy('date', descending: true).get();
      
      return snapshot.docs
          .map((doc) => MileageEntry.fromFirestore(doc).copyWith(userId: uid))
          .toList();
    } catch (e) {
      print('Error getting entries from Firebase: $e');
      return [];
    }
  }

  /// Add entry and optionally sync to Firebase
  Future<MileageEntry> addEntryWithSync(
    MileageEntry entry, {
    bool syncToCloud = false,
  }) async {
    // Add to local database first
    final savedEntry = await addEntry(entry);

    // Optionally sync to Firebase
    if (syncToCloud) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('mileage_entries')
              .add(savedEntry.copyWith(userId: user.uid).toFirestore());
        }
      } catch (e) {
        print('Error syncing entry to Firebase: $e');
        // Continue even if Firebase sync fails
      }
    }

    return savedEntry;
  }

  /// Update entry and optionally sync to Firebase
  Future<bool> updateEntryWithSync(
    MileageEntry entry, {
    bool syncToCloud = false,
  }) async {
    // Update local database first
    final success = await updateEntry(entry);
    
    if (success && syncToCloud) {
      // For simplicity, re-sync all entries to Firebase
      await syncToFirebase(userId: entry.userId);
    }

    return success;
  }

  /// Delete entry and optionally sync to Firebase
  Future<bool> deleteEntryWithSync(
    int id, {
    bool syncToCloud = false,
    String? userId,
  }) async {
    // Delete from local database first
    final success = await deleteEntry(id);
    
    if (success && syncToCloud) {
      // For simplicity, re-sync all entries to Firebase
      await syncToFirebase(userId: userId);
    }

    return success;
  }

  /// Clear all local data
  Future<void> clearLocalData({String? userId}) async {
    final db = await DatabaseHelper.instance.database;
    await MileageDatabaseHelper.deleteAllEntries(db, userId: userId);
  }

  /// Export entries as CSV string
  Future<String> exportToCsv({String? userId}) async {
    final entries = await getAllEntries(userId: userId);
    
    if (entries.isEmpty) return '';

    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Mileage,Fuel (L),Cost,Notes');
    
    // Data rows
    for (final entry in entries) {
      buffer.writeln([
        entry.date.toIso8601String().split('T')[0], // Date only
        entry.mileage.toString(),
        entry.fuel.toString(),
        entry.cost.toString(),
        entry.notes?.replaceAll(',', ';') ?? '', // Replace commas to avoid CSV issues
      ].join(','));
    }
    
    return buffer.toString();
  }
}
