import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
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
  }

  /// Clean up animation controllers and page controller
  @override
  void dispose() {
    _animationController.dispose();
    _carPageController.dispose();
    super.dispose();
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
                      _buildUpcomingReminders(),
                      const SizedBox(height: 24),

                      // Latest repairs
                      _buildLatestRepairs(),
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
                        hasNotificationBadge: true,
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
          color: AppTheme.getThemeAwareBackground(context).withOpacity(0.2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.getThemeAwareBackground(context).withOpacity(0.3),
            width: 1,
          ),
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
        color: AppTheme.getThemeAwareBackground(context).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.getThemeAwareBackground(context).withOpacity(0.2),
          width: 1,
        ),
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
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
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
            child: const Icon(
              IconData(0xe800, fontFamily: 'MyFlutterApp'),
              color: Color.fromARGB(255, 3, 27, 86),
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
            itemCount: 3, // Sample cars
            itemBuilder: (context, index) {
              return _buildCarCard(index);
            },
          ),
        ),

        const SizedBox(height: 6),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
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
    final cars = [
      {'name': 'Toyota Camry 2020', 'mileage': '45,230 km', 'health': 0.82},
      {'name': 'Honda Civic 2019', 'mileage': '32,100 km', 'health': 0.91},
      {'name': 'BMW 320i 2021', 'mileage': '15,670 km', 'health': 0.95},
    ];

    final car = cars[index];

    return ClipRect(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.darkGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 50,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.getThemeAwareIconColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  IconData(0xe800, fontFamily: 'MyFlutterApp'),
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getThemeAwareTextColor(context),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car['mileage'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14), // Reduced spacing between car details and health status

          // Health Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vehicle Health',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getThemeAwareTextColor(context),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  Text(
                    '${((car['health'] as double) * 100).toInt()}% Good',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: car['health'] as double,
                  backgroundColor: AppTheme.getThemeAwareCardBackground(context).withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 21, 219, 84)),
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24), // Reduced spacing between health status and action buttons

          // Circular action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularActionButton('Repairs', Icons.get_app_rounded, const Color.fromARGB(255, 10, 37, 105)),
              _buildCircularActionButton('Fuel Log', Icons.local_gas_station, const Color.fromARGB(255, 185, 109, 2)),
              _buildCircularActionButton('License', Icons.credit_card, const Color.fromARGB(255, 82, 16, 126)),
            ],
          ),
          
          const SizedBox(height: 8), // Bottom spacing for the card
        ],
      ),
    ));
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
    {'label': 'Multi-Car', 'icon': Icons.dashboard, 'color': const Color(0xFF3B82F6)}, // Blue
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
          color: AppTheme.darkGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getThemeAwareTextColor(context),
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

  // Upcoming Reminders Section
  Widget _buildUpcomingReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Reminders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getThemeAwareTextColor(context),
                fontFamily: 'Orbitron',
              ),
            ),
            TextButton(
              onPressed: () => _navigateToReminders(),
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

        _buildReminderItem('Oil Change', 'Due in 5 days', Icons.oil_barrel, const Color(0xFFFF6B35)),
        const SizedBox(height: 12),
        _buildReminderItem('Tire Rotation', 'Due in 22 days', Icons.tire_repair, AppTheme.primaryGreen),
        const SizedBox(height: 12),
        _buildReminderItem('Brake Inspection', 'Due in 45 days', Icons.disc_full, const Color(0xFF7B2CBF)),
      ],
    );
  }

  Widget _buildReminderItem(String title, String subtitle, IconData icon, Color color) {
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
            size: 16,
          ),
        ],
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

        _buildRepairItem('Brake Pad Replacement', '15 Aug 2025', 'EGP 1450', Icons.disc_full, const Color(0xFFFF6B35), 'Successful'),
        const SizedBox(height: 12),
        _buildRepairItem('Oil Change Service', '10 Aug 2025', 'EGP 1185', Icons.oil_barrel, AppTheme.primaryGreen, 'Successful'),
        const SizedBox(height: 12),
        _buildRepairItem('Tire Alignment', '05 Aug 2025', 'EGP 120', Icons.tire_repair, const Color(0xFF7B2CBF), 'Successful'),
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
            color: AppTheme.darkGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.getThemeAwareIconColor(context),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Insights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getThemeAwareIconColor(context),
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
                  foregroundColor: AppTheme.getThemeAwareIconColor(context),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.getThemeAwareTextColor(context),
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  // Navigation Methods
  void _showNotifications() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
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
      case 'multi-car':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyCarsScreen()),
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