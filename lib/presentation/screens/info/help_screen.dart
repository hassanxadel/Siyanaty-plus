import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/data_export_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/app_dialog.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                  // Quick Actions
                  _buildQuickActions(context),
                  
                  const SizedBox(height: 24),
                  
                  // FAQ Section
                  _buildFAQSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Support
                  _buildContactSupport(context),
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
                      'Help & Support',
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
                  'Get help and find answers to common questions',
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

  Widget _buildQuickActions(BuildContext context) {
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionCard(
            context,
            'Getting Started Guide',
            'Learn how to set up your car profile and start tracking maintenance',
            Icons.play_circle_outline,
            () => _showGettingStarted(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionCard(
            context,
            'Reset Account Data',
            'Clear all your data and start fresh',
            Icons.refresh,
            () => _showResetDialog(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionCard(
            context,
            'Export Data',
            'Download your maintenance records and data',
            Icons.download,
            () => _exportData(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundGreen,
              AppTheme.primaryGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
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
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFAQItem(
            context,
            'How do I add my first car?',
            'Go to the Home screen and tap the "+" button. Enter your car details including make, model, year, and mileage. The app will automatically set up maintenance schedules based on your vehicle.',
          ),
          
          _buildFAQItem(
            context,
            'How accurate are the maintenance reminders?',
            'Our AI analyzes your driving patterns, manufacturer recommendations, and real-world data to provide highly accurate reminders. You can also customize intervals based on your preferences.',
          ),
          
          _buildFAQItem(
            context,
            'Can I use the app without an internet connection?',
            'Yes! Most features work offline. Your data syncs automatically when you reconnect to the internet. Only real-time features like service center locations require an internet connection.',
          ),
          
          _buildFAQItem(
            context,
            'How do I connect my OBD device?',
            'Go to the OBD Dashboard and tap "Connect Device". Make sure your OBD adapter is plugged into your car and Bluetooth is enabled on your phone.',
          ),
          
          _buildFAQItem(
            context,
            'Is my data secure?',
            'Absolutely. All data is encrypted and stored securely. We never share your personal information with third parties. You can delete your account and all data at any time.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: const ExpansionTileThemeData(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Orbitron',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.white70,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport(BuildContext context) {
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
          const Text(
            'Still Need Help?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Our support team is here to help you get the most out of Siyana+.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
          ),
              const SizedBox(height: 16),
          
          // Email support — opens the phone's mail app with a draft to the
          // support address. (The "Chat" button was removed — there is no
          // chat backend.)
          SizedBox(
            width: double.infinity,
            child: _buildFadedPill(
              label: 'Email Support',
              icon: Icons.email_outlined,
              accent: AppTheme.secondaryGreen,
              onTap: () => _emailSupport(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Faded pill button — tinted fill, glowing rim, accent-coloured label.
  Widget _buildFadedPill({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.glowButtonDecoration(accent: accent),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _emailSupport(BuildContext context) async {
    // A mailto: URI opens the user's default mail app with the fields
    // pre-filled; the user reviews and sends it themselves.
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: 'subject=${Uri.encodeComponent('Siyanaty+ Support Request')}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnackbar.show(
        context,
        const SnackBar(
          content: Text(
            'No email app found. Reach us at ${AppConstants.supportEmail}',
            style: TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _showGettingStarted(BuildContext context) {
    AppDialog.message(
      context,
      title: 'Getting Started',
      message: '1. Add your car details in the Home screen\n'
          '2. Set up maintenance reminders\n'
          '3. Connect your OBD device (optional)\n'
          '4. Start tracking your car\'s health!\n\n'
          'Need more help? Check our full tutorial in the app.',
      icon: Icons.rocket_launch_outlined,
      buttonLabel: 'Got it!',
    );
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Reset Account Data',
      message:
          'This will permanently delete all your cars, maintenance records, and settings. This action cannot be undone.',
      icon: Icons.restart_alt,
      confirmLabel: 'Reset',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    // Implement reset logic
    AppSnackbar.show(context,
      const SnackBar(
        content: Text('Account data reset successfully', style: TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Export Data',
      message:
          'This gathers your cars, maintenance records, reminders and mileage '
          'into a file you can save or share, so you have your own copy of '
          'everything stored in the app.\n\n'
          'Do you want to export your data now?',
      icon: Icons.download_outlined,
      confirmLabel: 'Export',
    );

    if (confirmed != true || !context.mounted) return;

    AppSnackbar.show(context,
      const SnackBar(
        content: Text('Preparing your data export...', style: TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );

    final result = await DataExportService.instance.exportToFile();
    if (!context.mounted) return;

    if (!result.isSuccess || result.file == null) {
      AppSnackbar.show(context,
        SnackBar(
          content: Text(result.message, style: const TextStyle(fontFamily: 'Orbitron')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Hand the file to the OS share sheet — from there the user can save it to
    // Files/Drive or send it through any app.
    await Share.shareXFiles(
      [XFile(result.file!.path)],
      subject: 'Siyanaty+ data export',
      text: 'My Siyanaty+ data export.',
    );
  }
}

