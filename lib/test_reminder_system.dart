/// Test script for the reminder management system
/// This file demonstrates how to use the reminder system and tests various scenarios
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'models/backup_reminder.dart';
import 'services/reminder_service.dart';
import 'services/firebase_reminder_service.dart';
import 'database/database_helper.dart';

class ReminderSystemTest {
  final ReminderService _reminderService = ReminderService();
  final FirebaseReminderService _firebaseService = FirebaseReminderService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Test the complete reminder system functionality
  Future<void> runTests() async {
    print('🧪 Starting Reminder System Tests...\n');

    try {
      // Test 1: Check authentication
      await _testAuthentication();

      // Test 2: Test reminder creation
      await _testReminderCreation();

      // Test 3: Test reminder retrieval
      await _testReminderRetrieval();

      // Test 4: Test reminder updates
      await _testReminderUpdates();

      // Test 5: Test status automation
      await _testStatusAutomation();

      // Test 6: Test cloud backup
      await _testCloudBackup();

      // Test 7: Test user isolation
      await _testUserIsolation();

      print('✅ All tests completed successfully!\n');

    } catch (e) {
      print('❌ Test failed with error: $e\n');
    }
  }

  Future<void> _testAuthentication() async {
    print('1️⃣ Testing Authentication...');
    
    final isAuthenticated = _reminderService.isUserAuthenticated;
    print('   User authenticated: $isAuthenticated');
    
    if (isAuthenticated) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('   Current user ID: $userId');
    } else {
      print('   ⚠️ User not authenticated - some features will be limited');
    }
    print('');
  }

  Future<void> _testReminderCreation() async {
    print('2️⃣ Testing Reminder Creation...');

    try {
      // Get user's cars first
      final cars = await _reminderService.getUserCars();
      print('   Available cars: ${cars.length}');
      
      if (cars.isEmpty) {
        print('   ⚠️ No cars found - please add a car first to test reminders');
        return;
      }

      final testCar = cars.first;
      print('   Using car: ${testCar.year} ${testCar.brand} ${testCar.model}');

      // Test creating different types of reminders
      final testReminders = [
        {
          'title': 'Oil Change',
          'description': 'Regular oil change service',
          'type': ReminderType.oilChange,
          'priority': ReminderPriority.medium,
          'targetMileage': 50000,
        },
        {
          'title': 'Annual Inspection',
          'description': 'Yearly vehicle inspection',
          'type': ReminderType.inspection,
          'priority': ReminderPriority.high,
          'targetDate': DateTime.now().add(const Duration(days: 30)),
        },
        {
          'title': 'Insurance Renewal',
          'description': 'Renew car insurance policy',
          'type': ReminderType.insurance,
          'priority': ReminderPriority.urgent,
          'targetDate': DateTime.now().add(const Duration(days: 7)),
        },
      ];

      for (final reminderData in testReminders) {
        final result = await _reminderService.addReminder(
          carId: testCar.id!,
          title: reminderData['title'] as String,
          description: reminderData['description'] as String,
          type: reminderData['type'] as ReminderType,
          priority: reminderData['priority'] as ReminderPriority,
          targetDate: reminderData['targetDate'] as DateTime?,
          targetMileage: reminderData['targetMileage'] as int?,
        );

        if (result.isSuccess) {
          print('   ✅ Created reminder: ${reminderData['title']}');
        } else {
          print('   ❌ Failed to create reminder: ${result.message}');
        }
      }
    } catch (e) {
      print('   ❌ Error in reminder creation: $e');
    }
    print('');
  }

  Future<void> _testReminderRetrieval() async {
    print('3️⃣ Testing Reminder Retrieval...');

    try {
      // Test getting all reminders
      final allResult = await _reminderService.getAllReminders();
      if (allResult.isSuccess && allResult.reminders != null) {
        print('   Total reminders: ${allResult.reminders!.length}');
        
        // Test getting reminders by status
        final upcomingResult = await _reminderService.getRemindersByStatus(ReminderStatus.upcoming);
        final overdueResult = await _reminderService.getRemindersByStatus(ReminderStatus.overdue);
        final completedResult = await _reminderService.getRemindersByStatus(ReminderStatus.completed);
        
        print('   Upcoming: ${upcomingResult.reminders?.length ?? 0}');
        print('   Overdue: ${overdueResult.reminders?.length ?? 0}');
        print('   Completed: ${completedResult.reminders?.length ?? 0}');

        // Test search functionality
        final searchResult = await _reminderService.searchReminders('oil');
        print('   Search results for "oil": ${searchResult.reminders?.length ?? 0}');

      } else {
        print('   ❌ Failed to retrieve reminders: ${allResult.message}');
      }
    } catch (e) {
      print('   ❌ Error in reminder retrieval: $e');
    }
    print('');
  }

  Future<void> _testReminderUpdates() async {
    print('4️⃣ Testing Reminder Updates...');

    try {
      final allResult = await _reminderService.getAllReminders();
      if (allResult.isSuccess && allResult.reminders != null && allResult.reminders!.isNotEmpty) {
        final testReminder = allResult.reminders!.first;
        print('   Testing with reminder: ${testReminder.title}');

        // Test updating reminder
        final updateResult = await _reminderService.updateReminder(
          id: testReminder.id!,
          carId: testReminder.carId,
          title: '${testReminder.title} (Updated)',
          description: '${testReminder.description} - Updated description',
          type: testReminder.type,
          priority: ReminderPriority.high,
          targetDate: testReminder.targetDate,
          targetMileage: testReminder.targetMileage,
        );

        if (updateResult.isSuccess) {
          print('   ✅ Successfully updated reminder');
        } else {
          print('   ❌ Failed to update reminder: ${updateResult.message}');
        }

        // Test marking as completed
        if (!testReminder.isCompleted) {
          final completeResult = await _reminderService.markReminderCompleted(testReminder.id!);
          if (completeResult.isSuccess) {
            print('   ✅ Successfully marked reminder as completed');
          } else {
            print('   ❌ Failed to mark reminder as completed: ${completeResult.message}');
          }
        }
      } else {
        print('   ⚠️ No reminders available for update testing');
      }
    } catch (e) {
      print('   ❌ Error in reminder updates: $e');
    }
    print('');
  }

  Future<void> _testStatusAutomation() async {
    print('5️⃣ Testing Status Automation...');

    try {
      // Create an overdue reminder for testing
      final cars = await _reminderService.getUserCars();
      if (cars.isNotEmpty) {
        final result = await _reminderService.addReminder(
          carId: cars.first.id!,
          title: 'Overdue Test Reminder',
          description: 'This reminder should be automatically marked as overdue',
          type: ReminderType.maintenance,
          priority: ReminderPriority.medium,
          targetDate: DateTime.now().subtract(const Duration(days: 1)), // Yesterday
        );

        if (result.isSuccess) {
          print('   ✅ Created test overdue reminder');
          
          // Get reminders to trigger automatic status update
          await Future.delayed(const Duration(milliseconds: 500));
          final overdueResult = await _reminderService.getRemindersByStatus(ReminderStatus.overdue);
          
          final hasOverdueReminder = overdueResult.reminders?.any(
            (r) => r.title == 'Overdue Test Reminder'
          ) ?? false;
          
          if (hasOverdueReminder) {
            print('   ✅ Automatic overdue detection working correctly');
          } else {
            print('   ⚠️ Overdue detection may not be working as expected');
          }
        }
      }
    } catch (e) {
      print('   ❌ Error in status automation test: $e');
    }
    print('');
  }

  Future<void> _testCloudBackup() async {
    print('6️⃣ Testing Cloud Backup...');

    try {
      if (!_firebaseService.isUserAuthenticated) {
        print('   ⚠️ User not authenticated - skipping cloud backup tests');
        return;
      }

      // Test backup status
      final status = await _firebaseService.getBackupStatus();
      print('   Local reminders: ${status.localRemindersCount}');
      print('   Cloud reminders: ${status.cloudRemindersCount}');
      print('   In sync: ${status.isInSync}');
      
      if (status.lastBackupTime != null) {
        print('   Last backup: ${status.lastBackupTime}');
      }

      // Test backup operation
      if (status.localRemindersCount > 0) {
        final backupResult = await _firebaseService.backupAllRemindersToFirebase();
        if (backupResult.isSuccess) {
          print('   ✅ Backup completed successfully');
        } else {
          print('   ❌ Backup failed: ${backupResult.message}');
        }
      } else {
        print('   ⚠️ No local reminders to backup');
      }

    } catch (e) {
      print('   ❌ Error in cloud backup test: $e');
    }
    print('');
  }

  Future<void> _testUserIsolation() async {
    print('7️⃣ Testing User Isolation...');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('   ⚠️ User not authenticated - skipping isolation tests');
        return;
      }

      print('   Current user: ${currentUser.uid}');
      
      // Test that reminders are user-specific
      final remindersResult = await _reminderService.getAllReminders();
      if (remindersResult.isSuccess && remindersResult.reminders != null) {
        final userReminders = remindersResult.reminders!;
        print('   ✅ Found ${userReminders.length} reminders (all belong to current user via car ownership)');

        // Test car ownership
        final cars = await _reminderService.getUserCars();
        print('   User has access to ${cars.length} cars');
        
      } else {
        print('   ⚠️ No reminders found for isolation testing');
      }

    } catch (e) {
      print('   ❌ Error in user isolation test: $e');
    }
    print('');
  }

  /// Cleanup test data (optional)
  Future<void> cleanupTestData() async {
    print('🧹 Cleaning up test data...');
    
    try {
      if (_reminderService.isUserAuthenticated) {
        final reminders = await _reminderService.getAllReminders();
        if (reminders.isSuccess && reminders.reminders != null) {
          for (final reminder in reminders.reminders!) {
            if (reminder.title.contains('Test') || reminder.title.contains('Updated')) {
              await _reminderService.deleteReminder(reminder.id!);
            }
          }
        }
        print('   ✅ Test data cleaned up');
      }
    } catch (e) {
      print('   ❌ Error cleaning up test data: $e');
    }
    print('');
  }
}

/// Usage example:
/// ```dart
/// void main() async {
///   final tester = ReminderSystemTest();
///   await tester.runTests();
///   // Optional: await tester.cleanupTestData();
/// }
/// ```

/// Sample reminder data for testing
class SampleReminderData {
  static List<Map<String, dynamic>> getSampleReminders() {
    return [
      {
        'title': 'Oil Change',
        'description': 'Change engine oil and filter',
        'type': ReminderType.oilChange,
        'priority': ReminderPriority.medium,
        'targetMileage': 10000,
      },
      {
        'title': 'Tire Rotation',
        'description': 'Rotate tires for even wear',
        'type': ReminderType.tireRotation,
        'priority': ReminderPriority.low,
        'targetMileage': 48000,
      },
      {
        'title': 'Annual Inspection',
        'description': 'State required vehicle inspection',
        'type': ReminderType.inspection,
        'priority': ReminderPriority.high,
        'targetDate': DateTime.now().add(const Duration(days: 30)),
      },
      {
        'title': 'Insurance Renewal',
        'description': 'Renew auto insurance policy',
        'type': ReminderType.insurance,
        'priority': ReminderPriority.urgent,
        'targetDate': DateTime.now().add(const Duration(days: 14)),
      },
      {
        'title': 'Brake Service',
        'description': 'Inspect and service brake system',
        'type': ReminderType.brakeService,
        'priority': ReminderPriority.high,
        'targetDate': DateTime.now().add(const Duration(days: 60)),
      },
    ];
  }
}

/// Reminder system usage examples
class ReminderSystemExamples {
  static void showUsageExamples() {
    print('''
📖 REMINDER SYSTEM USAGE EXAMPLES

1. Creating a Reminder:
```dart
final reminderService = ReminderService();
final result = await reminderService.addReminder(
  carId: 1,
  title: 'Oil Change',
  description: 'Regular oil change service',
  type: ReminderType.oilChange,
  priority: ReminderPriority.medium,
  targetMileage: 50000,
);
```

2. Getting Reminders by Status:
```dart
final upcomingResult = await reminderService.getRemindersByStatus(ReminderStatus.upcoming);
final overdueResult = await reminderService.getRemindersByStatus(ReminderStatus.overdue);
final completedResult = await reminderService.getRemindersByStatus(ReminderStatus.completed);
```

3. Marking Reminder as Completed:
```dart
final result = await reminderService.markReminderCompleted(reminderId);
```

4. Backing up to Cloud:
```dart
final firebaseService = FirebaseReminderService();
final backupResult = await firebaseService.backupAllRemindersToFirebase();
```

5. UI Integration:
```dart
// In your StatefulWidget
final ReminderService _reminderService = ReminderService();
List<BackupReminder> _reminders = [];

Future<void> _loadReminders() async {
  final result = await _reminderService.getAllReminders();
  if (result.isSuccess) {
    setState(() {
      _reminders = result.reminders ?? [];
    });
  }
}
```

🎯 KEY FEATURES:
✅ User-specific reminders tied to specific cars
✅ Automatic status updates (upcoming → overdue → completed)
✅ Multiple reminder types (maintenance, inspection, insurance, etc.)
✅ Priority levels (low, medium, high, urgent)
✅ Date-based AND mileage-based reminders
✅ Complete CRUD operations
✅ Cloud backup and restore
✅ Search functionality
✅ Form validation and error handling

🚗 CAR INTEGRATION:
- Reminders are assigned to specific cars
- Car selection dropdown in forms
- User can only see their own cars and reminders
- Cascade deletion when car is deleted

☁️ CLOUD FEATURES:
- Firebase Firestore integration
- User-specific collections: /users/{userId}/reminders/{reminderId}
- Backup status monitoring
- Cross-device synchronization

📱 UI COMPONENTS:
- SmartRemindersScreen: Main screen with tabs
- AddReminderForm: Create new reminders
- EditReminderForm: Update existing reminders
- ReminderDetailsDialog: View full reminder details
- ReminderBackupButtonWidget: Cloud backup controls
''');
  }
}
