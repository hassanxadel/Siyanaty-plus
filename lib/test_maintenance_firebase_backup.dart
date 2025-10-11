import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_maintenance_service.dart';
import 'services/comprehensive_backup_service.dart';
import 'shared/utils/app_logger.dart';

/// Test class for verifying maintenance Firebase backup functionality
class MaintenanceFirebaseBackupTest {
  static final ComprehensiveBackupService _comprehensiveService = ComprehensiveBackupService();

  /// Test comprehensive backup functionality
  static Future<void> testComprehensiveBackup() async {
    AppLogger.info('🧪 Testing Comprehensive Firebase Backup...');
    
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.warning('❌ No authenticated user found. Please sign in first.');
        return;
      }
      
      AppLogger.info('✅ User authenticated: ${user.email}');
      
      // Test comprehensive backup
      AppLogger.info('📤 Starting comprehensive backup test...');
      final backupResult = await _comprehensiveService.backupAllDataToFirebase();
      
      if (backupResult.success) {
        AppLogger.info('✅ Comprehensive backup successful!');
        AppLogger.info('📊 Results: ${backupResult.totalSuccessCount} items backed up, ${backupResult.totalFailureCount} failures');
        
        // Log individual results
        final results = backupResult.results;
        if (results.containsKey('cars')) {
          final carResult = results['cars'];
          AppLogger.info('🚗 Cars: ${carResult['message']} (${carResult['count']} items)');
        }
        
        if (results.containsKey('reminders')) {
          final reminderResult = results['reminders'];
          AppLogger.info('🔔 Reminders: ${reminderResult['message']} (${reminderResult['count']} items)');
        }
        
        if (results.containsKey('maintenance')) {
          final maintenanceResult = results['maintenance'];
          AppLogger.info('🔧 Maintenance: ${maintenanceResult['message']} (${maintenanceResult['count']} items)');
        }
        
      } else {
        AppLogger.error('❌ Comprehensive backup failed: ${backupResult.message}');
      }
      
    } catch (e) {
      AppLogger.error('❌ Test failed with error: $e');
    }
  }

  /// Test maintenance backup status
  static Future<void> testMaintenanceBackupStatus() async {
    AppLogger.info('🧪 Testing Maintenance Backup Status...');
    
    try {
      final status = await FirebaseMaintenanceService.getBackupStatus();
      
      AppLogger.info('📊 Maintenance Backup Status:');
      AppLogger.info('   Local count: ${status.localCount}');
      AppLogger.info('   Cloud count: ${status.cloudCount}');
      AppLogger.info('   Last backup: ${status.lastBackupTime ?? 'Never'}');
      AppLogger.info('   Is backed up: ${status.isBackedUp ? '✅' : '❌'}');
      
    } catch (e) {
      AppLogger.error('❌ Failed to get backup status: $e');
    }
  }

  /// Test comprehensive backup status
  static Future<void> testComprehensiveBackupStatus() async {
    AppLogger.info('🧪 Testing Comprehensive Backup Status...');
    
    try {
      final status = await _comprehensiveService.getComprehensiveBackupStatus();
      
      AppLogger.info('📊 Comprehensive Backup Status:');
      AppLogger.info('   Cars backed up: ${status.carsBackedUp ? '✅' : '❌'}');
      AppLogger.info('   Reminders backed up: ${status.remindersBackedUp ? '✅' : '❌'}');
      AppLogger.info('   Maintenance backed up: ${status.maintenanceBackedUp ? '✅' : '❌'}');
      AppLogger.info('   Fully backed up: ${status.isFullyBackedUp ? '✅' : '❌'}');
      AppLogger.info('   Total local items: ${status.totalLocalItems}');
      AppLogger.info('   Total cloud items: ${status.totalCloudItems}');
      
    } catch (e) {
      AppLogger.error('❌ Failed to get comprehensive backup status: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    AppLogger.info('🚀 Starting Maintenance Firebase Backup Tests...');
    AppLogger.info('=' * 50);
    
    await testMaintenanceBackupStatus();
    AppLogger.info('');
    
    await testComprehensiveBackupStatus();
    AppLogger.info('');
    
    await testComprehensiveBackup();
    AppLogger.info('');
    
    AppLogger.info('🏁 All tests completed!');
    AppLogger.info('=' * 50);
  }
}

/// Main function to run tests (for debugging)
void main() async {
  await MaintenanceFirebaseBackupTest.runAllTests();
}
