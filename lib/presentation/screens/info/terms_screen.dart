import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                          Icons.description,
                          size: 64,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Terms of Service',
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
                    'Acceptance of Terms',
                    'By accessing and using Siyana+ mobile application, you accept and agree to be bound by the terms and provisions of this agreement. '
                    'If you do not agree to these terms, please do not use our service.',
                    Icons.check_circle,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Use License',
                    'Permission is granted to temporarily download one copy of Siyana+ for personal, non-commercial use only. '
                    'This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                    '• Modify or copy the materials\n'
                    '• Use the materials for any commercial purpose\n'
                    '• Attempt to decompile or reverse engineer any software\n'
                    '• Remove any copyright or proprietary notations\n'
                    '• Transfer the materials to another person',
                    Icons.verified_user,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'User Account',
                    'You are responsible for:\n'
                    '• Maintaining the confidentiality of your account\n'
                    '• All activities that occur under your account\n'
                    '• Notifying us immediately of any unauthorized use\n'
                    '• Ensuring your account information is accurate and up-to-date',
                    Icons.account_circle,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Service Availability',
                    'We strive to provide uninterrupted service, but we do not guarantee that:\n'
                    '• The service will be available at all times\n'
                    '• The service will be error-free\n'
                    '• Defects will be corrected immediately\n'
                    '• The service will meet your specific requirements',
                    Icons.cloud_done,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Disclaimer',
                    'The materials and services provided by Siyana+ are provided "as is". '
                    'We make no warranties, expressed or implied, and hereby disclaim all other warranties. '
                    'Furthermore, we do not warrant or make any representations concerning the accuracy, likely results, or reliability of the use of the materials.',
                    Icons.warning,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Limitations',
                    'In no event shall Siyana+ or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) '
                    'arising out of the use or inability to use the materials on Siyana+ app.',
                    Icons.block,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Modifications',
                    'We may revise these terms of service at any time without notice. '
                    'By using this app, you are agreeing to be bound by the current version of these terms of service. '
                    'Continued use of the service after changes constitutes acceptance of the modified terms.',
                    Icons.edit,
                  ),
                  
                    const SizedBox(height: 20),
                  
                  _buildSection(
                    'Contact Information',
                    'If you have any questions about these Terms of Service, please contact us at:\n\n'
                    'Email: support@siyanaplus.com\n'
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
                    'Terms of Service',
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
                  'Please read these terms carefully',
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
