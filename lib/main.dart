import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shared/constants/app_theme.dart';
import 'shared/services/firebase_service.dart';
import 'shared/utils/app_logger.dart';
import 'services/local_notification_service.dart';
import 'services/reminder_service.dart';
import 'services/mileage_background_service.dart';
import 'services/security/local_unlock_service.dart';
import 'services/security/authentication_manager.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart' as app_auth;
import 'presentation/widgets/bottom_nav_bar.dart';
import 'presentation/widgets/auth_wrapper.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/services/reminders_screen.dart';
import 'presentation/screens/services/obd_screen.dart';
import 'presentation/screens/services/services_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/email_verification_screen.dart';
import 'presentation/screens/security/unlock_screen.dart';
import 'presentation/screens/security/pin_setup_screen.dart';
import 'database/database_helper.dart';

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
    
    /// Initialize backup database helper
    await DatabaseHelper.instance.database;
    AppLogger.info('Database initialized successfully');
    
    /// Initialize local notification service
    try {
      await LocalNotificationService.instance.initialize();
      AppLogger.info('Local notification service initialized successfully');
    } catch (e) {
      AppLogger.warning('Local notification service initialization failed: $e');
    }
    
    /// Schedule all reminder notifications on app startup
    try {
      final reminderService = ReminderService();
      await reminderService.scheduleAllReminderNotifications();
      await reminderService.checkAndNotifyDueReminders();
      AppLogger.info('Reminder notifications scheduled successfully');
    } catch (e) {
      AppLogger.warning('Failed to schedule reminder notifications: $e');
    }
    
    /// Initialize and register mileage background service for automatic updates
    try {
      await MileageBackgroundService.initialize();
      await MileageBackgroundService.registerPeriodicTask();
      AppLogger.info('Mileage background service initialized successfully');
    } catch (e) {
      AppLogger.warning('Failed to initialize mileage background service: $e');
    }
    
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
          create: (context) => app_auth.AuthProvider(),
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
          home: SecurityWrapper(
            child: AuthWrapper(
              child: _buildMainApp(),
            ),
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

/// Security wrapper that handles authentication flow and local unlock
class SecurityWrapper extends StatefulWidget {
  final Widget child;

  const SecurityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> with WidgetsBindingObserver {
  final LocalUnlockService _localUnlockService = LocalUnlockService();
  final AuthenticationManager _authManager = AuthenticationManager();
  
  bool _isInitializing = true;
  bool _isAuthenticated = false;
  bool _needsLocalUnlock = false;
  bool _needsLogin = true;
  bool _needsPinSetup = false;
  bool _needsEmailVerification = false;
  bool _isReinitializing = false; // Prevent multiple simultaneous reinitializations
  bool _justCompletedMFA = false; // Track if user just completed MFA to skip duplicate email

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (!mounted) return;
      AppLogger.info('Auth state changed: user=${user?.uid}, _isAuthenticated=$_isAuthenticated, _needsLogin=$_needsLogin');
      
      if (user != null && !_isAuthenticated && !_isReinitializing) {
        // User signed in - check if they have tokens (MFA completed)
        // If no tokens, they're in the middle of MFA flow, so don't reinitialize yet
        final hasTokens = await _authManager.isAuthenticated();
        if (hasTokens) {
          AppLogger.info('User signed in with tokens, re-initializing security');
          _reinitializeSecurity();
        } else {
          AppLogger.info('User signed in but no tokens yet (MFA in progress), skipping reinitialize');
        }
      } else if (user != null && _needsLogin && !_isReinitializing) {
        // User is signed in but we're showing login screen (e.g., after MFA success)
        // Check if they have tokens now before reinitializing
        final hasTokens = await _authManager.isAuthenticated();
        if (hasTokens) {
          AppLogger.info('User signed in with tokens and needsLogin=true, re-initializing security');
          _reinitializeSecurity();
        } else {
          AppLogger.info('User signed in but no tokens yet (MFA in progress), skipping reinitialize');
        }
      } else if (user == null && _isAuthenticated) {
        // User signed out
        AppLogger.info('User signed out');
        setState(() {
          _isAuthenticated = false;
          _needsLocalUnlock = false;
          _needsLogin = true;
          _needsPinSetup = false;
        });
      }
    });
    
    _initializeSecurity();
  }
  
  /// Reinitialize security with debouncing and retry to prevent race conditions
  Future<void> _reinitializeSecurity() async {
    if (_isReinitializing) return;
    _isReinitializing = true;
    
    // Longer delay to allow auth tokens to be properly stored
    // The token storage happens asynchronously after Firebase auth completes
    // Increased to 1 second to ensure tokens are fully persisted
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) {
      _isReinitializing = false;
      return;
    }
    
    // Try to initialize, with retry if tokens aren't ready yet
    // Increased to 5 attempts with longer delays
    for (int attempt = 0; attempt < 5; attempt++) {
      final isAuthenticated = await _authManager.isAuthenticated();
      AppLogger.info('Reinitialize attempt ${attempt + 1}: isAuthenticated=$isAuthenticated');
      
      if (isAuthenticated) {
        AppLogger.info('Authentication confirmed, initializing security...');
        await _initializeSecurity();
        _isReinitializing = false;
        return;
      }
      
      // Wait a bit more before retrying (increasing delay each time)
      if (attempt < 4) {
        final delay = 500 + (attempt * 200); // 500, 700, 900, 1100ms
        AppLogger.info('Waiting ${delay}ms before retry...');
        await Future.delayed(Duration(milliseconds: delay));
        if (!mounted) {
          _isReinitializing = false;
          return;
        }
      }
    }
    
    // If still not authenticated after retries, initialize anyway
    // (will show login screen)
    AppLogger.warning('Authentication not confirmed after 5 attempts, showing login screen');
    if (mounted) {
      await _initializeSecurity();
    }
    
    _isReinitializing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App is going to background, require unlock on resume
      if (_isAuthenticated) {
        setState(() {
          _needsLocalUnlock = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is resuming, check if unlock is needed
      _checkUnlockRequirement();
    }
  }

  Future<void> _initializeSecurity() async {
    AppLogger.info('_initializeSecurity called');
    try {
      // Check if user is authenticated
      final isAuthenticated = await _authManager.isAuthenticated();
      AppLogger.info('isAuthenticated: $isAuthenticated');
      
      if (!mounted) return;
      
      if (!isAuthenticated) {
        AppLogger.info('Not authenticated, showing login screen');
        // No authentication, show login screen
        setState(() {
          _isInitializing = false;
          _needsLogin = true;
          _needsPinSetup = false;
          _needsEmailVerification = false;
        });
        return;
      }

      // Check if email is verified
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        AppLogger.info('Email not verified, showing email verification screen');
        setState(() {
          _isInitializing = false;
          _needsLogin = false;
          _needsPinSetup = false;
          _needsEmailVerification = true;
          // _justCompletedMFA flag will be used by EmailVerificationScreen
        });
        return;
      }
      
      // Email is verified, reset MFA flag
      if (_justCompletedMFA) {
        setState(() {
          _justCompletedMFA = false;
        });
      }

      // Validate session
      final sessionResult = await _authManager.validateSession();
      if (!mounted) return;
      
      if (!sessionResult.isValid) {
        // Session expired, show login screen
        setState(() {
          _isInitializing = false;
          _needsLogin = true;
          _needsPinSetup = false;
          _needsEmailVerification = false;
        });
        return;
      }

      // Check if local unlock is configured
      final hasLocalUnlock = await _localUnlockService.isLocalUnlockAvailable();
      if (!mounted) return;
      
      if (!hasLocalUnlock) {
        // No local unlock configured, user needs to set it up
        setState(() {
          _isInitializing = false;
          _isAuthenticated = true;
          _needsLocalUnlock = false;
          _needsLogin = false;
          _needsPinSetup = true; // Show PIN setup screen
          _needsEmailVerification = false;
        });
        return;
      }

      // Check if app should be locked
      final shouldLock = await _localUnlockService.shouldLockApp();
      if (!mounted) return;
      
      setState(() {
        _isInitializing = false;
        _isAuthenticated = true;
        _needsLocalUnlock = shouldLock;
        _needsLogin = false;
        _needsPinSetup = false;
        _needsEmailVerification = false;
      });

    } catch (e) {
      AppLogger.error('Security initialization failed', error: e);
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _needsLogin = true;
        _needsPinSetup = false;
      });
    }
  }

  Future<void> _checkUnlockRequirement() async {
    if (!_isAuthenticated) return;

    final shouldLock = await _localUnlockService.shouldLockApp();
    if (shouldLock && !_needsLocalUnlock) {
      setState(() {
        _needsLocalUnlock = true;
      });
    }
  }

  // ignore: unused_element
  void _onLoginSuccess() {
    // After login, re-initialize security to check if PIN setup is needed
    // This method is available for external widgets to trigger security re-initialization
    _initializeSecurity();
  }

  void _onPinSetupComplete() {
    // Re-initialize security to ensure everything is properly set up
    if (mounted) {
      _initializeSecurity();
    }
  }

  void _onUnlockSuccess() {
    setState(() {
      _needsLocalUnlock = false;
    });
  }

  // ignore: unused_element
  void _onLogout() {
    // This method is available for settings screen or other widgets to trigger logout
    setState(() {
      _isAuthenticated = false;
      _needsLocalUnlock = false;
      _needsLogin = true;
      _needsPinSetup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_needsLogin) {
      return LoginScreen(
        onAuthenticationComplete: () {
          // Re-check authentication after MFA completion
          AppLogger.info('Authentication completed, re-checking security state');
          setState(() {
            _justCompletedMFA = true; // Mark that user just completed MFA
          });
          _initializeSecurity();
        },
      );
    }

    if (_needsEmailVerification) {
      return EmailVerificationScreen(
        skipInitialEmail: _justCompletedMFA,
      );
    }

    if (_needsPinSetup) {
      return PinSetupScreen(
        onPinSetup: _onPinSetupComplete,
      );
    }

    if (_needsLocalUnlock) {
      return UnlockScreen(
        onUnlockSuccess: _onUnlockSuccess,
      );
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
            SizedBox(height: 24),
            Text(
              'Initializing Security...',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Orbitron',
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
