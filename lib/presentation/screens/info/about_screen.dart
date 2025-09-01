import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'About Siyana+',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.backgroundGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                      color: AppTheme.primaryGreen,
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
                      color: AppTheme.lightBackground,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Smart Car Maintenance Companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.darkAccentGreen,
                      fontFamily: 'Orbitron',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkAccentGreen,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Mission Section
            _buildSection(
              'Our Mission',
              'Siyana+ revolutionizes car maintenance by providing intelligent, personalized solutions that keep your vehicle running at peak performance. We combine cutting-edge technology with practical insights to make car care simple and effective.',
            ),
            
            const SizedBox(height: 24),
            
            // Features Section
            _buildSection(
              'Key Features',
              '• Smart maintenance reminders based on your driving patterns\n'
              '• Real-time OBD diagnostics and health monitoring\n'
              '• Comprehensive service history tracking\n'
              '• Fuel efficiency optimization tips\n'
              '• Local service center recommendations\n'
              '• Intelligent cost tracking and budgeting',
            ),
            
            const SizedBox(height: 24),
            
            // Technology Section
            _buildSection(
              'Technology',
              'Built with Flutter for seamless cross-platform performance, powered by Firebase for real-time data synchronization, and enhanced with AI-driven insights to provide the most accurate maintenance predictions.',
            ),
            
            const SizedBox(height: 24),
            
            // Contact Section
            _buildSection(
              'Contact Us',
              'For questions, suggestions, or support:\n\n'
              'Email: support@siyanaplus.com\n'
              'Website: www.siyanaplus.com\n'
              'Phone: +20 1125717681',
            ),
            
            const SizedBox(height: 40),
            
            // Copyright
            Center(
              child: Text(
                '© 2025 Siyana+. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkAccentGreen.withOpacity(0.7),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }
}
