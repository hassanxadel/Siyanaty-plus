import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../debug/firebase_debug_screen.dart';
import '../profile/profile_screen.dart';
import '../info/about_screen.dart';
import '../info/help_screen.dart';
import '../info/privacy_screen.dart';
import '../info/terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _maintenanceReminders = true;
  bool _fuelTracking = true;
  bool _obdAlerts = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.firebaseUser;

    return Scaffold(
      body: Column(
        children: [
          _buildHeaderWithBackground(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(currentUser, authProvider),
                  const SizedBox(height: 24),
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  _buildDataBackupSection(),
                  const SizedBox(height: 24),
                  _buildAppAppearanceSection(),
                  const SizedBox(height: 24),
                  _buildAboutSupportSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      width: double.infinity,
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
      child: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 26, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Configure your preferences and account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(dynamic currentUser, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryGreen
                  : AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Profile Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: AppTheme.primaryGreen,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.appUser?.fullName ?? currentUser?.email?.split('@').first ?? 'User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getThemeAwareTextColor(context),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.email ?? 'No email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    /*Text(
                          'Account verified: ${currentUser?.emailVerified == true ? "Yes" : "No"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentUser?.emailVerified == true 
                                ? AppTheme.getThemeAwareTextColor(context).withOpacity(0.8)
                                : const Color.fromARGB(255, 255, 46, 46),
                            fontFamily: 'Orbitron',
                          ),
                        ),
                    Row(
                      children: [
                        if (currentUser?.emailVerified != true) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendVerificationEmail,
                            child: Text(
                              'Verify Now',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryGreen,
                                fontFamily: 'Orbitron',
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _refreshVerificationStatus,
                            child: Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryGreen,
                                fontFamily: 'Orbitron',
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),*/
                  ],
                ),
              ),
              
              IconButton(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit),
                color: AppTheme.getThemeAwareTextColor(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text(
                'Sign Out',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryGreen
                  : AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            'All Notifications',
            'Enable or disable all notifications',
            _notifications,
            (value) => setState(() => _notifications = value),
          ),
          
          _buildSwitchTile(
            'Maintenance Reminders',
            'Get notified about upcoming maintenance',
            _maintenanceReminders,
            (value) => setState(() => _maintenanceReminders = value),
          ),
          
          _buildSwitchTile(
            'Fuel Tracking',
            'Track fuel consumption and efficiency',
            _fuelTracking,
            (value) => setState(() => _fuelTracking = value),
          ),
          
          _buildSwitchTile(
            'OBD Alerts',
            'Real-time diagnostic alerts',
            _obdAlerts,
            (value) => setState(() => _obdAlerts = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBackupSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data & Backup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryGreen
                  : AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionTile(
            'Export Data',
            'Download your maintenance records',
            Icons.download,
            _exportData,
          ),
          
          _buildActionTile(
            'Backup to Cloud',
            'Backup your data to cloud storage',
            Icons.cloud_upload,
            _backupData,
          ),
          
          _buildActionTile(
            'Clear Cache',
            'Free up storage space',
            Icons.cleaning_services,
            _clearCache,
          ),
          
          _buildActionTile(
            'Delete All Data',
            'Permanently delete all your data',
            Icons.delete_forever,
            _deleteAllData,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About & Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryGreen
                  : AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionTile(
            'Help & FAQ',
            'Get answers to common questions',
            Icons.help_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            ),
          ),
          
          _buildActionTile(
            'About Siyana+',
            'Learn about our app and mission',
            Icons.info_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
          
          _buildActionTile(
            'Privacy Policy',
            'How we protect your data',
            Icons.privacy_tip_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyScreen()),
            ),
          ),
          
          _buildActionTile(
            'Terms of Service',
            'Our terms and conditions',
            Icons.description_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            ),
          ),
          
          _buildActionTile(
            'Contact Support',
            'Get help from our team',
            Icons.support_agent,
            _contactSupport,
          ),
          
          _buildActionTile(
            'Rate Our App',
            'Leave a review on the app store',
            Icons.star_outline,
            _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryGreen
                  : AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Development tools for debugging Firebase issues',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.darkAccentGreen,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionTile(
            'Firebase Debug Tools',
            'Debug authentication and profile issues',
            Icons.bug_report,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FirebaseDebugScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.lightBackground
                        : Colors.black,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.lightBackground.withOpacity(0.8)
                        : Colors.black54,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            inactiveThumbColor: AppTheme.darkGray,
            inactiveTrackColor: AppTheme.darkGray.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isDestructive ? AppTheme.errorColor : AppTheme.primaryGreen).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppTheme.errorColor : AppTheme.primaryGreen,
                size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppTheme.errorColor
                          : AppTheme.getThemeAwareTextColor(context),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.darkAccentGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Action Methods
  void _editProfile() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }



  void _signOut() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppTheme.darkAccentGreen,
            fontFamily: 'Orbitron',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.darkAccentGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.signOut();
              if (success && mounted) {
                _showMessage('Successfully signed out');
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    HapticFeedback.lightImpact();
    _showMessage('Exporting your data...');
  }

  void _backupData() {
    HapticFeedback.lightImpact();
    _showMessage('Backing up data to cloud...');
  }

  void _clearCache() {
    HapticFeedback.lightImpact();
    _showMessage('Cache cleared successfully!');
  }

  void _deleteAllData() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete All Data',
          style: TextStyle(
            color: AppTheme.errorColor,
            fontFamily: 'Orbitron',
          ),
        ),
        content: const Text(
          'This will permanently delete all your cars, maintenance records, and settings. This action cannot be undone.',
          style: TextStyle(
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.darkAccentGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('All data deleted successfully');
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    HapticFeedback.lightImpact();
    _showMessage('Opening support chat...');
  }

  void _rateApp() {
    HapticFeedback.lightImpact();
    _showMessage('Opening app store...');
  }

  Widget _buildAppAppearanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryGreen
                  : AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          // Dark Mode Toggle
          ListTile(
            leading: const Icon(
              Icons.dark_mode,
              color: AppTheme.primaryGreen,
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.lightBackground
                    : Colors.black,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Change app theme from dark green to white',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.lightBackground.withOpacity(0.8)
                    : Colors.black54,
                fontFamily: 'Orbitron',
                fontSize: 12,
              ),
            ),
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Switch.adaptive(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    themeProvider.toggleTheme();
                  },
                  activeColor: Colors.white,
                  activeTrackColor: AppTheme.primaryGreen,
                  inactiveThumbColor: AppTheme.darkGray,
                  inactiveTrackColor: AppTheme.darkGray.withOpacity(0.3),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  void _showMessage(String message) {
    NotificationService.instance.showInfoNotification(
      context,
      message: message,
    );
  }

  void _sendVerificationEmail() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Verify Email',
          style: TextStyle(
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        content: const Text(
          'We\'ll send a verification email to your registered email address. Please check your inbox and click the verification link.',
          style: TextStyle(
            color: AppTheme.darkAccentGreen,
            fontFamily: 'Orbitron',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.darkAccentGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.sendEmailVerification();
              if (success && mounted) {
                _showMessage('Verification email sent! Check your inbox.');
              } else if (mounted) {
                _showMessage('Failed to send verification email. Please try again.');
              }
            },
            child: const Text(
              'Send Email',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshVerificationStatus() async {
    HapticFeedback.lightImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.reloadUser();
    if (success && mounted) {
      setState(() {}); // Refresh the UI
      _showMessage('Verification status refreshed!');
    } else if (mounted) {
      _showMessage('Failed to refresh verification status. Please try again.');
    }
  }
}