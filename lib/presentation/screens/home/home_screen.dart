import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../actions/all_actions_screen.dart';
import '../services/cars_screen.dart';
import '../services/vin_lookup_screen.dart';
import '../services/ocr_scanner_screen.dart';
import '../services/barcode_scanner_screen.dart';
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
import '../../../models/backup_car.dart';
import '../../../services/reminder_service.dart';
import '../../../services/maintenance_service.dart';
import '../../../services/notification_database_service.dart';
import '../../../models/backup_reminder.dart';
import '../../../models/backup_maintenance.dart';

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
  /// Fade animation for smooth screen entrance
  late Animation<double> _fadeAnimation;
  /// Slide animation for content movement
  late Animation<Offset> _slideAnimation;
  /// Controller for horizontal car selection carousel
  final PageController _carPageController = PageController();
  /// Index of currently selected vehicle
  int _currentCarIndex = 0;
  /// Car service for fetching real car data
  final CarService _carService = CarService();
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
  /// List of upcoming reminders (max 3)
  List<ReminderWithCarInfo> _upcomingReminders = [];
  /// Loading state for reminders
  bool _remindersLoading = true;
  /// List of latest maintenance records (max 3)
  List<MaintenanceWithInfo> _latestMaintenance = [];
  /// Loading state for maintenance
  bool _maintenanceLoading = true;

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
    /// Load user's cars
    _loadUserCars();
    /// Load upcoming reminders
    _loadUpcomingReminders();
    /// Load latest maintenance
    _loadLatestMaintenance();
    /// Load notification count
    _loadNotificationCount();
    
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
    _carPageController.dispose();
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
          _upcomingReminders = reminders
              .where((r) => r.reminder.status == ReminderStatus.upcoming)
              .take(3)
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
      if (mounted) {
        setState(() {
          // Take latest 3 maintenance records
          _latestMaintenance = maintenance.take(3).toList();
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
      final notifications = await _notificationService.getAllNotifications();
      if (mounted) {
        setState(() {
          _notificationCount = notifications.length;
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
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshHomeData,
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
            child: Column(
              children: [
                /// Header section with gradient background and user welcome
                _buildHeaderWithBackground(),

                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),

                      // App features container (like "pay your bills")
                      _buildAppFeaturesSection(),
                      const SizedBox(height: 24),

                      // Car container with swipe functionality
                      _buildCarSection(),
                      const SizedBox(height: 24),

                      // Actions section (3x2 grid)
                      _buildActionsSection(),
                      const SizedBox(height: 24),

                      // Upcoming reminders
                      _buildUpcomingRemindersSection(),
                      const SizedBox(height: 24),

                      // Latest maintenance
                      _buildLatestMaintenanceSection(),
                      const SizedBox(height: 24),

                      // Service recommendations (keep as is)
                      _buildServiceRecommendations(),
                      const SizedBox(height: 32),
                    ],
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

  // Header with gradient background design inspired by the money transfer app
  Widget _buildHeaderWithBackground() {
    return Container(
      height: 260,
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
                        hasNotificationBadge: _notificationCount > 0,
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
              
              // Floating greeting section
              Flexible(child: _buildFloatingGreeting()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIcon(IconData icon, VoidCallback onTap, {bool hasNotificationBadge = false, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 44,
        height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: (color ?? AppTheme.getThemeAwareIconColor(context)).withOpacity(0.3),
                size: 20,
              ),
            ),
            if (hasNotificationBadge)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
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
        ],
      ),
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
    );
  }

 
  Widget _buildAppFeaturesSection() {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 110,
            height: 60,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getThemeAwareIconColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),

            ),
            child: Icon(
              const IconData(0xe800, fontFamily: 'MyFlutterApp'),
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Your Vehicle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getThemeAwareTextColor(context),
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track maintenance, fuel, and more',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
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

  // Car section with swipe functionality
  Widget _buildCarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Cars',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
            TextButton(
              onPressed: () => _navigateToCarsList(),
              child: Text(
                'Manage',
                style: TextStyle(
                  color: AppTheme.getThemeAwareIconColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Car card with swipe functionality
        SizedBox(
          height: 230, // Increased height to accommodate content
          child: PageView.builder(
            controller: _carPageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarIndex = index;
              });
            },
            itemCount: _userCars.isEmpty ? 1 : _userCars.length,
            itemBuilder: (context, index) {
              return _buildCarCard(index);
            },
          ),
        ),

        const SizedBox(height: 6),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_userCars.isEmpty ? 1 : _userCars.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarIndex == index ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentCarIndex == index
                    ? AppTheme.getThemeAwareIconColor(context)
                    : AppTheme.getThemeAwareTextColor(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 0),

        // Circular action buttons moved inside car card
        const SizedBox(height: 2),
      ],
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconData(0xe800, fontFamily: 'MyFlutterApp'),
              size: 48,
              color: Colors.white54,
            ),
            SizedBox(height: 12),
            Text(
              'No Cars Added',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add your first car',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'Orbitron',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final car = _userCars[index];
    
    // Calculate health based on mileage and age (simple heuristic)
    final currentYear = DateTime.now().year;
    final age = currentYear - car.year;
    final health = (1.0 - (age * 0.05) - (car.mileage / 200000)).clamp(0.0, 1.0);
    
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
                height: 80,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${car.mileage.toStringAsFixed(0)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
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
                    '${(health * 100).toInt()}% Good',
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCarActionButton(
                Icons.credit_card,
                'License',
                () => _navigateToLicense(),
              ),
              _buildCarActionButton(
                Icons.info_outline,
                'Details',
                () => _showCarDetails(car),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 29, 90, 29),
              Color.fromARGB(255, 11, 67, 35),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
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

  Widget _buildUpcomingRemindersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
              TextButton(
                onPressed: _navigateToReminders,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_remindersLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          else if (_upcomingReminders.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No upcoming reminders',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _upcomingReminders.take(3).map((reminderWithCar) {
                return _buildReminderItem(reminderWithCar);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(ReminderWithCarInfo reminderWithCar) {
    final reminder = reminderWithCar.reminder;
    final daysUntil = reminder.targetDate?.difference(DateTime.now()).inDays ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reminder.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminderWithCar.carDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysUntil <= 3 ? Colors.red : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysUntil == 0 ? 'Today' : '$daysUntil days',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestMaintenanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Maintenance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
              TextButton(
                onPressed: _navigateToMaintenance,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_maintenanceLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          else if (_latestMaintenance.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No maintenance records',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _latestMaintenance.take(3).map((maintenanceWithInfo) {
                return _buildMaintenanceItem(maintenanceWithInfo);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(MaintenanceWithInfo maintenanceWithInfo) {
    final maintenance = maintenanceWithInfo.maintenance;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.build,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maintenance.type.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  maintenanceWithInfo.carDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'EGP ${maintenance.cost.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
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

  // Actions section (3x2 grid)
  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
            TextButton(
              onPressed: () => _navigateToAllActions(),
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.getThemeAwareIconColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // keep same as My Cars

        GridView.builder(
          padding: EdgeInsets.zero, // prevent GridView from adding default padding
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              action['label'] as String,
              action['icon'] as IconData,
              action['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  final actions = [
    {'label': 'VIN Lookup', 'icon': Icons.search, 'color': const Color(0xFFF59E0B)}, // Amber/Orange
    {'label': 'OCR Scanner', 'icon': Icons.document_scanner, 'color': const Color(0xFF06B6D4)}, // Cyan
    {'label': 'Barcode Scanner', 'icon': Icons.qr_code_scanner, 'color': const Color(0xFF8E44AD)}, // Purple
    {'label': 'Voice Notes', 'icon': Icons.mic, 'color': const Color(0xFFE74C3C)}, // Red
    {'label': 'Mileage Track', 'icon': Icons.track_changes, 'color': const Color(0xFF10B981)}, // Emerald
    {'label': 'Maintenance', 'icon': Icons.home_repair_service_rounded, 'color': const Color(0xFF3B82F6)}, // Blue
  ];

  Widget _buildActionCard(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleAction(label);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
            TextButton(
              onPressed: () => _navigateToMaintenance(),
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.getThemeAwareIconColor(context),
                  fontFamily: 'Orbitron',
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

  // Service Recommendations (keeping as is)
  Widget _buildServiceRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getThemeAwareTextColor(context),
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AI Insights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildRecommendationItem(
                'Your brake pads may need inspection in ~3 weeks.',
                'Based on your driving patterns and current mileage.',
              ),
              const SizedBox(height: 12),
              _buildRecommendationItem(
                'Consider scheduling an oil change before 10,500 km.',
                'You\'re approaching the recommended oil change interval.',
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => _navigateToServices(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Find Nearby Service Centers →',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
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
      case 'barcode scanner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LicenseScreen()),
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LicenseScreen()),
    );
  }

  void _navigateToMileageTrack() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MileageTrackScreen()),
    );
  }

  void _showCarDetails(BackupCar car) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Car Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Brand', car.brand),
              _buildDetailRow('Model', car.model),
              _buildDetailRow('Year', car.year.toString()),
              _buildDetailRow('Mileage', '${car.mileage.toStringAsFixed(0)} km'),
              _buildDetailRow('VIN', car.vin ?? 'N/A'),
              _buildDetailRow('License Plate', car.licensePlate ?? 'N/A'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToCarsList();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Edit Car',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
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