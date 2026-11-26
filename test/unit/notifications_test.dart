import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyanaty_plus/services/notification_database_service.dart';
import 'package:siyanaty_plus/presentation/screens/notifications/notifications_screen.dart';

NotificationItem _mk(DateTime t, {bool read = false, String title = 'Reminder'}) =>
    NotificationItem(
      id: t.toIso8601String(),
      title: title,
      message: 'message',
      type: NotificationType.reminder,
      timestamp: t,
      isRead: read,
      priority: NotificationPriority.low,
    );

void main() {
  group('groupNotificationsByTime', () {
    final now = DateTime(2026, 11, 23, 12, 0);

    test('buckets Today / Yesterday / This Week / Earlier in order', () {
      final items = [
        _mk(now),
        _mk(now.subtract(const Duration(days: 1))),
        _mk(now.subtract(const Duration(days: 3))),
        _mk(now.subtract(const Duration(days: 10))),
      ];
      final groups = groupNotificationsByTime(items, now);
      expect(groups.map((g) => g.label).toList(),
          ['Today', 'Yesterday', 'This Week', 'Earlier']);
      expect(groups.every((g) => g.items.length == 1), isTrue);
    });

    test('empty groups are omitted', () {
      final groups = groupNotificationsByTime([_mk(now)], now);
      expect(groups.length, 1);
      expect(groups.single.label, 'Today');
    });
  });

  group('relativeTime', () {
    final now = DateTime(2026, 1, 1, 12, 0);
    test('formats each range', () {
      expect(relativeTime(now.subtract(const Duration(seconds: 10)), now),
          'Just now');
      expect(relativeTime(now.subtract(const Duration(minutes: 5)), now),
          '5m ago');
      expect(
          relativeTime(now.subtract(const Duration(hours: 2)), now), '2h ago');
      expect(relativeTime(now.subtract(const Duration(days: 1)), now),
          'Yesterday');
      expect(
          relativeTime(now.subtract(const Duration(days: 3)), now), '3d ago');
    });
  });

  group('cleanNotificationTitle', () {
    test('strips leading emoji', () {
      expect(cleanNotificationTitle('🔧 Overdue Maintenance'),
          'Overdue Maintenance');
      expect(cleanNotificationTitle('🛡️ Overdue Insurance'),
          'Overdue Insurance');
    });
  });

  testWidgets('NotificationRow does not overflow at 320px with long text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = NotificationItem(
      id: '1',
      title:
          '🔧 A very long overdue maintenance notification title that should ellipsize',
      message:
          'A very long message that should wrap to two lines then ellipsize without overflowing the row on a small screen. ' *
              2,
      type: NotificationType.reminder,
      timestamp: DateTime.now(),
      isRead: false,
      priority: NotificationPriority.high,
      carName: 'Toyota Corolla 2018',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            NotificationRow(item: item, showCar: true, onTap: () {}),
          ],
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });
}
