import 'dart:async';
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
import 'services/global_navigation_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart' as app_auth;
import 'presentation/widgets/bottom_nav_bar.dart';
import 'presentation/widgets/auth_wrapper.dart';
import 'presentation/widgets/responsive_wrapper.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/services/reminders_screen.dart';
import 'presentation/screens/services/obd_screen.dart';
import 'presentation/screens/services/services_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/email_verification_screen.dart';
import 'presentation/screens/security/unlock_screen.dart';
import 'presentation/screens/security/pin_setup_screen.dart';
import 'presentation/screens/security/mfa_verification_screen.dart';
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

  @override
  void initState() {
    super.initState();
    // Set up global navigation callback
    GlobalNavigationService.onNavigateToTab = _navigateToTab;
  }

  @override
  void dispose() {
    // Clean up global navigation callback
    GlobalNavigationService.onNavigateToTab = null;
    super.dispose();
  }

  /// Navigate to a specific tab and pop all routes if needed
  void _navigateToTab(int index) {
    // Pop all routes to get back to main app
    final navigator = GlobalNavigationService.navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    
    // Update selected index
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }

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
          navigatorKey: GlobalNavigationService.navigatorKey,
          builder: (context, child) {
            // Wrap the entire app with ResponsiveWrapper to enforce text scaling limits
            // This prevents render overflow errors on smaller devices
            return ResponsiveWrapper(
              minTextScaleFactor: 0.8,
              maxTextScaleFactor: 1.3,
              child: child ?? const SizedBox.shrink(),
            );
          },
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
        onTap: _navigateToTab,
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
  
  bool _isInitializing = false; // Changed to false - will be set to true when initialization starts
  bool _isAuthenticated = false;
  bool _needsLocalUnlock = false;
  bool _needsLogin = false; // Changed to false initially - will be determined by initialization
  bool _needsPinSetup = false;
  bool _needsEmailVerification = false;
  bool _isReinitializing = false; // Prevent multiple simultaneous reinitializations
  bool _justCompletedMFA = false; // Track if user just completed MFA to skip duplicate email
  bool _showLoadingScreen = true; // Show loading screen until initialization completes
  bool _needsMfaVerification = false; // Untrusted device must pass OTP before anything else
  String? _mfaUserId;
  String? _mfaDeviceId;

  /// When the app was last sent to the background. Used on resume to decide
  /// whether enough time passed to require a re-unlock — see
  /// [didChangeAppLifecycleState]. Null while the app is in the foreground.
  DateTime? _backgroundedAt;

  /// Transient lifecycle blips shorter than this (the Android predictive-back
  /// gesture, a permission dialog, the keyboard) must NOT lock the app.
  static const Duration _minBackgroundBeforeLock = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to Firebase auth state changes (only if Firebase is initialized)
    if (FirebaseService.isInitialized) {
      try {
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
      } catch (e) {
        AppLogger.warning('Failed to listen to Firebase auth state changes: $e');
      }
    } else {
      AppLogger.info('Firebase not initialized - skipping auth state listener');
    }
    
    _initializeSecurity();
  }
  
  /// Reinitialize security with debouncing and retry to prevent race conditions
  Future<void> _reinitializeSecurity() async {
    if (_isReinitializing) return;
    _isReinitializing = true;
    
    // Don't show loading screen during reinitialize - keep current screen visible
    // This prevents the black screen issue
    
    // Shorter delay - tokens are usually ready immediately
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) {
      _isReinitializing = false;
      return;
    }
    
    // Try to initialize, with fewer retries and shorter delays
    for (int attempt = 0; attempt < 3; attempt++) {
      final isAuthenticated = await _authManager.isAuthenticated();
      AppLogger.info('Reinitialize attempt ${attempt + 1}: isAuthenticated=$isAuthenticated');
      
      if (isAuthenticated) {
        AppLogger.info('Authentication confirmed, initializing security...');
        await _initializeSecurity();
        _isReinitializing = false;
        return;
      }
      
      // Wait a bit before retrying
      if (attempt < 2) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) {
          _isReinitializing = false;
          return;
        }
      }
    }
    
    // If still not authenticated after retries, initialize anyway
    // (will show login screen)
    AppLogger.warning('Authentication not confirmed after 3 attempts, showing login screen');
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
    if (state == AppLifecycleState.paused) {
      // App is going to the background. Only REMEMBER when this happened — do
      // NOT lock here. Locking on every pause meant transient blips (the
      // predictive-back gesture, permission dialogs, the image picker, opening
      // Maps/the phone dialer) sent the user to the PIN screen during ordinary
      // in-app navigation — e.g. pressing back to go Home landed on the PIN
      // screen. The decision to lock is made on resume, based on elapsed time.
      if (_isAuthenticated) {
        _backgroundedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.detached) {
      // App is being closed/terminated, reset authentication state
      // This ensures fresh authentication check when app is reopened
      setState(() {
        _isAuthenticated = false;
        _needsLocalUnlock = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      // App is resuming from background
      // Only check unlock requirement if app was just backgrounded (not closed and reopened)
      if (_isAuthenticated) {
        _checkUnlockRequirement();
      } else {
        // App was closed and reopened, re-initialize security from scratch
        _initializeSecurity();
      }
    } else if (state == AppLifecycleState.inactive) {
      // App is transitioning (e.g., receiving a phone call)
      // Don't change state, just wait
    }
  }

  Future<void> _initializeSecurity() async {
    AppLogger.info('_initializeSecurity called');
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing && !_isReinitializing) {
      AppLogger.info('Already initializing, skipping duplicate call');
      return;
    }
    
    // Set flag to indicate initialization is starting
    // Only show loading screen if this is NOT a reinitialize (i.e., initial app startup)
    if (mounted) {
      setState(() {
        _isInitializing = true;
        // Only show loading screen on initial startup, not during reinitialize
        if (!_isReinitializing) {
          _showLoadingScreen = true;
        }
      });
    }
    
    // Add timeout to prevent hanging forever
    try {
      await _initializeSecurityWithTimeout();
    } catch (e, stackTrace) {
      AppLogger.error('Security initialization failed or timed out', error: e);
      AppLogger.error('Stack trace', error: stackTrace);
      if (!mounted) return;

      // A timeout does NOT mean the user is signed out. `Future.any` does not
      // cancel the losing future, so the real initialization is still running
      // and will set the correct state when its Firestore calls return.
      // Falling back to the login screen here is what made a freshly verified
      // user see the sign-in page flash before PIN setup.
      final hasFirebaseUser = FirebaseAuth.instance.currentUser != null;
      if (mounted) {
        setState(() {
          _isInitializing = false;
          if (hasFirebaseUser) {
            // Stay on the loading screen until the in-flight init finishes
            _showLoadingScreen = true;
          } else {
            _showLoadingScreen = false;
            _needsLogin = true;
            _needsPinSetup = false;
            _needsEmailVerification = false;
            _needsLocalUnlock = false;
          }
        });
      }
    }
  }

  Future<void> _initializeSecurityWithTimeout() async {
    // Wrap entire initialization in a timeout. Generous, because the device
    // trust check is a Firestore round-trip that is slow on emulators and
    // poor connections.
    await Future.any([
      _performSecurityInitialization(),
      Future.delayed(const Duration(seconds: 25)).then((_) {
        throw TimeoutException('Security initialization timed out after 25 seconds');
      }),
    ]);
  }

  Future<void> _performSecurityInitialization() async {
    try {
      // Reset authentication state at the start to ensure fresh check
      // This is important when app is closed and reopened
      if (_isInitializing && !_isReinitializing) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _needsLocalUnlock = false;
          });
        }
      }
      
      // Check if user is authenticated
      final isAuthenticated = await _authManager.isAuthenticated();
      AppLogger.info('isAuthenticated: $isAuthenticated');
      
      if (!mounted) return;
      
      if (!isAuthenticated) {
        AppLogger.info('Not authenticated, showing login screen');
        // No authentication, show login screen
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _showLoadingScreen = false;
            _isAuthenticated = false;
            _needsLogin = true;
            _needsPinSetup = false;
            _needsEmailVerification = false;
            _needsLocalUnlock = false;
          });
        }
        return;
      }

      // Email verification step removed — OTP (MFA) is the only email-based
      // verification in the auth flow. Firebase's emailVerified flag is
      // intentionally not checked here.

      // Reset MFA flag
      if (_justCompletedMFA) {
        if (mounted) {
          setState(() {
            _justCompletedMFA = false;
          });
        }
      }

      // Require OTP verification on devices this account hasn't trusted yet.
      // This is what routes a freshly created account through the OTP email:
      // registration signs the user in without passing the login MFA gate.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final deviceId = await _authManager.getCurrentDeviceId();
        final mfaRequired =
            await _authManager.isMfaRequiredForCurrentDevice(currentUser.uid);
        if (!mounted) return;

        if (mfaRequired) {
          AppLogger.info('Device not trusted yet, showing OTP verification');
          setState(() {
            _isInitializing = false;
            _showLoadingScreen = false;
            _needsLogin = false;
            _needsPinSetup = false;
            _needsMfaVerification = true;
            _mfaUserId = currentUser.uid;
            _mfaDeviceId = deviceId;
          });
          return;
        }
      }
      if (_needsMfaVerification && mounted) {
        setState(() => _needsMfaVerification = false);
      }

      // Validate session
      final sessionResult = await _authManager.validateSession();
      if (!mounted) return;
      
      if (!sessionResult.isValid) {
        // Session expired, show login screen
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _showLoadingScreen = false;
            _needsLogin = true;
            _needsPinSetup = false;
            _needsEmailVerification = false;
          });
        }
        return;
      }

      // Check if local unlock is configured
      final hasLocalUnlock = await _localUnlockService.isLocalUnlockAvailable();
      if (!mounted) return;
      
      if (!hasLocalUnlock) {
        // No local unlock configured, user needs to set it up
        AppLogger.info('No local unlock configured, showing PIN setup screen');
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _showLoadingScreen = false;
            _isAuthenticated = true;
            _needsLocalUnlock = false;
            _needsLogin = false;
            _needsPinSetup = true; // Show PIN setup screen
            _needsEmailVerification = false;
          });
        }
        return;
      }

      // Check if app should be locked
      final shouldLock = await _localUnlockService.shouldLockApp();
      if (!mounted) return;
      
      AppLogger.info('Security initialization complete, showing main app');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showLoadingScreen = false;
          _isAuthenticated = true;
          _needsLocalUnlock = shouldLock;
          _needsLogin = false;
          _needsPinSetup = false;
          _needsEmailVerification = false;
        });
      }

    } catch (e, stackTrace) {
      AppLogger.error('Security initialization failed', error: e);
      AppLogger.error('Stack trace', error: stackTrace);
      if (!mounted) return;
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showLoadingScreen = false;
          _needsLogin = true;
          _needsPinSetup = false;
          _needsEmailVerification = false;
          _needsLocalUnlock = false;
        });
      }
    }
  }

  Future<void> _checkUnlockRequirement() async {
    if (!_isAuthenticated) return;

    // Consume the backgrounded timestamp recorded in the paused handler.
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    // Resumed without a real pause, or only a transient blip (back gesture,
    // permission dialog, keyboard): never lock. This is what stops ordinary
    // in-app navigation from kicking the user to the PIN screen.
    if (backgroundedAt == null) return;
    final awayFor = DateTime.now().difference(backgroundedAt);
    if (awayFor < _minBackgroundBeforeLock) return;

    // Genuinely returned from the background: lock only if the idle timeout
    // has elapsed since the last unlock.
    final shouldLock = await _localUnlockService.shouldLockApp();
    if (shouldLock && !_needsLocalUnlock && mounted) {
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

  void _onEmailVerificationComplete() {
    // Re-initialize security to check if email is now verified
    if (mounted) {
      _initializeSecurity();
    }
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
    try {
      if (_showLoadingScreen) {
        return _buildLoadingScreen();
      }

      if (_needsLogin) {
        return LoginScreen(
          onAuthenticationComplete: () {
            // Re-check authentication after MFA completion
            AppLogger.info('Authentication completed, re-checking security state');
            // Use a post-frame callback to ensure state updates happen after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _justCompletedMFA = true; // Mark that user just completed MFA
                });
                _initializeSecurity();
              }
            });
          },
        );
      }

      if (_needsMfaVerification && _mfaUserId != null && _mfaDeviceId != null) {
        return MfaVerificationScreen(
          userId: _mfaUserId!,
          deviceId: _mfaDeviceId!,
          onVerificationSuccess: () {
            if (mounted) {
              setState(() {
                _needsMfaVerification = false;
                _justCompletedMFA = true;
              });
              _initializeSecurity();
            }
          },
          onSignOut: () {
            // The MFA screen is the root route here, so it cannot pop itself.
            // Leave the MFA gate and hand control back to the login screen.
            if (mounted) {
              setState(() {
                _needsMfaVerification = false;
                _mfaUserId = null;
                _mfaDeviceId = null;
                _isAuthenticated = false;
                _needsPinSetup = false;
                _needsLocalUnlock = false;
                _showLoadingScreen = false;
                _needsLogin = true;
              });
            }
          },
        );
      }

      if (_needsEmailVerification) {
        return EmailVerificationScreen(
          skipInitialEmail: _justCompletedMFA,
          onVerificationComplete: _onEmailVerificationComplete,
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
    } catch (e, stackTrace) {
      AppLogger.error('Error in SecurityWrapper build method', error: e);
      AppLogger.error('Stack trace', error: stackTrace);
      // Return a safe fallback widget
      return Scaffold(
        backgroundColor: AppTheme.getThemeAwareBackground(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'An error occurred',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Orbitron',
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = false; 
                    _showLoadingScreen = true;
                    _needsLogin = false;
                    _needsPinSetup = false;
                    _needsEmailVerification = false;
                    _needsLocalUnlock = false;
                    _isAuthenticated = false;
                  });
                  _initializeSecurity();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
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
