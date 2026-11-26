import 'package:flutter/cupertino.dart';

import '../../shared/constants/app_theme.dart';
import '../screens/health/car_health_dashboard_screen.dart';
import '../screens/services/maintenance_screen.dart';
import '../screens/services/mileage_track_screen.dart';
import '../screens/services/obd_screen.dart';
import '../screens/services/ocr_scanner_screen.dart';
import '../screens/services/reminders_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/services/vin_lookup_screen.dart';
import '../screens/services/voice_notes_screen.dart';

/// The grouping an [AppAction] belongs to on the All Actions screen.
enum AppActionCategory { vehicle, maintenance, documents, tools }

extension AppActionCategoryLabel on AppActionCategory {
  String get label {
    switch (this) {
      case AppActionCategory.vehicle:
        return 'Vehicle';
      case AppActionCategory.maintenance:
        return 'Maintenance';
      case AppActionCategory.documents:
        return 'Documents';
      case AppActionCategory.tools:
        return 'Tools';
    }
  }
}

/// A single app action (tool). This is the ONE source of truth for the Home
/// Actions tiles and the All Actions screen — define each action here so the
/// name, icon, colour and destination can never drift between the two places.
@immutable
class AppAction {
  final String id;

  /// Short name shown on both the Home tile and the All Actions card (yellow).
  final String title;

  /// One-line description shown on the All Actions card (white).
  final String subtitle;

  /// SF-Symbols-style (Cupertino) icon.
  final IconData icon;

  /// The icon's own colour (matching the Home tiles); text is never this colour.
  final Color iconColor;

  final AppActionCategory category;

  /// Whether this action appears among the 6 tiles on the Home screen.
  final bool showOnHome;

  /// Builds the destination screen.
  final WidgetBuilder builder;

  const AppAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.category,
    required this.builder,
    this.showOnHome = false,
  });
}

/// Every action in the app, in display order. The first six are the Home tiles
/// (keep their title/icon/colour exactly as the Home screen shows them).
final List<AppAction> kAppActions = <AppAction>[
  AppAction(
    id: 'vin_lookup',
    title: 'VIN Lookup',
    subtitle: 'Decode your VIN & get recommendations',
    icon: CupertinoIcons.barcode_viewfinder,
    iconColor: AppTheme.infoBlue,
    category: AppActionCategory.vehicle,
    showOnHome: true,
    builder: (_) => const VinLookupScreen(),
  ),
  AppAction(
    id: 'ocr_scanner',
    title: 'OCR Scanner',
    subtitle: 'Extract data from service reports',
    icon: CupertinoIcons.doc_text_viewfinder,
    iconColor: AppTheme.costHighlight,
    category: AppActionCategory.documents,
    showOnHome: true,
    builder: (_) => const OcrScannerScreen(),
  ),
  AppAction(
    id: 'car_health',
    title: 'Car Health',
    subtitle: 'Health score, analytics & insights',
    icon: CupertinoIcons.heart_fill,
    iconColor: AppTheme.errorColor,
    category: AppActionCategory.vehicle,
    showOnHome: true,
    builder: (_) => const CarHealthDashboardScreen(),
  ),
  AppAction(
    id: 'voice_notes',
    title: 'Voice Notes',
    subtitle: 'Quick maintenance notes',
    icon: CupertinoIcons.mic_fill,
    iconColor: AppTheme.warningColor,
    category: AppActionCategory.documents,
    showOnHome: true,
    builder: (_) => const VoiceNotesScreen(),
  ),
  AppAction(
    id: 'mileage_track',
    title: 'Mileage Track',
    subtitle: 'Tracking & predictive alerts',
    icon: CupertinoIcons.gauge,
    iconColor: AppTheme.secondaryGreen,
    category: AppActionCategory.maintenance,
    showOnHome: true,
    builder: (_) => const MileageTrackScreen(),
  ),
  AppAction(
    id: 'maintenance',
    title: 'Maintenance',
    subtitle: 'Service history & records',
    icon: CupertinoIcons.wrench_fill,
    iconColor: AppTheme.primaryGreen,
    category: AppActionCategory.maintenance,
    showOnHome: true,
    builder: (_) => const MaintenanceRecordsScreen(),
  ),
  AppAction(
    id: 'obd',
    title: 'OBD-II Diagnostics',
    subtitle: 'Real-time vehicle diagnostics',
    icon: CupertinoIcons.antenna_radiowaves_left_right,
    iconColor: AppTheme.primaryGreen,
    category: AppActionCategory.vehicle,
    builder: (_) => const OBDDashboardScreen(),
  ),
  AppAction(
    id: 'service_centers',
    title: 'Service Centers',
    subtitle: 'Nearby centers & last parked location',
    icon: CupertinoIcons.location_solid,
    iconColor: const Color(0xFF10B981),
    category: AppActionCategory.tools,
    builder: (_) => const ServiceCentersScreen(),
  ),
  AppAction(
    id: 'service_reminders',
    title: 'Service Reminders',
    subtitle: 'Maintenance logs & reminders',
    icon: CupertinoIcons.bell_fill,
    iconColor: AppTheme.warningColor,
    category: AppActionCategory.maintenance,
    builder: (_) => const SmartRemindersScreen(),
  ),
];

/// The actions shown on the Home screen (the first six), in order.
List<AppAction> get homeActions =>
    kAppActions.where((a) => a.showOnHome).toList();
