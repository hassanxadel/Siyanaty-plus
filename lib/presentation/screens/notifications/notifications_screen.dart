import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/notification_database_service.dart';
import '../../../services/local_notification_service.dart';
import '../../../services/car_service.dart';
import '../services/reminders_screen.dart';

// ---------------------------------------------------------------------------
// Pure, testable helpers
// ---------------------------------------------------------------------------

/// Strip emoji / non-ASCII from a title (the row shows a real icon badge).
String cleanNotificationTitle(String title) =>
    title.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();

/// Relative time: "Just now", "5m ago", "2h ago", "Yesterday", "3d ago", else a date.
String relativeTime(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.isNegative) return 'Just now';
  if (d.inSeconds < 60) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('MMM d').format(t);
}

class NotificationGroup {
  final String label;
  final List<NotificationItem> items;
  const NotificationGroup(this.label, this.items);
}

/// Group notifications into Today / Yesterday / This Week / Earlier. Items are
/// expected newest-first; empty groups are omitted.
List<NotificationGroup> groupNotificationsByTime(
    List<NotificationItem> items, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(const Duration(days: 7));

  final todayL = <NotificationItem>[];
  final yest = <NotificationItem>[];
  final week = <NotificationItem>[];
  final earlier = <NotificationItem>[];

  for (final n in items) {
    final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
    if (!d.isBefore(today)) {
      todayL.add(n);
    } else if (d == yesterday) {
      yest.add(n);
    } else if (!d.isBefore(weekStart)) {
      week.add(n);
    } else {
      earlier.add(n);
    }
  }

  return [
    if (todayL.isNotEmpty) NotificationGroup('Today', todayL),
    if (yest.isNotEmpty) NotificationGroup('Yesterday', yest),
    if (week.isNotEmpty) NotificationGroup('This Week', week),
    if (earlier.isNotEmpty) NotificationGroup('Earlier', earlier),
  ];
}

IconData notificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.maintenance:
      return CupertinoIcons.wrench_fill;
    case NotificationType.reminder:
      return CupertinoIcons.bell_fill;
    case NotificationType.alert:
    case NotificationType.warning:
      return CupertinoIcons.exclamationmark_triangle_fill;
    case NotificationType.success:
      return CupertinoIcons.checkmark_seal_fill;
    case NotificationType.info:
      return CupertinoIcons.info_circle_fill;
  }
}

Color notificationTint(NotificationPriority p) {
  switch (p) {
    case NotificationPriority.high:
      return AppTheme.errorColor;
    case NotificationPriority.medium:
      return AppTheme.warningColor;
    case NotificationPriority.low:
      return AppTheme.secondaryGreen;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationDatabaseService _service =
      NotificationDatabaseService.instance;
  final LocalNotificationService _localService =
      LocalNotificationService.instance;
  final CarService _carService = CarService();

  List<NotificationItem> _all = [];
  bool _isLoading = true;
  bool _unreadOnly = false;
  int _carCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await _localService.initialize();
      final items = await _service.getAllNotifications();
      final cars = await _carService.getAllCars();
      if (!mounted) return;
      setState(() {
        _all = items;
        _carCount = cars.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _all = [];
        _isLoading = false;
      });
      _snack('Could not load notifications');
    }
  }

  int get _unreadCount => _all.where((n) => !n.isRead).length;

  List<NotificationItem> get _visible =>
      _unreadOnly ? _all.where((n) => !n.isRead).toList() : _all;

  Future<void> _setRead(NotificationItem n, bool read) async {
    HapticFeedback.lightImpact();
    setState(() => n.isRead = read);
    if (read) {
      await _service.markNotificationAsRead(n.id);
    } else {
      await _service.markNotificationAsUnread(n.id);
    }
  }

  Future<void> _markAll() async {
    HapticFeedback.mediumImpact();
    await _service.markAllAsRead();
    if (!mounted) return;
    setState(() {
      for (final n in _all) {
        n.isRead = true;
      }
    });
    _snack('All notifications marked as read');
  }

  Future<void> _dismiss(NotificationItem n) async {
    HapticFeedback.mediumImpact();
    await _service.dismissNotification(n.id);
    if (!mounted) return;
    setState(() => _all.removeWhere((e) => e.id == n.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.darkAccentGreen,
          duration: const Duration(seconds: 4),
          content: const Text('Notification deleted',
              style: TextStyle(fontFamily: 'Orbitron', color: Colors.white)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppTheme.lightBackground,
            onPressed: () => _restore(n),
          ),
        ),
      );
  }

  Future<void> _restore(NotificationItem n) async {
    await _service.restoreNotification(n.id);
    await _load();
  }

  Future<void> _open(NotificationItem n) async {
    if (!n.isRead) await _setRead(n, true);
    if (!mounted) return;
    // All current notifications are reminder-derived → open the Reminders list.
    if (n.reminderId == null) {
      _snack('This item is no longer available');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmartRemindersScreen()),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: AppTheme.darkAccentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  // "Mark all as read" — plain text in the app yellow, only when
                  // there are unread items. Fixed-width slot keeps the title centred.
                  SizedBox(
                    width: 96,
                    child: _unreadCount > 0
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: _markAllAction(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _unreadCount > 0
                    ? '$_unreadCount unread'
                    : "You're all caught up",
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontFamily: 'Orbitron'),
              ),
              const SizedBox(height: 12),
              // All · Unread — fits well under 320pt.
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<bool>(
                  backgroundColor: AppTheme.backgroundGreen.withOpacity(0.5),
                  thumbColor: AppTheme.lightBackground,
                  groupValue: _unreadOnly,
                  onValueChanged: (v) {
                    if (v == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _unreadOnly = v);
                  },
                  children: {
                    false: _segLabel('All', !_unreadOnly),
                    true: _segLabel('Unread', _unreadOnly),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segLabel(String text, bool selected) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? AppTheme.backgroundGreen : Colors.white,
          ),
        ),
      );

  Widget _markAllAction() {
    return Semantics(
      button: true,
      label: 'Mark all as read',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _markAll,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Text(
              'Mark all read',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(color: Colors.white));
    }
    final groups = groupNotificationsByTime(_visible, DateTime.now());

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _load),
        if (groups.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
        else
          for (final g in groups) ...[
            SliverToBoxAdapter(child: _sectionHeader(g.label)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildRow(g.items[i]),
                childCount: g.items.length,
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightBackground,
            fontFamily: 'Orbitron',
          ),
        ),
      );

  Widget _buildRow(NotificationItem n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Dismissible(
        key: ValueKey(n.id),
        // Swipe right → toggle read/unread (never actually dismisses).
        background: _swipeBg(
          align: Alignment.centerLeft,
          icon: n.isRead ? CupertinoIcons.envelope_badge : CupertinoIcons.envelope_open,
          label: n.isRead ? 'Unread' : 'Read',
          color: AppTheme.secondaryGreen,
        ),
        // Swipe left → delete.
        secondaryBackground: _swipeBg(
          align: Alignment.centerRight,
          icon: CupertinoIcons.trash,
          label: 'Delete',
          color: AppTheme.errorColor,
        ),
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.startToEnd) {
            await _setRead(n, !n.isRead);
            return false;
          }
          return true;
        },
        onDismissed: (_) => _dismiss(n),
        child: NotificationRow(
          item: n,
          showCar: _carCount > 1,
          onTap: () => _open(n),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Alignment align,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final unreadFilterEmpty = _unreadOnly && _all.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unreadFilterEmpty
                  ? CupertinoIcons.bell
                  : CupertinoIcons.checkmark_circle,
              size: 64,
              color: AppTheme.lightBackground.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              unreadFilterEmpty ? 'No unread notifications' : "You're all caught up",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unreadFilterEmpty
                  ? 'Switch to All to see read notifications.'
                  : 'Reminders that are due or overdue will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withOpacity(0.65),
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single notification row — pure (no services), so it can be pumped in a
/// widget test at any width to prove it never overflows.
class NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final bool showCar;
  final VoidCallback onTap;

  const NotificationRow({
    super.key,
    required this.item,
    required this.showCar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = notificationTint(item.priority);
    final title = cleanNotificationTitle(item.title);
    final time = relativeTime(item.timestamp, DateTime.now());
    final semantics =
        '${item.isRead ? 'Read' : 'Unread'}, $title, $time';

    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glowCardDecoration(
              radius: 16,
              elevated: !item.isRead,
              accent: item.isRead
                  ? AppTheme.secondaryGreen.withOpacity(0.4)
                  : tint,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rounded-square type badge, softly tinted.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tint.withOpacity(0.45)),
                  ),
                  child: Icon(notificationIcon(item.type), color: tint, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.lightBackground,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: Colors.white.withOpacity(0.75),
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.55),
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          if (showCar &&
                              item.carName != null &&
                              item.carName!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.car_detailed,
                                      size: 11,
                                      color: Colors.white.withOpacity(0.55)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      item.carName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.55),
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
