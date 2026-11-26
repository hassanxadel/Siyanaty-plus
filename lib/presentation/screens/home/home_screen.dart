import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../providers/auth_provider.dart';
import '../actions/all_actions_screen.dart';
import '../../actions/app_action.dart';
import '../services/cars_screen.dart';
import '../services/vin_lookup_screen.dart';
import '../services/ocr_scanner_screen.dart';
import '../health/car_health_dashboard_screen.dart';
import '../services/voice_notes_screen.dart';
import '../services/mileage_track_screen.dart';
import '../services/reminders_screen.dart';
import '../services/obd_screen.dart';
import '../services/services_screen.dart';
import '../services/maintenance_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import 'license_screen.dart';
import '../../../services/car_service.dart';
import '../../../services/car_health_service.dart';
import '../../../models/car_health_score.dart';
import '../../../models/backup_car.dart';
import '../../../services/reminder_service.dart';
import '../../../services/maintenance_service.dart';
import '../../../services/notification_database_service.dart';
import '../../../models/backup_reminder.dart';
import '../../../models/backup_maintenance.dart';
import '../../widgets/license_pin_sheet.dart';
import '../../widgets/reminder_done_button.dart';
import '../../../shared/utils/reminder_urgency.dart';
import '../../../services/profile_image_service.dart';
import '../../../shared/utils/string_extensions.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/car_assistant_sheet.dart';

/// Main dashboard screen that serves as the home page
/// Displays user welcome, quick actions, and vehicle overview
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

/// State class for the home dashboard
/// Manages animations, car selection, and user interactions
class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Controller for managing entrance animations (fade and slide)
  late AnimationController _animationController;
  /// Slow controller driving the Reminders card's "live" glow. One controller,
  /// disposed in [dispose]; paused when reduce-motion is on.
  late final AnimationController _glowController;
  /// Fade animation for smooth screen entrance
  late Animation<double> _fadeAnimation;
  /// Slide animation for content movement
  late Animation<Offset> _slideAnimation;
  /// Controller for horizontal car selection carousel
  final PageController _carPageController = PageController();
  /// Index of currently selected vehicle
  int _currentCarIndex = 0;
  /// Inline "Ask Siyanaty AI" input; opens the full chat sheet on send.
  final TextEditingController _aiInput = TextEditingController();
  /// Car service for fetching real car data
  final CarService _carService = CarService();
  /// Car health service for calculating health scores
  final CarHealthService _carHealthService = CarHealthService();
  /// Reminder service for fetching reminders data
  final ReminderService _reminderService = ReminderService();
  /// Maintenance service for fetching maintenance data
  final MaintenanceService _maintenanceService = MaintenanceService();
  /// Notification database service for checking notification count
  final NotificationDatabaseService _notificationService = NotificationDatabaseService.instance;
  /// Count of unread notifications for badge
  int _notificationCount = 0;
  /// List of user's cars (max 5 for swipe)
  List<BackupCar> _userCars = [];
  /// Loading state for cars
  bool _carsLoading = true;
  /// Map of car health scores by car ID
  final Map<int, CarHealthScore> _carHealthScores = {};
  /// List of upcoming reminders (max 3)
  List<ReminderWithCarInfo> _upcomingReminders = [];
  /// Loading state for reminders
  bool _remindersLoading = true;
  /// List of latest maintenance records (max 3)
  List<MaintenanceWithInfo> _latestMaintenance = [];
  /// Loading state for maintenance
  bool _maintenanceLoading = true;
  /// Total paid across ALL maintenance records (the real total, not just the
  /// three shown), from the same source as the Maintenance screen.
  double _totalMaintenanceCost = 0.0;
  /// Reminder ids being completed right now — blocks double taps.
  final Set<int> _completingReminderIds = {};

  /// Initialize animation controllers and start entrance animations
  @override
  void initState() {
    super.initState();
    /// Create animation controller with 1.2 second duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    /// Configure fade animation for smooth opacity transition
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    /// Configure slide animation for content movement
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    /// Start the entrance animations
    _animationController.forward();

    /// Slow pulse for the Reminders "live" border glow.
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
    /// Load user's cars
    _loadUserCars();
    /// Load upcoming reminders
    _loadUpcomingReminders();
    /// Load latest maintenance
    _loadLatestMaintenance();
    /// Load notification count
    _loadNotificationCount();
    /// Load the saved profile picture for the greeting card
    ProfileImageService.instance.loadProfileImage();

    /// Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh notification count when app becomes active
      _loadNotificationCount();
    }
  }

  /// Clean up animation controllers and page controller
  @override
  void dispose() {
    /// Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _glowController.dispose();
    _carPageController.dispose();
    _aiInput.dispose();
    super.dispose();
  }

  /// Load user's cars from database (max 5 for swipe functionality)
  Future<void> _loadUserCars() async {
    try {
      final cars = await _carService.getAllCars();
      if (mounted) {
        setState(() {
          // Take maximum 5 cars for swipe functionality
          _userCars = cars.take(5).toList();
          _carsLoading = false;
          // Reset current index if needed
          if (_currentCarIndex >= _userCars.length && _userCars.isNotEmpty) {
            _currentCarIndex = 0;
          }
        });
        
        // Calculate health scores for all loaded cars
        // Uses the same CarHealthService.calculateHealthScore() as Car Health Dashboard
        // This ensures consistency between home screen and health dashboard displays
        for (var car in _userCars) {
          if (car.id != null) {
            try {
              final healthScore = await _carHealthService.calculateHealthScore(car);
              if (mounted) {
                setState(() {
                  _carHealthScores[car.id!] = healthScore;
                });
              }
            } catch (e) {
              print('[HomeScreen] Error calculating health score for car ${car.id}: $e');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carsLoading = false;
        });
      }
    }
  }

  /// Load upcoming reminders from database (max 3)
  Future<void> _loadUpcomingReminders() async {
    try {
      final reminders = await _reminderService.getAllRemindersWithCarInfo();
      if (mounted) {
        setState(() {
          // Filter upcoming reminders and take max 3
          // Keep ALL upcoming reminders; the section filters to the selected
          // car and caps the display, so swiping updates the list correctly.
          _upcomingReminders = reminders
              .where((r) => r.reminder.status == ReminderStatus.upcoming)
              .toList();
          _remindersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _remindersLoading = false;
        });
      }
    }
  }

  /// Load latest maintenance records from database (max 3)
  Future<void> _loadLatestMaintenance() async {
    try {
      final maintenance = await _maintenanceService.getAllMaintenanceWithInfo();
      final total = await _maintenanceService.getTotalMaintenanceCost();
      if (mounted) {
        setState(() {
          // Take latest 3 maintenance records
          _latestMaintenance = maintenance.take(3).toList();
          _totalMaintenanceCost = total;
          _maintenanceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _maintenanceLoading = false;
        });
      }
    }
  }

  /// Load notification count for badge
  Future<void> _loadNotificationCount() async {
    try {
      // Badge reflects UNREAD notifications, in sync with the Notifications screen.
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationCount = 0;
        });
      }
    }
  }

  /// Refreshes all data on the home screen
  Future<void> _refreshHomeData() async {
    await Future.wait([
      _loadUserCars(),
      _loadUpcomingReminders(),
      _loadLatestMaintenance(),
      _loadNotificationCount(),
    ]);
  }

  /// Get time-based greeting message (Morning, Afternoon, Evening)
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Extract user's full name from AppUser data
  /// Falls back to email username if full name is not available
  String _getUserName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appUser = authProvider.appUser;
    if (appUser?.fullName != null && appUser!.fullName.isNotEmpty) {
      return appUser.fullName;
    }
    final user = authProvider.firebaseUser;
    if (user?.email != null) {
      return user!.email!.split('@').first.split('.').first;
    }
    return 'User';
  }

  /// Build the main dashboard layout with animations and content
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Respect user text scaling, but cap it so large accessibility text can
    // never overflow a card on a small screen.
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Pull-to-refresh reloads cars, reminders and maintenance.
                CupertinoSliverRefreshControl(onRefresh: _refreshHomeData),
                // Top bar + greeting (unchanged).
                SliverToBoxAdapter(child: _buildHeaderWithBackground()),
                SliverToBoxAdapter(
                  child: Padding(
                    // One horizontal margin for EVERY section → aligned edges.
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCarHero(), // the one and only car section
                        const SizedBox(height: 16),
                        _buildUpcomingRemindersSection(), // most important
                        const SizedBox(height: 16),
                        _buildActionsSection(),
                        const SizedBox(height: 16),
                        _buildLatestMaintenanceSection(),
                        const SizedBox(height: 16),
                        _buildServiceRecommendations(),
                      ],
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

  // Header with gradient background design inspired by the money transfer app
  Widget _buildHeaderWithBackground() {
    return Container(
      // No fixed height — the header hugs its content so there's no dead green
      // space below the greeting card.
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row with logo, notification, and profile
              Row(
                children: [
                  // Logo 
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35, // Reduced size to save space
                    height: 75,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),

                  // Circular notification and profile buttons
                  Row(
                    children: [
                    
                     //  Notifications - circular
                      _buildCircularIcon(
                        Icons.notifications_outlined,
                            () => _showNotifications(),
                        badgeCount: _notificationCount,
                        color: AppTheme.lightBackground,
                      ),
                      const SizedBox(width: 8),
                      //  Profile - circular
                      _buildCircularIcon(
                        Icons.person_outline,
                            () => _showProfile(),
                            color: AppTheme.lightBackground,
                      ),
                    ],
                  ),
                ],
              ),

                            const SizedBox(height: 20),
              
              // Floating greeting section (plain child: the column now shrink-wraps).
              _buildFloatingGreeting(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIcon(IconData icon, VoidCallback onTap, {int badgeCount = 0, Color? color}) {
    final iconColor = color ?? AppTheme.getThemeAwareIconColor(context);

    // The decoration lives on an outer Container, NOT on an Ink: Ink paints
    // into the parent Material's ink layer, which is clipped to the Material's
    // bounds, so a glow wider than the button gets cut into a hard square.
    // Material here only hosts the ripple.
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        shape: BoxShape.circle,
        // Rim keeps the button readable against the dark header gradient
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.4),
            blurRadius: 22,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: AppTheme.secondaryGreen.withOpacity(0.25),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              // Unread-count badge: a number, not a dot; hidden entirely at 0.
              if (badgeCount > 0)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppTheme.backgroundGreen,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingGreeting() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
          ),        ],
      ),
      child: Row(
        children: [
          // Profile picture, kept small so it reads as an accent next to the
          // name rather than dominating the greeting card.
          ProfileAvatar(
            name: _getUserName(),
            size: 48,
            onTap: _showProfile,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _getUserName(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 
  static const Color _accent = AppTheme.primaryGreen;

  /// The one reusable section component. Every titled section uses this, which
  /// is what makes the page consistent: one surface, one padding, one header
  /// style, and a plain-text `label ›` action (no pill background).
  Widget _sectionCard({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
    Widget? titleBadge,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glowCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightBackground, // "the yellow color"
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                    if (titleBadge != null) ...[
                      const SizedBox(width: 8),
                      titleBadge,
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                Semantics(
                  button: true,
                  label: actionLabel,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onAction();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        // 11+11+~22 text ≈ 44pt tap target.
                        padding: const EdgeInsets.symmetric(
                            vertical: 11, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.lightBackground,
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(CupertinoIcons.chevron_right,
                                size: 15, color: AppTheme.lightBackground),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // --- Car hero (replaces "Manage your vehicle") -----------------------------

  /// Dark panel with a thin `lightBackground` (yellow) border — the car card
  /// look, now from the one shared source so the Cars list and the All Actions
  /// cards stay identical to it.
  BoxDecoration _heroDecoration() => AppTheme.carCardDecoration();

  Widget _buildCarHero() {
    if (_carsLoading) {
      return Container(
        height: 136,
        decoration: _heroDecoration(),
        child: const Center(
            child: CupertinoActivityIndicator(color: Colors.white)),
      );
    }
    if (_userCars.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _heroDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.car_detailed,
                size: 40, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 10),
            const Text('No cars yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron')),
            const SizedBox(height: 14),
            // Standard app button: gradient fill + yellow frame + glow.
            Semantics(
              button: true,
              label: 'Add your first car',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _navigateToCarsList();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: AppTheme.primaryButtonDecoration(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Add your first car',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Carousel height derived from available width and clamped — never a magic
    // number that can overflow a small screen.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Floor raised to 136 so the three single-line rows (~108px) always
        // clear the width-derived height (fixes the 0.213px bottom overflow).
        final cardH = (constraints.maxWidth * 0.34).clamp(136.0, 160.0);
        return Column(
          children: [
            SizedBox(
              height: cardH,
              child: PageView.builder(
                controller: _carPageController,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentCarIndex = i);
                },
                itemCount: _userCars.length,
                itemBuilder: (context, i) => _buildHeroCard(_userCars[i]),
              ),
            ),
            if (_userCars.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_userCars.length, (i) {
                  final active = _currentCarIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color:
                          active ? AppTheme.lightBackground : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _heroLink(String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightBackground,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron')),
                const SizedBox(width: 2),
                const Icon(CupertinoIcons.chevron_right,
                    size: 14, color: AppTheme.lightBackground),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BackupCar car) {
    final score = car.id != null ? _carHealthScores[car.id] : null;
    final status = score?.healthStatus ?? 'unknown';
    final healthColor = Color(CarHealthScore.getHealthColor(status));
    final healthLabel = CarHealthScore.getHealthStatusDisplay(status);
    final hasImage = car.imagePath != null &&
        car.imagePath!.isNotEmpty &&
        File(car.imagePath!).existsSync();

    void openDetails() {
      HapticFeedback.lightImpact();
      _showCarDetailsDialog(car);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: _heroDecoration(),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image (tap → details); square, sized to the card height.
            GestureDetector(
              onTap: openDetails,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? Image.file(File(car.imagePath!), fit: BoxFit.cover)
                      : Container(
                          color: Colors.white.withOpacity(0.06),
                          child: Icon(CupertinoIcons.car_detailed,
                              size: 32, color: Colors.white.withOpacity(0.5)),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (left) + View all at the top-right of the card.
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: openDetails,
                          child: Text(
                            '${car.brand} ${car.model}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Orbitron'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _heroLink('View all', _navigateToCarsList),
                    ],
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: openDetails,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${car.year} · ${_formatMileage(car.mileage)} km',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                            fontFamily: 'Orbitron'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Health (left) + License on the SAME row, under View all.
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: healthColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          score != null
                              ? '$healthLabel · ${score.overallScore.round()}'
                              : 'Health —',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: healthColor,
                              fontFamily: 'Orbitron'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _heroLink('License', _navigateToLicense),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `84,250` style grouping.
  String _formatMileage(num mileage) =>
      NumberFormat('#,###').format(mileage.round());

  /// `EGP 12,500` — consistent currency + thousands separators.
  String _formatCost(num cost) =>
      'EGP ${NumberFormat('#,##0').format(cost.round())}';

  Widget _rowDivider() => Divider(
      height: 1, thickness: 1, color: Colors.white.withOpacity(0.08));

  Widget _emptyRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Orbitron')),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(int index) {
    if (_carsLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkAccentGreen,
              AppTheme.backgroundGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_userCars.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkAccentGreen,
              AppTheme.backgroundGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-40, 0),
              child: const Icon(
                IconData(0xe800, fontFamily: 'MyFlutterApp'),
                size: 48,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: double.infinity,
              child: Text(
                'No Cars Added',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: double.infinity,
              child: Text(
                'Tap + to add your first car',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final car = _userCars[index];
    
    // Get real health score from CarHealthService
    // This matches the score shown in Car Health Dashboard screen
    final healthScore = _carHealthScores[car.id];
    final health = healthScore != null ? healthScore.overallScore / 100 : 0.5;
    final healthLabel = healthScore != null ? healthScore.healthStatus : 'Unknown';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Car Image
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.darkAccentGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: car.imagePath != null && car.imagePath!.isNotEmpty
                      ? Image.file(
                          File(car.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              IconData(0xe800, fontFamily: 'MyFlutterApp'),
                              size: 40,
                              color: Colors.white,
                            );
                          },
                        )
                      : const Icon(
                          IconData(0xe800, fontFamily: 'MyFlutterApp'),
                          size: 40,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.brand} ${car.model}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${car.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
              // Mileage badge styled as a digital odometer chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.backgroundGreen, AppTheme.darkAccentGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.secondaryGreen.withOpacity(0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryGreen.withOpacity(0.3),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 12,
                      color: AppTheme.secondaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${car.mileage.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightBackground,
                        fontFamily: 'Orbitron',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Vehicle Health
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vehicle Health',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  Text(
                    '${(health * 100).toInt()}% ${healthLabel.capitalize()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: health,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    health > 0.7 ? Colors.green : health > 0.4 ? Colors.orange : Colors.red,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              _buildCarActionButton(
                Icons.credit_card,
                'License',
                () => _navigateToLicense(),
              ),
              _buildCarActionButton(
                Icons.info_outline,
                'Details',
                () => _showCarDetailsDialog(car),
              ),
              _buildCarActionButton(
                Icons.speed,
                'Mileage',
                () => _navigateToMileageTrack(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.secondaryGreen.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGreen.withOpacity(0.3),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.secondaryGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarIndicators() {
    if (_userCars.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _userCars.length > 5 ? 5 : _userCars.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentCarIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // Reminders — the most important section. Filtered to the shown car, with a
  // tasteful animated yellow glow border (the one "live" effect on the page).
  Widget _buildUpcomingRemindersSection() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    // Pause the controller under reduce-motion; resume otherwise.
    if (reduceMotion) {
      if (_glowController.isAnimating) _glowController.stop();
    } else if (!_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }

    final selectedCarId =
        (_userCars.isNotEmpty && _currentCarIndex < _userCars.length)
            ? _userCars[_currentCarIndex].id
            : null;
    final list = selectedCarId == null
        ? _upcomingReminders
        : _upcomingReminders
            .where((r) => r.reminder.carId == selectedCarId)
            .toList();
    final shown = list.take(3).toList();

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reminders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightBackground,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              _heroLink('View all', _navigateToReminders),
            ],
          ),
          const SizedBox(height: 12),
          if (_remindersLoading)
            const Padding(
                padding: EdgeInsets.all(8),
                child: CupertinoActivityIndicator(color: Colors.white))
          else if (shown.isEmpty)
            _emptyRow(CupertinoIcons.bell, 'No upcoming reminders')
          else
            // AnimatedSize collapses smoothly when a reminder is completed.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    _buildReminderItem(shown[i]),
                    if (i != shown.length - 1) _rowDivider(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    // RepaintBoundary isolates the per-frame glow repaint from the rest of the
    // page; the content is passed as a non-rebuilding `child`.
    return RepaintBoundary(
      child: reduceMotion
          ? _remindersGlow(content, 1.0) // static highlight
          : AnimatedBuilder(
              animation: _glowController,
              child: content,
              builder: (context, child) => _remindersGlow(
                  child!, Curves.easeInOut.transform(_glowController.value)),
            ),
    );
  }

  Widget _remindersGlow(Widget child, double t) {
    const c = AppTheme.lightBackground;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35 + 0.55 * t), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: c.withOpacity(0.10 + 0.22 * t),
            blurRadius: 18 + 14 * t,
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReminderItem(ReminderWithCarInfo reminderWithCar) {
    final reminder = reminderWithCar.reminder;
    final days = reminder.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final color = daysLeftColor(days);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Bell ~+17% larger, aligned with the title.
          Icon(CupertinoIcons.bell_fill, size: 21, color: color),
          const SizedBox(width: 14),
          // Tapping the body (title/car) opens the reminder's detail card.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showReminderDetailsDialog(reminderWithCar),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Orbitron'),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reminderWithCar.carDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontFamily: 'Orbitron'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Reminder · days · Done — days sits between the body and the button.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showReminderDetailsDialog(reminderWithCar),
            child: Text(
              daysLeftText(days),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Orbitron'),
            ),
          ),
          const SizedBox(width: 12),
          _doneButton(reminderWithCar),
        ],
      ),
    );
  }

  /// Capsule Done button — the shared [ReminderDoneButton], so Home and the
  /// Reminders screen can never drift. Completion logic stays here.
  Widget _doneButton(ReminderWithCarInfo rc) {
    final id = rc.reminder.id;
    final busy = id != null && _completingReminderIds.contains(id);
    return ReminderDoneButton(
      busy: busy,
      semanticLabel: 'Mark ${rc.reminder.title} as done',
      onPressed: busy ? null : () => _completeReminder(rc),
    );
  }

  /// Completes a reminder by reusing the Reminders screen's exact service call,
  /// so recurring behavior stays identical. Optimistically removes the row and
  /// offers Undo.
  Future<void> _completeReminder(ReminderWithCarInfo rc) async {
    final id = rc.reminder.id;
    if (id == null || _completingReminderIds.contains(id)) return;
    HapticFeedback.lightImpact();
    setState(() => _completingReminderIds.add(id));

    final result = await _reminderService.markReminderCompleted(id);
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _completingReminderIds.remove(id));
      _showHomeSnack(result.message);
      return;
    }
    setState(() {
      _completingReminderIds.remove(id);
      _upcomingReminders.removeWhere((e) => e.reminder.id == id);
    });
    // Completing a reminder changes overdue state → refresh health and counts.
    _loadUserCars();
    _loadNotificationCount();
    _showUndoSnack(rc.reminder);
  }

  void _showUndoSnack(BackupReminder reminder) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.darkAccentGreen,
          duration: const Duration(seconds: 4),
          content: const Text('Reminder completed',
              style: TextStyle(fontFamily: 'Orbitron', color: Colors.white)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppTheme.lightBackground,
            onPressed: () => _undoComplete(reminder),
          ),
        ),
      );
  }

  Future<void> _undoComplete(BackupReminder reminder) async {
    final id = reminder.id;
    if (id == null) return;
    final result = await _reminderService.markReminderUncompleted(id);
    if (!mounted) return;
    if (result.isSuccess) {
      await _loadUpcomingReminders();
      _loadUserCars();
      _loadNotificationCount();
    } else {
      _showHomeSnack(result.message);
    }
  }

  void _showHomeSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: AppTheme.darkAccentGreen,
      ),
    );
  }

  Widget _buildLatestMaintenanceSection() {
    return _sectionCard(
      title: 'Latest Maintenance',
      actionLabel: 'View all',
      onAction: _navigateToMaintenance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total paid across ALL records (live from getTotalMaintenanceCost).
          Text(
            'Total spent on maintenance',
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Orbitron'),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCost(_totalMaintenanceCost),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron'),
            ),
          ),
          const SizedBox(height: 10),
          _rowDivider(),
          const SizedBox(height: 4),
          if (_maintenanceLoading)
            const Padding(
                padding: EdgeInsets.all(8),
                child: CupertinoActivityIndicator(color: Colors.white))
          else if (_latestMaintenance.isEmpty)
            _emptyRow(CupertinoIcons.wrench, 'No maintenance records')
          else
            for (var i = 0; i < _latestMaintenance.length && i < 3; i++) ...[
              _buildMaintenanceItem(_latestMaintenance[i]),
              if (i != _latestMaintenance.length - 1 && i < 2) _rowDivider(),
            ],
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(MaintenanceWithInfo maintenanceWithInfo) {
    final maintenance = maintenanceWithInfo.maintenance;
    // Whole row taps through to the maintenance detail card.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMaintenanceDetailsDialog(maintenanceWithInfo),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
        children: [
          const Icon(CupertinoIcons.wrench_fill, size: 18, color: _accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maintenance.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Orbitron'),
                ),
                const SizedBox(height: 3),
                Text(
                  '${maintenanceWithInfo.carDisplayName} · ${DateFormat('dd MMM yyyy').format(maintenance.maintenanceDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'Orbitron'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatCost(maintenance.cost),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.lightBackground, // colored, formatted price
                fontFamily: 'Orbitron'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCircularActionButton(String label, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleAction(label),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
                const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Actions — colored tinted badges, in a grid whose column count adapts to
  // the width (via maxCrossAxisExtent) with a fixed tile height (no overflow).
  // The tiles come from the shared [homeActions] registry so they can never
  // drift from the All Actions screen.
  Widget _buildActionsSection() {
    final actions = homeActions;
    return _sectionCard(
      title: 'Actions',
      actionLabel: 'View all',
      onAction: _navigateToAllActions,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 118,
          mainAxisExtent: 94, // fixed height → never overflows on narrow screens
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(action.title, action.icon, action.iconColor);
        },
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _handleAction(label);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
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

  // Latest Repairs Section
  Widget _buildLatestRepairs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest Repairs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaintenanceRecordsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_maintenanceLoading)
          const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        else if (_latestMaintenance.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.build_circle_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No Maintenance Records',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your vehicle maintenance history',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._latestMaintenance.asMap().entries.map((entry) {
            final index = entry.key;
            final maintenanceWithInfo = entry.value;
            final maintenance = maintenanceWithInfo.maintenance;
            
            // Format date
            final dateFormat = DateFormat('dd MMM yyyy');
            final dateText = dateFormat.format(maintenance.maintenanceDate);
            
            // Format cost
            final costText = 'EGP ${maintenance.cost.toStringAsFixed(0)}';
            
            // Get icon and color based on maintenance type
            final iconData = _getMaintenanceIcon(maintenance.type);
            final color = _getMaintenanceColor(maintenance.type);
            
            return Column(
              children: [
                _buildRepairItem(
                  maintenance.title,
                  dateText,
                  costText,
                  iconData,
                  color,
                  'Successful',
                ),
                if (index < _latestMaintenance.length - 1) const SizedBox(height: 12),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildRepairItem(String title, String date, String cost, IconData icon, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
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
                    color: AppTheme.getThemeAwareTextColor(context),
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cost,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // "Ask Siyanaty AI" — an inline, iMessage-style entry to the car assistant,
  // scoped to the car shown in the carousel. Replaces the old static
  // recommendation list; the chat itself reuses the shared CarAssistantSheet +
  // MockCarAssistantService (still UI only).
  Widget _buildServiceRecommendations() {
    final car = (_userCars.isNotEmpty && _currentCarIndex < _userCars.length)
        ? _userCars[_currentCarIndex]
        : null;
    final carLabel =
        car != null ? '${car.brand} ${car.model} ${car.year}' : 'your car';

    return _sectionCard(
      title: 'Ask Siyanaty AI',
      titleBadge: _aiBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // Welcome bubble from the assistant, naming the selected car.
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.75),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkAccentGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Hi 👋 Ask me anything about your $carLabel — oil changes, '
                'tires, brakes or warning lights.',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontSize: 12.5,
                    height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Suggestion chips (horizontal scroll) open the full chat prefilled.
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: kAssistantSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) =>
                  _suggestionChip(kAssistantSuggestions[i], car),
            ),
          ),
          const SizedBox(height: 12),
          _buildAiInputBar(car),
          const SizedBox(height: 10),
          _rowDivider(),
          // Keep a quiet path to real workshops (the chat's real-world CTA).
          Semantics(
            button: true,
            label: 'Find nearby service centers',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _navigateToServices();
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Find Nearby Service Centers',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.lightBackground,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Orbitron')),
                      SizedBox(width: 2),
                      Icon(CupertinoIcons.chevron_right,
                          size: 15, color: AppTheme.lightBackground),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sparkles glyph + a small "Beta" capsule shown next to the AI section
  /// title, so the section reads unmistakably as the AI assistant.
  Widget _aiBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(CupertinoIcons.sparkles,
            size: 16, color: AppTheme.lightBackground),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.lightBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Beta',
            style: TextStyle(
              color: AppTheme.backgroundGreen,
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// iMessage-style input pill + send button. Both open the full chat sheet
  /// (reused, UI only) with the typed question sent; send is disabled while
  /// the field is empty.
  Widget _buildAiInputBar(BackupCar? car) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: AppTheme.lightBackground.withOpacity(0.35)),
            ),
            child: TextField(
              controller: _aiInput,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendAiFromBar(car),
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Orbitron', fontSize: 13),
              cursorColor: AppTheme.lightBackground,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Ask about your car…',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontFamily: 'Orbitron',
                    fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _aiInput,
          builder: (context, value, _) {
            final enabled = value.text.trim().isNotEmpty;
            return Semantics(
              button: true,
              enabled: enabled,
              label: 'Send message',
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Material(
                  color: AppTheme.lightBackground,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? () => _sendAiFromBar(car) : null,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(CupertinoIcons.arrow_up,
                          color: AppTheme.backgroundGreen, size: 20),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _sendAiFromBar(BackupCar? car) {
    final text = _aiInput.text.trim();
    if (text.isEmpty) return;
    _aiInput.clear();
    _openAssistant(car, initial: text);
  }

  Widget _suggestionChip(String label, BackupCar? car) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openAssistant(car, initial: label),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppTheme.lightBackground.withOpacity(0.4)),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.lightBackground,
                    fontFamily: 'Orbitron',
                    fontSize: 12)),
          ),
        ),
      ),
    );
  }

  void _openAssistant(BackupCar? car, {String? initial}) {
    HapticFeedback.selectionClick();
    showCarAssistantSheet(context, car: car, initialQuestion: initial);
  }

  // Navigation Methods
  void _showNotifications() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    // Refresh notification count when returning from notifications screen
    _loadNotificationCount();
  }

  void _showProfile() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  

  void _handleAction(String action) {
    HapticFeedback.lightImpact();

    // Navigate to specific screens for fully implemented features
    switch (action.toLowerCase()) {
      case 'maintenance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MaintenanceRecordsScreen()),
        );
        break;
      case 'vin lookup':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VinLookupScreen()),
        );
        break;
        case 'ocr scanner':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OcrScannerScreen()),
          );
          break;
      case 'car health':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CarHealthDashboardScreen()),
        );
        break;
      case 'voice notes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VoiceNotesScreen()),
        );
        break;
      case 'mileage track':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MileageTrackScreen()),
        );
        break;
      case 'license':
        _showPinVerificationForLicense();
        break;
      
      default:
        _showMessage('A&A!');
    }
  }

  
  void _navigateToReminders() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SmartRemindersScreen(),
      ),
    );
  }

  void _navigateToMaintenance() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MaintenanceRecordsScreen()),
    );
  }

  void _navigateToExport() {
    HapticFeedback.lightImpact();
    AppSnackbar.show(context, 
      SnackBar(
        content: const Text(
          'Export Data feature coming soon!',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.getThemeAwareIconColor(context),
      ),
    );
  }

  void _navigateToOBD() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OBDDashboardScreen(),
      ),
    );
  }

  void _navigateToServices() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServiceCentersScreen(),
      ),
    );
  }


  void _navigateToAllActions() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllActionsScreen()),
    );
  }

  void _navigateToCarsList() {
    HapticFeedback.lightImpact();
   Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyCarsScreen()),
    );
  }

  void _navigateToLicense() {
    HapticFeedback.lightImpact();
    _showPinVerificationForLicense();
  }

  /// Gate the License screen behind the app PIN using the shared iOS sheet.
  /// The sheet verifies through the shared LocalUnlockService, so cancelling
  /// or swiping it down never opens the License — only an explicit success does.
  Future<void> _showPinVerificationForLicense() async {
    final car = (_userCars.isNotEmpty && _currentCarIndex < _userCars.length)
        ? _userCars[_currentCarIndex]
        : null;
    final carLabel =
        car != null ? '${car.brand} ${car.model} ${car.year}' : '';

    final result = await showLicensePinSheet(context, carLabel: carLabel);
    if (!mounted) return;

    if (result == LicensePinResult.success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LicenseScreen()),
      );
    } else if (result == LicensePinResult.forgotPin) {
      _handleLicenseForgotPin();
    }
  }

  /// Forgot-PIN from the License gate mirrors the unlock screen: sign out so a
  /// fresh sign-in sets a new PIN. Signing out flips auth state, and the root
  /// AuthWrapper routes back to login.
  Future<void> _handleLicenseForgotPin() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
            'You will be signed out. Sign in again to set a new PIN.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _navigateToMileageTrack() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MileageTrackScreen()),
    );
  }

  void _showCarDetailsDialog(BackupCar car) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(dialogContext.r(20)),
            constraints: BoxConstraints(
              maxWidth: dialogContext.r(480),
              maxHeight: dialogContext.screenHeight * 0.95,
            ),
            // Matches AppDialogPanel so this card belongs to the same family
            // as every other pop-up in the app.
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundGreen,
                  AppTheme.darkAccentGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(dialogContext.responsiveBorderRadius(24)),
              border: Border.all(
                color: AppTheme.secondaryGreen.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: AppTheme.glowShadow(elevated: true),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: dialogContext.r(50),
                            height: dialogContext.r(50),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(dialogContext.responsiveBorderRadius(16)),
                            ),
                            child: car.imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(dialogContext.responsiveBorderRadius(16)),
                                    child: Image.file(
                                      File(car.imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.directions_car,
                                          color: AppTheme.primaryGreen,
                                          size: dialogContext.responsiveIconSize(24),
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.directions_car,
                                    color: AppTheme.primaryGreen,
                                    size: dialogContext.responsiveIconSize(24),
                                  ),
                          ),
                          SizedBox(width: dialogContext.r(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${car.year} ${car.brand} ${car.model}',
                                  style: dialogContext.responsiveTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: dialogContext.r(4)),
                                if (car.licensePlate.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: dialogContext.r(8), 
                                      vertical: dialogContext.r(4),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.backgroundGreen,
                                          AppTheme.darkAccentGreen,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(dialogContext.responsiveBorderRadius(20)),
                                      border: Border.all(
                                        color: AppTheme.secondaryGreen.withOpacity(0.6),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      car.licensePlate,
                                      style: dialogContext.responsiveTextStyle(
                                        fontSize: 11,
                                        color: AppTheme.lightBackground,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.backgroundGreen,
                            AppTheme.darkAccentGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(dialogContext.responsiveBorderRadius(16)),
                        border: Border.all(
                          color: AppTheme.secondaryGreen.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryGreen.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.secondaryGreen,
                          size: dialogContext.responsiveIconSize(20),
                        ),
                        padding: EdgeInsets.all(dialogContext.r(8)),
                        constraints: BoxConstraints(
                          minWidth: dialogContext.r(32),
                          minHeight: dialogContext.r(32),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dialogContext.r(20)),
                
                // Details section with modern styling
                Container(
                  padding: EdgeInsets.all(dialogContext.r(14)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundGreen,
                        AppTheme.darkAccentGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(dialogContext.responsiveBorderRadius(20)),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGreen.withOpacity(0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildModernDetailRow('Mileage', '${car.mileage.toStringAsFixed(0)} km', Icons.speed, Colors.blue),
                      _buildModernDetailRow('Color', car.color.isNotEmpty ? car.color : 'N/A', Icons.color_lens, Colors.purple),
                      _buildModernDetailRow('Fuel Type', car.fuelType.isNotEmpty ? car.fuelType : 'N/A', Icons.local_gas_station, Colors.orange),
                      _buildModernDetailRow('Engine', car.engineCC + (car.turbo ? ' Turbo' : ''), Icons.build, Colors.red),
                      _buildModernDetailRow('VIN', car.vin.isNotEmpty ? car.vin : 'N/A', Icons.qr_code, Colors.cyan),
                      _buildModernDetailRow('Added', _formatCarDate(car.createdAt), Icons.calendar_today, Colors.green),
                      if (car.updatedAt != car.createdAt)
                        _buildModernDetailRow('Last Updated', _formatCarDate(car.updatedAt), Icons.update, Colors.teal),
                    ],
                  ),
                ),
                
                SizedBox(height: dialogContext.r(20)),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: _buildModernActionButton(
                    icon: Icons.edit_rounded,
                    label: 'View & Edit in My Cars',
                    color: AppTheme.primaryGreen,
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToCarsList();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shared pop-up shell — same family as [_showCarDetailsDialog] (gradient
  /// panel, icon badge header, close button, boxed detail rows, action button).
  /// Used by the reminder and maintenance detail cards so they look identical
  /// to the car card's pop-up.
  void _showDetailsDialog({
    required IconData headerIcon,
    required Color headerColor,
    required String title,
    String? badge,
    required List<Widget> rows,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(dialogContext.r(20)),
            constraints: BoxConstraints(
              maxWidth: dialogContext.r(480),
              maxHeight: dialogContext.screenHeight * 0.95,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.backgroundGreen, AppTheme.darkAccentGreen],
              ),
              borderRadius:
                  BorderRadius.circular(dialogContext.responsiveBorderRadius(24)),
              border: Border.all(
                color: AppTheme.secondaryGreen.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: AppTheme.glowShadow(elevated: true),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icon badge + title (+ optional badge) + close.
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: dialogContext.r(50),
                            height: dialogContext.r(50),
                            decoration: BoxDecoration(
                              color: headerColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                  dialogContext.responsiveBorderRadius(16)),
                            ),
                            child: Icon(headerIcon,
                                color: headerColor,
                                size: dialogContext.responsiveIconSize(24)),
                          ),
                          SizedBox(width: dialogContext.r(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: dialogContext.responsiveTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (badge != null && badge.isNotEmpty) ...[
                                  SizedBox(height: dialogContext.r(4)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: dialogContext.r(8),
                                      vertical: dialogContext.r(4),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.backgroundGreen,
                                          AppTheme.darkAccentGreen,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          dialogContext
                                              .responsiveBorderRadius(20)),
                                      border: Border.all(
                                        color: AppTheme.secondaryGreen
                                            .withOpacity(0.6),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.secondaryGreen
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      badge,
                                      style: dialogContext.responsiveTextStyle(
                                        fontSize: 11,
                                        color: AppTheme.lightBackground,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.backgroundGreen,
                            AppTheme.darkAccentGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                            dialogContext.responsiveBorderRadius(16)),
                        border: Border.all(
                          color: AppTheme.secondaryGreen.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryGreen.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.secondaryGreen,
                          size: dialogContext.responsiveIconSize(20),
                        ),
                        padding: EdgeInsets.all(dialogContext.r(8)),
                        constraints: BoxConstraints(
                          minWidth: dialogContext.r(32),
                          minHeight: dialogContext.r(32),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dialogContext.r(20)),
                // Detail rows inside the same boxed panel the car card uses.
                Container(
                  padding: EdgeInsets.all(dialogContext.r(14)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundGreen,
                        AppTheme.darkAccentGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                        dialogContext.responsiveBorderRadius(20)),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGreen.withOpacity(0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(children: rows),
                ),
                SizedBox(height: dialogContext.r(20)),
                SizedBox(
                  width: double.infinity,
                  child: _buildModernActionButton(
                    icon: Icons.arrow_forward_rounded,
                    label: actionLabel,
                    color: AppTheme.primaryGreen,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onAction();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reminder detail card — opened by tapping a reminder row.
  void _showReminderDetailsDialog(ReminderWithCarInfo rc) {
    final r = rc.reminder;
    final days = r.targetDate?.difference(DateTime.now()).inDays ?? 0;
    _showDetailsDialog(
      headerIcon: _getReminderIcon(r.type),
      headerColor: _getReminderColor(r.type),
      title: r.title,
      badge: r.type.displayName,
      rows: [
        _buildModernDetailRow(
            'Car', rc.carDisplayName, Icons.directions_car, Colors.blue),
        if (r.targetDate != null)
          _buildModernDetailRow('Due date', _formatCarDate(r.targetDate),
              Icons.event, Colors.orange),
        _buildModernDetailRow(
            'Time left', daysLeftText(days), Icons.timelapse, daysLeftColor(days)),
        if (r.targetMileage != null)
          _buildModernDetailRow('Target mileage',
              '${_formatMileage(r.targetMileage!)} km', Icons.speed, Colors.cyan),
        _buildModernDetailRow(
            'Priority', r.priority.displayName, Icons.flag, Colors.purple),
        if (r.description.isNotEmpty)
          _buildModernDetailRow(
              'Notes', r.description, Icons.notes, Colors.green),
      ],
      actionLabel: 'Open in Reminders',
      onAction: _navigateToReminders,
    );
  }

  /// Maintenance detail card — opened by tapping a maintenance row.
  void _showMaintenanceDetailsDialog(MaintenanceWithInfo mi) {
    final m = mi.maintenance;
    _showDetailsDialog(
      headerIcon: _getMaintenanceIcon(m.type),
      headerColor: _getMaintenanceColor(m.type),
      title: m.title,
      badge: m.type.displayName,
      rows: [
        _buildModernDetailRow(
            'Car', mi.carDisplayName, Icons.directions_car, Colors.blue),
        _buildModernDetailRow('Cost', _formatCost(m.cost), Icons.payments,
            AppTheme.primaryGreen),
        _buildModernDetailRow(
            'Date',
            DateFormat('dd MMM yyyy').format(m.maintenanceDate),
            Icons.calendar_today,
            Colors.orange),
        if (m.mechanicName != null && m.mechanicName!.isNotEmpty)
          _buildModernDetailRow(
              'Mechanic', m.mechanicName!, Icons.person, Colors.purple),
        if (m.invoiceNumber != null && m.invoiceNumber!.isNotEmpty)
          _buildModernDetailRow(
              'Invoice', m.invoiceNumber!, Icons.receipt_long, Colors.cyan),
        if (m.description.isNotEmpty)
          _buildModernDetailRow(
              'Notes', m.description, Icons.notes, Colors.green),
      ],
      actionLabel: 'Open in Maintenance',
      onAction: _navigateToMaintenance,
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.r(6)),
      child: Row(
        children: [
          Container(
            width: context.r(34),
            height: context.r(34),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(12)),
              border: Border.all(
                color: color.withOpacity(0.45),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: context.responsiveIconSize(16),
            ),
          ),
          SizedBox(width: context.r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.responsiveTextStyle(
                    fontSize: 11,
                    color: AppTheme.lightBackground.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.r(2)),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: context.responsiveTextStyle(
                    fontSize: 14,
                    color: AppTheme.lightBackground,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.secondaryGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.lightBackground,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Orbitron',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCarDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get icon for reminder type
  IconData _getReminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.oilChange:
        return Icons.oil_barrel;
      case ReminderType.tireRotation:
        return Icons.tire_repair;
      case ReminderType.brakeService:
        return Icons.disc_full;
      case ReminderType.maintenance:
        return Icons.build;
      case ReminderType.inspection:
        return Icons.search;
      case ReminderType.insurance:
        return Icons.shield;
      case ReminderType.registration:
        return Icons.assignment;
      case ReminderType.custom:
        return Icons.event;
    }
  }

  /// Get color for reminder type
  Color _getReminderColor(ReminderType type) {
    switch (type) {
      case ReminderType.oilChange:
        return const Color(0xFFFF6B35);
      case ReminderType.tireRotation:
        return AppTheme.primaryGreen;
      case ReminderType.brakeService:
        return const Color(0xFF7B2CBF);
      case ReminderType.maintenance:
        return const Color(0xFFFF9800);
      case ReminderType.inspection:
        return const Color(0xFF2196F3);
      case ReminderType.insurance:
        return const Color(0xFFFFD23F);
      case ReminderType.registration:
        return const Color(0xFF795548);
      case ReminderType.custom:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Get icon for maintenance type
  IconData _getMaintenanceIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Icons.build;
      case MaintenanceType.electrical:
        return Icons.electrical_services;
      case MaintenanceType.suspension:
        return Icons.car_repair;
      case MaintenanceType.others:
        return Icons.more_vert;
    }
  }

  /// Get color for maintenance type
  Color _getMaintenanceColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Colors.orange;
      case MaintenanceType.electrical:
        return Colors.red;
      case MaintenanceType.suspension:
        return Colors.purple;
      case MaintenanceType.others:
        return Colors.green;
    }
  }

  void _showMessage(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.getThemeAwareIconColor(context),
      ),
    );
  }
}