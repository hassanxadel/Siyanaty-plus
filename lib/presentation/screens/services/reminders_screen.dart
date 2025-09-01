import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
// import '../home/home_screen.dart';
// import 'add_reminder_screen.dart';

// Reminder domain types (top-level to satisfy linter)
enum ReminderStatus { upcoming, overdue, completed }

class _Reminder {
  _Reminder({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priority,
    required this.car,
    required this.mileage,
    required this.status,
  });

  final int id;
  final String title;
  final String subtitle;
  final IconData icon;
  String priority;
  final String car;
  final String mileage;
  ReminderStatus status;
}

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // Selection and data state
  bool _selectionMode = false;
  final Set<int> _selectedIds = <int>{};

  // Simple model and status handled at top-level above

  // Selection helpers and bulk actions
  void _enterSelection(_Reminder r) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(r.id);
    });
  }

  void _toggleSelect(_Reminder r) {
    setState(() {
      if (_selectedIds.contains(r.id)) {
        _selectedIds.remove(r.id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(r.id);
      }
    });
  }

  List<_Reminder> _currentTabReminders() {
    switch (_tabController.index) {
      case 0:
        return _reminders.where((r) => r.status == ReminderStatus.upcoming).toList();
      case 1:
        return _reminders.where((r) => r.status == ReminderStatus.overdue).toList();
      case 2:
        return _reminders.where((r) => r.status == ReminderStatus.completed).toList();
      default:
        return _reminders;
    }
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getThemeAwareCardBackground(context).withOpacity(0.3),
        border: Border.all(color: AppTheme.getThemeAwareBorderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} selected',
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: AppTheme.getThemeAwareTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              final visible = _currentTabReminders();
              final visibleIds = visible.map((e) => e.id).toSet();
              setState(() {
                if (visibleIds.difference(_selectedIds).isEmpty && _selectedIds.isNotEmpty) {
                  // All visible already selected -> clear only visible
                  _selectedIds.removeWhere((id) => visibleIds.contains(id));
                  if (_selectedIds.isEmpty) _selectionMode = false;
                } else {
                  _selectionMode = true;
                  _selectedIds.addAll(visibleIds);
                }
              });
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Select All'),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Mark Read',
            icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    setState(() {
                      for (final id in _selectedIds) {
                        final r = _reminders.firstWhere((e) => e.id == id);
                        r.status = ReminderStatus.completed;
                        r.priority = 'Completed';
                      }
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    setState(() {
                      _reminders.removeWhere((e) => _selectedIds.contains(e.id));
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
          ),
          IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  int _nextId = 1;
  late List<_Reminder> _reminders;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reminders = <_Reminder>[
      _Reminder(
        id: _nextId++,
        title: 'Oil Change',
        subtitle: 'Due in 3 days',
        icon: Icons.oil_barrel,
        priority: 'High',
        car: 'Toyota Camry',
                  mileage: '75,000 km',
        status: ReminderStatus.upcoming,
      ),
      _Reminder(
        id: _nextId++,
        title: 'Tire Rotation',
        subtitle: 'Due in 1 week',
        icon: Icons.tire_repair,
        priority: 'Medium',
        car: 'Toyota Camry',
                  mileage: '75,200 km',
        status: ReminderStatus.upcoming,
      ),
      _Reminder(
        id: _nextId++,
        title: 'Brake Inspection',
        subtitle: 'Overdue by 5 days',
        icon: Icons.disc_full,
        priority: 'Critical',
        car: 'Honda Civic',
                  mileage: '42,500 km',
        status: ReminderStatus.overdue,
      ),
      _Reminder(
        id: _nextId++,
        title: 'Battery Check',
        subtitle: 'Completed 2 days ago',
        icon: Icons.battery_full,
        priority: 'Completed',
        car: 'Toyota Camry',
                  mileage: '74,800 km',
        status: ReminderStatus.completed,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: Column(
        children: [
          // Cool header design
          _buildHeaderWithBackground(),
          
          // Tab content
          Expanded(
            child: Container(
              color: AppTheme.getThemeAwareBackground(context),
              child: Column(
                children: [
                  // selection bar moved to header and bottom actions
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUpcomingReminders(),
                        _buildOverdueReminders(),
                        _buildCompletedReminders(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Builder(
        builder: (context) {
          final width = MediaQuery.of(context).size.width * 0.9;
          if (_selectionMode) {
            return SizedBox(
              width: width,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedIds.isEmpty ? null : () {
                        setState(() {
                          for (final id in _selectedIds) {
                            final r = _reminders.firstWhere((e) => e.id == id);
                            r.status = ReminderStatus.completed;
                            r.priority = 'Completed';
                          }
                          _selectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Mark as read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryGreen,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedIds.isEmpty ? null : () {
                        setState(() {
                          _reminders.removeWhere((e) => _selectedIds.contains(e.id));
                          _selectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _showAddReminderSheet,
              icon: const Icon(Icons.add, size: 22),
              label: const Text(
                'New Reminder',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: AppTheme.primaryGreen.withOpacity(0.5),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
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
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // If no previous route, try to navigate to root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Smart Reminders',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                                     ),
                 ],
               ),
               const SizedBox(height: 16),
               
               // Tab Bar
              SizedBox(
                height: 44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                 child: Container(
                   decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
                   ),
                   child: TabBar(
                     controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                     labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(vertical: 6),
                     indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
                     ),
                     labelStyle: const TextStyle(
                       fontFamily: 'Orbitron',
                       fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                     ),
                     tabs: const [
                       Tab(text: 'Upcoming'),
                       Tab(text: 'Overdue'),
                       Tab(text: 'Completed'),
                     ],
                    ),
                   ),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern bottom sheet add form (popup)
  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, controller) {
            final formKey = GlobalKey<FormState>();
            final title = TextEditingController();
            final subtitle = TextEditingController();
            final car = TextEditingController();
            final mileage = TextEditingController();
            DateTime? dueDate;
            String priority = 'Medium';

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.getThemeAwareCardBackground(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppTheme.getThemeAwareBorderColor(context)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add Reminder',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _buildSheetTextField(title, 'Title', 'Oil Change'),
                    const SizedBox(height: 12),
                    _buildSheetTextField(subtitle, 'Subtitle', 'Due in 3 days'),
                    const SizedBox(height: 12),
                    _buildSheetTextField(car, 'Car', 'Toyota Camry'),
                    const SizedBox(height: 12),
                    _buildSheetTextField(mileage, 'Mileage', '75200 km', keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                      ],
                      onChanged: (v) => priority = v ?? 'Medium',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          dueDate = picked;
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(dueDate == null ? 'Pick due date' : 'Due: ${dueDate.toLocal().toString().split(' ')[0]}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        setState(() {
                          _reminders.add(_Reminder(
                            id: _nextId++,
                            title: title.text.trim(),
                            subtitle: subtitle.text.trim(),
                            icon: Icons.notifications,
                            priority: priority,
                            car: car.text.trim(),
                            mileage: mileage.text.trim(),
                            status: ReminderStatus.upcoming,
                          ));
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetTextField(TextEditingController c, String label, String hint, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
  // duplicate removed

  void _deleteSelectedReminders() {
    final List<_Reminder> remainingReminders = _reminders.where((reminder) => !_selectedIds.contains(reminder.id)).toList();
    setState(() {
      _reminders = remainingReminders;
      _selectedIds.clear();
      _selectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedIds.length} reminders deleted.',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _markSelectedComplete() {
    final List<_Reminder> updatedReminders = _reminders.map((reminder) {
      if (_selectedIds.contains(reminder.id)) {
        return _Reminder(
          id: reminder.id,
          title: reminder.title,
          subtitle: reminder.subtitle,
          icon: reminder.icon,
          priority: reminder.priority,
          car: reminder.car,
          mileage: reminder.mileage,
          status: ReminderStatus.completed,
        );
      }
      return reminder;
    }).toList();
    setState(() {
      _reminders = updatedReminders;
      _selectedIds.clear();
      _selectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedIds.length} reminders marked as complete.',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Widget _buildUpcomingReminders() {
    final items = _reminders.where((r) => r.status == ReminderStatus.upcoming).toList();
    return _buildRemindersList(items, isOverdue: false, completed: false);
  }

  Widget _buildOverdueReminders() {
    final items = _reminders.where((r) => r.status == ReminderStatus.overdue).toList();
    return _buildRemindersList(items, isOverdue: true, completed: false);
  }

  Widget _buildCompletedReminders() {
    final items = _reminders.where((r) => r.status == ReminderStatus.completed).toList();
    return _buildRemindersList(items, isOverdue: false, completed: true);
  }

  Widget _buildRemindersList(List<_Reminder> items, {required bool isOverdue, required bool completed}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        return _buildReminderCard(r, isOverdue, completed: completed);
      },
    );
  }

  Widget _buildReminderCard(_Reminder reminder, bool isOverdue, {bool completed = false}) {
    Color priorityColor = AppTheme.primaryGreen;
    
    if (completed) {
      priorityColor = AppTheme.secondaryGreen;
    } else if (isOverdue) {
      priorityColor = AppTheme.errorColor;
    } else {
      switch (reminder.priority) {
        case 'High':
          priorityColor = AppTheme.warningColor;
          break;
        case 'Critical':
          priorityColor = AppTheme.errorColor;
          break;
        case 'Medium':
          priorityColor = AppTheme.secondaryGreen;
          break;
        default:
          priorityColor = AppTheme.primaryGreen;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            reminder.icon,
            color: priorityColor,
            size: 24,
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: completed ? AppTheme.getThemeAwareTextColor(context).withOpacity(0.6) : AppTheme.getThemeAwareTextColor(context),
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              reminder.subtitle,
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: priorityColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                  Container(
                   width: 45,
                   
                   padding: const EdgeInsets.all(4),
                   decoration: BoxDecoration(
                     color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.05),
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: Icon(
                     const IconData(0xe800, fontFamily: 'MyFlutterApp'),
                  size: 14,
                  color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
                   ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    reminder.car,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.speed,
                  size: 14,
                  color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    reminder.mileage,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _selectionMode
            ? Checkbox(
                value: _selectedIds.contains(reminder.id),
                onChanged: (v) => _toggleSelect(reminder),
              )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reminder.priority,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: priorityColor,
                ),
              ),
            ),
            if (!completed) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6)),
                onSelected: (value) => _handleReminderAction(value, reminder),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor),
                        SizedBox(width: 8),
                        Text('Mark Complete'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'snooze',
                    child: Row(
                      children: [
                        Icon(Icons.snooze, color: AppTheme.warningColor),
                        SizedBox(width: 8),
                        Text('Snooze'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onLongPress: () => _enterSelection(reminder),
        onTap: _selectionMode ? () => _toggleSelect(reminder) : () => _showReminderDetails(reminder),
      ),
    );
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add New Reminder',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Add reminder feature will be implemented here.',
          style: TextStyle(fontFamily: 'Orbitron'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Add',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReminderAction(String action, _Reminder reminder) {
    switch (action) {
      case 'complete':
        _markComplete(reminder);
        break;
      case 'snooze':
        _snoozeReminder(reminder);
        break;
      case 'edit':
        _editReminder(reminder);
        break;
      case 'delete':
        _deleteReminder(reminder);
        break;
    }
  }

  void _markComplete(_Reminder reminder) {
    setState(() {
      reminder.status = ReminderStatus.completed;
      reminder.priority = 'Completed';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${reminder.title} marked as complete!',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _snoozeReminder(_Reminder reminder) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${reminder.title} snoozed for 1 week.',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  void _editReminder(_Reminder reminder) {
    // Implementation for editing reminder
  }

  void _deleteReminder(_Reminder reminder) {
    setState(() {
      _reminders.removeWhere((r) => r.id == reminder.id);
    });
    // Implementation for deleting reminder
  }

 void _showReminderDetails(_Reminder reminder) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    barrierLabel: 'Reminder details',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, a1, a2) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.getThemeAwareCardBackground(context).withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.getThemeAwareBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(reminder.icon, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: AppTheme.getThemeAwareTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.subtitle,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: AppTheme.getThemeAwareBorderColor(context)),
              const SizedBox(height: 12),

              /// Details section
              _detailRow(Icons.directions_car, "Car", reminder.car),
              _detailRow(Icons.speed, "Mileage", reminder.mileage),
              _detailRow(Icons.event, "Due", reminder.subtitle),

              const SizedBox(height: 20),

              /// Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          reminder.status = ReminderStatus.completed;
                          reminder.priority = 'Completed';
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Mark as Read"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.getThemeAwareBorderColor(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _reminders.removeWhere((r) => r.id == reminder.id);
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, a2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim.value),
        child: Opacity(opacity: anim.value, child: child),
      );
    },
  );
}

Widget _detailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              color: AppTheme.getThemeAwareTextColor(context),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    ),
  );
}

}