import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/profile_avatar.dart';
import '../../../services/car_service.dart';
import '../../../services/reminder_service.dart';
import '../../../services/maintenance_service.dart';
import '../../../services/profile_image_service.dart';

/// iOS-style Profile screen: a collapsing large title, a header with the avatar,
/// name (white) and email (white), inset grouped sections (yellow labels, white
/// values), and a destructive Sign Out group at the bottom. There is no green
/// text anywhere — labels use [AppTheme.lightBackground] (the app yellow),
/// values are white. All sizing is responsive (no fixed widths) so it never
/// overflows on small screens or at large text scales.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSigningOut = false;

  // Services for fetching real data
  final CarService _carService = CarService();
  final ReminderService _reminderService = ReminderService();
  final MaintenanceService _maintenanceService = MaintenanceService();
  final ProfileImageService _profileImageService = ProfileImageService.instance;

  // Real data counts
  int _vehicleCount = 0;
  int _reminderCount = 0;
  int _maintenanceCount = 0;
  bool _countsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCounts();
    _profileImageService.loadProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.firebaseUser;
    final appUser = authProvider.appUser;

    if (user != null) {
      _nameController.text = appUser?.fullName ?? user.displayName ?? '';
      _phoneController.text = appUser?.phoneNumber ?? '';

      // Load emergency contact data
      final emergencyName = appUser?.emergencyContactName ?? '';
      final emergencyPhone = appUser?.emergencyContactPhone ?? '';
      if (emergencyName.isNotEmpty && emergencyPhone.isNotEmpty) {
        _emergencyContactController.text = '$emergencyName - $emergencyPhone';
      } else {
        _emergencyContactController.text = '';
      }
    }
  }

  Future<void> _loadCounts() async {
    try {
      final vehicleCount = await _carService.getCarsCount();
      final reminderCount = await _reminderService.getRemindersCount();
      final maintenanceCount = await _maintenanceService.getMaintenanceCount();

      if (mounted) {
        setState(() {
          _vehicleCount = vehicleCount;
          _reminderCount = reminderCount;
          _maintenanceCount = maintenanceCount;
          _countsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _countsLoading = false;
        });
      }
    }
  }

  void _startEditing() {
    HapticFeedback.lightImpact();
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    HapticFeedback.lightImpact();
    _loadUserData(); // discard unsaved edits
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final updates = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      // Parse emergency contact data ("Name - Phone")
      final emergencyText = _emergencyContactController.text.trim();
      if (emergencyText.isNotEmpty) {
        final parts = emergencyText.split(' - ');
        if (parts.length == 2) {
          updates['emergencyContactName'] = parts[0].trim();
          updates['emergencyContactPhone'] = parts[1].trim();
        }
      }

      final success = await authProvider.updateProfile(updates);
      if (!mounted) return;

      if (success) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        _showMessage('Profile updated successfully!');
        HapticFeedback.lightImpact();
      } else {
        setState(() => _isLoading = false);
        _showMessage('Failed to update profile. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Failed to update profile. Please try again.');
    }
  }

  void _showMessage(String message) {
    AppSnackbar.show(
      context,
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Bottom sheet offering camera / gallery / remove for the profile picture.
  void _showImageSourceSheet() {
    HapticFeedback.lightImpact();
    final hasImage = _profileImageService.currentPath != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: AppTheme.glowCardDecoration(radius: 24, elevated: true),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.secondaryGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Profile Picture',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightBackground,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 18),
            _buildSheetAction(
              icon: CupertinoIcons.camera,
              label: 'Take a photo',
              onTap: () {
                Navigator.pop(sheetContext);
                _updateProfileImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _buildSheetAction(
              icon: CupertinoIcons.photo,
              label: 'Choose from gallery',
              onTap: () {
                Navigator.pop(sheetContext);
                _updateProfileImage(ImageSource.gallery);
              },
            ),
            if (hasImage) ...[
              const SizedBox(height: 10),
              _buildSheetAction(
                icon: CupertinoIcons.trash,
                label: 'Remove photo',
                accent: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeProfileImage();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final color = accent ?? AppTheme.lightBackground;
    return Container(
      decoration: AppTheme.glowButtonDecoration(accent: color, radius: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Future<void> _updateProfileImage(ImageSource source) async {
    final result = await _profileImageService.pickAndSaveImage(source);
    if (!mounted) return;
    if (!result.isSuccess && result.message == 'No image selected') return;
    _showMessage(result.message);
  }

  Future<void> _removeProfileImage() async {
    final result = await _profileImageService.removeProfileImage();
    if (!mounted) return;
    _showMessage(result.message);
  }

  Future<void> _confirmSignOut() async {
    HapticFeedback.mediumImpact();

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Sign out of Siyanaty Plus?'),
        content: const Text(
          '\nYou will need to sign in again, and set a new PIN on this device.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);

    // Captured before the await so we never touch an unmounted context.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    final success = await authProvider.signOut(); // signs out Firebase + Google, clears PIN + data
    if (!mounted) return;

    if (!success) {
      setState(() => _isSigningOut = false);
      _showMessage('Could not sign out. Please try again.');
      return;
    }

    // Unwind to the root so SecurityWrapper (now without a user) shows Sign In.
    // Back cannot return into the app afterwards.
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.firebaseUser;
    final appUser = authProvider.appUser;

    final width = MediaQuery.sizeOf(context).width;
    final avatarSize = (width * 0.26).clamp(72.0, 116.0).toDouble();
    final displayName = appUser?.fullName ?? user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      bottomNavigationBar: BottomNavBar(currentIndex: 4, onTap: (i) {}),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: _buildHeaderCard(displayName, email, avatarSize),
          ),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(
            child: _buildSection('Personal Information', [
              _buildInfoRow(
                icon: CupertinoIcons.person,
                label: 'Full Name',
                controller: _nameController,
              ),
              _buildInfoRow(
                icon: CupertinoIcons.phone,
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: _buildSection('Account', [
              _buildInfoRow(
                icon: CupertinoIcons.mail,
                label: 'Email Address',
                value: email,
                editable: false,
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: _buildSection('Emergency Contact', [
              _buildInfoRow(
                icon: CupertinoIcons.exclamationmark_shield,
                label: 'Emergency Contact',
                controller: _emergencyContactController,
                hint: 'Name - Phone',
                maxLines: 2,
              ),
            ]),
          ),
          SliverToBoxAdapter(child: _buildSignOutSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              tooltip: 'Back',
              icon: const Icon(CupertinoIcons.back,
                  color: AppTheme.lightBackground),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      expandedHeight: 104,
      collapsedHeight: 56,
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(start: 20, bottom: 14),
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: AppTheme.lightBackground,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String displayName, String email, double avatarSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glowCardDecoration(radius: 20, elevated: true),
        child: Column(
          children: [
            ProfileAvatar(
              name: displayName,
              size: avatarSize,
              showEditBadge: true,
              onTap: _showImageSourceSheet,
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.72),
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
            const SizedBox(height: 18),
            _buildEditButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    if (!_isEditing) {
      return GradientButton(
        label: 'Edit Profile',
        icon: CupertinoIcons.pencil,
        onPressed: _startEditing,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _secondaryButton(
            label: 'Cancel',
            onPressed: _isLoading ? null : _cancelEditing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GradientButton(
            label: 'Save',
            icon: CupertinoIcons.check_mark,
            isLoading: _isLoading,
            onPressed: _saveChanges,
          ),
        ),
      ],
    );
  }

  /// A quiet, non-gradient secondary button (yellow outline + yellow label).
  Widget _secondaryButton({required String label, VoidCallback? onPressed}) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed();
              }
            : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.backgroundGreen.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightBackground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: AppTheme.glowCardDecoration(radius: 16),
        child: Row(
          children: [
            _buildStat('Cars', _vehicleCount),
            _statDivider(),
            _buildStat('Maintenance', _maintenanceCount),
            _statDivider(),
            _buildStat('Reminders', _reminderCount),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 34,
        color: AppTheme.lightBackground.withOpacity(0.15),
      );

  Widget _buildStat(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _countsLoading ? '—' : '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white, // value → white (was green)
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.lightBackground, // label → yellow
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 62),
          child: Container(
            height: 1,
            color: AppTheme.lightBackground.withOpacity(0.08),
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.lightBackground, // section header → yellow
                letterSpacing: 0.6,
              ),
            ),
          ),
          Container(
            decoration: AppTheme.glowCardDecoration(radius: 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    TextEditingController? controller,
    String? value,
    bool editable = true,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final editing = _isEditing && editable && controller != null;
    final display = (controller?.text ?? value ?? '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightBackground, // label → yellow
                  ),
                ),
                const SizedBox(height: 4),
                if (editing)
                  TextField(
                    controller: controller,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    cursorColor: AppTheme.lightBackground,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 15.5,
                      color: Colors.white, // value → white
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 6),
                      hintText: hint ?? 'Enter $label',
                      hintStyle: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.lightBackground.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppTheme.lightBackground),
                      ),
                    ),
                  )
                else
                  Text(
                    display.isEmpty ? 'Not set' : display,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 15.5,
                      color: display.isEmpty
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white, // value → white
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.lightBackground.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.lightBackground, size: 19),
    );
  }

  Widget _buildSignOutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: GestureDetector(
        onTap: _isSigningOut ? null : _confirmSignOut,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          alignment: Alignment.center,
          decoration:
              AppTheme.glowCardDecoration(radius: 16, accent: AppTheme.errorColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _isSigningOut
              ? const CupertinoActivityIndicator(color: CupertinoColors.destructiveRed)
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.square_arrow_right,
                      color: CupertinoColors.destructiveRed,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
