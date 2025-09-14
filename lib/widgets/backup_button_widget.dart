import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_backup_service.dart';
import '../services/firebase_reminder_service.dart';
import '../shared/constants/app_theme.dart';
import '../presentation/screens/settings/detailed_backup_screen.dart';

/// Widget for handling backup to cloud functionality
/// Displays backup status and provides backup/restore options
class BackupButtonWidget extends StatefulWidget {
  const BackupButtonWidget({super.key});

  @override
  State<BackupButtonWidget> createState() => _BackupButtonWidgetState();
}

class _BackupButtonWidgetState extends State<BackupButtonWidget> {
  final FirebaseBackupService _backupService = FirebaseBackupService();
  final FirebaseReminderService _reminderService = FirebaseReminderService();
  bool _isLoading = false;
  BackupStatus? _backupStatus;
  ReminderBackupStatus? _reminderBackupStatus;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  /// Load current backup status
  Future<void> _loadBackupStatus() async {
    try {
      final carStatus = await _backupService.getBackupStatus();
      final reminderStatus = await _reminderService.getBackupStatus();
      if (mounted) {
        setState(() {
          _backupStatus = carStatus;
          _reminderBackupStatus = reminderStatus;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load backup status: ${e.toString()}', isError: true);
      }
    }
  }

  /// Handle backup to cloud
  Future<void> _handleBackupToCloud() async {
    if (_isLoading) return;

    // Show confirmation dialog
    final confirmed = await _showBackupConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.lightImpact();
      
      // Backup cars first
      final carResult = await _backupService.backupAllCarsToFirebase();
      
      // Backup reminders
      final reminderResult = await _reminderService.backupAllRemindersToFirebase();
      
      // Combine results
      if (carResult.isSuccess && reminderResult.isSuccess) {
        _showSnackBar('All data backed up successfully to cloud', isError: false);
        await _loadBackupStatus(); // Refresh status
      } else if (carResult.isSuccess || reminderResult.isSuccess) {
        String message = '';
        if (carResult.isSuccess) {
          message = 'Cars backed up successfully. ${reminderResult.message}';
        } else {
          message = 'Reminders backed up successfully. ${carResult.message}';
        }
        _showSnackBar(message, isError: false);
        await _loadBackupStatus(); // Refresh status
      } else {
        _showSnackBar('Backup failed: Cars - ${carResult.message}, Reminders - ${reminderResult.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Backup failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle restore from cloud
  Future<void> _handleRestoreFromCloud() async {
    if (_isLoading) return;

    // Show confirmation dialog
    final confirmed = await _showRestoreConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.lightImpact();
      
      // Restore cars first
      final carResult = await _backupService.restoreCarsFromFirebase();
      
      // Restore reminders
      final reminderResult = await _reminderService.restoreRemindersFromFirebase();
      
      // Combine results
      if (carResult.isSuccess && reminderResult.isSuccess) {
        _showSnackBar('All data restored successfully from cloud', isError: false);
        await _loadBackupStatus(); // Refresh status
      } else if (carResult.isSuccess || reminderResult.isSuccess) {
        String message = '';
        if (carResult.isSuccess) {
          message = 'Cars restored successfully. ${reminderResult.message}';
        } else {
          message = 'Reminders restored successfully. ${carResult.message}';
        }
        _showSnackBar(message, isError: false);
        await _loadBackupStatus(); // Refresh status
      } else {
        _showSnackBar('Restore failed: Cars - ${carResult.message}, Reminders - ${reminderResult.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Restore failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show backup confirmation dialog
  Future<bool> _showBackupConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getThemeAwareCardBackground(context),
          title: Text(
            'Backup to Cloud',
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will backup all your cars and reminders to the cloud.',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 12),
              if (_backupStatus != null) ...[
                Text(
                  'Local cars: ${_backupStatus!.localCarsCount}',
                  style: TextStyle(
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Cloud cars: ${_backupStatus!.cloudCarsCount}',
                  style: TextStyle(
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Do you want to continue?',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Backup',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show restore confirmation dialog
  Future<bool> _showRestoreConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getThemeAwareCardBackground(context),
          title: Text(
            'Restore from Cloud',
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will restore cars and reminders from your cloud backup.',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 12),
              if (_backupStatus != null) ...[
                Text(
                  'Local cars: ${_backupStatus!.localCarsCount}',
                  style: TextStyle(
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Cloud cars: ${_backupStatus!.cloudCarsCount}',
                  style: TextStyle(
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Existing cars with same VIN will be updated.',
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Do you want to continue?',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Restore',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show partial success dialog
  void _showPartialSuccessDialog(BackupResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getThemeAwareCardBackground(context),
          title: const Text(
            'Backup Partially Completed',
            style: TextStyle(
              color: Colors.orange,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.message,
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
              if (result.errors != null && result.errors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Errors:',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.errors!.take(3).map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                    ),
                  ),
                )),
                if (result.errors!.length > 3)
                  Text(
                    '... and ${result.errors!.length - 3} more errors',
                    style: TextStyle(
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.getThemeAwareIconColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show partial restore dialog
  void _showPartialRestoreDialog(RestoreResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getThemeAwareCardBackground(context),
          title: const Text(
            'Restore Partially Completed',
            style: TextStyle(
              color: Colors.orange,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.message,
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
              if (result.errors != null && result.errors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Errors:',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.errors!.take(3).map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                    ),
                  ),
                )),
                if (result.errors!.length > 3)
                  Text(
                    '... and ${result.errors!.length - 3} more errors',
                    style: TextStyle(
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.getThemeAwareIconColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show snackbar message
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DetailedBackupScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getThemeAwareCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload,
                color: AppTheme.getThemeAwareIconColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Cloud Backup - All Data',
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
          if (_backupStatus != null || _reminderBackupStatus != null) ...[
            if (_backupStatus != null)
              _buildStatusRow('Authentication', _backupStatus!.isAuthenticated ? 'Connected' : 'Not connected'),
            
            // Combined data status
            if (_backupStatus != null || _reminderBackupStatus != null) ...[
              _buildStatusRow('Local Data', '${(_backupStatus?.localCarsCount ?? 0) + (_reminderBackupStatus?.localRemindersCount ?? 0)}'),
              _buildStatusRow('Cloud Data', '${(_backupStatus?.cloudCarsCount ?? 0) + (_reminderBackupStatus?.cloudRemindersCount ?? 0)}'),
            ],
            
            if (_backupStatus?.lastBackupTime != null)
              _buildStatusRow('Last Backup', _formatDateTime(_backupStatus!.lastBackupTime!)),
            if (_backupStatus?.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error: ${_backupStatus!.error}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          if (_backupStatus?.isAuthenticated == true) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleBackupToCloud,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload, size: 18),
                    label: Text(
                      _isLoading ? 'Backing up...' : 'Backup',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleRestoreFromCloud,
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: const Text(
                      'Restore',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.getThemeAwareCardBackground(context),
                      foregroundColor: AppTheme.getThemeAwareTextColor(context),
                      side: BorderSide(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'Please sign in to use cloud backup features',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
              fontFamily: 'Orbitron',
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
