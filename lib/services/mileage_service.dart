import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mileage_entry.dart';
import '../database/database_helper.dart';
import '../database/mileage_database_helper.dart';
import 'car_service.dart';

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

  /// Sync local entries to Firebase (prevents duplicates by checking local_id)
  Future<bool> syncToFirebase({String? userId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null && userId == null) {
        throw Exception('No authenticated user');
      }

      final uid = userId ?? user!.uid;
      final localEntries = await getAllEntries(userId: uid);
      
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('mileage_entries');

      // Get existing cloud entries to check for duplicates
      final existingDocs = await collection.get();
      final existingLocalIds = <int>{};
      for (final doc in existingDocs.docs) {
        final data = doc.data();
        if (data['local_id'] != null) {
          existingLocalIds.add(data['local_id'] as int);
        }
      }

      final batch = _firestore.batch();
      int addedCount = 0;

      // Add only new local entries to Firebase
      for (final entry in localEntries) {
        // Skip if entry already exists in cloud
        if (entry.id != null && existingLocalIds.contains(entry.id)) {
          continue;
        }
        
        final docRef = collection.doc();
        final entryData = entry.toFirestore();
        entryData['local_id'] = entry.id; // Add local_id for duplicate detection
        batch.set(docRef, entryData);
        addedCount++;
      }

      if (addedCount > 0) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      print('Error syncing to Firebase: $e');
      return false;
    }
  }

  /// Load entries from Firebase and save to local database (prevents duplicates)
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

      // Get existing local entries to check for duplicates
      final existingLocalEntries = await getAllEntries(userId: uid);
      final existingLocalIds = existingLocalEntries.map((e) => e.id).whereType<int>().toSet();
      
      // Also track by date + carId to avoid duplicates
      final existingEntryKeys = existingLocalEntries
          .map((e) => '${e.carId}_${e.date.millisecondsSinceEpoch}')
          .toSet();

      final db = await DatabaseHelper.instance.database;

      // Add Firebase entries to local database only if they don't exist
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final localId = data['local_id'] as int?;
        
        // Skip if entry already exists locally (by local_id)
        if (localId != null && existingLocalIds.contains(localId)) {
          continue;
        }
        
        final entry = MileageEntry.fromFirestore(doc).copyWith(userId: uid);
        
        // Also check by date + carId combination
        final entryKey = '${entry.carId}_${entry.date.millisecondsSinceEpoch}';
        if (existingEntryKeys.contains(entryKey)) {
          continue;
        }
        
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

  /// Calculate total mileage accumulated from entries for a specific car
  /// Takes into account trip frequency and time elapsed since entry creation
  Future<double> calculateAccumulatedMileage(String carId, {String? userId}) async {
    final entries = await getAllEntries(userId: userId);
    final carEntries = entries.where((e) => e.carId == carId).toList();
    
    if (carEntries.isEmpty) return 0;
    
    double totalMileage = 0;
    final now = DateTime.now();
    
    for (final entry in carEntries) {
      switch (entry.tripFrequency) {
        case TripFrequency.oneTime:
          // One-time trips are counted once
          totalMileage += entry.mileage;
          break;
          
        case TripFrequency.daily:
          // Calculate days since entry was created
          final daysSinceCreation = now.difference(entry.createdAt).inDays;
          totalMileage += entry.mileage * (daysSinceCreation + 1); // +1 to include creation day
          break;
          
        case TripFrequency.weekly:
          // Calculate weeks since entry was created
          final weeksSinceCreation = (now.difference(entry.createdAt).inDays / 7).floor();
          totalMileage += entry.mileage * (weeksSinceCreation + 1); // +1 to include creation week
          break;
          
        case TripFrequency.monthly:
          // Calculate months since entry was created (approximate)
          final monthsSinceCreation = ((now.year - entry.createdAt.year) * 12 + 
                                       (now.month - entry.createdAt.month));
          totalMileage += entry.mileage * (monthsSinceCreation + 1); // +1 to include creation month
          break;
      }
    }
    
    return totalMileage;
  }

  /// Add entry and automatically update car mileage based on trip frequency
  Future<MileageEntry> addEntryWithAutoMileageUpdate(
    MileageEntry entry, {
    bool syncToCloud = false,
  }) async {
    // Add entry to local database first
    final savedEntry = await addEntry(entry);

    // Update car mileage if carId is provided
    if (entry.carId != null && entry.carId!.isNotEmpty) {
      try {
        final carService = CarService();
        
        // For one-time trips, add the mileage immediately
        if (entry.tripFrequency == TripFrequency.oneTime) {
          await carService.updateCarMileage(
            int.parse(entry.carId!),
            entry.mileage,
          );
        }
        // For recurring trips, we'll update mileage based on accumulated trips
        // The mileage will be calculated and updated when viewing the car details
        
      } catch (e) {
        print('Error updating car mileage: $e');
        // Continue even if car mileage update fails
      }
    }

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

  /// Update car mileage based on all accumulated trips
  /// This should be called periodically or when viewing car details
  Future<bool> syncCarMileageFromEntries(String carId, int initialMileage, {String? userId}) async {
    try {
      final accumulatedMileage = await calculateAccumulatedMileage(carId, userId: userId);
      
      final carService = CarService();
      final result = await carService.updateCarMileage(
        int.parse(carId),
        accumulatedMileage,
      );
      
      return result.isSuccess;
    } catch (e) {
      print('Error syncing car mileage: $e');
      return false;
    }
  }

  /// Get entries for a specific car
  Future<List<MileageEntry>> getEntriesForCar(String carId, {String? userId}) async {
    final allEntries = await getAllEntries(userId: userId);
    return allEntries.where((entry) => entry.carId == carId).toList();
  }

  /// Get mileage breakdown by trip frequency for a car
  Future<Map<String, double>> getMileageBreakdownForCar(String carId, {String? userId}) async {
    final entries = await getEntriesForCar(carId, userId: userId);
    
    double oneTimeMileage = 0;
    double dailyMileage = 0;
    double weeklyMileage = 0;
    double monthlyMileage = 0;
    
    final now = DateTime.now();
    
    for (final entry in entries) {
      switch (entry.tripFrequency) {
        case TripFrequency.oneTime:
          oneTimeMileage += entry.mileage;
          break;
        case TripFrequency.daily:
          final days = now.difference(entry.createdAt).inDays + 1;
          dailyMileage += entry.mileage * days;
          break;
        case TripFrequency.weekly:
          final weeks = (now.difference(entry.createdAt).inDays / 7).floor() + 1;
          weeklyMileage += entry.mileage * weeks;
          break;
        case TripFrequency.monthly:
          final months = ((now.year - entry.createdAt.year) * 12 + 
                         (now.month - entry.createdAt.month)) + 1;
          monthlyMileage += entry.mileage * months;
          break;
      }
    }
    
    return {
      'oneTime': oneTimeMileage,
      'daily': dailyMileage,
      'weekly': weeklyMileage,
      'monthly': monthlyMileage,
      'total': oneTimeMileage + dailyMileage + weeklyMileage + monthlyMileage,
    };
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
