import 'services/local_notification_service.dart';
import 'services/notification_database_service.dart';
import 'models/backup_reminder.dart';

/// Test class for the notification system
/// This can be used to test local notifications and notification database functionality
class NotificationSystemTest {
  static final LocalNotificationService _localNotificationService = LocalNotificationService.instance;
  static final NotificationDatabaseService _notificationService = NotificationDatabaseService.instance;

  /// Test local notification scheduling
  static Future<void> testLocalNotificationScheduling() async {
    print('Testing local notification scheduling...');
    
    try {
      // Initialize the notification service
      await _localNotificationService.initialize();
      
      // Create a test reminder for 1 minute from now
      final testReminder = BackupReminder(
        carId: 1,
        title: 'Test Oil Change',
        description: 'This is a test reminder for oil change',
        type: ReminderType.oilChange,
        priority: ReminderPriority.high,
        targetDate: DateTime.now().add(const Duration(minutes: 1)),
        status: ReminderStatus.upcoming,
        isCompleted: false,
      );
      
      // Schedule the notification
      await _localNotificationService.scheduleReminderNotification(testReminder);
      print('✅ Test notification scheduled successfully');
      
      // Test overdue notification
      final overdueReminder = BackupReminder(
        carId: 1,
        title: 'Overdue Maintenance',
        description: 'This is an overdue maintenance reminder',
        type: ReminderType.maintenance,
        priority: ReminderPriority.high,
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
        status: ReminderStatus.overdue,
        isCompleted: false,
      );
      
      await _localNotificationService.scheduleOverdueNotification(overdueReminder);
      print('✅ Overdue notification sent successfully');
      
    } catch (e) {
      print('❌ Error testing local notifications: $e');
    }
  }

  /// Test notification database service
  static Future<void> testNotificationDatabase() async {
    print('Testing notification database service...');
    
    try {
      // Test getting overdue notifications
      final overdueNotifications = await _notificationService.getOverdueRemindersAsNotifications();
      print('✅ Found ${overdueNotifications.length} overdue notifications');
      
      // Test getting upcoming notifications
      final upcomingNotifications = await _notificationService.getUpcomingRemindersAsNotifications();
      print('✅ Found ${upcomingNotifications.length} upcoming notifications');
      
      // Test getting all notifications
      final allNotifications = await _notificationService.getAllNotifications();
      print('✅ Found ${allNotifications.length} total notifications');
      
      // Print sample notifications
      if (allNotifications.isNotEmpty) {
        print('\n📱 Sample notifications:');
        for (int i = 0; i < allNotifications.length && i < 3; i++) {
          final notification = allNotifications[i];
          print('  ${i + 1}. ${notification.title}');
          print('     ${notification.message}');
          print('     Priority: ${notification.priority}');
          print('     Time: ${notification.timestamp}');
          print('');
        }
      }
      
    } catch (e) {
      print('❌ Error testing notification database: $e');
    }
  }

  /// Run all notification tests
  static Future<void> runAllTests() async {
    print('🚀 Starting notification system tests...\n');
    
    await testNotificationDatabase();
    print('');
    await testLocalNotificationScheduling();
    
    print('\n✅ Notification system tests completed!');
  }

  /// Test notification permissions
  static Future<void> testNotificationPermissions() async {
    print('Testing notification permissions...');
    
    try {
      final areEnabled = await _localNotificationService.areNotificationsEnabled();
      print('Notifications enabled: $areEnabled');
      
      if (!areEnabled) {
        print('⚠️ Notifications are not enabled. User may need to enable them in settings.');
      }
      
    } catch (e) {
      print('❌ Error checking notification permissions: $e');
    }
  }
}
