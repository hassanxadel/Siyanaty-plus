import 'services/maintenance_service.dart';
import 'services/reminder_service.dart';
import 'models/backup_maintenance.dart';
import 'shared/utils/app_logger.dart';

/// Test class for verifying maintenance-reminder connection
class MaintenanceReminderConnectionTest {
  static final MaintenanceService _maintenanceService = MaintenanceService();
  static final ReminderService _reminderService = ReminderService();

  /// Test creating a maintenance record connected to a reminder
  static Future<void> testMaintenanceReminderConnection() async {
    AppLogger.info('🧪 Testing Maintenance-Reminder Connection...');
    
    try {
      // First, get an existing reminder to connect to
      final remindersResult = await _reminderService.getAllReminders();
      
      if (!remindersResult.isSuccess || remindersResult.reminders?.isEmpty != false) {
        AppLogger.warning('⚠️ No reminders found. Please create a reminder first.');
        return;
      }
      
      // Use the first reminder
      final reminder = remindersResult.reminders!.first;
      AppLogger.info('📋 Using reminder: ${reminder.title} (ID: ${reminder.id})');
      
      // Create a maintenance record connected to this reminder
      final maintenanceResult = await _maintenanceService.addMaintenance(
        reminderId: reminder.id!,
        title: 'Test Maintenance Record',
        description: 'This is a test maintenance record connected to a reminder',
        cost: 150.0,
        maintenanceDate: DateTime.now(),
        type: MaintenanceType.mechanics,
        mechanicName: 'Test Mechanic',
        invoiceNumber: 'INV-001',
      );
      
      if (maintenanceResult.success) {
        AppLogger.info('✅ Maintenance record created successfully!');
        AppLogger.info('🔗 Connected to reminder: ${reminder.title}');
        
        // Verify the connection by getting maintenance records for this reminder
        final connectedMaintenance = await _maintenanceService.getMaintenanceByReminder(reminder.id!);
        AppLogger.info('📊 Found ${connectedMaintenance.length} maintenance records connected to this reminder');
        
        for (final maintenance in connectedMaintenance) {
          AppLogger.info('   - ${maintenance.title} (Cost: \$${maintenance.cost})');
        }
        
      } else {
        AppLogger.error('❌ Failed to create maintenance record: ${maintenanceResult.message}');
      }
      
    } catch (e) {
      AppLogger.error('❌ Test failed with error: $e');
    }
  }

  /// Test getting maintenance records by reminder ID
  static Future<void> testGetMaintenanceByReminder() async {
    AppLogger.info('🧪 Testing Get Maintenance by Reminder...');
    
    try {
      final remindersResult = await _reminderService.getAllReminders();
      
      if (!remindersResult.isSuccess || remindersResult.reminders?.isEmpty != false) {
        AppLogger.warning('⚠️ No reminders found.');
        return;
      }
      
      // Test with each reminder
      for (final reminder in remindersResult.reminders!.take(3)) { // Test first 3 reminders
        final maintenance = await _maintenanceService.getMaintenanceByReminder(reminder.id!);
        AppLogger.info('📋 Reminder: ${reminder.title}');
        AppLogger.info('   Connected maintenance records: ${maintenance.length}');
        
        for (final maint in maintenance) {
          AppLogger.info('   - ${maint.title} (${maint.type.displayName}) - \$${maint.cost}');
        }
      }
      
    } catch (e) {
      AppLogger.error('❌ Test failed with error: $e');
    }
  }

  /// Test maintenance record structure and reminder ID field
  static Future<void> testMaintenanceStructure() async {
    AppLogger.info('🧪 Testing Maintenance Record Structure...');
    
    try {
      final allMaintenance = await _maintenanceService.getAllMaintenance();
      
      if (allMaintenance.isEmpty) {
        AppLogger.warning('⚠️ No maintenance records found.');
        return;
      }
      
      AppLogger.info('📊 Found ${allMaintenance.length} maintenance records:');
      
      for (final maintenance in allMaintenance.take(5)) { // Show first 5
        AppLogger.info('🔧 ${maintenance.title}');
        AppLogger.info('   ID: ${maintenance.id}');
        AppLogger.info('   Reminder ID: ${maintenance.reminderId} ✅');
        AppLogger.info('   Type: ${maintenance.type.displayName}');
        AppLogger.info('   Cost: \$${maintenance.cost}');
        AppLogger.info('   Date: ${maintenance.maintenanceDate.toString().split(' ')[0]}');
        AppLogger.info('   Created: ${maintenance.createdAt.toString().split(' ')[0]}');
        AppLogger.info('   Updated: ${maintenance.updatedAt.toString().split(' ')[0]}');
        AppLogger.info('');
      }
      
    } catch (e) {
      AppLogger.error('❌ Test failed with error: $e');
    }
  }

  /// Run all connection tests
  static Future<void> runAllTests() async {
    AppLogger.info('🚀 Starting Maintenance-Reminder Connection Tests...');
    AppLogger.info('=' * 60);
    
    await testMaintenanceStructure();
    AppLogger.info('');
    
    await testGetMaintenanceByReminder();
    AppLogger.info('');
    
    await testMaintenanceReminderConnection();
    AppLogger.info('');
    
    AppLogger.info('🏁 All connection tests completed!');
    AppLogger.info('=' * 60);
  }
}

/// Main function to run tests (for debugging)
void main() async {
  await MaintenanceReminderConnectionTest.runAllTests();
}
