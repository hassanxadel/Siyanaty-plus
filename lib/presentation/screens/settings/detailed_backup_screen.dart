import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/firebase_backup_service.dart';
import '../../../services/firebase_reminder_service.dart';
import '../../../services/firebase_maintenance_service.dart';

class DetailedBackupScreen extends StatefulWidget {
  const DetailedBackupScreen({super.key});

  @override
  State<DetailedBackupScreen> createState() => _DetailedBackupScreenState();
}

class _DetailedBackupScreenState extends State<DetailedBackupScreen> {
  final FirebaseBackupService _backupService = FirebaseBackupService();
  final FirebaseReminderService _reminderService = FirebaseReminderService();
  
  bool _isLoading = false;
  BackupStatus? _backupStatus;
  ReminderBackupStatus? _reminderBackupStatus;
  MaintenanceBackupStatus? _maintenanceBackupStatus;

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
      if (mounted) {
        setState(() {
          _backupStatus = carStatus;
          _reminderBackupStatus = reminderStatus;
          _maintenanceBackupStatus = maintenanceStatus;
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                  const Expanded(
                    child: Text(
                      'Detailed Backup Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Manage your data backup and restore',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddCar() {
    // Navigate back and go to cars screen
    Navigator.pop(context);
    // You can add navigation logic here based on your app's navigation structure
    // For now, just pop back to the previous screen (settings)
  }

  void _navigateToAddReminder() {
    // Navigate back and go to reminders screen  
    Navigator.pop(context);
    // You can add navigation logic here based on your app's navigation structure
    // For now, just pop back to the previous screen (settings)
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.getThemeAwareCardBackground(context),
              AppTheme.getThemeAwareCardBackground(context).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getThemeAwareTextColor(context),
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
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onBackup,
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text(
                      'Backup',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onRestore,
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: const Text(
                      'Restore',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
              fontFamily: 'Orbitron',
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
