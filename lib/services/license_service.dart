import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/license_image.dart';

class LicenseService {
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  /// Add a new license image
  Future<LicenseOperationResult> addLicenseImage({
    required int carId,
    required String licenseType,
    required String imagePath,
  }) async {
    try {
      if (!isUserAuthenticated) {
        return LicenseOperationResult.error('User must be signed in to add license images');
      }

      final userId = _currentUserId!;
      final now = DateTime.now();

      final licenseImage = LicenseImage(
        carId: carId,
        licenseType: licenseType,
        imagePath: imagePath,
        createdAt: now,
        updatedAt: now,
        userId: userId,
      );

      final id = await _databaseHelper.insertLicenseImage(licenseImage);
      final savedImage = await _databaseHelper.getLicenseImageById(id, userId);

      return LicenseOperationResult.success(
        message: 'License image added successfully',
        licenseImage: savedImage,
      );
    } catch (e) {
      return LicenseOperationResult.error('Failed to add license image: ${e.toString()}');
    }
  }

  /// Update an existing license image
  Future<LicenseOperationResult> updateLicenseImage({
    required int id,
    required int carId,
    required String licenseType,
    required String imagePath,
  }) async {
    try {
      if (!isUserAuthenticated) {
        return LicenseOperationResult.error('User must be signed in to update license images');
      }

      final userId = _currentUserId!;
      
      // Check if license image exists for this user
      final existingImage = await _databaseHelper.getLicenseImageById(id, userId);
      if (existingImage == null) {
        return LicenseOperationResult.error('License image not found');
      }

      final updatedImage = existingImage.copyWith(
        carId: carId,
        licenseType: licenseType,
        imagePath: imagePath,
        updatedAt: DateTime.now(),
      );

      final rowsAffected = await _databaseHelper.updateLicenseImage(updatedImage);
      
      if (rowsAffected == 0) {
        return LicenseOperationResult.error('Failed to update license image');
      }

      final savedImage = await _databaseHelper.getLicenseImageById(id, userId);

      return LicenseOperationResult.success(
        message: 'License image updated successfully',
        licenseImage: savedImage,
      );
    } catch (e) {
      return LicenseOperationResult.error('Failed to update license image: ${e.toString()}');
    }
  }

  /// Delete a license image
  Future<LicenseOperationResult> deleteLicenseImage(int id) async {
    try {
      if (!isUserAuthenticated) {
        return LicenseOperationResult.error('User must be signed in to delete license images');
      }

      final userId = _currentUserId!;
      
      // Check if license image exists for this user
      final existingImage = await _databaseHelper.getLicenseImageById(id, userId);
      if (existingImage == null) {
        return LicenseOperationResult.error('License image not found');
      }

      // Delete the physical file
      try {
        final file = File(existingImage.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Warning: Could not delete image file: $e');
      }

      final rowsAffected = await _databaseHelper.deleteLicenseImage(id, userId);
      
      if (rowsAffected == 0) {
        return LicenseOperationResult.error('Failed to delete license image');
      }

      return LicenseOperationResult.success(
        message: 'License image deleted successfully',
      );
    } catch (e) {
      return LicenseOperationResult.error('Failed to delete license image: ${e.toString()}');
    }
  }

  /// Get all license images for a specific car
  Future<List<LicenseImage>> getLicenseImagesForCar(int carId) async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }
      return await _databaseHelper.getLicenseImagesForCar(carId, _currentUserId!);
    } catch (e) {
      print('Error getting license images for car: $e');
      return [];
    }
  }

  /// Get license image by type for a specific car
  Future<LicenseImage?> getLicenseImageByType(int carId, String licenseType) async {
    try {
      if (!isUserAuthenticated) {
        return null;
      }
      return await _databaseHelper.getLicenseImageByType(carId, licenseType, _currentUserId!);
    } catch (e) {
      print('Error getting license image by type: $e');
      return null;
    }
  }

  /// Get all license images for the current user
  Future<List<LicenseImage>> getAllLicenseImages() async {
    try {
      if (!isUserAuthenticated) {
        return [];
      }
      return await _databaseHelper.getAllLicenseImages(_currentUserId!);
    } catch (e) {
      print('Error getting all license images: $e');
      return [];
    }
  }

  /// Take photo from camera
  Future<LicenseOperationResult> takePhotoFromCamera() async {
    try {
      // Check camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        return LicenseOperationResult.error('Camera permission is required');
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo == null) {
        return LicenseOperationResult.error('No photo taken');
      }

      return LicenseOperationResult.success(
        message: 'Photo taken successfully',
        imagePath: photo.path,
      );
    } catch (e) {
      return LicenseOperationResult.error('Failed to take photo: ${e.toString()}');
    }
  }

  /// Pick image from gallery
  Future<LicenseOperationResult> pickImageFromGallery() async {
    try {
      // Check storage permission
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted) {
        return LicenseOperationResult.error('Storage permission is required');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        return LicenseOperationResult.error('No image selected');
      }

      return LicenseOperationResult.success(
        message: 'Image selected successfully',
        imagePath: image.path,
      );
    } catch (e) {
      return LicenseOperationResult.error('Failed to pick image: ${e.toString()}');
    }
  }

  /// Upload license images to Firebase Storage and update URLs
  Future<LicenseBackupResult> backupLicenseImagesToFirebase() async {
    try {
      if (!isUserAuthenticated) {
        return LicenseBackupResult.error('User must be signed in to backup license images');
      }

      final userId = _currentUserId!;
      final licenseImages = await getAllLicenseImages();
      
      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];

      for (final licenseImage in licenseImages) {
        try {
          // Upload image to Firebase Storage
          final file = File(licenseImage.imagePath);
          if (!await file.exists()) {
            failureCount++;
            errors.add('Image file not found: ${licenseImage.imagePath}');
            continue;
          }

          final storageRef = _storage.ref().child(
            'license_images/$userId/${licenseImage.carId}/${licenseImage.licenseType}_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );

          final uploadTask = await storageRef.putFile(file);
          final downloadUrl = await uploadTask.ref.getDownloadURL();

          // Update the license image with the Firebase URL
          final updatedImage = licenseImage.copyWith(
            imageUrl: downloadUrl,
            updatedAt: DateTime.now(),
          );

          await _databaseHelper.updateLicenseImage(updatedImage);

          // Save to Firestore
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('license_images')
              .doc(licenseImage.id.toString())
              .set(updatedImage.toFirestore());

          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Failed to backup license image ${licenseImage.id}: $e');
        }
      }

      return LicenseBackupResult.success(
        message: 'License images backup completed',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );
    } catch (e) {
      return LicenseBackupResult.error('Failed to backup license images: ${e.toString()}');
    }
  }

  /// Restore license images from Firebase
  Future<LicenseBackupResult> restoreLicenseImagesFromFirebase() async {
    try {
      if (!isUserAuthenticated) {
        return LicenseBackupResult.error('User must be signed in to restore license images');
      }

      final userId = _currentUserId!;
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('license_images')
          .get();

      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];

      for (final doc in querySnapshot.docs) {
        try {
          final licenseImage = LicenseImage.fromFirestore(doc.data(), doc.id);
          
          // Check if already exists locally
          final existing = await _databaseHelper.getLicenseImageById(
            licenseImage.id ?? 0, 
            userId
          );

          if (existing == null) {
            await _databaseHelper.insertLicenseImage(licenseImage);
          } else {
            await _databaseHelper.updateLicenseImage(licenseImage);
          }

          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Failed to restore license image ${doc.id}: $e');
        }
      }

      return LicenseBackupResult.success(
        message: 'License images restore completed',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );
    } catch (e) {
      return LicenseBackupResult.error('Failed to restore license images: ${e.toString()}');
    }
  }

  /// Get license backup status
  Future<LicenseBackupStatus> getLicenseBackupStatus() async {
    try {
      if (!isUserAuthenticated) {
        return LicenseBackupStatus(
          localCount: 0,
          cloudCount: 0,
          isAuthenticated: false,
        );
      }

      final userId = _currentUserId!;
      final localImages = await getAllLicenseImages();
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('license_images')
          .get();

      return LicenseBackupStatus(
        localCount: localImages.length,
        cloudCount: querySnapshot.docs.length,
        isAuthenticated: true,
        lastBackupTime: localImages.isNotEmpty 
            ? localImages.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );
    } catch (e) {
      return LicenseBackupStatus(
        localCount: 0,
        cloudCount: 0,
        isAuthenticated: isUserAuthenticated,
      );
    }
  }
}

/// Result class for license operations
class LicenseOperationResult {
  final bool isSuccess;
  final String message;
  final LicenseImage? licenseImage;
  final String? imagePath;

  LicenseOperationResult._({
    required this.isSuccess,
    required this.message,
    this.licenseImage,
    this.imagePath,
  });

  factory LicenseOperationResult.success({
    required String message,
    LicenseImage? licenseImage,
    String? imagePath,
  }) {
    return LicenseOperationResult._(
      isSuccess: true,
      message: message,
      licenseImage: licenseImage,
      imagePath: imagePath,
    );
  }

  factory LicenseOperationResult.error(String message) {
    return LicenseOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isFailure => !isSuccess;
}

/// Result class for license backup operations
class LicenseBackupResult {
  final bool isSuccess;
  final String message;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  LicenseBackupResult._({
    required this.isSuccess,
    required this.message,
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  factory LicenseBackupResult.success({
    required String message,
    required int successCount,
    required int failureCount,
    required List<String> errors,
  }) {
    return LicenseBackupResult._(
      isSuccess: true,
      message: message,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }

  factory LicenseBackupResult.error(String message) {
    return LicenseBackupResult._(
      isSuccess: false,
      message: message,
      successCount: 0,
      failureCount: 0,
      errors: [message],
    );
  }
}

/// Status class for license backup
class LicenseBackupStatus {
  final int localCount;
  final int cloudCount;
  final bool isAuthenticated;
  final DateTime? lastBackupTime;

  LicenseBackupStatus({
    required this.localCount,
    required this.cloudCount,
    required this.isAuthenticated,
    this.lastBackupTime,
  });
}
