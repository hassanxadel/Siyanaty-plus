import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/constants/app_theme.dart';
import 'shared/services/database_service.dart';
import 'shared/services/firebase_service.dart';
import 'shared/utils/app_logger.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/widgets/bottom_nav_bar.dart';
import 'presentation/widgets/auth_wrapper.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/services/reminders_screen.dart';
import 'presentation/screens/services/obd_screen.dart';
import 'presentation/screens/services/services_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

/// Main entry point for the Siyanaty+ car maintenance application
/// Initializes services, providers, and launches the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    /// Initialize Firebase services (optional - app works with local storage if Firebase fails)
    try {
      await FirebaseService.initialize();
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      AppLogger.warning('Firebase not configured - app will work with local storage only');
      AppLogger.error('Firebase initialization failed', error: e);
    }
    
    /// Initialize local database for offline functionality
    await DatabaseService.database;
    
    AppLogger.info('App initialization completed successfully');
  } catch (e) {
    AppLogger.error('Critical app initialization failed', error: e);
  }
  
  /// Launch app with provider setup for state management
  runApp(
    MultiProvider(
      providers: [
        /// Theme provider for light/dark mode switching
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        /// Authentication provider for user login/logout management
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
      ],
      child: const App(),
    ),
  );
}

/// Root application widget that sets up the main app structure
/// Configures theme, navigation, and main content
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

/// State class for the main app
/// Manages navigation between main screens and theme switching
class _AppState extends State<App> {
  /// Currently selected tab index for bottom navigation
  int _selectedIndex = 0;

  /// List of main screen widgets for tab navigation
  /// Each screen represents a major app section
  final List<Widget> _mainScreens = [
    const HomeDashboard(),        // Main dashboard with quick actions
    const SmartRemindersScreen(), // Service reminders and maintenance tracking
    const OBDDashboardScreen(),   // Vehicle diagnostics and OBD data
    const ServiceCentersScreen(), // Service center locator and information
    const SettingsScreen(),       // App settings and user preferences
  ];

  /// Build the main app with theme support and authentication wrapper
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'siyanaty+ Car Maintenance',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: AuthWrapper(
            child: _buildMainApp(),
          ),
        );
      },
    );
  }

  /// Build the main app content with navigation and screen management
  /// Handles tab switching and displays appropriate screen content
  Widget _buildMainApp() {
    return Scaffold(
      body: _mainScreens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
