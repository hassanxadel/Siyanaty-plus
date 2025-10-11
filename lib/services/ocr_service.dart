import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/scan_model.dart';
import '../database/database_helper.dart';
import '../database/ocr_database_helper.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

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
      throw Exception('Failed to capture image: $e');
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
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Save image to app directory and return the path
  Future<String> saveImageToAppDirectory(XFile imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String scanDir = path.join(appDir.path, 'scans');
      
      // Create scans directory if it doesn't exist
      final Directory scanDirectory = Directory(scanDir);
      if (!await scanDirectory.exists()) {
        await scanDirectory.create(recursive: true);
      }
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(imageFile.path);
      final String fileName = 'scan_$timestamp$extension';
      final String savedPath = path.join(scanDir, fileName);
      
      // Copy file to app directory
      final File sourceFile = File(imageFile.path);
      await sourceFile.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Save scan to local database
  Future<int> saveScanToDatabase(ScanModel scan) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.insertScan(db, scan);
    } catch (e) {
      throw Exception('Failed to save scan to database: $e');
    }
  }

  /// Get all scans from database
  Future<List<ScanModel>> getAllScans() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.getAllScans(db);
    } catch (e) {
      throw Exception('Failed to get scans: $e');
    }
  }

  /// Get scans for specific user
  Future<List<ScanModel>> getUserScans(String userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.getScansByUser(db, userId);
    } catch (e) {
      throw Exception('Failed to get user scans: $e');
    }
  }

  /// Update scan in database
  Future<int> updateScan(ScanModel scan) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.updateScan(db, scan);
    } catch (e) {
      throw Exception('Failed to update scan: $e');
    }
  }

  /// Delete scan from database
  Future<int> deleteScan(int scanId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.deleteScan(db, scanId);
    } catch (e) {
      throw Exception('Failed to delete scan: $e');
    }
  }

  /// Search scans by text content
  Future<List<ScanModel>> searchScans(String query) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.searchScans(db, query);
    } catch (e) {
      throw Exception('Failed to search scans: $e');
    }
  }

  /// Get scan count
  Future<int> getScanCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.getScanCount(db);
    } catch (e) {
      throw Exception('Failed to get scan count: $e');
    }
  }

  /// Get user scan count
  Future<int> getUserScanCount(String userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await OcrDatabaseHelper.getUserScanCount(db, userId);
    } catch (e) {
      throw Exception('Failed to get user scan count: $e');
    }
  }

  /// Compress image for cloud processing
  Future<Uint8List> compressImageForCloud(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // For now, return original bytes
      // In production, you might want to add actual compression here
      return imageBytes;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Clean up old scan images (optional maintenance)
  Future<void> cleanupOldImages({int daysOld = 30}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String scanDir = path.join(appDir.path, 'scans');
      final Directory scanDirectory = Directory(scanDir);
      
      if (await scanDirectory.exists()) {
        final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
        
        await for (final FileSystemEntity entity in scanDirectory.list()) {
          if (entity is File) {
            final FileStat stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      // Log error but don't throw - this is maintenance
      print('Failed to cleanup old images: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
