import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
            const Text(
              'Your Privacy Matters',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: January 2025',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkAccentGreen,
                fontFamily: 'Orbitron',
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, such as:\n\n'
              '• Vehicle information (make, model, year, mileage)\n'
              '• Maintenance records and service history\n'
              '• Account information (email, profile details)\n'
              '• App usage data and preferences\n'
              '• OBD diagnostic data (when connected)',
            ),
            
            _buildSection(
              '2. How We Use Your Information',
              'We use your information to:\n\n'
              '• Provide personalized maintenance reminders\n'
              '• Analyze vehicle performance and health\n'
              '• Improve our services and user experience\n'
              '• Send important updates and notifications\n'
              '• Provide customer support',
            ),
            
            _buildSection(
              '3. Information Sharing',
              'We do not sell, trade, or share your personal information with third parties, except:\n\n'
              '• When required by law or legal process\n'
              '• To protect our rights and safety\n'
              '• With your explicit consent\n'
              '• With trusted service providers who assist our operations',
            ),
            
            _buildSection(
              '4. Data Security',
              'We implement industry-standard security measures:\n\n'
              '• End-to-end encryption for sensitive data\n'
              '• Secure cloud storage with Firebase\n'
              '• Regular security audits and updates\n'
              '• Access controls and authentication\n'
              '• Automatic logout after inactivity',
            ),
            
            _buildSection(
              '5. Your Rights',
              'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Correct inaccurate information\n'
              '• Delete your account and data\n'
              '• Export your data\n'
              '• Opt-out of non-essential communications',
            ),
            
            _buildSection(
              '6. Data Retention',
              'We retain your information for as long as your account is active or as needed to provide services. You may delete your account at any time through the app settings.',
            ),
            
            _buildSection(
              '7. Children\'s Privacy',
              'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
            ),
            
            _buildSection(
              '8. Changes to Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last updated" date.',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'If you have questions about this privacy policy or our practices:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightBackground,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email: privacy@siyanaplus.com\n'
                    'Address: 123 Tech Street, Innovation City, IC 12345',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkAccentGreen,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppTheme.darkAccentGreen.withOpacity(0.9),
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }
}
