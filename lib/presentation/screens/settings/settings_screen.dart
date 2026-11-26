import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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

  // Settings palette: NO green accents on this page. Labels/headers use the
  // app's yellow (costHighlight), values are white, destructive is red. The
  // dark surfaces/rims stay (app identity) but rims are tinted yellow.
  static const Color _label = AppTheme.costHighlight; // yellow
  static const Color _value = Colors.white;
  static const Color _destructive = AppTheme.errorColor; // red

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();

    /// Load the saved profile picture for the profile section
    ProfileImageService.instance.loadProfileImage();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
        backgroundColor: AppTheme.backgroundGreen,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshSettingsData,
                color: AppTheme.costHighlight,
                backgroundColor: AppTheme.backgroundGreen,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(currentUser, authProvider),
                      _sectionHeader('Account'),
                      _insetGroup([
                        _navRow(
                          badge: AppTheme.infoBlue,
                          icon: CupertinoIcons.lock_rotation,
                          label: 'Change PIN',
                          onTap: _changePin,
                        ),
                      ]),
                      _sectionHeader('Preferences'),
                      _insetGroup([
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return _switchRow(
                              badge: AppTheme.costHighlight,
                              icon: CupertinoIcons.moon_fill,
                              label: 'Dark Mode',
                              subtitle: 'Switch between light and dark theme',
                              value: themeProvider.isDarkMode,
                              onChanged: (_) => themeProvider.toggleTheme(),
                            );
                          },
                        ),
                      ]),
                      _sectionHeader('Notifications'),
                      _insetGroup([
                        _switchRow(
                          badge: AppTheme.infoBlue,
                          icon: CupertinoIcons.bell_fill,
                          label: 'Reminders',
                          subtitle: 'Get notified when reminders become overdue',
                          value: _remindersNotifications,
                          onChanged: (value) async {
                            setState(() => _remindersNotifications = value);
                            await _saveNotificationPreference(value);
                          },
                        ),
                      ]),
                      _sectionHeader('Data & Backup'),
                      const BackupButtonWidget(),
                      const SizedBox(height: 12),
                      _insetGroup([
                        _navRow(
                          badge: _destructive,
                          icon: CupertinoIcons.cloud_fill,
                          label: _isDeletingCloudData
                              ? 'Deleting…'
                              : 'Delete All Cloud Data',
                          destructive: true,
                          trailing: _isDeletingCloudData
                              ? const CupertinoActivityIndicator(
                                  color: _destructive)
                              : null,
                          onTap:
                              _isDeletingCloudData ? null : _deleteAllCloudData,
                        ),
                      ]),
                      _sectionFooter(
                          'Removes your data from the cloud. Records on this device are kept.'),
                      _sectionHeader('Support & About'),
                      _insetGroup([
                        _navRow(
                          badge: AppTheme.infoBlue,
                          icon: CupertinoIcons.question_circle_fill,
                          label: 'Help & FAQ',
                          onTap: () => _push(const HelpScreen()),
                        ),
                        _navRow(
                          badge: AppTheme.costHighlight,
                          icon: CupertinoIcons.info_circle_fill,
                          label: 'About Siyanaty+',
                          onTap: () => _push(const AboutScreen()),
                        ),
                        _navRow(
                          badge: AppTheme.infoBlue,
                          icon: CupertinoIcons.lock_shield_fill,
                          label: 'Privacy Policy',
                          onTap: () => _push(const PrivacyScreen()),
                        ),
                        _navRow(
                          badge: AppTheme.costHighlight,
                          icon: CupertinoIcons.doc_text_fill,
                          label: 'Terms of Service',
                          onTap: () => _push(const TermsScreen()),
                        ),
                        _navRow(
                          badge: AppTheme.infoBlue,
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          label: 'Contact Support',
                          onTap: _contactSupport,
                        ),
                        _navRow(
                          badge: AppTheme.costHighlight,
                          icon: CupertinoIcons.star_fill,
                          label: 'Rate Our App',
                          onTap: _rateApp,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _insetGroup([
                        _navRow(
                          badge: _destructive,
                          icon: CupertinoIcons.square_arrow_right,
                          label: 'Sign Out',
                          destructive: true,
                          showChevron: false,
                          onTap: _signOut,
                        ),
                      ]),
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

  // ---------------------------------------------------------------------------
  // Header & profile
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
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

  Widget _buildProfileCard(dynamic currentUser, AuthProvider authProvider) {
    final name = authProvider.appUser?.fullName ??
        currentUser?.email?.split('@').first ??
        'User';
    final email = currentUser?.email ?? 'No email';

    return Semantics(
      button: true,
      label: 'Open profile for $name',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _editProfile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration:
                AppTheme.glowCardDecoration(radius: 16, accent: _label),
            child: Row(
              children: [
                ProfileAvatar(name: name, size: 56, onTap: _editProfile),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _value,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: _value.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.chevron_forward,
                    color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // iOS inset-grouped building blocks
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: _label,
          fontFamily: 'Orbitron',
        ),
      ),
    );
  }

  Widget _sectionFooter(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          color: _value.withOpacity(0.55),
          fontFamily: 'Orbitron',
        ),
      ),
    );
  }

  /// A rounded inset card holding [rows], with hairline separators between
  /// them (indented past the icon badge, iOS-style).
  Widget _insetGroup(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Divider(
                height: 1, thickness: 1, color: Colors.white.withOpacity(0.08)),
          ),
        );
      }
    }
    return Container(
      decoration: AppTheme.glowCardDecoration(radius: 16, accent: _label),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }

  Widget _navRow({
    required Color badge,
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
    bool destructive = false,
    bool showChevron = true,
    Widget? trailing,
  }) {
    final labelColor = destructive ? _destructive : _label;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                _iconBadge(icon, badge),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
                if (value != null)
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _value,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ] else if (showChevron && !destructive) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_forward,
                      color: Colors.white38, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchRow({
    required Color badge,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _iconBadge(icon, badge),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _label,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: _value.withOpacity(0.7),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: label,
            toggled: value,
            child: CupertinoSwitch(
              value: value,
              activeColor: AppTheme.costHighlight, // yellow track, never green
              onChanged: (v) {
                HapticFeedback.lightImpact();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions (behaviour unchanged)
  // ---------------------------------------------------------------------------

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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

  void _editProfile() {
    HapticFeedback.lightImpact();
    _push(const ProfileScreen());
  }

  void _changePin() async {
    HapticFeedback.lightImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(isChangingPin: true),
      ),
    );

    if (result == true && mounted) {
      _showMessage('PIN changed successfully');
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.mediumImpact();

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

  void _showMessage(String message) {
    NotificationService.instance.showInfoNotification(
      context,
      message: message,
    );
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
