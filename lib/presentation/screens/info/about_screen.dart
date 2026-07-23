import 'package:flutter/material.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/constants/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon and Name
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.darkAccentGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            IconData(0xe800, fontFamily: 'MyFlutterApp'),
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Siyanaty+',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        const Text(
                          'Smart Car Maintenance Companion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontFamily: 'Orbitron',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        const Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Mission Section
                  _buildSection(
                    context,
                    'Our Mission',
                    'Siyanaty+ helps you take care of your car with confidence. We bring '
                        'your maintenance history, reminders, mileage and diagnostics '
                        'together in one place, so nothing important slips through the '
                        'cracks — whether you own one car or a whole garage. Our goal is '
                        'simple: keep your vehicle safe, reliable and running longer, '
                        'without the guesswork.',
                    Icons.flag,
                  ),

                  const SizedBox(height: 20),

                  // Features Section
                  _buildSection(
                    context,
                    'What You Can Do',
                    '• Track maintenance history and costs for every car\n'
                        '• Get smart reminders before services fall due\n'
                        '• Automatically keep your mileage up to date\n'
                        '• Read live engine data over an OBD-II adapter\n'
                        '• Scan service documents with the OCR scanner\n'
                        '• Decode your VIN and store car & licence details\n'
                        '• Find nearby service centers and save favourites\n'
                        '• Back up and restore everything to the cloud',
                    Icons.stars,
                  ),

                  const SizedBox(height: 20),

                  // Privacy Section
                  _buildSection(
                    context,
                    'Your Data, Your Control',
                    'Siyanaty+ is offline-first: your records live on your device and '
                        'sync to your private cloud backup only when you choose. Sensitive '
                        'information is encrypted, and you can export or permanently delete '
                        'all of your data — on the device and in the cloud — at any time '
                        'from Settings.',
                    Icons.shield_outlined,
                  ),

                  const SizedBox(height: 20),

                  // Contact Section
                  _buildSection(
                    context,
                    'Get in Touch',
                    'We\'d love to hear your feedback and ideas.\n\n'
                        'Email: ${AppConstants.supportEmail}\n\n'
                        'You can also reach us any time from Help & Support inside the app.',
                    Icons.contact_mail,
                  ),

                  const SizedBox(height: 20),

                  // Legal Section
                  _buildSection(
                    context,
                    'Legal',
                    '© 2026 Siyanaty+. All rights reserved.\n\n'
                        'Siyanaty+ is a maintenance-tracking assistant. It supports, but '
                        'does not replace, inspection and advice from a qualified '
                        'mechanic. Always follow your manufacturer\'s guidance for your '
                        'specific vehicle.',
                    Icons.gavel,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Made with love
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Made with',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'for car enthusiasts',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'About Siyanaty+',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Learn more about our mission and features',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
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
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Orbitron',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
