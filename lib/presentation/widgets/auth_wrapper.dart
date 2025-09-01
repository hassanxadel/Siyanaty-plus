import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Authentication wrapper that manages app access based on user login status
/// Routes users to appropriate screens (login, main app, or error) based on auth state
class AuthWrapper extends StatelessWidget {
  /// Main app content to show when user is authenticated
  final Widget child;
  
  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        /// Display splash screen while checking authentication status
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        /// Show error screen if authentication process failed
        if (authProvider.errorMessage != null) {
          return _buildErrorScreen(context, authProvider.errorMessage!);
        }

        /// Display login screen for unauthenticated users
        if (!authProvider.isAuthenticated) {
          return ModernLoginScreen(
            onLogin: () {
              /// Authentication logic is handled by the provider
              /// Navigation occurs automatically when auth state changes
            },
          );
        }

        /// Show main app content for authenticated users
        return child;
      },
    );
  }

  /// Builds error screen displayed when authentication fails
  /// Shows error message with retry option
  Widget _buildErrorScreen(BuildContext context, String errorMessage) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Error icon with circular background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppTheme.errorColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              /// Error title text
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              /// Dynamic error message from provider
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.lightBackground.withOpacity(0.8),
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              /// Retry button for authentication
              ElevatedButton(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
