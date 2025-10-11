import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/backup_reminder.dart';

/// Service for managing local notifications for reminders
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // Request basic notification permission
      await androidImplementation?.requestNotificationsPermission();
      
      // Request exact alarms permission (Android 12+)
      await androidImplementation?.requestExactAlarmsPermission();
      
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule a notification for a reminder
  Future<void> scheduleReminderNotification(BackupReminder reminder) async {
    if (!_isInitialized) await initialize();

    // Don't schedule notifications for completed reminders
    if (reminder.isCompleted || reminder.targetDate == null) return;

    final now = DateTime.now();
    final reminderDate = reminder.targetDate!;

    // Only schedule if the reminder is in the future
    if (reminderDate.isAfter(now)) {
      final notificationId = reminder.id ?? DateTime.now().millisecondsSinceEpoch;
      
      // Schedule notification for the exact reminder time
      await _notifications.zonedSchedule(
        notificationId,
        _getNotificationTitle(reminder),
        _getNotificationBody(reminder),
        tz.TZDateTime.from(reminderDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder Notifications',
            channelDescription: 'Notifications for car maintenance reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF2E7D32), // AppTheme.primaryGreen equivalent
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reminder_${reminder.id}',
      );
    }
  }

  /// Schedule overdue notification for a reminder
  Future<void> scheduleOverdueNotification(BackupReminder reminder) async {
    if (!_isInitialized) await initialize();

    // Don't schedule notifications for completed reminders
    if (reminder.isCompleted) return;

    final notificationId = 'overdue_${reminder.id ?? DateTime.now().millisecondsSinceEpoch}';
    
    // Schedule immediate notification for overdue reminder
    await _notifications.show(
      notificationId.hashCode,
      _getOverdueNotificationTitle(reminder),
      _getOverdueNotificationBody(reminder),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'overdue_channel',
          'Overdue Reminder Notifications',
          channelDescription: 'Notifications for overdue car maintenance reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD32F2F), // Red color for overdue
          playSound: true,
          enableVibration: true,
          ongoing: false, // Allow user to dismiss
          autoCancel: true,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      payload: 'overdue_reminder_${reminder.id}',
    );
  }

  /// Send test notification when notifications are enabled
  Future<void> sendNotificationsEnabledNotification() async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      'notifications_enabled'.hashCode,
      '🔔 Notifications Enabled',
      'Siyanaty+ notifications are now active. You\'ll receive alerts for car maintenance reminders.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'system_channel',
          'System Notifications',
          channelDescription: 'System notifications for app settings',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2E7D32),
          playSound: true,
          enableVibration: true,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'notifications_enabled',
    );
  }

  /// Send test notification when notifications are disabled
  Future<void> sendNotificationsDisabledNotification() async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      'notifications_disabled'.hashCode,
      '🔕 Notifications Disabled',
      'Siyanaty+ notifications are now turned off. You won\'t receive maintenance reminders.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'system_channel',
          'System Notifications',
          channelDescription: 'System notifications for app settings',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF757575),
          playSound: true,
          enableVibration: true,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'notifications_disabled',
    );
  }

  /// Cancel a scheduled notification for a reminder
  Future<void> cancelReminderNotification(int reminderId) async {
    if (!_isInitialized) return;

    await _notifications.cancel(reminderId);
    await _notifications.cancel('overdue_$reminderId'.hashCode);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    await _notifications.cancelAll();
  }

  /// Get notification title for reminder
  String _getNotificationTitle(BackupReminder reminder) {
    switch (reminder.type) {
      case ReminderType.maintenance:
        return '🔧 Maintenance Reminder';
      case ReminderType.inspection:
        return '🔍 Inspection Reminder';
      case ReminderType.insurance:
        return '🛡️ Insurance Reminder';
      case ReminderType.registration:
        return '📋 Registration Reminder';
      case ReminderType.oilChange:
        return '🛢️ Oil Change Reminder';
      case ReminderType.tireRotation:
        return '🛞 Tire Rotation Reminder';
      case ReminderType.brakeService:
        return '🛑 Brake Service Reminder';
      case ReminderType.custom:
        return '📝 Reminder';
    }
  }

  /// Get notification body for reminder
  String _getNotificationBody(BackupReminder reminder) {
    final dateStr = reminder.targetDate != null 
        ? '${reminder.targetDate!.day}/${reminder.targetDate!.month}/${reminder.targetDate!.year}'
        : '';
    
    if (reminder.targetDate != null && reminder.targetMileage != null) {
      return '${reminder.title} - Due on $dateStr or at ${reminder.targetMileage}km';
    } else if (reminder.targetDate != null) {
      return '${reminder.title} - Due on $dateStr';
    } else if (reminder.targetMileage != null) {
      return '${reminder.title} - Due at ${reminder.targetMileage}km';
    } else {
      return reminder.title;
    }
  }

  /// Get overdue notification title
  String _getOverdueNotificationTitle(BackupReminder reminder) {
    return '⚠️ Overdue: ${_getNotificationTitle(reminder)}';
  }

  /// Get overdue notification body
  String _getOverdueNotificationBody(BackupReminder reminder) {
    final now = DateTime.now();
    final overdueDate = reminder.targetDate;
    
    if (overdueDate != null) {
      final daysOverdue = now.difference(overdueDate).inDays;
      return '${reminder.title} was due $daysOverdue day${daysOverdue == 1 ? '' : 's'} ago. Please take action!';
    } else {
      return '${reminder.title} is overdue. Please take action!';
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      // For iOS, we assume notifications are enabled if we can initialize
      return true;
    }
    return false;
  }

  /// Check if exact alarms permission is granted (Android 12+)
  Future<bool> areExactAlarmsEnabled() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS doesn't have this restriction
  }

  /// Request all necessary permissions
  Future<bool> requestAllPermissions() async {
    if (!_isInitialized) await initialize();

    try {
      await _requestPermissions();
      
      // Check if permissions were granted
      final notificationsEnabled = await areNotificationsEnabled();
      final exactAlarmsEnabled = await areExactAlarmsEnabled();
      
      return notificationsEnabled && exactAlarmsEnabled;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Open app notification settings
  Future<void> openNotificationSettings() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      // Note: openNotificationSettings might not be available in all versions
      // This is a placeholder for when the method becomes available
      print('Opening notification settings...');
    }
    // iOS doesn't have a direct way to open notification settings programmatically
  }
}
