import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/license_service.dart';
import '../../../services/car_service.dart';
import '../../../models/license_image.dart';
import '../../../models/backup_car.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
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
      return Scaffold(
        backgroundColor: AppTheme.getThemeAwareBackground(context),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: SingleChildScrollView(
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
                      () => _showImageOptions(context, 'personal'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vehicle License Section
                    _buildLicenseSection(
                      context,
                      'Vehicle License',
                      'Your vehicle registration or title',
                      Icons.directions_car,
                      _vehicleLicense?.imagePath,
                      () => _showImageOptions(context, 'vehicle'),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkAccentGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Select Vehicle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BackupCar>(
                value: _selectedCar,
                isExpanded: true,
                dropdownColor: AppTheme.darkAccentGreen,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: _cars.map((car) {
                  return DropdownMenuItem<BackupCar>(
                    value: car,
                    child: Text(
                      '${car.brand} ${car.model} (${car.year})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (BackupCar? newCar) {
                  if (newCar != null) {
                    setState(() {
                      _selectedCar = newCar;
                    });
                    _loadLicenseImages();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkAccentGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkAccentGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              color: Colors.white,
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
  Widget _buildHeaderWithBackground() {
    return Container(
      height: 200,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // If no previous route, try to navigate to root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'License Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.credit_card),
                    onPressed: () {
                      // TODO: Add license management options
                    },
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Store and manage your personal and vehicle licenses',
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
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkAccentGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Image Preview
          if (imagePath != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withOpacity(0.1),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.white70,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Image not found',
                            style: TextStyle(
                              color: Colors.white70,
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
            const SizedBox(height: 16),
          ] else ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white70,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No image added',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.greenAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    label: Text(
                      imagePath != null ? 'Update Image' : 'Add Image',
                      style: const TextStyle(
                        fontFamily: 'Orbitron', 
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              if (imagePath != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _viewImage(context, imagePath, title),
                      icon: const Icon(Icons.visibility, size: 18, color: Colors.white),
                      label: const Text(
                        'View',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryGreen,
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
