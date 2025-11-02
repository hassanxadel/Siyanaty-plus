import 'package:flutter/material.dart';
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
                          'Siyana+',
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
                    'Siyana+ revolutionizes car maintenance by providing intelligent, personalized solutions that keep your vehicle running at peak performance. We combine cutting-edge technology with practical insights to make car care simple and effective.',
                    Icons.flag,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Features Section
                  _buildSection(
                    context,
                    'Key Features',
                    '• Smart Maintenance Reminders\n• Real-time Vehicle Diagnostics\n• Service Center Locator\n• Comprehensive Maintenance History\n• OCR Document Scanner\n• VIN Decoder\n• Fuel Tracking\n• Cloud Backup & Sync',
                    Icons.stars,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Technology Section
                  _buildSection(
                    context,
                    'Technology Stack',
                    'Built with Flutter for cross-platform excellence, powered by Firebase for real-time synchronization, and enhanced with Google ML Kit for intelligent document processing.',
                    Icons.computer,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Contact Section
                  _buildSection(
                    context,
                    'Contact Us',
                    'Email: support@siyanaplus.com\nWebsite: www.siyanaplus.com\n\nWe value your feedback and are committed to continuously improving your experience.',
                    Icons.contact_mail,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Legal Section
                  _buildSection(
                    context,
                    'Legal',
                    '© 2024 Siyana+. All rights reserved.\n\nThis application is designed to assist with vehicle maintenance tracking and should not replace professional automotive advice.',
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
                  const SizedBox(width: 16),
                  const Text(
                    'About Siyana+',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
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
