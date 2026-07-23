import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../debug/firebase_debug_screen.dart';
import '../profile/profile_screen.dart';
import '../security/pin_setup_screen.dart';
import '../info/about_screen.dart';
import '../info/help_screen.dart';
import '../info/privacy_screen.dart';
import '../info/terms_screen.dart';
import '../../../widgets/backup_button_widget.dart';
import '../../../services/cloud_data_service.dart';
import '../../../services/profile_image_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/screen_with_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersNotifications = true;

  /// True while a cloud wipe is in flight, so the action can show progress.
  bool _isDeletingCloudData = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    /// Load the saved profile picture for the profile section
    ProfileImageService.instance.loadProfileImage();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersNotifications = prefs.getBool('reminders_notifications') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_notifications', value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.firebaseUser;

    return ScreenWithNavBar(
      currentIndex: 4, // Settings is index 4 in nav bar
      child: Scaffold(
        body: Column(
        children: [
          _buildHeaderWithBackground(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSettingsData,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(currentUser, authProvider),
                    const SizedBox(height: 24),
                    _buildNotificationsSection(),
                    const SizedBox(height: 24),
                    const BackupButtonWidget(),
                    const SizedBox(height: 24),
                    _buildCloudDataSection(),
                    const SizedBox(height: 24),
                    _buildAppAppearanceSection(),
                    const SizedBox(height: 24),
                    _buildAboutSupportSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
      decoration: AppTheme.glowCardDecoration(radius: 16),
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
              // Profile picture — shares ProfileImageService with the profile
              // and home screens, so it stays in sync automatically.
              ProfileAvatar(
                name: authProvider.appUser?.fullName ??
                    currentUser?.email?.split('@').first ??
                    'User',
                size: 60,
                onTap: _editProfile,
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
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildSettingsActionButton(
                  label: 'Change PIN',
                  icon: Icons.lock_reset,
                  onPressed: _changePin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettingsActionButton(
                  label: 'Sign Out',
                  icon: Icons.logout,
                  accent: AppTheme.errorColor,
                  onPressed: _signOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCardDecoration(radius: 16),
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
            'Reminders Notifications',
            'Get notified when reminders become overdue',
            _remindersNotifications,
            (value) async {
              setState(() => _remindersNotifications = value);
              // Save preference to shared preferences
              await _saveNotificationPreference(value);
            },
          ),
          
        ],
      ),
    );
  }


  /// Cloud data management — currently the "delete everything from the cloud"
  /// action. Kept visually distinct (red accent) because it is destructive.
  Widget _buildCloudDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cloud Data',
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
          Text(
            'Remove your data from the cloud. Records on this device are kept.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _buildSettingsActionButton(
              label: _isDeletingCloudData
                  ? 'Deleting...'
                  : 'Delete All Cloud Data',
              icon: Icons.cloud_off,
              accent: AppDialog.destructive,
              onPressed: _isDeletingCloudData ? null : _deleteAllCloudData,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllCloudData() async {
    HapticFeedback.lightImpact();

    final confirmed = await AppDialog.show(
      context,
      title: 'Delete All Cloud Data?',
      message:
          'This permanently removes every backup from the cloud — cars, reminders, '
          'maintenance, mileage, licenses and scans.\n\n'
          'Data on this device is NOT deleted. This cannot be undone.',
      icon: Icons.cloud_off,
      confirmLabel: 'Delete',
      isDestructive: true,
      barrierDismissible: false,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingCloudData = true);
    final result = await CloudDataService.instance.deleteAllCloudData();
    if (!mounted) return;
    setState(() => _isDeletingCloudData = false);

    _showMessage(result.message);
  }

  Widget _buildAboutSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCardDecoration(radius: 16),
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

  void _changePin() async {
    HapticFeedback.lightImpact();
    
    // Import the PIN setup screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(isChangingPin: true),
      ),
    );
    
    if (result == true && mounted) {
      AppSnackbar.show(context, 
        const SnackBar(
          content: Text(
            'PIN changed successfully',
            style: TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  /// Pill action button matching the app's glow language.
  Widget _buildSettingsActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? accent,
  }) {
    // A null callback renders the button dimmed and inert (used while a
    // long-running action such as the cloud wipe is in flight).
    final base = accent ?? AppTheme.secondaryGreen;
    final color = onPressed == null ? base.withOpacity(0.45) : base;
    return Container(
      decoration: AppTheme.glowButtonDecoration(accent: color),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    HapticFeedback.lightImpact();

    final confirmed = await AppDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your account?',
      icon: Icons.logout,
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    // Captured before the await so we never touch an unmounted context.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    final success = await authProvider.signOut();
    if (!mounted) return;

    if (!success) {
      _showMessage('Could not sign out. Please try again.');
      return;
    }

    // Settings was pushed on top of the auth wrapper, so signing out alone
    // leaves the user staring at this screen. Unwinding to the first route
    // reveals the wrapper, which now has no user and renders the sign-in
    // screen.
    navigator.popUntil((route) => route.isFirst);
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
      decoration: AppTheme.glowCardDecoration(radius: 16),
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSwitchTile(
                'Dark Mode',
                'Toggle between light and dark theme',
                themeProvider.isDarkMode,
                (value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOldAppAppearanceSection() {
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

  Future<void> _sendVerificationEmail() async {
    HapticFeedback.lightImpact();

    final confirmed = await AppDialog.show(
      context,
      title: 'Verify Email',
      message:
          'We\'ll send a verification email to your registered email address. Please check your inbox and click the verification link.',
      icon: Icons.mark_email_unread_outlined,
      confirmLabel: 'Send Email',
    );

    if (confirmed != true || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendEmailVerification();
    if (!mounted) return;

    _showMessage(success
        ? 'Verification email sent! Check your inbox.'
        : 'Failed to send verification email. Please try again.');
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

  /// Refreshes all data on the settings screen
  Future<void> _refreshSettingsData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.reloadUser();
    if (mounted) {
      setState(() {}); // Refresh the UI
    }
  }
}