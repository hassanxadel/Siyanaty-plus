import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
            // Quick Actions
            _buildQuickActions(context),
            
            const SizedBox(height: 32),
            
            // FAQ Section
            _buildFAQSection(),
            
            const SizedBox(height: 32),
            
            // Contact Support
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 16),
        
        _buildActionCard(
          'Getting Started Guide',
          'Learn how to set up your car profile and start tracking maintenance',
          Icons.play_circle_outline,
          () => _showGettingStarted(context),
        ),
        
        const SizedBox(height: 12),
        
        _buildActionCard(
          'Reset Account Data',
          'Clear all your data and start fresh',
          Icons.refresh,
          () => _showResetDialog(context),
        ),
        
        const SizedBox(height: 12),
        
        _buildActionCard(
          'Export Data',
          'Download your maintenance records and data',
          Icons.download,
          () => _exportData(context),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightBackground,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkAccentGreen.withOpacity(0.8),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.darkAccentGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 16),
        
        _buildFAQItem(
          'How do I add my first car?',
          'Go to the Home screen and tap the "+" button. Enter your car details including make, model, year, and mileage. The app will automatically set up maintenance schedules based on your vehicle.',
        ),
        
        _buildFAQItem(
          'How accurate are the maintenance reminders?',
          'Our AI analyzes your driving patterns, manufacturer recommendations, and real-world data to provide highly accurate reminders. You can also customize intervals based on your preferences.',
        ),
        
        _buildFAQItem(
          'Can I use the app without an internet connection?',
          'Yes! Most features work offline. Your data syncs automatically when you reconnect to the internet. Only real-time features like service center locations require an internet connection.',
        ),
        
        _buildFAQItem(
          'How do I connect my OBD device?',
          'Go to the OBD Dashboard and tap "Connect Device". Make sure your OBD adapter is plugged into your car and Bluetooth is enabled on your phone.',
        ),
        
        _buildFAQItem(
          'Is my data secure?',
          'Absolutely. All data is encrypted and stored securely. We never share your personal information with third parties. You can delete your account and all data at any time.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.lightBackground,
          fontFamily: 'Orbitron',
        ),
      ),
      iconColor: AppTheme.primaryGreen,
      collapsedIconColor: AppTheme.darkAccentGreen,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppTheme.darkAccentGreen.withOpacity(0.9),
              fontFamily: 'Orbitron',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Still Need Help?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Our support team is here to help you get the most out of Siyana+.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.lightBackground,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open email
                  },
                  icon: const Icon(Icons.email, size: 18),
                  label: const Text(
                    'Email Support',
                    style: TextStyle(fontFamily: 'Orbitron'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Open chat or phone
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text(
                    'Live Chat',
                    style: TextStyle(fontFamily: 'Orbitron'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGettingStarted(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundGreen,
        title: const Text(
          'Getting Started',
          style: TextStyle(color: AppTheme.primaryGreen, fontFamily: 'Orbitron'),
        ),
        content: const Text(
          '1. Add your car details in the Home screen\n'
          '2. Set up maintenance reminders\n'
          '3. Connect your OBD device (optional)\n'
          '4. Start tracking your car\'s health!\n\n'
          'Need more help? Check our full tutorial in the app.',
          style: TextStyle(color: AppTheme.lightBackground, fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: AppTheme.primaryGreen, fontFamily: 'Orbitron'),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundGreen,
        title: const Text(
          'Reset Account Data',
          style: TextStyle(color: AppTheme.errorColor, fontFamily: 'Orbitron'),
        ),
        content: const Text(
          'This will permanently delete all your cars, maintenance records, and settings. This action cannot be undone.',
          style: TextStyle(color: AppTheme.lightBackground, fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.darkAccentGreen, fontFamily: 'Orbitron'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement reset logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account data reset successfully'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.errorColor, fontFamily: 'Orbitron'),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting your data...'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
    // Implement export logic
  }
}
