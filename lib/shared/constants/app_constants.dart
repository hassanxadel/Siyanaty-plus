class AppConstants {
  // App Info
  static const String appName = 'siyanaty+';
  static const String appVersion = '1.0.0';

  // Support / contact
  static const String supportEmail = 'siyanatyplus@gmail.com';
  
  // Database
  static const String databaseName = 'siyana_database.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String carsTable = 'cars';
  static const String repairsTable = 'repairs';
  static const String remindersTable = 'reminders';
  static const String maintenanceTable = 'maintenance_records';
  static const String fuelLogsTable = 'fuel_logs';
  
  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';
  
  // API Endpoints (if needed later)
  static const String baseUrl = 'https://api.siyana.com';
  
  // External API Keys (placeholders; override securely at runtime if possible)
  static const String zpkBaseUrl  = 'https://zpk.systems/api';
  static const String zpkApiKey  = 'QGSnX7CFtNtbWe5WLsMWdqQscNMM5ebn5sJCq1szq42PHOcL8w';
  static const String zpkApplicationId  = 'u398i132nMyYNd';
  static const String googleMapsApiKey = 'AIzaSyCtDx-w7cQCYMCS-xEKRcOVzp_l5wk_A7A';
  
  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 500);
  static const Duration longDuration = Duration(milliseconds: 800);
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  
  // Pagination
  static const int defaultPageSize = 20;
}
