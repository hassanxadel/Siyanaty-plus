import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/local_notification_service.dart';

class NotificationPermissionsScreen extends StatefulWidget {
  const NotificationPermissionsScreen({super.key});

  @override
  State<NotificationPermissionsScreen> createState() => _NotificationPermissionsScreenState();
}

class _NotificationPermissionsScreenState extends State<NotificationPermissionsScreen> {
  final LocalNotificationService _notificationService = LocalNotificationService.instance;
  
  bool _isLoading = false;
  bool _notificationsEnabled = false;
  bool _exactAlarmsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      final exactAlarmsEnabled = await _notificationService.areExactAlarmsEnabled();
      
      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _exactAlarmsEnabled = exactAlarmsEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error checking permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _notificationService.requestAllPermissions();
      
      if (granted) {
        _showSuccess('All permissions granted!');
      } else {
        _showWarning('Some permissions were not granted. Please enable them manually.');
      }
      
      await _checkPermissions();
    } catch (e) {
      _showError('Error requesting permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAppSettings() async {
    try {
      // Try to open app settings
      const url = 'package:com.example.siyanaty_plus'; // Replace with your actual package name
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Cannot open app settings. Please go to Settings > Apps > Siyanaty+ manually.');
      }
    } catch (e) {
      _showError('Error opening settings: $e');
    }
  }

  void _showSuccess(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showWarning(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _buildPermissionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Notification Permissions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Enable notifications to receive reminder alerts',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
      ),
    );
  }

  Widget _buildPermissionsList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildPermissionCard(
            title: 'Basic Notifications',
            description: 'Allow the app to show notifications',
            isEnabled: _notificationsEnabled,
            icon: Icons.notifications,
          ),
          const SizedBox(height: 16),
          _buildPermissionCard(
            title: 'Exact Alarms & Reminders',
            description: 'Allow the app to schedule exact alarm times',
            isEnabled: _exactAlarmsEnabled,
            icon: Icons.alarm,
          ),
          const SizedBox(height: 32),
          
          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Request Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open App Settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.darkAccentGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Help section
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If permissions are still not working:\n'
                    '1. Go to Settings > Apps > Siyanaty+\n'
                    '2. Enable "Notifications"\n'
                    '3. Enable "Alarms & reminders"\n'
                    '4. Disable battery optimization',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required bool isEnabled,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEnabled ? AppTheme.primaryGreen : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isEnabled 
                    ? AppTheme.primaryGreen.withOpacity(0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: isEnabled ? AppTheme.primaryGreen : Colors.grey.shade600,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.lightBackground
                          : AppTheme.darkAccentGreen,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                    const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.lightBackground.withOpacity(0.7)
                          : AppTheme.darkAccentGreen.withOpacity(0.7),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isEnabled ? Icons.check_circle : Icons.cancel,
              color: isEnabled ? Colors.green : Colors.red,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
