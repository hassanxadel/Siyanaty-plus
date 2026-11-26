import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/license_service.dart';
import '../../../services/car_service.dart';
import '../../../models/license_image.dart';
import '../../../models/backup_car.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/gradient_button.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final LicenseService _licenseService = LicenseService();
  final CarService _carService = CarService();
  
  List<BackupCar> _cars = [];
  BackupCar? _selectedCar;
  LicenseImage? _personalLicense;
  LicenseImage? _vehicleLicense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cars = await _carService.getAllCars();
      setState(() {
        _cars = cars;
        if (_cars.isNotEmpty && _selectedCar == null) {
          _selectedCar = _cars.first;
        }
      });
      
      if (_selectedCar != null) {
        await _loadLicenseImages();
      }
    } catch (e) {
      _showMessage('Failed to load data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLicenseImages() async {
    if (_selectedCar == null) return;
    
    try {
      final personalLicense = await _licenseService.getLicenseImageByType(
        _selectedCar!.id!, 
        'personal'
      );
      final vehicleLicense = await _licenseService.getLicenseImageByType(
        _selectedCar!.id!, 
        'vehicle'
      );
      
      setState(() {
        _personalLicense = personalLicense;
        _vehicleLicense = vehicleLicense;
      });
    } catch (e) {
      _showMessage('Failed to load license images: $e');
    }
  }

  void _showMessage(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: Center(
          child: CupertinoActivityIndicator(color: Colors.white),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderWithBackground(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Car Selection Section
                  if (_cars.isNotEmpty) _buildCarSelectionCard(),
                  if (_cars.isNotEmpty) const SizedBox(height: 16),
                  
                  // Show content only if a car is selected
                  if (_selectedCar != null) ...[
                    // Personal License Section
                    _buildLicenseSection(
                      context,
                      'Personal License',
                      'Your driver\'s license or ID card',
                      Icons.person,
                      _personalLicense?.imagePath,
                      'personal',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vehicle License Section
                    _buildLicenseSection(
                      context,
                      'Vehicle License',
                      'Your vehicle registration or title',
                      Icons.directions_car,
                      _vehicleLicense?.imagePath,
                      'vehicle',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Info Card
                    _buildInfoCard(),
                  ] else if (_cars.isEmpty) ...[
                    // No cars message
                    _buildNoCarsMessage(),
                  ],
                  
                  const SizedBox(height: 100), // Bottom spacing for navigation
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarSelectionCard() {
    return Container(
      decoration: AppTheme.carCardDecoration(radius: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showCarSelectionDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedCar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _selectedCar!.imagePath != null
                              ? Image.file(
                                  File(_selectedCar!.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 24,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        )
                      : const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCar != null
                            ? '${_selectedCar!.brand} ${_selectedCar!.model}'
                            : 'Select Car',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCar != null
                            ? 'Year: ${_selectedCar!.year}'
                            : 'Tap to choose vehicle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCarSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Car list
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    final isSelected = _selectedCar?.id == car.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCar = car;
                        });
                        Navigator.pop(context);
                        _loadLicenseImages();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.darkAccentGreen,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.darkAccentGreen.withOpacity(0.5),
                                    AppTheme.backgroundGreen.withOpacity(0.5),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: car.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(car.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.directions_car,
                                            color: Colors.white,
                                            size: isSelected ? 28 : 24,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: isSelected ? 28 : 24,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.brand} ${car.model}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: isSelected ? 18 : 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Year: ${car.year}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (car.licensePlate.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'License: ${car.licensePlate}',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.carCardDecoration(radius: 14),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your license images are stored securely on your device and can be backed up to Firebase.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCarsMessage() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.carCardDecoration(radius: 16),
      child: const Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Colors.white70,
          ),
          SizedBox(height: 16),
          Text(
            'No Vehicles Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please add a vehicle first to manage license images.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Header with gradient background design matching the app
  // Standard app page header — kept per the app-wide header rule. minHeight
  // (not a fixed height) so large text grows instead of overflowing.
  Widget _buildHeaderWithBackground() {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    tooltip: 'Back',
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
                  ),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'License',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightBackground,
                          fontFamily: 'Orbitron',
                          shadows: [
                            Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Store and manage your license photos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String? imagePath,
    String licenseType,
  ) {
    final hasImage = imagePath != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.carCardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.lightBackground, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightBackground, // yellow label
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ID-card ratio (~1.586:1), sized from the card width — never a fixed
          // height, so it can't overflow on a small screen.
          AspectRatio(
            aspectRatio: 1.586,
            child: GestureDetector(
              onTap: hasImage
                  ? () => _viewImage(context, imagePath, title)
                  : () => _requestPermissionsAndShowOptions(context,
                      licenseType: licenseType),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.18), width: 1),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: hasImage
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _previewFallback(
                                CupertinoIcons.photo, 'Image not found'),
                      )
                    : _previewFallback(
                        CupertinoIcons.add, 'Tap to add a photo'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: hasImage ? 'Update photo' : 'Add photo',
                  icon: CupertinoIcons.camera,
                  onPressed: () => _requestPermissionsAndShowOptions(context,
                      licenseType: licenseType),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                _secondaryLink('View', CupertinoIcons.eye,
                    () => _viewImage(context, imagePath, title)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewFallback(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 38),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Orbitron',
                  fontSize: 12)),
        ],
      ),
    );
  }

  /// Clean yellow text button with an icon — no pill background.
  Widget _secondaryLink(String label, IconData icon, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppTheme.lightBackground),
                const SizedBox(width: 5),
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.lightBackground,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermissionsAndShowOptions(BuildContext context, {required String licenseType}) async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    // Request photos permission (for gallery access)
    final photosStatus = await Permission.photos.request();
    
    if (!mounted) return;
    
    if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
      // Show dialog to open settings
      final openSettings = await AppDialog.show(
        context,
        title: 'Permissions Required',
        message:
            'Camera and photo library permissions are required to add license images. Please enable them in your device settings.',
        icon: Icons.lock_outline,
        confirmLabel: 'Open Settings',
      );

      if (openSettings == true) {
        openAppSettings();
      }
      return;
    }
    
    // Show image options if permissions are granted or can be requested
    _showImageOptions(context, licenseType);
  }

  void _showImageOptions(BuildContext context, String licenseType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    context,
                    'Camera',
                    Icons.camera_alt,
                    () => _takePhoto(context, licenseType),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    context,
                    'Gallery',
                    Icons.photo_library,
                    () => _pickFromGallery(context, licenseType),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkModeCardBackground : AppTheme.lightModeCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightBackground.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.lightBackground,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(BuildContext context, String licenseType) async {
    Navigator.pop(context);
    
    if (_selectedCar == null) {
      _showMessage('Please select a car first');
      return;
    }
    
    try {
      final result = await _licenseService.takePhotoFromCamera();
      
      if (result.isSuccess && result.imagePath != null) {
        await _saveLicenseImage(licenseType, result.imagePath!);
      } else {
        _showMessage(result.message);
      }
    } catch (e) {
      _showMessage('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery(BuildContext context, String licenseType) async {
    Navigator.pop(context);
    
    if (_selectedCar == null) {
      _showMessage('Please select a car first');
      return;
    }
    
    try {
      final result = await _licenseService.pickImageFromGallery();
      
      if (result.isSuccess && result.imagePath != null) {
        await _saveLicenseImage(licenseType, result.imagePath!);
      } else {
        _showMessage(result.message);
      }
    } catch (e) {
      _showMessage('Failed to pick image: $e');
    }
  }

  Future<void> _saveLicenseImage(String licenseType, String imagePath) async {
    if (_selectedCar == null) return;
    
    try {
      // Check if license image already exists
      final existingLicense = await _licenseService.getLicenseImageByType(
        _selectedCar!.id!, 
        licenseType
      );
      
      if (existingLicense != null) {
        // Update existing license image
        final result = await _licenseService.updateLicenseImage(
          id: existingLicense.id!,
          carId: _selectedCar!.id!,
          licenseType: licenseType,
          imagePath: imagePath,
        );
        
        if (result.isSuccess) {
          _showMessage('License image updated successfully');
          HapticFeedback.lightImpact();
          await _loadLicenseImages();
        } else {
          _showMessage(result.message);
        }
      } else {
        // Add new license image
        final result = await _licenseService.addLicenseImage(
          carId: _selectedCar!.id!,
          licenseType: licenseType,
          imagePath: imagePath,
        );
        
        if (result.isSuccess) {
          _showMessage('License image added successfully');
          HapticFeedback.lightImpact();
          await _loadLicenseImages();
        } else {
          _showMessage(result.message);
        }
      }
    } catch (e) {
      _showMessage('Failed to save license image: $e');
    }
  }

  void _viewImage(BuildContext context, String imagePath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              title,
              style: const TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(imagePath),
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Image not found',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
