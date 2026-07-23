import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/services.dart';
import '../services/firebase_backup_service.dart';
import '../services/firebase_reminder_service.dart';
import '../services/comprehensive_backup_service.dart';
import '../shared/constants/app_theme.dart';
import '../presentation/screens/settings/detailed_backup_screen.dart';
import '../presentation/widgets/app_dialog.dart';

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
  final ComprehensiveBackupService _comprehensiveService = ComprehensiveBackupService();
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
      
      // Use comprehensive backup service to backup all data
      final result = await _comprehensiveService.backupAllDataToFirebase();
      
      if (result.success) {
        _showSnackBar('All data backed up successfully to cloud! ${result.totalSuccessCount} items processed.', isError: false);
        await _loadBackupStatus(); // Refresh status
      } else {
        _showSnackBar('Backup failed: ${result.message}', isError: true);
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
      
      // Use comprehensive backup service to restore all data
      final result = await _comprehensiveService.restoreAllDataFromFirebase();
      
      if (result.success) {
        _showSnackBar('All data restored successfully from cloud! ${result.totalSuccessCount} items processed.', isError: false);
        await _loadBackupStatus(); // Refresh status
      } else {
        _showSnackBar('Restore failed: ${result.message}', isError: true);
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
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: 'Backup to Cloud',
        message:
            'This will backup all your cars and reminders to the cloud. Do you want to continue?',
        icon: Icons.cloud_upload_outlined,
        content: _backupStatus == null
            ? const SizedBox.shrink()
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glowFieldDecoration(),
                child: Column(
                  children: [
                    _buildRestoreStat(
                      'Local cars',
                      '${_backupStatus!.localCarsCount}',
                    ),
                    const SizedBox(height: 6),
                    _buildRestoreStat(
                      'Cloud cars',
                      '${_backupStatus!.cloudCarsCount}',
                    ),
                  ],
                ),
              ),
        actions: [
          AppDialogAction(
            label: 'Cancel',
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction(
            label: 'Backup All',
            filled: true,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Show restore confirmation dialog
  Future<bool> _showRestoreConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: 'Restore from Cloud',
        message: 'This will restore cars and reminders from your cloud backup.',
        icon: Icons.cloud_download_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_backupStatus != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glowFieldDecoration(),
                child: Column(
                  children: [
                    _buildRestoreStat(
                      'Local cars',
                      '${_backupStatus!.localCarsCount}',
                    ),
                    const SizedBox(height: 6),
                    _buildRestoreStat(
                      'Cloud cars',
                      '${_backupStatus!.cloudCarsCount}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Existing cars with the same VIN will be updated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.costHighlight.withOpacity(0.95),
                fontFamily: 'Orbitron',
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          AppDialogAction(
            label: 'Cancel',
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction(
            label: 'Restore All',
            filled: true,
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Faded pill action for the Cloud Backup card — tinted fill, glowing rim,
  /// accent-coloured label. A null [onTap] renders it dimmed and inert.
  Widget _buildCardAction({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    final enabled = onTap != null;
    final color = enabled ? accent : accent.withOpacity(0.4);

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        decoration: AppTheme.glowButtonDecoration(accent: color),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  else
                    Icon(icon, size: 17, color: color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.lightBackground.withOpacity(0.7),
            fontFamily: 'Orbitron',
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.secondaryGreen,
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Show partial success dialog
  void _showPartialSuccessDialog(BackupResult result) {
    _showPartialResultDialog(
      title: 'Backup Partially Completed',
      message: result.message,
      errors: result.errors,
    );
  }

  /// Shared amber "finished, but with problems" pop-up for both backup and
  /// restore, so the two report failures identically.
  void _showPartialResultDialog({
    required String title,
    required String message,
    List<String>? errors,
  }) {
    AppDialog.custom<void>(
      context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      accent: AppDialog.warning,
      closeLabel: 'OK',
      content: (errors == null || errors.isEmpty)
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.glowFieldDecoration(
                accent: AppDialog.destructive,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Errors:',
                    style: TextStyle(
                      color: AppDialog.destructive,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...errors.take(3).map((error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $error',
                          style: TextStyle(
                            color: AppTheme.lightBackground.withOpacity(0.85),
                            fontFamily: 'Orbitron',
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      )),
                  if (errors.length > 3)
                    Text(
                      '... and ${errors.length - 3} more errors',
                      style: TextStyle(
                        color: AppTheme.lightBackground.withOpacity(0.6),
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// Show partial restore dialog
  void _showPartialRestoreDialog(RestoreResult result) {
    _showPartialResultDialog(
      title: 'Restore Partially Completed',
      message: result.message,
      errors: result.errors,
    );
  }

  /// Show snackbar message
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    AppSnackbar.show(context, 
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
    // This is the headline feature of the Settings screen, so it gets a
    // larger radius and the `elevated` glow — deliberately more prominent
    // than the surrounding sections, which use radius 16 unelevated.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCardDecoration(radius: 20, elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Glowing icon chip, matching the pop-up cards
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.secondaryGreen.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryGreen.withOpacity(0.3),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_sync,
                  color: AppTheme.secondaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cloud Backup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightBackground,
                        fontFamily: 'Orbitron',
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cars, reminders & maintenance',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.lightBackground.withOpacity(0.7),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
              // View All pill
              Material(
                color: Colors.transparent,
                child: Container(
                  decoration: AppTheme.glowButtonDecoration(radius: 18),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DetailedBackupScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: AppTheme.secondaryGreen,
                                fontFamily: 'Orbitron',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: AppTheme.secondaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hairline divider under the header
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryGreen.withOpacity(0.5),
                  AppTheme.secondaryGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status information
          if (_backupStatus != null || _reminderBackupStatus != null) ...[
            if (_backupStatus != null)
              _buildStatusRowGradient('Authentication', _backupStatus!.isAuthenticated ? 'Connected' : 'Not connected'),
            
            // Combined data status
            if (_backupStatus != null || _reminderBackupStatus != null) ...[
              _buildStatusRowGradient('Local Data', '${(_backupStatus?.localCarsCount ?? 0) + (_reminderBackupStatus?.localRemindersCount ?? 0)}'),
              _buildStatusRowGradient('Cloud Data', '${(_backupStatus?.cloudCarsCount ?? 0) + (_reminderBackupStatus?.cloudRemindersCount ?? 0)}'),
            ],
            
            if (_backupStatus?.lastBackupTime != null)
              _buildStatusRowGradient('Last Backup', _formatDateTime(_backupStatus!.lastBackupTime!)),
            if (_backupStatus?.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error: ${_backupStatus!.error}',
                  style: const TextStyle(
                    color: Colors.orange,
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
                  child: _buildCardAction(
                    label: _isLoading ? 'Backing up...' : 'Backup All',
                    icon: Icons.cloud_upload,
                    // Amber, matching the Backup buttons in the Detailed
                    // Backup screen, so it stands out from the blue Restore.
                    accent: AppTheme.costHighlight,
                    busy: _isLoading,
                    onTap: _isLoading ? null : _handleBackupToCloud,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCardAction(
                    label: 'Restore All',
                    icon: Icons.cloud_download,
                    accent: AppTheme.infoBlue,
                    onTap: _isLoading ? null : _handleRestoreFromCloud,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppDialog.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppDialog.warning.withOpacity(0.45),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppDialog.warning.withOpacity(0.18),
                    blurRadius: 14,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppDialog.warning,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Sign in to use cloud backup',
                      style: TextStyle(
                        color: AppDialog.warning,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _buildStatusRowGradient(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.lightBackground.withOpacity(0.65),
              fontFamily: 'Orbitron',
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.secondaryGreen,
              fontFamily: 'Orbitron',
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
