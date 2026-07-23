import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/utils/app_logger.dart';

/// Result of a profile-image operation.
///
/// Follows the project convention of returning result objects instead of
/// throwing: screens branch on [isSuccess] rather than wrapping calls in
/// try/catch.
class ProfileImageResult {
  final bool isSuccess;
  final String message;
  final String? imagePath;

  const ProfileImageResult._({
    required this.isSuccess,
    required this.message,
    this.imagePath,
  });

  factory ProfileImageResult.success(String message, {String? imagePath}) =>
      ProfileImageResult._(
        isSuccess: true,
        message: message,
        imagePath: imagePath,
      );

  factory ProfileImageResult.error(String message) =>
      ProfileImageResult._(isSuccess: false, message: message);
}

/// Stores and retrieves the signed-in user's profile picture.
///
/// The image is copied into the app's private documents directory and only its
/// path is persisted (in `SharedPreferences`, keyed by Firebase UID so two
/// accounts on one device never see each other's picture). Nothing is uploaded,
/// which keeps the feature working offline like the rest of the app.
///
/// [pathListenable] lets any widget rebuild the instant the picture changes —
/// that is how the home screen greeting card stays in sync with the profile
/// screen without either one knowing about the other.
class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  static ProfileImageService get instance => _instance;

  static const String _keyPrefix = 'profile_image_path_';
  static const int _maxDimension = 600;
  static const int _imageQuality = 85;

  final ImagePicker _picker = ImagePicker();

  final ValueNotifier<String?> _currentPath = ValueNotifier<String?>(null);

  /// Current profile image path, or `null` when none is set.
  /// Widgets can listen to this to refresh automatically.
  ValueListenable<String?> get pathListenable => _currentPath;

  String? get currentPath => _currentPath.value;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  String get _storageKey => '$_keyPrefix${_userId ?? 'guest'}';

  /// Load the stored path for the current user into [pathListenable].
  ///
  /// Safe to call on every screen build/init — a missing or deleted file
  /// resolves to `null` so a stale path never renders a broken image.
  Future<String?> loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_storageKey);

      if (path == null || path.isEmpty) {
        _currentPath.value = null;
        return null;
      }

      // The file can disappear (app data cleared, restored backup), so verify
      // before handing the path to an Image widget.
      if (!await File(path).exists()) {
        await prefs.remove(_storageKey);
        _currentPath.value = null;
        return null;
      }

      _currentPath.value = path;
      return path;
    } catch (e) {
      AppLogger.error('Failed to load profile image', error: e);
      _currentPath.value = null;
      return null;
    }
  }

  /// Pick an image from [source], copy it into app storage and persist it.
  Future<ProfileImageResult> pickAndSaveImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension.toDouble(),
        maxHeight: _maxDimension.toDouble(),
        imageQuality: _imageQuality,
      );

      if (picked == null) {
        return ProfileImageResult.error('No image selected');
      }

      return await _persist(picked);
    } catch (e) {
      AppLogger.error('Failed to pick profile image', error: e);
      return ProfileImageResult.error('Could not open the image picker');
    }
  }

  /// Copy the picked file into the documents directory under a per-user name.
  Future<ProfileImageResult> _persist(XFile picked) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path);

      // A timestamp in the filename avoids Flutter's image cache serving the
      // previous picture when a user replaces their photo.
      final fileName =
          'profile_${_userId ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final destination = File(p.join(directory.path, fileName));

      await destination.writeAsBytes(await picked.readAsBytes());

      final previousPath = _currentPath.value;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, destination.path);
      _currentPath.value = destination.path;

      await _deleteFileQuietly(previousPath);

      AppLogger.info('Profile image saved');
      return ProfileImageResult.success(
        'Profile picture updated',
        imagePath: destination.path,
      );
    } catch (e) {
      AppLogger.error('Failed to save profile image', error: e);
      return ProfileImageResult.error('Could not save the image');
    }
  }

  /// Remove the stored picture for the current user.
  Future<ProfileImageResult> removeProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_storageKey);

      await prefs.remove(_storageKey);
      _currentPath.value = null;
      await _deleteFileQuietly(path);

      AppLogger.info('Profile image removed');
      return ProfileImageResult.success('Profile picture removed');
    } catch (e) {
      AppLogger.error('Failed to remove profile image', error: e);
      return ProfileImageResult.error('Could not remove the image');
    }
  }

  /// Deleting the old file is best-effort — losing it is harmless, and a
  /// failure here must never fail the surrounding save/remove operation.
  Future<void> _deleteFileQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.warning('Could not delete old profile image', error: e);
    }
  }
}
