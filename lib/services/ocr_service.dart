import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scan_model.dart';
import '../database/ocr_database_helper.dart';
import '../database/database_helper.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  /// Capture image from camera
  Future<XFile?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to capture image from camera: $e');
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Save image to app directory and return the path
  Future<String> saveImageToAppDirectory(dynamic imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'ocr_image_$timestamp.jpg';
      final String targetPath = path.join(appDir.path, 'ocr_images', fileName);
      
      // Create directory if it doesn't exist
      final Directory ocrDir = Directory(path.dirname(targetPath));
      if (!await ocrDir.exists()) {
        await ocrDir.create(recursive: true);
      }
      
      File sourceFile;
      if (imageFile is XFile) {
        sourceFile = File(imageFile.path);
      } else if (imageFile is File) {
        sourceFile = imageFile;
      } else {
        throw Exception('Unsupported image file type');
      }
      
      // Copy file to app directory
      await sourceFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      throw Exception('Failed to save image to app directory: $e');
    }
  }

  /// Process image with ML Kit text recognition
  Future<String> recognizeTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        throw Exception('No text found in the image');
      }
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  /// Process image from XFile (camera capture)
  Future<String> recognizeTextFromXFile(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        throw Exception('No text found in the image');
      }
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  /// Save scan to local database
  Future<ScanModel> saveScanLocal(ScanModel scan) async {
    final db = await DatabaseHelper.instance.database;
    final id = await OcrDatabaseHelper.insertScan(db, scan);
    return scan.copyWith(id: id);
  }

  Future<List<ScanModel>> getAllScans(String? userId) async {
    final db = await DatabaseHelper.instance.database;
    if (userId != null) {
      return OcrDatabaseHelper.getScansByUser(db, userId);
    } else {
      return OcrDatabaseHelper.getAllScans(db);
    }
  }

  Future<ScanModel?> getScanById(int id, String? userId) async {
    final db = await DatabaseHelper.instance.database;
    return OcrDatabaseHelper.getScanById(db, id);
  }

  Future<int> updateScan(ScanModel scan, String? userId) async {
    final db = await DatabaseHelper.instance.database;
    return OcrDatabaseHelper.updateScan(db, scan);
  }

  Future<int> deleteScan(int id, String? userId) async {
    final db = await DatabaseHelper.instance.database;
    return OcrDatabaseHelper.deleteScan(db, id);
  }

  /// Clean up old OCR images from the app's directory
  Future<void> cleanupOldOcrImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory ocrDir = Directory(path.join(appDir.path, 'ocr_images'));
      
      if (await ocrDir.exists()) {
        final List<FileSystemEntity> files = ocrDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Log error but don't throw - this is maintenance
      print('Failed to cleanup old images: $e');
    }
  }

  /// Backup all OCR scans to Firebase (prevents duplicates by checking local_id)
  Future<OcrBackupResult> backupScansToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return OcrBackupResult(
          isSuccess: false,
          message: 'User not authenticated',
          successCount: 0,
        );
      }

      // Get all local scans
      final localScans = await getAllScans(user.uid);
      
      if (localScans.isEmpty) {
        return OcrBackupResult(
          isSuccess: true,
          message: 'No scans to backup',
          successCount: 0,
        );
      }

      // Get existing cloud scans to check for duplicates
      final existingCloudScans = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .get();
      
      final existingLocalIds = <int>{};
      for (final doc in existingCloudScans.docs) {
        final data = doc.data();
        if (data['local_id'] != null) {
          existingLocalIds.add(data['local_id'] as int);
        }
      }

      int successCount = 0;
      int skippedCount = 0;
      final List<String> errors = [];

      // Backup each scan to Firestore
      for (final scan in localScans) {
        try {
          // Skip if scan already exists in cloud
          if (scan.id != null && existingLocalIds.contains(scan.id)) {
            skippedCount++;
            continue;
          }
          
          final scanData = scan.toFirestore();
          scanData['local_id'] = scan.id; // Add local_id for duplicate detection
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .add(scanData);
          successCount++;
        } catch (e) {
          errors.add('Failed to backup scan ${scan.id}: $e');
        }
      }

      final message = skippedCount > 0
          ? 'Backed up $successCount scans, $skippedCount already in cloud'
          : successCount == localScans.length
              ? 'All scans backed up successfully'
              : 'Backed up $successCount of ${localScans.length} scans';

      return OcrBackupResult(
        isSuccess: successCount > 0 || skippedCount > 0,
        message: message,
        successCount: successCount,
        errors: errors.isEmpty ? null : errors,
      );
    } catch (e) {
      return OcrBackupResult(
        isSuccess: false,
        message: 'Backup failed: $e',
        successCount: 0,
      );
    }
  }

  /// Restore OCR scans from Firebase (prevents duplicates and restores text only)
  Future<OcrBackupResult> restoreScansFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return OcrBackupResult(
          isSuccess: false,
          message: 'User not authenticated',
          successCount: 0,
        );
      }

      // Get all cloud scans
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return OcrBackupResult(
          isSuccess: true,
          message: 'No scans to restore',
          successCount: 0,
        );
      }

      // Get existing local scans to check for duplicates
      final existingLocalScans = await getAllScans(user.uid);
      final existingLocalIds = existingLocalScans.map((s) => s.id).whereType<int>().toSet();
      
      // Also track by text content to avoid duplicates
      final existingTexts = existingLocalScans.map((s) => s.text).toSet();

      int successCount = 0;
      int skippedCount = 0;
      final List<String> errors = [];

      // Restore each scan to local database
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final localId = data['local_id'] as int?;
          
          // Skip if already exists locally (by local_id or by text content)
          if (localId != null && existingLocalIds.contains(localId)) {
            skippedCount++;
            continue;
          }
          
          final text = data['text'] as String? ?? '';
          if (text.isNotEmpty && existingTexts.contains(text)) {
            skippedCount++;
            continue;
          }
          
          // Create scan from Firestore data
          // IMPORTANT: Clear imagePath since the image file doesn't exist locally
          // We only restore the extracted text, not the image
          final scan = ScanModel(
            id: null, // Let local DB assign new ID
            text: text,
            imagePath: null, // Don't try to use cloud image path - it won't exist locally
            source: data['source'] as String? ?? 'cloud_restore',
            timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
            userId: user.uid,
          );
          
          await saveScanLocal(scan);
          successCount++;
        } catch (e) {
          errors.add('Failed to restore scan ${doc.id}: $e');
        }
      }

      final message = skippedCount > 0
          ? 'Restored $successCount scans, $skippedCount already exist locally'
          : successCount == querySnapshot.docs.length
              ? 'All scans restored successfully'
              : 'Restored $successCount of ${querySnapshot.docs.length} scans';

      return OcrBackupResult(
        isSuccess: successCount > 0 || skippedCount > 0,
        message: message,
        successCount: successCount,
        errors: errors.isEmpty ? null : errors,
      );
    } catch (e) {
      return OcrBackupResult(
        isSuccess: false,
        message: 'Restore failed: $e',
        successCount: 0,
      );
    }
  }

  /// Get OCR backup status
  Future<OcrBackupStatus> getOcrBackupStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        return OcrBackupStatus(
          isAuthenticated: false,
          localScansCount: 0,
          cloudScansCount: 0,
        );
      }

      // Get local scans count
      final localScans = await getAllScans(user.uid);
      
      // Get cloud scans count
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .get();

      return OcrBackupStatus(
        isAuthenticated: true,
        localScansCount: localScans.length,
        cloudScansCount: querySnapshot.docs.length,
      );
    } catch (e) {
      return OcrBackupStatus(
        isAuthenticated: false,
        localScansCount: 0,
        cloudScansCount: 0,
        error: e.toString(),
      );
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Result class for OCR backup/restore operations
class OcrBackupResult {
  final bool isSuccess;
  final String message;
  final int successCount;
  final List<String>? errors;

  OcrBackupResult({
    required this.isSuccess,
    required this.message,
    required this.successCount,
    this.errors,
  });
}

/// Status class for OCR backup
class OcrBackupStatus {
  final bool isAuthenticated;
  final int localScansCount;
  final int cloudScansCount;
  final String? error;

  OcrBackupStatus({
    required this.isAuthenticated,
    required this.localScansCount,
    required this.cloudScansCount,
    this.error,
  });
}
