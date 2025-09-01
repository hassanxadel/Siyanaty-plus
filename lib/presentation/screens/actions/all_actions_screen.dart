import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../services/vin_lookup_screen.dart';
import '../services/ocr_scanner_screen.dart';
import '../services/barcode_scanner_screen.dart';
import '../services/voice_notes_screen.dart';
import '../services/mileage_track_screen.dart';
import '../services/reminders_screen.dart';
import '../services/obd_screen.dart';
import '../services/services_screen.dart';
import '../services/cars_screen.dart';
import '../services/maintenance_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class AllActionsScreen extends StatelessWidget {
  const AllActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'VIN Lookup', 'subtitle': 'Maintenance Recommendations', 'icon': Icons.search, 'color': AppTheme.primaryGreen},
      {'label': 'OCR Scanner', 'subtitle': 'Extract Data from Service Reports', 'icon': Icons.document_scanner, 'color': const Color(0xFF8E44AD)},
      {'label': 'Barcode Scanner', 'subtitle': 'Part Details & Product Information', 'icon': Icons.qr_code_scanner, 'color': AppTheme.darkAccentGreen},
      {'label': 'Voice Notes', 'subtitle': 'Quick Maintenance Notes', 'icon': Icons.mic, 'color': const Color(0xFF7B2CBF)},
      {'label': 'Mileage Track', 'subtitle': 'Tracking & Predictive Alerts', 'icon': Icons.track_changes, 'color': const Color(0xFFFF6B35)},
      {'label': 'Maintenance', 'subtitle': 'Service History & Records', 'icon': Icons.calendar_month, 'color': const Color(0xFF8B5CF6)},
      {'label': 'OBD-II Diagnostics', 'subtitle': 'Real-time Vehicle Diagnostics', 'icon': Icons.cable, 'color': AppTheme.primaryGreen},
      {'label': 'Service Centers', 'subtitle': 'Nearby Service Centers & Last Parked Location', 'icon': Icons.location_on, 'color': const Color(0xFF10B981)},
      {'label': 'Service Reminders', 'subtitle': 'Maintenance Logs & Reminders', 'icon': Icons.schedule, 'color': const Color(0xFFF59E0B)},
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header with gradient background
          _buildHeader(context),
          
          // Actions grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _buildActionCard(
                    context,
                    action['label'] as String,
                    action['subtitle'] as String,
                    action['icon'] as IconData,
                    action['color'] as Color,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (i) {}),
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
              // Top row with back button and title
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
                    'All Actions',
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
              
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Complete suite of vehicle management tools',
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

  Widget _buildActionCard(BuildContext context, String label, String subtitle, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToService(context, label);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkAccentGreen.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.lightBackground
                    : Colors.black,
                fontFamily: 'Orbitron',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.lightBackground.withOpacity(0.8)
                      : Colors.black,
                  fontFamily: 'Orbitron',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToService(BuildContext context, String serviceName) {
    // Navigate to specific screens for fully implemented features
    switch (serviceName.toLowerCase()) {
      case 'vin lookup':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VinLookupScreen()),
        );
        break;
      case 'ocr scanner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OcrScannerScreen()),
        );
        break;
      case 'barcode scanner':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
        );
        break;
      case 'voice notes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VoiceNotesScreen()),
        );
        break;
      case 'mileage track':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MileageTrackScreen()),
        );
        break;
      case 'maintenance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MaintenanceRecordsScreen()),
        );
        break;
      case 'service reminders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SmartRemindersScreen()),
        );
        break;
      case 'obd-ii diagnostics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OBDDashboardScreen()),
        );
        break;
      case 'service centers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServiceCentersScreen()),
        );
        break;
      case 'multi-car':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyCarsScreen()),
        );
        break;
      default:
        _showMessage(context, 'Service coming soon!');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
