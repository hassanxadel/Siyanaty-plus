import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/backup_reminder.dart';
import '../models/backup_car.dart';

/// Service for managing notification history and overdue reminders
class NotificationDatabaseService {
  static final NotificationDatabaseService _instance = NotificationDatabaseService._internal();
  factory NotificationDatabaseService() => _instance;
  NotificationDatabaseService._internal();

  static NotificationDatabaseService get instance => _instance;

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _currentUserId != null;

  /// Get all overdue reminders as notifications
  Future<List<NotificationItem>> getOverdueRemindersAsNotifications() async {
    try {
      if (!isUserAuthenticated) return [];

      final userId = _currentUserId!;
      
      // Get read notification IDs
      final readIds = await getReadNotificationIds();
      
      // Get all overdue reminders with car info
      final overdueReminders = await _databaseHelper.getOverdueRemindersWithCarInfo(userId);
      
      // Convert to notification items
      return overdueReminders.map((reminderMap) {
        final reminder = BackupReminder.fromMap(reminderMap);
        final car = _parseCarFromJoinedQuery(reminderMap);
        final notificationId = 'overdue_${reminder.id}';
        
        return NotificationItem(
          id: notificationId,
          title: _getOverdueNotificationTitle(reminder),
          message: _getOverdueNotificationMessage(reminder, car),
          type: NotificationType.reminder,
          timestamp: reminder.updatedAt,
          isRead: readIds.contains(notificationId),
          priority: _getNotificationPriority(reminder),
          reminderId: reminder.id,
          carId: reminder.carId,
        );
      }).toList();
    } catch (e) {
      print('Error getting overdue reminders as notifications: $e');
      return [];
    }
  }

  /// Get upcoming reminders that are due soon (within 5 days) as notifications
  Future<List<NotificationItem>> getUpcomingRemindersAsNotifications() async {
    try {
      if (!isUserAuthenticated) return [];

      final userId = _currentUserId!;
      final now = DateTime.now();
      final fiveDaysFromNow = now.add(const Duration(days: 5));
      
      // Get read notification IDs
      final readIds = await getReadNotificationIds();
      
      // Get all upcoming reminders with car info
      final upcomingReminders = await _databaseHelper.getUpcomingRemindersWithCarInfo(userId);
      
      // Filter reminders due within 5 days
      final soonDueReminders = upcomingReminders.where((reminderMap) {
        final reminder = BackupReminder.fromMap(reminderMap);
        return reminder.targetDate != null && 
               reminder.targetDate!.isAfter(now) && 
               reminder.targetDate!.isBefore(fiveDaysFromNow);
      }).toList();
      
      // Convert to notification items
      return soonDueReminders.map((reminderMap) {
        final reminder = BackupReminder.fromMap(reminderMap);
        final car = _parseCarFromJoinedQuery(reminderMap);
        final notificationId = 'upcoming_${reminder.id}';
        
        return NotificationItem(
          id: notificationId,
          title: _getUpcomingNotificationTitle(reminder),
          message: _getUpcomingNotificationMessage(reminder, car),
          type: NotificationType.reminder,
          timestamp: reminder.updatedAt,
          isRead: readIds.contains(notificationId),
          priority: NotificationPriority.medium,
          reminderId: reminder.id,
          carId: reminder.carId,
        );
      }).toList();
    } catch (e) {
      print('Error getting upcoming reminders as notifications: $e');
      return [];
    }
  }

  /// Get all notifications (overdue + upcoming)
  Future<List<NotificationItem>> getAllNotifications() async {
    final overdueNotifications = await getOverdueRemindersAsNotifications();
    final upcomingNotifications = await getUpcomingRemindersAsNotifications();
    
    // Combine and sort by timestamp (newest first)
    final allNotifications = [...overdueNotifications, ...upcomingNotifications];
    allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return allNotifications;
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];
      
      if (!readNotifications.contains(notificationId)) {
        readNotifications.add(notificationId);
        await prefs.setStringList('read_notifications', readNotifications);
      }
      
      print('Marked notification as read: $notificationId');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  /// Check if a notification has been read
  Future<bool> isNotificationRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];
      return readNotifications.contains(notificationId);
    } catch (e) {
      print('Error checking notification read status: $e');
      return false;
    }
  }
  
  /// Get list of all read notification IDs
  Future<Set<String>> getReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];
      return readNotifications.toSet();
    } catch (e) {
      print('Error getting read notification IDs: $e');
      return {};
    }
  }
  
  /// Clear read status for a notification (when it becomes unread)
  Future<void> markNotificationAsUnread(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];
      
      readNotifications.remove(notificationId);
      await prefs.setStringList('read_notifications', readNotifications);
    } catch (e) {
      print('Error marking notification as unread: $e');
    }
  }

  /// Delete a notification (mark reminder as completed)
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (!isUserAuthenticated) return;

      // Extract reminder ID from notification ID
      final reminderIdStr = notificationId.replaceAll('overdue_', '').replaceAll('upcoming_', '');
      final reminderId = int.tryParse(reminderIdStr);
      
      if (reminderId != null) {
        // Only mark as completed if it's overdue, not if it's just upcoming
        if (notificationId.startsWith('overdue_')) {
          await _databaseHelper.markReminderCompleted(reminderId, _currentUserId!);
        }
        // For upcoming notifications, we don't mark as completed - just remove from notifications
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Get notification title for overdue reminder
  String _getOverdueNotificationTitle(BackupReminder reminder) {
    switch (reminder.type) {
      case ReminderType.maintenance:
        return '🔧 Overdue Maintenance';
      case ReminderType.inspection:
        return '🔍 Overdue Inspection';
      case ReminderType.insurance:
        return '🛡️ Overdue Insurance';
      case ReminderType.registration:
        return '📋 Overdue Registration';
      case ReminderType.oilChange:
        return '🛢️ Overdue Oil Change';
      case ReminderType.tireRotation:
        return '🛞 Overdue Tire Rotation';
      case ReminderType.brakeService:
        return '🛑 Overdue Brake Service';
      case ReminderType.custom:
        return '📝 Overdue Reminder';
    }
  }

  /// Get notification message for overdue reminder
  String _getOverdueNotificationMessage(BackupReminder reminder, BackupCar car) {
    final carName = '${car.brand} ${car.model}';
    final daysOverdue = _getDaysOverdue(reminder);
    
    if (daysOverdue > 0) {
      return '$carName - ${reminder.title} is $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue';
    } else {
      return '$carName - ${reminder.title} is overdue';
    }
  }

  /// Get notification title for upcoming reminder
  String _getUpcomingNotificationTitle(BackupReminder reminder) {
    switch (reminder.type) {
      case ReminderType.maintenance:
        return '🔧 Maintenance Due Soon';
      case ReminderType.inspection:
        return '🔍 Inspection Due Soon';
      case ReminderType.insurance:
        return '🛡️ Insurance Due Soon';
      case ReminderType.registration:
        return '📋 Registration Due Soon';
      case ReminderType.oilChange:
        return '🛢️ Oil Change Due Soon';
      case ReminderType.tireRotation:
        return '🛞 Tire Rotation Due Soon';
      case ReminderType.brakeService:
        return '🛑 Brake Service Due Soon';
      case ReminderType.custom:
        return '📝 Reminder Due Soon';
    }
  }

  /// Get notification message for upcoming reminder
  String _getUpcomingNotificationMessage(BackupReminder reminder, BackupCar car) {
    final carName = '${car.brand} ${car.model}';
    final daysUntilDue = _getDaysUntilDue(reminder);
    
    if (daysUntilDue > 0) {
      return '$carName - ${reminder.title} due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}';
    } else {
      return '$carName - ${reminder.title} is due today';
    }
  }

  /// Get notification priority based on reminder
  NotificationPriority _getNotificationPriority(BackupReminder reminder) {
    final daysOverdue = _getDaysOverdue(reminder);
    
    if (daysOverdue > 7) {
      return NotificationPriority.high;
    } else if (daysOverdue > 3) {
      return NotificationPriority.medium;
    } else {
      return NotificationPriority.low;
    }
  }

  /// Calculate days overdue for a reminder
  int _getDaysOverdue(BackupReminder reminder) {
    if (reminder.targetDate == null) return 0;
    
    final now = DateTime.now();
    final overdueDate = reminder.targetDate!;
    
    if (overdueDate.isAfter(now)) return 0;
    
    return now.difference(overdueDate).inDays;
  }

  /// Calculate days until due for a reminder
  int _getDaysUntilDue(BackupReminder reminder) {
    if (reminder.targetDate == null) return 0;
    
    final now = DateTime.now();
    final dueDate = reminder.targetDate!;
    
    if (dueDate.isBefore(now)) return 0;
    
    return dueDate.difference(now).inDays;
  }

  /// Parse car data from joined query result
  BackupCar _parseCarFromJoinedQuery(Map<String, dynamic> map) {
    return BackupCar(
      id: map['car_id']?.toInt(),
      userId: map['user_id'] ?? '',
      brand: map['car_brand'] ?? '',
      model: map['car_model'] ?? '',
      year: map['car_year']?.toInt() ?? 0,
      mileage: 0, // Not available in joined query
      color: '', // Not available in joined query
      fuelType: '', // Not available in joined query
      engineCC: '', // Not available in joined query
      turbo: false, // Not available in joined query
      licensePlate: map['car_license_plate'] ?? '',
      vin: '', // Not available in joined query
      imagePath: null, // Not available in joined query
      createdAt: DateTime.now(), // Not available in joined query
      updatedAt: DateTime.now(), // Not available in joined query
    );
  }
}

/// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final NotificationPriority priority;
  final int? reminderId;
  final int? carId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.priority,
    this.reminderId,
    this.carId,
  });
}

/// Notification types
enum NotificationType {
  maintenance,
  reminder,
  alert,
  info,
  warning,
  success,
}

/// Notification priorities
enum NotificationPriority {
  high,
  medium,
  low,
}
