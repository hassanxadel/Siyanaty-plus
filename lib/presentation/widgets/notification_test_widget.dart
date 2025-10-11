import 'package:flutter/material.dart';
import '../../services/local_notification_service.dart';
import '../../services/notification_database_service.dart';
import '../../shared/constants/app_theme.dart';
import '../../test_notification_system.dart';

/// Widget for testing notification functionality
/// Can be added to settings or debug screens
class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  bool _isLoading = false;
  String _status = 'Ready to test notifications';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notification System Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.lightBackground.withOpacity(0.8)
                    : AppTheme.darkAccentGreen.withOpacity(0.8),
                fontFamily: 'Orbitron',
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _testLocalNotifications,
                    icon: const Icon(Icons.notifications, size: 16),
                    label: const Text('Test Local Notifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _testNotificationDatabase,
                    icon: const Icon(Icons.storage, size: 16),
                    label: const Text('Test Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _checkPermissions,
                    icon: const Icon(Icons.security, size: 16),
                    label: const Text('Check Permissions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _runAllTests,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Run All Tests'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkAccentGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testLocalNotifications() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing local notifications...';
    });

    try {
      await NotificationSystemTest.testLocalNotificationScheduling();
      setState(() {
        _status = '✅ Local notifications test completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Local notifications test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotificationDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing notification database...';
    });

    try {
      await NotificationSystemTest.testNotificationDatabase();
      setState(() {
        _status = '✅ Notification database test completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Notification database test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking notification permissions...';
    });

    try {
      await NotificationSystemTest.testNotificationPermissions();
      setState(() {
        _status = '✅ Permission check completed!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Permission check failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _status = 'Running all notification tests...';
    });

    try {
      await NotificationSystemTest.runAllTests();
      setState(() {
        _status = '✅ All notification tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Some tests failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
