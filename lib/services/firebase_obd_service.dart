import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/obd_scan.dart';
import '../database/database_helper.dart';

/// Service for backing up and restoring OBD scan data to/from Firebase
class FirebaseOBDService {
  static final FirebaseOBDService _instance = FirebaseOBDService._internal();
  factory FirebaseOBDService() => _instance;
  FirebaseOBDService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Backup all OBD scans to Firebase
  Future<bool> backupAllScansToFirebase() async {
    try {
      if (_userId == null) {
        print('[Firebase OBD] No user logged in');
        return false;
      }

      print('[Firebase OBD] Starting backup...');

      // Get all local scans
      final localScans = await _dbHelper.getAllOBDScans();
      
      if (localScans.isEmpty) {
        print('[Firebase OBD] No scans to backup');
        return true;
      }

      // Get existing cloud scans to avoid duplicates
      final cloudScansSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('obd_scans')
          .get();

      final existingLocalIds = cloudScansSnapshot.docs
          .map((doc) => doc.data()['local_id'] as int?)
          .where((id) => id != null)
          .toSet();

      int uploadedCount = 0;
      int skippedCount = 0;

      // Upload each scan
      for (var scanMap in localScans) {
        final scan = OBDScan.fromMap(scanMap);
        
        // Skip if already exists in cloud
        if (scan.id != null && existingLocalIds.contains(scan.id)) {
          print('[Firebase OBD] Skipping duplicate scan ID: ${scan.id}');
          skippedCount++;
          continue;
        }

        try {
          // Use local ID as document ID to prevent duplicates
          final docId = scan.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('obd_scans')
              .doc(docId)
              .set(scan.toFirestore());
          
          uploadedCount++;
        } catch (e) {
          print('[Firebase OBD] Error uploading scan ${scan.id}: $e');
        }
      }

      print('[Firebase OBD] Backup complete: $uploadedCount uploaded, $skippedCount skipped');
      return true;
    } catch (e) {
      print('[Firebase OBD] Backup error: $e');
      return false;
    }
  }

  /// Restore OBD scans from Firebase
  Future<bool> restoreScansFromFirebase() async {
    try {
      if (_userId == null) {
        print('[Firebase OBD] No user logged in');
        return false;
      }

      print('[Firebase OBD] Starting restore...');

      // Get all cloud scans
      final cloudScansSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('obd_scans')
          .get();

      if (cloudScansSnapshot.docs.isEmpty) {
        print('[Firebase OBD] No scans to restore');
        return true;
      }

      // Get existing local scans to avoid duplicates
      final localScans = await _dbHelper.getAllOBDScans();
      final existingLocalIds = localScans
          .map((scan) => scan['id'] as int?)
          .where((id) => id != null)
          .toSet();

      int restoredCount = 0;
      int skippedCount = 0;

      // Restore each scan
      for (var doc in cloudScansSnapshot.docs) {
        try {
          final scan = OBDScan.fromFirestore(doc.data(), doc.id);
          
          // Check if scan already exists locally
          if (scan.id != null && existingLocalIds.contains(scan.id)) {
            print('[Firebase OBD] Skipping existing scan ID: ${scan.id}');
            skippedCount++;
            continue;
          }

          // Also check by car_id and scan_date to avoid duplicates
          final duplicateCheck = await _dbHelper.database.then((db) => 
            db.query(
              DatabaseHelper.tableOBDScans,
              where: 'car_id = ? AND scan_date = ?',
              whereArgs: [scan.carId, scan.scanDate.millisecondsSinceEpoch],
            )
          );

          if (duplicateCheck.isNotEmpty) {
            print('[Firebase OBD] Skipping duplicate scan by date for car ${scan.carId}');
            skippedCount++;
            continue;
          }

          // Insert scan (without ID to let database auto-generate)
          final scanMap = scan.toMap();
          scanMap.remove('id'); // Remove ID to let database auto-generate
          
          await _dbHelper.insertOBDScan(scanMap);
          restoredCount++;
        } catch (e) {
          print('[Firebase OBD] Error restoring scan ${doc.id}: $e');
        }
      }

      print('[Firebase OBD] Restore complete: $restoredCount restored, $skippedCount skipped');
      return true;
    } catch (e) {
      print('[Firebase OBD] Restore error: $e');
      return false;
    }
  }

  /// Backup a single scan to Firebase
  Future<bool> backupScan(OBDScan scan) async {
    try {
      if (_userId == null) {
        print('[Firebase OBD] No user logged in');
        return false;
      }

      // Use local ID as document ID
      final docId = scan.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('obd_scans')
          .doc(docId)
          .set(scan.toFirestore());

      print('[Firebase OBD] Scan backed up successfully');
      return true;
    } catch (e) {
      print('[Firebase OBD] Error backing up scan: $e');
      return false;
    }
  }

  /// Delete a scan from Firebase
  Future<bool> deleteScanFromFirebase(int scanId) async {
    try {
      if (_userId == null) {
        print('[Firebase OBD] No user logged in');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('obd_scans')
          .doc(scanId.toString())
          .delete();

      print('[Firebase OBD] Scan deleted from Firebase');
      return true;
    } catch (e) {
      print('[Firebase OBD] Error deleting scan: $e');
      return false;
    }
  }

  /// Delete all scans from Firebase
  Future<bool> deleteAllScansFromFirebase() async {
    try {
      if (_userId == null) {
        print('[Firebase OBD] No user logged in');
        return false;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('obd_scans')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('[Firebase OBD] All scans deleted from Firebase');
      return true;
    } catch (e) {
      print('[Firebase OBD] Error deleting all scans: $e');
      return false;
    }
  }

  /// Get scans count from Firebase
  Future<int> getFirebaseScansCount() async {
    try {
      if (_userId == null) {
        return 0;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('obd_scans')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('[Firebase OBD] Error getting scans count: $e');
      return 0;
    }
  }
}

