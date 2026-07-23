import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/profile_image_service.dart';
import '../../shared/constants/app_theme.dart';

/// The user's profile picture, rendered with the app's glowing rim treatment.
///
/// Falls back to the initials of [name] when no picture has been set, so the
/// avatar never renders as an empty hole. Listens to
/// [ProfileImageService.pathListenable], which is what keeps the home screen
/// greeting card in sync when the picture is changed on the profile screen.
class ProfileAvatar extends StatelessWidget {
  /// Diameter of the avatar in logical pixels.
  final double size;

  /// Used for the initials fallback.
  final String name;

  final VoidCallback? onTap;

  /// Shows a small camera badge in the bottom-right corner.
  final bool showEditBadge;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.onTap,
    this.showEditBadge = false,
  });

  /// First letters of the first two words, e.g. "Hassan Adel" -> "HA".
  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileImageService.instance.pathListenable,
      builder: (context, imagePath, _) {
        final avatar = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
            ),
            border: Border.all(
              color: AppTheme.secondaryGreen.withOpacity(0.7),
              width: size > 80 ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: size > 80 ? 20 : 12,
                offset: Offset(0, size > 80 ? 8 : 5),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppTheme.secondaryGreen.withOpacity(0.4),
                blurRadius: size > 80 ? 26 : 16,
              ),
            ],
          ),
          child: ClipOval(
            child: _buildContent(imagePath),
          ),
        );

        final withBadge = showEditBadge
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  avatar,
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(size > 80 ? 7 : 5),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundGreen,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryGreen.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: size > 80 ? 16 : 11,
                        color: AppTheme.backgroundGreen,
                      ),
                    ),
                  ),
                ],
              )
            : avatar;

        if (onTap == null) return withBadge;

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: withBadge,
          ),
        );
      },
    );
  }

  Widget _buildContent(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A path can outlive its file (cleared app data); fall back rather
        // than showing Flutter's grey error box.
        errorBuilder: (context, error, stackTrace) => _buildInitials(),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
          fontSize: size * 0.36,
          color: AppTheme.lightBackground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
