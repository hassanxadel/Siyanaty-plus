import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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

  void dispose() {
    _textRecognizer.close();
  }
}
