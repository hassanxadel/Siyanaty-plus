import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Modern create account screen with animated entrance and form validation
/// Handles user registration through Firebase Auth
class ModernCreateAccountScreen extends StatefulWidget {
  /// Callback function triggered after successful registration
  final VoidCallback? onRegistration;
  const ModernCreateAccountScreen({super.key, this.onRegistration});

  @override
  State<ModernCreateAccountScreen> createState() => _ModernCreateAccountScreenState();
}

/// State class for the modern create account screen
/// Manages form state, animations, and registration logic
class _ModernCreateAccountScreenState extends State<ModernCreateAccountScreen>
    with TickerProviderStateMixin {
  /// Controllers for input fields
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  
  /// Form validation key for input validation
  final _formKey = GlobalKey<FormState>();
  
  /// Toggle for password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  /// Loading state during registration
  bool _isLoading = false;
  
  /// Selected country code
  final String _selectedCountryCode = '+20';
  
  /// Controller for fade-in animation
  late AnimationController _fadeController;
  /// Controller for slide-up animation
  late AnimationController _slideController;
  /// Fade animation for smooth entrance
  late Animation<double> _fadeAnimation;
  /// Slide animation for content movement
  late Animation<Offset> _slideAnimation;



  /// Initialize animation controllers and start entrance animations
  @override
  void initState() {
    super.initState();
    /// Create fade controller for smooth opacity transition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    /// Create slide controller for content movement
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    /// Configure fade animation for form elements
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    /// Configure slide animation for content entrance
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    /// Start both animations for smooth entrance
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo at top
                    SizedBox(
                      height: 100,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 22),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildRegistrationForm(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightBackground.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: AppTheme.backgroundGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightBackground,
                  fontFamily: 'Orbitron',
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.lightBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: AppTheme.lightBackground,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Join Siyana+ for smart car maintenance',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.lightBackground.withOpacity(0.9),
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name Field
        const Text(
          'Full Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildFullNameField(),
        const SizedBox(height: 24),
        
        // Mobile Number Field
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildMobileField(),
        const SizedBox(height: 24),
        
        // Email Field
        const Text(
          'Email address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildEmailField(),
        const SizedBox(height: 24),
        
        // Password Field
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildPasswordField(),
        const SizedBox(height: 24),
        
        // Confirm Password Field
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildConfirmPasswordField(),
        const SizedBox(height: 24),
        
        // Emergency Contact Section
        const Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        _buildEmergencyContactSection(),
      ],
    );
  }

  Widget _buildFullNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBackground.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: TextFormField(
        controller: _fullNameController,
        keyboardType: TextInputType.name,
        style: const TextStyle(
          color: AppTheme.lightBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
        decoration: const InputDecoration(
          hintText: 'Enter your full name',
          hintStyle: TextStyle(
            color: AppTheme.lightBackground,
            fontSize: 16,
            fontFamily: 'Orbitron',
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your full name';
          }
          if (value.length < 2) {
            return 'Name must be at least 2 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMobileField() {
    return Row(
      children: [
        // Country Code Display (Egypt Only)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.3),
              width: 1.5,
            ),
            color: Colors.transparent,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Egyptian Flag Emoji
                Text(
                  '🇪🇬',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: 8),
                // Country Code
                Text(
                  '+20',
                  style: TextStyle(
                    color: AppTheme.lightBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Mobile Number Input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.lightBackground.withOpacity(0.3),
                width: 1.5,
              ),
              color: Colors.transparent,
            ),
            child: TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                color: AppTheme.lightBackground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Orbitron',
              ),
              decoration: const InputDecoration(
                hintText: 'Mobile number',
                hintStyle: TextStyle(
                  color: AppTheme.lightBackground,
                  fontSize: 16,
                  fontFamily: 'Orbitron',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your mobile number';
                }
                if (value.length < 10) {
                  return 'Mobile number must be at least 10 digits';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBackground.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: AppTheme.lightBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
        decoration: const InputDecoration(
          hintText: 'Email address',
          hintStyle: TextStyle(
            color: AppTheme.lightBackground,
            fontSize: 16,
            fontFamily: 'Orbitron',
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBackground.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(
          color: AppTheme.lightBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            color: AppTheme.lightBackground,
            fontSize: 16,
            fontFamily: 'Orbitron',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.primaryGreen,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightBackground.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmPasswordVisible,
        style: const TextStyle(
          color: AppTheme.lightBackground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Orbitron',
        ),
        decoration: InputDecoration(
          hintText: 'Confirm password',
          hintStyle: const TextStyle(
            color: AppTheme.lightBackground,
            fontSize: 16,
            fontFamily: 'Orbitron',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.primaryGreen,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      children: [
        // Emergency Contact Name
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightBackground.withOpacity(0.3),
              width: 1.5,
            ),
            color: Colors.transparent,
          ),
          child: TextFormField(
            controller: _emergencyContactNameController,
            keyboardType: TextInputType.name,
            style: const TextStyle(
              color: AppTheme.lightBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
            decoration: const InputDecoration(
              hintText: 'Emergency contact name',
              hintStyle: TextStyle(
                color: AppTheme.lightBackground,
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter emergency contact name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        // Emergency Contact Phone
        Row(
          children: [
            // Country Code Display (Egypt Only)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.lightBackground.withOpacity(0.3),
                  width: 1.5,
                ),
                color: Colors.transparent,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Egyptian Flag Emoji
                    Text(
                      '🇪🇬',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    // Country Code
                    Text(
                      '+20',
                      style: TextStyle(
                        color: AppTheme.lightBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Emergency Contact Phone Number Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.lightBackground.withOpacity(0.3),
                    width: 1.5,
                  ),
                  color: Colors.transparent,
                ),
                child: TextFormField(
                  controller: _emergencyContactPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: AppTheme.lightBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Emergency contact phone',
                    hintStyle: TextStyle(
                      color: AppTheme.lightBackground,
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter emergency contact phone';
                    }
                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isLoading 
            ? null 
            : const LinearGradient(
                colors: [AppTheme.lightBackground, AppTheme.secondaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isLoading ? AppTheme.lightBackground.withOpacity(0.3) : null,
        boxShadow: _isLoading ? null : [
          BoxShadow(
            color: AppTheme.lightBackground.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _handleRegistration,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundGreen),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.backgroundGreen,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: AppTheme.backgroundGreen,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: AppTheme.lightBackground.withOpacity(0.6),
            fontSize: 14,
            fontFamily: 'Orbitron',
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppTheme.secondaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.secondaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: '$_selectedCountryCode${_mobileController.text.trim()}',
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: '$_selectedCountryCode${_emergencyContactPhoneController.text.trim()}',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Show success feedback with haptic
          HapticFeedback.mediumImpact();
          
          // Show success message with email verification notice
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Welcome! Please check your email to verify your account',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Auto-navigate to main app after brief delay
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            // The AuthWrapper will automatically detect the authentication
            // and navigate to the appropriate screen (PIN setup or home)
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        } else {
          // Show error message with icon
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage ?? 'Registration failed. Please try again.',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
