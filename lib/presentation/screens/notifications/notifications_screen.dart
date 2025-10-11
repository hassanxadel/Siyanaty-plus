import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/notification_database_service.dart';
import '../../../services/local_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  final NotificationDatabaseService _notificationService = NotificationDatabaseService.instance;
  final LocalNotificationService _localNotificationService = LocalNotificationService.instance;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize local notification service
      await _localNotificationService.initialize();
      
      // Load real notifications from database
      final notifications = await _notificationService.getAllNotifications();
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
      
      if (mounted) {
        _showMessage('Error loading notifications: $e');
      }
    }
  }


  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      
      setState(() {
        final notification = _notifications.firstWhere((n) => n.id == notificationId);
        notification.isRead = true;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      _showMessage('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      HapticFeedback.lightImpact();
      _showMessage('Notification deleted');
      
      // Reload notifications to get updated data
      await _loadNotifications();
    } catch (e) {
      _showMessage('Error deleting notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      for (var notification in _notifications) {
        if (!notification.isRead) {
          await _notificationService.markNotificationAsRead(notification.id);
          notification.isRead = true;
        }
      }
      
      setState(() {});
      HapticFeedback.lightImpact();
      _showMessage('All notifications marked as read');
    } catch (e) {
      _showMessage('Error marking notifications as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      // Delete all notifications (mark all reminders as completed)
      for (var notification in _notifications) {
        await _notificationService.deleteNotification(notification.id);
      }
      
      setState(() {
        _notifications.clear();
      });
      HapticFeedback.lightImpact();
      _showMessage('All notifications cleared');
      
      // Reload notifications to get updated data
      await _loadNotifications();
    } catch (e) {
      _showMessage('Error clearing notifications: $e');
    }
  }

  void _showMessage(String message) {
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

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return AppTheme.errorColor;
      case NotificationPriority.medium:
        return AppTheme.warningColor;
      case NotificationPriority.low:
        return AppTheme.infoColor;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.maintenance:
        return Icons.car_repair;
      case NotificationType.reminder:
        return Icons.schedule;
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.error;
      case NotificationType.success:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, unreadCount),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
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
                  const SizedBox(width: 16),
                  const Text(
                    'Notifications',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$unreadCount unread notifications',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          onPressed: _markAllAsRead,
                          icon: const Icon(
                            Icons.mark_email_read,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'Mark all as read',
                        ),
                        IconButton(
                          onPressed: _clearAllNotifications,
                          icon: const Icon(
                            Icons.clear_all,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'Clear all',
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.lightBackground
                  : AppTheme.darkAccentGreen,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.lightBackground.withOpacity(0.3)
                : AppTheme.darkAccentGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.lightBackground
                  : AppTheme.darkAccentGreen,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see important updates here',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.lightBackground.withOpacity(0.7)
                  : AppTheme.darkAccentGreen.withOpacity(0.7),
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? AppTheme.darkAccentGreen.withOpacity(0.2)
            : AppTheme.darkAccentGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead 
              ? AppTheme.primaryGreen.withOpacity(0.2)
              : AppTheme.primaryGreen.withOpacity(0.4),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getPriorityColor(notification.priority).withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getPriorityColor(notification.priority),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.lightBackground
                      : AppTheme.darkAccentGreen,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.lightBackground.withOpacity(0.8)
                    : AppTheme.darkAccentGreen.withOpacity(0.8),
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getTimeAgo(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.lightBackground.withOpacity(0.6)
                    : AppTheme.darkAccentGreen.withOpacity(0.6),
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.lightBackground.withOpacity(0.7)
                : AppTheme.darkAccentGreen.withOpacity(0.7),
          ),
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                _markAsRead(notification.id);
                break;
              case 'delete':
                _deleteNotification(notification.id);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!notification.isRead)
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                                         Icon(
                       Icons.mark_email_read, 
                       size: 20,
                       color: Theme.of(context).brightness == Brightness.dark
                           ? null
                           : AppTheme.darkAccentGreen,
                     ),
                     const SizedBox(width: 8),
                     Text(
                       'Mark as read',
                       style: TextStyle(
                         color: Theme.of(context).brightness == Brightness.dark
                             ? null
                             : AppTheme.darkAccentGreen,
                         fontFamily: 'Orbitron',
                       ),
                     ),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                                     Text(
                     'Delete',
                     style: TextStyle(
                       color: Theme.of(context).brightness == Brightness.dark
                           ? null
                           : AppTheme.darkAccentGreen,
                       fontFamily: 'Orbitron',
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!notification.isRead) {
            await _markAsRead(notification.id);
          }
          // Navigate to reminders screen when notification is tapped
          if (notification.reminderId != null) {
            Navigator.pushNamed(context, '/reminders');
          }
        },
      ),
    );
  }
}

