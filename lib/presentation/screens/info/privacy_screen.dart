import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.privacy_tip,
                          size: 64,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
              'Your Privacy Matters',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                            color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
                        SizedBox(height: 8),
            Text(
              'Last updated: January 2025',
              style: TextStyle(
                fontSize: 12,
                            color: Colors.white70,
                fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
              ),
            ),
            
                  const SizedBox(height: 32),
            
            _buildSection(
                    'Information We Collect',
              '• Vehicle information (make, model, year, mileage)\n'
              '• Maintenance records and service history\n'
                    '• Reminders and notifications preferences\n'
                    '• Location data (only when using service center locator)\n'
                    '• Account information (email, name, profile picture)',
                    Icons.info,
                  ),
                  
                  const SizedBox(height: 20),
            
            _buildSection(
                    'How We Use Your Information',
                    '• To provide and maintain our service\n'
                    '• To send maintenance reminders and notifications\n'
                    '• To improve and personalize your experience\n'
                    '• To analyze usage patterns and optimize features\n'
                    '• To communicate important updates',
                    Icons.settings,
                  ),
                  
                  const SizedBox(height: 20),
            
            _buildSection(
                    'Data Storage & Security',
                    'Your data is stored securely using industry-standard encryption. '
                    'We use Firebase services for cloud storage and authentication. '
                    'Local data is stored on your device and synced to the cloud only when you choose to enable backup.',
                    Icons.security,
                  ),
                  
                  const SizedBox(height: 20),
            
            _buildSection(
                    'Data Sharing',
                    'We do not sell, trade, or rent your personal information to third parties. '
                    'Your data is only shared with:\n'
                    '• Firebase (Google) for cloud storage and authentication\n'
                    '• Google Maps for location services\n'
                    '• No other third parties have access to your data',
                    Icons.share,
                  ),
                  
                  const SizedBox(height: 20),
            
            _buildSection(
                    'Your Rights',
                    '• Access your personal data at any time\n'
                    '• Request data deletion from our servers\n'
                    '• Export your data in a portable format\n'
                    '• Opt-out of notifications\n'
                    '• Delete your account and all associated data',
                    Icons.verified_user,
                  ),
                  
                  const SizedBox(height: 20),
            
            _buildSection(
                    'Contact Us',
                    'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                    'Email: privacy@siyanaplus.com\n'
                    'Website: www.siyanaplus.com',
                    Icons.contact_mail,
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
                    'Privacy Policy',
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
                  'How we protect and handle your data',
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

  Widget _buildSection(String title, String content, IconData icon) {
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
                    fontSize: 18,
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
