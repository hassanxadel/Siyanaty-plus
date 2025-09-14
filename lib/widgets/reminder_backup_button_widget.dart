import 'package:flutter/material.dart';
import '../shared/constants/app_theme.dart';
import '../services/firebase_reminder_service.dart';

/// Widget for handling reminder backup and restore operations
class ReminderBackupButtonWidget extends StatefulWidget {
  const ReminderBackupButtonWidget({super.key});

  @override
  State<ReminderBackupButtonWidget> createState() => _ReminderBackupButtonWidgetState();
}

class _ReminderBackupButtonWidgetState extends State<ReminderBackupButtonWidget> {
  final FirebaseReminderService _firebaseReminderService = FirebaseReminderService();
  bool _isLoading = false;
  ReminderBackupStatus? _backupStatus;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  Future<void> _loadBackupStatus() async {
    try {
      final status = await _firebaseReminderService.getBackupStatus();
      if (mounted) {
        setState(() {
          _backupStatus = status;
        });
      }
    } catch (e) {
      // Handle error silently for status loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_sync,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Reminder Cloud Backup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBackupStatus,
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Status information
          if (_backupStatus != null) ...[
            _buildStatusRow('Local Reminders', _backupStatus!.localRemindersCount.toString()),
            _buildStatusRow('Cloud Reminders', _backupStatus!.cloudRemindersCount.toString()),
            if (_backupStatus!.lastBackupTime != null)
              _buildStatusRow('Last Backup', _formatDateTime(_backupStatus!.lastBackupTime!)),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _backupStatus!.isInSync 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _backupStatus!.statusMessage,
                style: TextStyle(
                  color: _backupStatus!.isInSync ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _backupReminders,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _restoreReminders,
                  icon: const Icon(Icons.cloud_download, size: 18),
                  label: const Text('Restore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            'Backup your reminders to the cloud for safe keeping. Restore them on any device.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _backupReminders() async {
    if (!_firebaseReminderService.isUserAuthenticated) {
      _showMessage('Please sign in to backup your reminders', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _firebaseReminderService.backupAllRemindersToFirebase();
      
      if (result.isSuccess) {
        _showMessage(result.message, isError: false);
        await _loadBackupStatus(); // Refresh status
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Failed to backup reminders: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreReminders() async {
    if (!_firebaseReminderService.isUserAuthenticated) {
      _showMessage('Please sign in to restore your reminders', isError: true);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Reminders'),
        content: const Text(
          'This will restore all reminders from your cloud backup. '
          'This may create duplicates if you have local reminders. '
          'Do you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _firebaseReminderService.restoreRemindersFromFirebase();
      
      if (result.isSuccess) {
        _showMessage(result.message, isError: false);
        await _loadBackupStatus(); // Refresh status
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Failed to restore reminders: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
