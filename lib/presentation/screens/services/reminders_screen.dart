import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/reminder_service.dart';
import '../../../models/backup_reminder.dart';
import '../../../models/backup_car.dart';

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  
  List<ReminderWithCarInfo> _allReminders = [];
  List<ReminderWithCarInfo> _filteredReminders = [];
  bool _isLoading = true;
  int _selectedIndex = 0; // 0: Upcoming, 1: Overdue, 2: Completed
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final reminders = await _reminderService.getAllRemindersWithCarInfo();
      if (mounted) {
        setState(() {
          _allReminders = reminders;
          _filteredReminders = reminders;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allReminders = [];
          _filteredReminders = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ReminderWithCarInfo> get _upcomingReminders =>
      _filteredReminders.where((r) => r.reminder.status == ReminderStatus.upcoming).toList();

  List<ReminderWithCarInfo> get _overdueReminders =>
      _filteredReminders.where((r) => r.reminder.status == ReminderStatus.overdue).toList();

  List<ReminderWithCarInfo> get _completedReminders =>
      _filteredReminders.where((r) => r.reminder.status == ReminderStatus.completed).toList();

  void _applyFilters() {
              setState(() {
      if (_searchQuery.isEmpty) {
        _filteredReminders = _allReminders;
                } else {
        _filteredReminders = _allReminders.where((reminderWithCar) {
          final reminder = reminderWithCar.reminder;
          final searchLower = _searchQuery.toLowerCase();
          return reminder.title.toLowerCase().contains(searchLower) ||
                 reminder.description.toLowerCase().contains(searchLower) ||
                 reminder.type.displayName.toLowerCase().contains(searchLower) ||
                 reminder.priority.displayName.toLowerCase().contains(searchLower) ||
                 reminderWithCar.carDisplayName.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  void _toggleSearch() {
                    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _applyFilters();
      }
    });
  }

  void _onSearchChanged(String query) {
                    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeaderWithBackground(),
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCurrentRemindersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      height: 320,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Smart Reminders',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                                     ),
                   IconButton(
                     icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 24),
                     onPressed: _toggleSearch,
                                     ),
                 ],
               ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Stay on top of your vehicle maintenance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                       fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
               const SizedBox(height: 16),
               // Add Reminder button in header
               Container(
                 width: 170,
                 height: 45,
                 decoration: BoxDecoration(
                   gradient: const LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [
                       AppTheme.primaryGreen,
                       AppTheme.darkAccentGreen,
                     ],
                   ),
                   borderRadius: BorderRadius.circular(28),
                   boxShadow: [
                     BoxShadow(
                       color: AppTheme.primaryGreen.withOpacity(0.4),
                       blurRadius: 8,
                       offset: const Offset(0, 4),
                     ),
                   ],
                 ),
                 child: Material(
                   color: Colors.transparent,
                   child: InkWell(
                     onTap: _showAddReminderSheet,
                     borderRadius: BorderRadius.circular(28),
                     child: const Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(
                           Icons.add_circle_outline,
                           color: Colors.white,
                           size: 20,
                         ),
                         SizedBox(width: 8),
                         Text(
                           'Add Reminder',
                           style: TextStyle(
                             color: Colors.white,
                             fontSize: 14,
                             fontWeight: FontWeight.w600,
                             fontFamily: 'Orbitron',
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   _buildClickableStatCard('Upcoming', _upcomingReminders.length, Colors.blue, 0),
                   const SizedBox(width: 8),
                   _buildClickableStatCard('Overdue', _overdueReminders.length, Colors.red, 1),
                   const SizedBox(width: 8),
                   _buildClickableStatCard('Completed', _completedReminders.length, Colors.green, 2),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableStatCard(String title, int count, Color color, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      AppTheme.primaryGreen.withOpacity(0.4),
                      AppTheme.darkAccentGreen.withOpacity(0.4),
                    ]
                  : [
                      AppTheme.darkAccentGreen.withOpacity(0.3),
                      AppTheme.backgroundGreen.withOpacity(0.3),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.4) 
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
                  children: [
              Container(
                width: 32,
                height: 32,
                        decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.3) 
                      : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.white70,
                  fontFamily: 'Orbitron',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search reminders...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Orbitron',
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontFamily: 'Orbitron'),
      ),
    );
  }

  Widget _buildCurrentRemindersList() {
    List<ReminderWithCarInfo> currentReminders;
    ReminderStatus currentStatus;
    
    switch (_selectedIndex) {
      case 0:
        currentReminders = _upcomingReminders;
        currentStatus = ReminderStatus.upcoming;
        break;
      case 1:
        currentReminders = _overdueReminders;
        currentStatus = ReminderStatus.overdue;
        break;
      case 2:
        currentReminders = _completedReminders;
        currentStatus = ReminderStatus.completed;
        break;
      default:
        currentReminders = _upcomingReminders;
        currentStatus = ReminderStatus.upcoming;
    }
    
    return _buildRemindersList(currentReminders, currentStatus);
  }

  Widget _buildRemindersList(List<ReminderWithCarInfo> reminders, ReminderStatus status) {
    if (reminders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadReminders,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReminderCard(reminder),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ReminderStatus status) {
    String message;
    String emoji;
    
    switch (status) {
      case ReminderStatus.upcoming:
        message = 'No upcoming reminders.\nYour schedule is clear!';
        emoji = '✅';
          break;
      case ReminderStatus.overdue:
        message = 'No overdue reminders.\nYou\'re all caught up!';
        emoji = '🎉';
          break;
      case ReminderStatus.completed:
        message = 'No completed reminders yet.\nStart completing tasks!';
        emoji = '📝';
          break;
    }

    return RefreshIndicator(
      onRefresh: _loadReminders,
      color: AppTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400, // Give enough height for pull-to-refresh
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderWithCarInfo reminderWithCar) {
    final reminder = reminderWithCar.reminder;
    Color priorityColor = _getPriorityColor(reminder.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showReminderDetails(reminder, reminderWithCar.carDisplayName),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                  Container(
                    width: 50,
                    height: 50,
                   decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                  child: Text(
                        reminder.type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reminderWithCar.carDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.type.displayName,
                    style: TextStyle(
                      fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
                  ),
                ],
              ),
                    const SizedBox(height: 12),
              Text(
                reminder.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                    ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    reminder.displayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (reminder.status != ReminderStatus.completed)
                    ElevatedButton(
                      onPressed: () => _markReminderCompleted(reminder),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Mark as Completed',
                        style: TextStyle(fontSize: 10, fontFamily: 'Orbitron'),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reminder.priority.displayName,
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
                ),
      ),
    );
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.green;
      case ReminderPriority.medium:
        return Colors.orange;
      case ReminderPriority.high:
        return Colors.red;
      case ReminderPriority.urgent:
        return Colors.purple;
    }
  }


  void _showReminderDetails(BackupReminder reminder, String carDisplayName) {
    showDialog(
      context: context,
      builder: (context) => ReminderDetailsDialog(
        reminder: reminder,
        carDisplayName: carDisplayName,
         onEdit: () => _showEditReminderDialog(reminder),
         onDelete: () {
           Navigator.pop(context);
           _deleteReminder(reminder);
         },
        onMarkCompleted: () => _markReminderCompleted(reminder),
        onMarkUncompleted: () => _markReminderUncompleted(reminder),
      ),
    );
  }

  void _showEditReminderDialog(BackupReminder reminder) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditReminderForm(
        reminder: reminder,
        onReminderUpdated: () {},
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteReminder(BackupReminder reminder) async {
    Navigator.pop(context); // Close details dialog first
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await _reminderService.deleteReminder(reminder.id!);
        if (result.isSuccess) {
          await _loadReminders();
          if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
                content: Text(result.message),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.red,
      ),
    );
  }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markReminderCompleted(BackupReminder reminder) async {
    if (reminder.isCompleted) return;

    try {
      final result = await _reminderService.markReminderCompleted(reminder.id!);
      if (result.isSuccess) {
        await _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking reminder as completed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markReminderUncompleted(BackupReminder reminder) async {
    if (!reminder.isCompleted) return;

    try {
      final result = await _reminderService.markReminderUncompleted(reminder.id!);
      if (result.isSuccess) {
        await _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking reminder as uncompleted: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddReminderForm(onReminderAdded: _loadReminders),
    );
  }
}

// Reminder Details Dialog
class ReminderDetailsDialog extends StatelessWidget {
  final BackupReminder reminder;
  final String? carDisplayName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkUncompleted;

  const ReminderDetailsDialog({
    super.key,
    required this.reminder,
    this.carDisplayName,
    required this.onEdit,
    required this.onDelete,
    this.onMarkCompleted,
    this.onMarkUncompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
        child: Container(
          padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A362A), // Dark green
              Color(0xFF2E4032), // Slightly lighter dark green
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getPriorityColor(reminder.priority).withOpacity(0.3),
            width: 1,
          ),
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(reminder.priority).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            reminder.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(reminder.priority).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${reminder.type.displayName} - ${reminder.priority.displayName}',
                                style: TextStyle(
                                  color: _getPriorityColor(reminder.priority),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Details section with modern styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildModernReminderDetailRow('Description', reminder.description, Icons.description, Colors.grey),
                  if (carDisplayName != null)
                    _buildModernReminderDetailRow('Car', carDisplayName!, Icons.directions_car, Colors.orange),
                  _buildModernReminderDetailRow('Due Date/Mileage', reminder.displayText, Icons.schedule, Colors.blue),
                  _buildModernReminderDetailRow('Status', reminder.status.name.toUpperCase(), Icons.flag, _getPriorityColor(reminder.priority)),
                  _buildModernReminderDetailRow('Created', _formatDate(reminder.createdAt), Icons.calendar_today, Colors.green),
                  if (reminder.isCompleted && reminder.completedAt != null)
                    _buildModernReminderDetailRow('Completed', _formatDate(reminder.completedAt!), Icons.check_circle, Colors.green),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Modern action buttons
            Column(
              children: [
                // Top row - Complete/Revert and Edit
                Row(
                  children: [
                    if (!reminder.isCompleted && onMarkCompleted != null) ...[
                      Expanded(
                        child: _buildModernReminderButton(
                          icon: Icons.check_circle_rounded,
                          label: 'Complete',
                          color: const Color(0xFF4CAF50),
                          onPressed: () {
                            if (context.mounted) {
                              Navigator.pop(context);
                              onMarkCompleted!();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (reminder.isCompleted && onMarkUncompleted != null) ...[
                      Expanded(
                        child: _buildModernReminderButton(
                          icon: Icons.undo_rounded,
                          label: 'Revert',
                          color: Colors.orange,
                          onPressed: () {
                            if (context.mounted) {
                              Navigator.pop(context);
                              onMarkUncompleted!();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildModernReminderButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: const Color(0xFF2196F3),
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                            onEdit();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Bottom row - Delete and Close
                Row(
                  children: [
                    Expanded(
                      child: _buildModernReminderButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: const Color.fromARGB(255, 219, 25, 25),
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                            onDelete();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernReminderButton(
                        icon: Icons.close_rounded,
                        label: 'Close',
                        color: Colors.grey[600]!,
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
              child: Text(
              '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                color: Color(0xFFA5D6A7), // Muted light green
                ),
              ),
            ),
                  Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFFC8E6C9), // Light green text
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernReminderDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernReminderButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.green;
      case ReminderPriority.medium:
        return Colors.orange;
      case ReminderPriority.high:
        return Colors.red;
      case ReminderPriority.urgent:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Add Reminder Form
class AddReminderForm extends StatefulWidget {
  final VoidCallback onReminderAdded;
  
  const AddReminderForm({super.key, required this.onReminderAdded});
  
  @override
  State<AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<AddReminderForm> {
  final ReminderService _reminderService = ReminderService();
  
  String title = '';
  String description = '';
  ReminderType selectedType = ReminderType.maintenance;
  ReminderPriority selectedPriority = ReminderPriority.medium;
  DateTime? targetDate;
  int? targetMileage;
  BackupCar? selectedCar;
  List<BackupCar> userCars = [];
  bool _isLoading = false;
  bool _isLoadingCars = true;

  @override
  void initState() {
    super.initState();
    _loadUserCars();
  }

  Future<void> _loadUserCars() async {
    try {
      final cars = await _reminderService.getUserCars();
                        setState(() {
        userCars = cars;
        _isLoadingCars = false;
        if (cars.isNotEmpty) {
          selectedCar = cars.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCars = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.viewInsets.bottom + 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Add New Reminder', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            
            // Car selection
            if (_isLoadingCars)
              const Center(child: CircularProgressIndicator())
            else if (userCars.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'No cars found. Please add a car first before creating reminders.',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              )
            else ...[
              _buildDropdown<BackupCar>(
                label: 'Select Car*',
                value: selectedCar,
                items: userCars,
                onChanged: (car) => setState(() => selectedCar = car),
                itemBuilder: (car) => '${car.year} ${car.brand} ${car.model}',
              ),
              const SizedBox(height: 16),
              
              // Title and Type
              Row(
                      children: [
                  Expanded(child: _field(label: 'Title*', onChanged: (v) => title = v)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown<ReminderType>(
                      label: 'Type*',
                      value: selectedType,
                      items: ReminderType.values,
                      onChanged: (type) => setState(() => selectedType = type!),
                      itemBuilder: (type) => type.displayName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              _field(
                label: 'Description*',
                onChanged: (v) => description = v,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Priority
              _buildDropdown<ReminderPriority>(
                label: 'Priority*',
                value: selectedPriority,
                items: ReminderPriority.values,
                onChanged: (priority) => setState(() => selectedPriority = priority!),
                itemBuilder: (priority) => priority.displayName,
              ),
              const SizedBox(height: 16),
              
              // Target Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() => targetDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                    child: Row(
                      children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        targetDate != null
                            ? 'Target Date: ${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                            : 'Select Target Date',
                        style: const TextStyle(fontFamily: 'Orbitron'),
                      ),
                      ],
                    ),
                  ),
              ),
              const SizedBox(height: 16),
              
              // Target Mileage
              _field(
                label: 'Target Mileage (optional)',
                keyboard: TextInputType.number,
                onChanged: (v) => targetMileage = int.tryParse(v),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.darkAccentGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading || selectedCar == null ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Reminder', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    TextInputType? keyboard,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: keyboard,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Orbitron'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemBuilder,
    double? textSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder(item), style: TextStyle(fontFamily: 'Orbitron', fontSize: textSize ?? 16)),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Future<void> _saveReminder() async {
    setState(() => _isLoading = true);
    
    // Validation
    if (title.isEmpty || description.isEmpty || selectedCar == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final result = await _reminderService.addReminder(
        carId: selectedCar!.id!,
        title: title,
        description: description,
        type: selectedType,
        priority: selectedPriority,
        targetDate: targetDate,
        targetMileage: targetMileage,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        if (result.isSuccess) {
          widget.onReminderAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Edit Reminder Form
class EditReminderForm extends StatefulWidget {
  final BackupReminder reminder;
  final VoidCallback onReminderUpdated;
  
  const EditReminderForm({super.key, required this.reminder, required this.onReminderUpdated});
  
  @override
  State<EditReminderForm> createState() => _EditReminderFormState();
}

class _EditReminderFormState extends State<EditReminderForm> {
  final ReminderService _reminderService = ReminderService();
  
  late String title;
  late String description;
  late ReminderType selectedType;
  late ReminderPriority selectedPriority;
  DateTime? targetDate;
  int? targetMileage;
  BackupCar? selectedCar;
  List<BackupCar> userCars = [];
  bool _isLoading = false;
  bool _isLoadingCars = true;

  @override
  void initState() {
    super.initState();
    // Initialize with current reminder data
    title = widget.reminder.title;
    description = widget.reminder.description;
    selectedType = widget.reminder.type;
    selectedPriority = widget.reminder.priority;
    targetDate = widget.reminder.targetDate;
    targetMileage = widget.reminder.targetMileage;
    _loadUserCars();
  }

  Future<void> _loadUserCars() async {
    try {
      final cars = await _reminderService.getUserCars();
    setState(() {
        userCars = cars;
        _isLoadingCars = false;
        // Find the car that matches the reminder's car ID
        try {
          selectedCar = cars.firstWhere((car) => car.id == widget.reminder.carId);
        } catch (e) {
          selectedCar = cars.isNotEmpty ? cars.first : null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCars = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
  return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.viewInsets.bottom + 16,
        top: 16,
      ),
      child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                    decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Edit Reminder', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            
            // Car selection
            if (_isLoadingCars)
              const Center(child: CircularProgressIndicator())
            else if (userCars.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'No cars found. Please add a car first.',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              )
            else ...[
              _buildDropdown<BackupCar>(
                label: 'Select Car*',
                value: selectedCar,
                items: userCars,
                onChanged: (car) => setState(() => selectedCar = car),
                itemBuilder: (car) => '${car.year} ${car.brand} ${car.model}',
              ),
              const SizedBox(height: 16),
              
              // Title and Type
              Row(
                children: [
                  Expanded(child: _field(label: 'Title*', initialValue: title, onChanged: (v) => title = v)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown<ReminderType>(
                      label: 'Type*',
                      value: selectedType,
                      items: ReminderType.values,
                      textSize: 12,
                      onChanged: (type) => setState(() => selectedType = type!),
                      itemBuilder: (type) => type.displayName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              _field(
                label: 'Description*',
                initialValue: description,
                onChanged: (v) => description = v,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Priority
              _buildDropdown<ReminderPriority>(
                label: 'Priority*',
                value: selectedPriority,
                items: ReminderPriority.values,
                onChanged: (priority) => setState(() => selectedPriority = priority!),
                itemBuilder: (priority) => priority.displayName,
              ),
              const SizedBox(height: 16),
              
              // Target Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: targetDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() => targetDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
    child: Row(
      children: [
                      const Icon(Icons.calendar_today),
        const SizedBox(width: 8),
        Text(
                        targetDate != null
                            ? 'Target Date: ${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                            : 'Select Target Date',
                        style: const TextStyle(fontFamily: 'Orbitron'),
                      ),
                      const Spacer(),
                      if (targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => targetDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Target Mileage
              _field(
                label: 'Target Mileage (optional)',
                initialValue: targetMileage?.toString() ?? '',
                keyboard: TextInputType.number,
                onChanged: (v) => targetMileage = v.isEmpty ? null : int.tryParse(v),
              ),
              const SizedBox(height: 24),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.darkAccentGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Reminder', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ],
          ),
        ),
    );
  }

  Widget _field({
    required String label,
    String? initialValue,
    TextInputType? keyboard,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboard,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Orbitron'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemBuilder,
    double? textSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder(item), style: TextStyle(fontFamily: 'Orbitron', fontSize: textSize ?? 12)),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Future<void> _updateReminder() async {
    // Validation
    if (title.trim().isEmpty || description.trim().isEmpty || selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _reminderService.updateReminder(
        id: widget.reminder.id!,
        carId: selectedCar!.id!,
        title: title.trim(),
        description: description.trim(),
        type: selectedType,
        priority: selectedPriority,
        targetDate: targetDate,
        targetMileage: targetMileage,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating reminder: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}