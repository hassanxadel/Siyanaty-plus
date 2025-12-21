import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/firebase_backup_service.dart';
import '../../../services/firebase_reminder_service.dart';
import '../../../services/firebase_maintenance_service.dart';
import '../../../services/comprehensive_backup_service.dart';
import '../../../services/mileage_service.dart';
import '../../../services/license_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/firebase_obd_service.dart';
import '../../../services/obd_service.dart';

class DetailedBackupScreen extends StatefulWidget {
  const DetailedBackupScreen({super.key});

  @override
  State<DetailedBackupScreen> createState() => _DetailedBackupScreenState();
}

class _DetailedBackupScreenState extends State<DetailedBackupScreen> {
  final FirebaseBackupService _backupService = FirebaseBackupService();
  final FirebaseReminderService _reminderService = FirebaseReminderService();
  final ComprehensiveBackupService _comprehensiveService = ComprehensiveBackupService();
  final MileageService _mileageService = MileageService();
  final LicenseService _licenseService = LicenseService();
  final OcrService _ocrService = OcrService();
  final FirebaseOBDService _obdFirebaseService = FirebaseOBDService();
  final OBDService _obdService = OBDService();
  
  bool _isLoading = false;
  BackupStatus? _backupStatus;
  ReminderBackupStatus? _reminderBackupStatus;
  MaintenanceBackupStatus? _maintenanceBackupStatus;
  ComprehensiveBackupStatus? _comprehensiveStatus;
  LicenseBackupStatus? _licenseBackupStatus;
  OcrBackupStatus? _ocrBackupStatus;
  int _localMileageCount = 0;
  int _cloudMileageCount = 0;
  int _localOBDScansCount = 0;
  int _cloudOBDScansCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  Future<void> _loadBackupStatus() async {
    try {
      final carStatus = await _backupService.getBackupStatus();
      final reminderStatus = await _reminderService.getBackupStatus();
      final maintenanceStatus = await FirebaseMaintenanceService.getBackupStatus();
      final comprehensiveStatus = await _comprehensiveService.getComprehensiveBackupStatus();
      
      // Get mileage counts
      final localMileage = await _mileageService.getAllEntries();
      final cloudMileage = await _mileageService.getEntriesFromFirebase();
      
      // Get license backup status
      final licenseStatus = await _licenseService.getLicenseBackupStatus();
      
      // Get OCR backup status
      final ocrStatus = await _ocrService.getOcrBackupStatus();
      
      // Get OBD scans counts
      final localOBDScans = await _obdService.getAllScans();
      final cloudOBDScans = await _obdFirebaseService.getFirebaseScansCount();
      
      if (mounted) {
        setState(() {
          _backupStatus = carStatus;
          _reminderBackupStatus = reminderStatus;
          _maintenanceBackupStatus = maintenanceStatus;
          _comprehensiveStatus = comprehensiveStatus;
          _licenseBackupStatus = licenseStatus;
          _ocrBackupStatus = ocrStatus;
          _localMileageCount = localMileage.length;
          _cloudMileageCount = cloudMileage.length;
          _localOBDScansCount = localOBDScans.length;
          _cloudOBDScansCount = cloudOBDScans;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load backup status: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      height: 190,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                   IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Detailed Backup Management',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Manage your data backup and restore',
                  style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
              ),
              const SizedBox(height: 22),
              
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: Column(
        children: [
          // Header with gradient
          _buildHeaderWithBackground(),
          // Body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataTypeCard(
                    title: 'Cars Data',
                    icon: Icons.directions_car,
                    localCount: _backupStatus?.localCarsCount ?? 0,
                    cloudCount: _backupStatus?.cloudCarsCount ?? 0,
                    onBackup: _backupCars,
                    onRestore: _restoreCars,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeCard(
                    title: 'Reminders Data',
                    icon: Icons.notifications_active,
                    localCount: _reminderBackupStatus?.localRemindersCount ?? 0,
                    cloudCount: _reminderBackupStatus?.cloudRemindersCount ?? 0,
                    onBackup: _backupReminders,
                    onRestore: _restoreReminders,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeCard(
                    title: 'Maintenance Data',
                    icon: Icons.build_circle,
                    localCount: _maintenanceBackupStatus?.localCount ?? 0,
                    cloudCount: _maintenanceBackupStatus?.cloudCount ?? 0,
                    onBackup: _backupMaintenance,
                    onRestore: _restoreMaintenance,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeCard(
                    title: 'Mileage Tracking Data',
                    icon: Icons.speed,
                    localCount: _localMileageCount,
                    cloudCount: _cloudMileageCount,
                    onBackup: _backupMileage,
                    onRestore: _restoreMileage,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeCard(
                    title: 'License Images',
                    icon: Icons.credit_card,
                    localCount: _licenseBackupStatus?.localCount ?? 0,
                    cloudCount: _licenseBackupStatus?.cloudCount ?? 0,
                    onBackup: _backupLicenseImages,
                    onRestore: _restoreLicenseImages,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeCard(
                    title: 'OCR Scans',
                    icon: Icons.document_scanner,
                    localCount: _ocrBackupStatus?.localScansCount ?? 0,
                    cloudCount: _ocrBackupStatus?.cloudScansCount ?? 0,
                    onBackup: _backupOcrScans,
                    onRestore: _restoreOcrScans,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeCard(
                    title: 'OBD-II Scans',
                    icon: Icons.bluetooth_searching,
                    localCount: _localOBDScansCount,
                    cloudCount: _cloudOBDScansCount,
                    onBackup: _backupOBDScans,
                    onRestore: _restoreOBDScans,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildComprehensiveBackupCard(),
                  const SizedBox(height: 24),
                  _buildOverallStatus(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeCard({
    required String title,
    required IconData icon,
    required int localCount,
    required int cloudCount,
    required VoidCallback onBackup,
    required VoidCallback onRestore,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
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
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status information
            _buildStatusRow('Local Items', localCount.toString()),
            _buildStatusRow('Cloud Items', cloudCount.toString()),
            _buildStatusRow('Status', localCount == cloudCount ? 'In Sync' : 'Out of Sync'),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : onBackup,
                      icon: const Icon(Icons.cloud_upload, size: 18, color: Colors.white),
                      label: const Text(
                        'Backup',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade800,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : onRestore,
                      icon: const Icon(Icons.cloud_download, size: 18, color: Colors.white),
                      label: const Text(
                        'Restore',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Orbitron',
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatus() {
    if (_backupStatus == null && _reminderBackupStatus == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 12),
            if (_backupStatus != null)
              _buildStatusRow('Authentication', _backupStatus!.isAuthenticated ? 'Connected' : 'Not Connected'),
            if (_backupStatus?.lastBackupTime != null)
              _buildStatusRow('Last Backup', _formatDateTime(_backupStatus!.lastBackupTime!)),
          ],
        ),
      ),
    );
  }

  Future<void> _backupCars() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _backupService.backupAllCarsToFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('Cars backed up successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup cars: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up cars: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreCars() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _backupService.restoreCarsFromFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('Cars restored successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore cars: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring cars: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupReminders() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _reminderService.backupAllRemindersToFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('Reminders backed up successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup reminders: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up reminders: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreReminders() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _reminderService.restoreRemindersFromFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('Reminders restored successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore reminders: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring reminders: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupMaintenance() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await FirebaseMaintenanceService.backupMaintenanceToFirestore();
      
      if (result.success) {
        _showSnackBar('Maintenance records backed up successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup maintenance: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up maintenance: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupMileage() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final success = await _mileageService.syncToFirebase();
      
      if (success) {
        _showSnackBar('Mileage data backed up successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup mileage data', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up mileage data: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreMileage() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final success = await _mileageService.syncFromFirebase();
      
      if (success) {
        _showSnackBar('Mileage data restored successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore mileage data', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring mileage data: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupLicenseImages() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _licenseService.backupLicenseImagesToFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('License images backed up successfully! ${result.successCount} images processed.', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup license images: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up license images: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreLicenseImages() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _licenseService.restoreLicenseImagesFromFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('License images restored successfully! ${result.successCount} images processed.', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore license images: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring license images: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupOcrScans() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _ocrService.backupScansToFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('OCR scans backed up successfully! ${result.successCount} scans processed.', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup OCR scans: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up OCR scans: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreOcrScans() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _ocrService.restoreScansFromFirebase();
      
      if (result.isSuccess) {
        _showSnackBar('OCR scans restored successfully! ${result.successCount} scans processed.', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore OCR scans: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring OCR scans: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildComprehensiveBackupCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withOpacity(0.1),
              AppTheme.primaryGreen.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.backup,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comprehensive Backup',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        'Backup all data (Cars, Reminders, Maintenance) at once',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Status indicators
            Row(
              children: [
                Expanded(
                  child: _buildStatusIndicator(
                    'Cars',
                    _comprehensiveStatus?.carsBackedUp ?? false,
                  ),
                ),
                Expanded(
                  child: _buildStatusIndicator(
                    'Reminders',
                    _comprehensiveStatus?.remindersBackedUp ?? false,
                  ),
                ),
                Expanded(
                  child: _buildStatusIndicator(
                    'Maintenance',
                    _comprehensiveStatus?.maintenanceBackedUp ?? false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _backupAllData,
                      icon: const Icon(Icons.cloud_upload, size: 18, color: Colors.white),
                      label: const Text(
                        'Backup All',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade800,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _restoreAllData,
                      icon: const Icon(Icons.cloud_download, size: 18, color: Colors.white),
                      label: const Text(
                        'Restore All',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isBackedUp) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isBackedUp ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _backupAllData() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _comprehensiveService.backupAllDataToFirebase();
      
      if (result.success) {
        _showSnackBar('All data backed up successfully! ${result.totalSuccessCount} items processed.', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup all data: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up all data: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreAllData() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await _comprehensiveService.restoreAllDataFromFirebase();
      
      if (result.success) {
        _showSnackBar('All data restored successfully! ${result.totalSuccessCount} items processed.', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore all data: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring all data: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreMaintenance() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final result = await FirebaseMaintenanceService.restoreMaintenanceFromFirestore();
      
      if (result.success) {
        _showSnackBar('Maintenance records restored successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore maintenance: ${result.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring maintenance: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _backupOBDScans() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final success = await _obdFirebaseService.backupAllScansToFirebase();
      
      if (success) {
        _showSnackBar('OBD scans backed up successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to backup OBD scans', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error backing up OBD scans: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreOBDScans() async {
    setState(() => _isLoading = true);
    
    try {
      HapticFeedback.lightImpact();
      final success = await _obdFirebaseService.restoreScansFromFirebase();
      
      if (success) {
        _showSnackBar('OBD scans restored successfully', isError: false);
        await _loadBackupStatus();
      } else {
        _showSnackBar('Failed to restore OBD scans', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error restoring OBD scans: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
