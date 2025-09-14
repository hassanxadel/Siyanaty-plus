import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/backup_car.dart';
import '../database/database_helper.dart';

/// Firebase service for backing up and syncing car data to the cloud
/// Handles Firestore operations only (images stored locally)
class FirebaseBackupService {
  static final FirebaseBackupService _instance = FirebaseBackupService._internal();
  factory FirebaseBackupService() => _instance;
  FirebaseBackupService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  static const String carsCollection = 'cars';
  static const String usersCollection = 'users';
  
  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;
  
  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;
  
  /// Get user's cars collection reference
  CollectionReference get _userCarsCollection {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection(usersCollection)
        .doc(_currentUserId!)
        .collection(carsCollection);
  }
  
  /// Backup all cars to Firebase
  Future<BackupResult> backupAllCarsToFirebase() async {
    try {
      if (!isUserAuthenticated) {
        return BackupResult.error('User not authenticated. Please sign in first.');
      }
      
      // Get all cars from local database for current user
      final cars = await _databaseHelper.getAllCars(_currentUserId!);
      
      if (cars.isEmpty) {
        return BackupResult.success(
          message: 'No cars to backup',
          carsProcessed: 0,
        );
      }
      
      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];
      
      // Use batch write for better performance
      WriteBatch batch = _firestore.batch();
      
      for (BackupCar car in cars) {
        try {
          // Prepare car data for Firestore (images stored locally only)
          final carData = car.toFirebaseMap();
          carData['local_id'] = car.id; // Keep reference to local ID
          carData['backup_timestamp'] = FieldValue.serverTimestamp();
          
          // Add to batch
          final docRef = _userCarsCollection.doc();
          batch.set(docRef, carData);
          
          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Failed to backup car ${car.brand} ${car.model}: $e');
        }
      }
      
      // Commit batch
      await batch.commit();
      
      // Update backup metadata
      await _updateBackupMetadata(successCount, failureCount);
      
      if (failureCount == 0) {
        return BackupResult.success(
          message: 'All cars backed up successfully',
          carsProcessed: successCount,
        );
      } else {
        return BackupResult.partialSuccess(
          message: '$successCount cars backed up, $failureCount failed',
          carsProcessed: successCount,
          errors: errors,
        );
      }
      
    } catch (e) {
      return BackupResult.error('Backup failed: ${e.toString()}');
    }
  }
  
  /// Backup a single car to Firebase
  Future<BackupResult> backupCarToFirebase(BackupCar car) async {
    try {
      if (!isUserAuthenticated) {
        return BackupResult.error('User not authenticated. Please sign in first.');
      }
      
      // Prepare car data for Firestore (images stored locally only)
      final carData = car.toFirebaseMap();
      carData['local_id'] = car.id;
      carData['backup_timestamp'] = FieldValue.serverTimestamp();
      
      // Save to Firestore
      await _userCarsCollection.add(carData);
      
      return BackupResult.success(
        message: 'BackupCar backed up successfully',
        carsProcessed: 1,
      );
      
    } catch (e) {
      return BackupResult.error('Failed to backup car: ${e.toString()}');
    }
  }
  
  
  /// Restore cars from Firebase to local database
  Future<RestoreResult> restoreCarsFromFirebase() async {
    try {
      if (!isUserAuthenticated) {
        return RestoreResult.error('User not authenticated. Please sign in first.');
      }
      
      // Get cars from Firestore
      final querySnapshot = await _userCarsCollection.get();
      
      if (querySnapshot.docs.isEmpty) {
        return RestoreResult.success(
          message: 'No cars found in cloud backup',
          carsProcessed: 0,
        );
      }
      
      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];
      
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Create car from Firebase data
          final car = BackupCar.fromFirebaseMap(data);
          
          // Check if car already exists locally (by VIN)
          final existingCar = await _databaseHelper.getCarByVin(car.vin, _currentUserId!);
          if (existingCar != null) {
            // Update existing car
            final updatedCar = existingCar.copyWith(
              brand: car.brand,
              model: car.model,
              year: car.year,
              mileage: car.mileage,
              color: car.color,
              fuelType: car.fuelType,
              engineCC: car.engineCC,
              turbo: car.turbo,
              licensePlate: car.licensePlate,
              imagePath: car.imagePath,
              updatedAt: DateTime.now(),
            );
            await _databaseHelper.updateCar(updatedCar);
          } else {
            // Insert new car
            await _databaseHelper.insertCar(car);
          }
          
          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Failed to restore car: $e');
        }
      }
      
      if (failureCount == 0) {
        return RestoreResult.success(
          message: 'All cars restored successfully',
          carsProcessed: successCount,
        );
      } else {
        return RestoreResult.partialSuccess(
          message: '$successCount cars restored, $failureCount failed',
          carsProcessed: successCount,
          errors: errors,
        );
      }
      
    } catch (e) {
      return RestoreResult.error('Restore failed: ${e.toString()}');
    }
  }
  
  /// Get backup status and metadata
  Future<BackupStatus> getBackupStatus() async {
    try {
      if (!isUserAuthenticated) {
      return BackupStatus(
        isAuthenticated: false,
        localCarsCount: 0,
        cloudCarsCount: 0,
        lastBackupTime: null,
      );
      }
      
      // Get local cars count for current user
      final localCount = await _databaseHelper.getCarsCount(_currentUserId!);
      
      // Get cloud cars count
      final querySnapshot = await _userCarsCollection.get();
      final cloudCount = querySnapshot.docs.length;
      
      // Get last backup time
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(_currentUserId!)
          .get();
      
      DateTime? lastBackupTime;
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['last_backup_time'] != null) {
          final timestamp = data['last_backup_time'] as Timestamp;
          lastBackupTime = timestamp.toDate();
        }
      }
      
      return BackupStatus(
        isAuthenticated: true,
        localCarsCount: localCount,
        cloudCarsCount: cloudCount,
        lastBackupTime: lastBackupTime,
      );
      
    } catch (e) {
      return BackupStatus(
        isAuthenticated: isUserAuthenticated,
        localCarsCount: 0,
        cloudCarsCount: 0,
        lastBackupTime: null,
        error: e.toString(),
      );
    }
  }
  
  /// Update backup metadata
  Future<void> _updateBackupMetadata(int successCount, int failureCount) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(_currentUserId!)
          .set({
        'last_backup_time': FieldValue.serverTimestamp(),
        'last_backup_success_count': successCount,
        'last_backup_failure_count': failureCount,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Warning: Failed to update backup metadata: $e');
    }
  }
  
  /// Clear all cars from Firebase (use with caution)
  Future<void> clearCloudBackup() async {
    if (!isUserAuthenticated) {
      throw Exception('User not authenticated');
    }
    
    final querySnapshot = await _userCarsCollection.get();
    WriteBatch batch = _firestore.batch();
    
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}

/// Result classes for backup operations
class BackupResult {
  final bool isSuccess;
  final bool isPartialSuccess;
  final String message;
  final int carsProcessed;
  final List<String>? errors;
  
  BackupResult._({
    required this.isSuccess,
    required this.isPartialSuccess,
    required this.message,
    required this.carsProcessed,
    this.errors,
  });
  
  factory BackupResult.success({
    required String message,
    required int carsProcessed,
  }) {
    return BackupResult._(
      isSuccess: true,
      isPartialSuccess: false,
      message: message,
      carsProcessed: carsProcessed,
    );
  }
  
  factory BackupResult.partialSuccess({
    required String message,
    required int carsProcessed,
    required List<String> errors,
  }) {
    return BackupResult._(
      isSuccess: false,
      isPartialSuccess: true,
      message: message,
      carsProcessed: carsProcessed,
      errors: errors,
    );
  }
  
  factory BackupResult.error(String message) {
    return BackupResult._(
      isSuccess: false,
      isPartialSuccess: false,
      message: message,
      carsProcessed: 0,
    );
  }
}

class RestoreResult {
  final bool isSuccess;
  final bool isPartialSuccess;
  final String message;
  final int carsProcessed;
  final List<String>? errors;
  
  RestoreResult._({
    required this.isSuccess,
    required this.isPartialSuccess,
    required this.message,
    required this.carsProcessed,
    this.errors,
  });
  
  factory RestoreResult.success({
    required String message,
    required int carsProcessed,
  }) {
    return RestoreResult._(
      isSuccess: true,
      isPartialSuccess: false,
      message: message,
      carsProcessed: carsProcessed,
    );
  }
  
  factory RestoreResult.partialSuccess({
    required String message,
    required int carsProcessed,
    required List<String> errors,
  }) {
    return RestoreResult._(
      isSuccess: false,
      isPartialSuccess: true,
      message: message,
      carsProcessed: carsProcessed,
      errors: errors,
    );
  }
  
  factory RestoreResult.error(String message) {
    return RestoreResult._(
      isSuccess: false,
      isPartialSuccess: false,
      message: message,
      carsProcessed: 0,
    );
  }
}


class BackupStatus {
  final bool isAuthenticated;
  final int localCarsCount;
  final int cloudCarsCount;
  final DateTime? lastBackupTime;
  final String? error;
  
  BackupStatus({
    required this.isAuthenticated,
    required this.localCarsCount,
    required this.cloudCarsCount,
    this.lastBackupTime,
    this.error,
  });
  
  bool get isInSync => localCarsCount == cloudCarsCount;
}
