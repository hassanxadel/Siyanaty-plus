import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using Siyana+ ("the App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'Siyana+ is a car maintenance management application that provides:\n\n'
              '• Maintenance tracking and reminders\n'
              '• Vehicle diagnostics integration\n'
              '• Service history management\n'
              '• Performance analytics\n'
              '• Service center recommendations',
            ),
            
            _buildSection(
              '3. User Account and Responsibilities',
              'You are responsible for:\n\n'
              '• Maintaining the confidentiality of your account\n'
              '• All activities that occur under your account\n'
              '• Providing accurate and up-to-date information\n'
              '• Notifying us immediately of any unauthorized use\n'
              '• Using the service in compliance with applicable laws',
            ),
            
            _buildSection(
              '4. Acceptable Use',
              'You agree not to:\n\n'
              '• Use the service for any unlawful purpose\n'
              '• Attempt to gain unauthorized access to our systems\n'
              '• Interfere with or disrupt the service\n'
              '• Upload malicious code or content\n'
              '• Reverse engineer or copy our software\n'
              '• Share your account with others',
            ),
            
            _buildSection(
              '5. Data and Privacy',
              'Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy, which is incorporated by reference into these Terms.',
            ),
            
            _buildSection(
              '6. Disclaimer of Warranties',
              'The service is provided "as is" without warranties of any kind. We do not warrant that:\n\n'
              '• The service will be uninterrupted or error-free\n'
              '• Defects will be corrected\n'
              '• The service is free of viruses or harmful components\n'
              '• Results from using the service will meet your requirements',
            ),
            
            _buildSection(
              '7. Limitation of Liability',
              'In no event shall Siyana+ be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, or other intangible losses.',
            ),
            
            _buildSection(
              '8. Vehicle Safety',
              'Important: Siyana+ provides maintenance suggestions and reminders for informational purposes only. Always:\n\n'
              '• Consult qualified mechanics for vehicle issues\n'
              '• Follow manufacturer recommendations\n'
              '• Use professional diagnostic tools for safety-critical systems\n'
              '• Do not rely solely on app diagnostics for vehicle safety',
            ),
            
            _buildSection(
              '9. Subscription and Payments',
              'Some features may require subscription. Subscription fees are charged in advance and are non-refundable. You may cancel your subscription at any time through your account settings.',
            ),
            
            _buildSection(
              '10. Termination',
              'We may terminate or suspend your account immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users of the service, us, or third parties.',
            ),
            
            _buildSection(
              '11. Changes to Terms',
              'We reserve the right to modify these terms at any time. We will notify users of any changes by posting the new terms in the app. Your continued use constitutes acceptance of the new terms.',
            ),
            
            _buildSection(
              '12. Governing Law',
              'These Terms shall be interpreted and governed by the laws of the jurisdiction in which our company is incorporated, without regard to conflict of law provisions.',
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
                    'Questions?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'If you have any questions about these Terms of Service:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightBackground,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email: legal@siyanaplus.com\n'
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
