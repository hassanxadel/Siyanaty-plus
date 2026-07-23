import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/reminder_service.dart';
import '../../../models/backup_reminder.dart';
import '../../../models/backup_car.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

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
        AppSnackbar.show(context, 
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
    return ScreenWithNavBar(
      currentIndex: 1, // Reminders is index 1 in nav bar
      child: Scaffold(
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundGreen,
              AppTheme.darkAccentGreen,
            ],
          ),
                   borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.secondaryGreen.withOpacity(0.6),
            width: 1,
          ),
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
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
                    // Glowing pill so the primary action on the card pops.
                    Container(
                      decoration: AppTheme.glowButtonDecoration(radius: 18),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _markReminderCompleted(reminder),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 13,
                                  color: AppTheme.secondaryGreen,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Mark as Completed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondaryGreen,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Completed badge — same pill language, but static.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGreen.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.secondaryGreen.withOpacity(0.7),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryGreen.withOpacity(0.3),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 13,
                            color: AppTheme.secondaryGreen,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: AppTheme.secondaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              fontFamily: 'Orbitron',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
      builder: (dialogContext) => ReminderDetailsDialog(
        reminder: reminder,
        carDisplayName: carDisplayName,
         onEdit: () => _showEditReminderDialog(reminder),
         onDelete: () {
           // The dialog already pops itself before calling this callback
           // So just show the delete confirmation
           _showDeleteConfirmation(reminder);
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
        AppSnackbar.show(context, 
          const SnackBar(content: Text('Reminder updated successfully')),
        );
      }
    }
  }

  /// Shows delete confirmation dialog (called when details dialog is already closed)
  Future<void> _showDeleteConfirmation(BackupReminder reminder) async {
    // Wait a frame for any previous dialog to fully close
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;
    
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Reminder',
      message:
          'Are you sure you want to delete "${reminder.title}"? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmLabel: 'Delete',
      isDestructive: true,
      barrierDismissible: false,
    );

    if (confirmed == true && mounted) {
      await _performDelete(reminder);
    }
  }

  /// Performs the actual delete operation
  Future<void> _performDelete(BackupReminder reminder) async {
    if (!mounted) return;
    
    try {
      final result = await _reminderService.deleteReminder(reminder.id!);
      if (!mounted) return;
      
      if (result.isSuccess) {
        await _loadReminders();
        if (mounted) {
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 
          SnackBar(
            content: Text('Error deleting reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Legacy delete method - kept for any direct calls
  Future<void> _deleteReminder(BackupReminder reminder) async {
    await _showDeleteConfirmation(reminder);
  }

  Future<void> _markReminderCompleted(BackupReminder reminder) async {
    if (reminder.isCompleted) return;

    try {
      final result = await _reminderService.markReminderCompleted(reminder.id!);
      if (result.isSuccess) {
        await _loadReminders();
        if (mounted) {
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 
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
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 
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
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => AddReminderForm(
          onReminderAdded: _loadReminders,
          scrollController: scrollController,
        ),
      ),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        // Matches AppDialogPanel so this card belongs to the same family as
        // every other pop-up in the app.
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundGreen,
              AppTheme.darkAccentGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.secondaryGreen.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: AppTheme.glowShadow(elevated: true),
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header — same anatomy as the car details card: glowing icon
            // chip, title + subtitle stack, raised close button.
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGreen.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          color: AppTheme.lightBackground,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${reminder.type.displayName} · ${reminder.priority.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightBackground.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGreen.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.lightBackground,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hairline divider under the header
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryGreen.withOpacity(0.5),
                    AppTheme.secondaryGreen.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details section with modern styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGreen.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryGreen.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
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
                          color: AppTheme.secondaryGreen,
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
                          color: AppDialog.warning,
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
                        color: AppTheme.infoBlue,
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
                        color: AppDialog.destructive,
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
                        color: AppTheme.lightBackground,
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1,
              ),
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
                    fontSize: 11,
                    color: AppTheme.lightBackground.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.lightBackground,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pill action matching the car details card — tinted "faded" fill with a
  /// glowing rim and an accent-coloured label, instead of a solid block.
  Widget _buildModernReminderButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: AppTheme.glowButtonDecoration(accent: color),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Add Reminder Form
class AddReminderForm extends StatefulWidget {
  final VoidCallback onReminderAdded;
  final ScrollController? scrollController;
  
  const AddReminderForm({
    super.key, 
    required this.onReminderAdded,
    this.scrollController,
  });
  
  @override
  State<AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<AddReminderForm> {
  final ReminderService _reminderService = ReminderService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetMileageController = TextEditingController();
  
  ReminderType selectedType = ReminderType.maintenance;
  ReminderPriority selectedPriority = ReminderPriority.medium;
  DateTime? targetDate;
  BackupCar? selectedCar;
  List<BackupCar> userCars = [];
  bool _isLoading = false;
  bool _isLoadingCars = true;
  String? _carError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _loadUserCars();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetMileageController.dispose();
    super.dispose();
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
        top: 8,
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Form(
          key: _formKey,
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
            const SizedBox(height: 10),
            const Text('Add New Reminder', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text('* Required fields', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 12),
            
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
              _buildCarSelector(),
              if (_carError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _carError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              // Title and Type
              Row(
                      children: [
                  Expanded(child: _field(
                    label: 'Title*', 
                    controller: _titleController,
                    customValidator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters long';
                      }
                      if (value.trim().length > 100) {
                        return 'Title must be less than 100 characters';
                      }
                      return null;
                    },
                  )),
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
                label: 'Description (optional)',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Priority
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              
              // Target Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Date*',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                        setState(() {
                          targetDate = date;
                          _dateError = null; // Clear error when date is selected
                        });
                  }
                },
                child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                        border: Border.all(
                          color: _dateError != null ? Colors.red : AppTheme.primaryGreen,
                          width: _dateError != null ? 2 : 1,
                        ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                    child: Row(
                      children: [
                          Icon(
                            Icons.calendar_today,
                            color: _dateError != null ? Colors.red : AppTheme.primaryGreen,
                            size: 20,
                          ),
                      const SizedBox(width: 8),
                      Text(
                        targetDate != null
                            ? 'Target Date: ${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                            : 'Select Target Date',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: _dateError != null ? Colors.red : AppTheme.lightBackground,
                            ),
                      ),
                      ],
                    ),
                  ),
                  ),
                  if (_dateError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _dateError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Target Mileage
              _field(
                label: 'Target Mileage (optional)',
                controller: _targetMileageController,
                keyboard: TextInputType.number,
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
                        AppTheme.darkAccentGreen,
                        AppTheme.backgroundGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.6),
                      width: 1,
                    ),
                    boxShadow: AppTheme.glowShadow(elevated: true),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading || selectedCar == null ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              const SizedBox(height: 8),
            ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? customValidator,
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
        const SizedBox(height: 6),
        // Shadow sits on a wrapper because the field paints its own fill.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.glowShadow(),
          ),
          child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Orbitron'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.backgroundGreen,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen.withOpacity(0.4), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          validator: customValidator ?? (label.contains('*')
              ? (value) => value?.isEmpty == true ? 'This field is required' : null
              : null),
          ),
        ),
        ],
    );
  }

  Widget _buildCarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Car*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
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
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCarSelectionDialog(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedCar != null && selectedCar!.imagePath != null && selectedCar!.imagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedCar!.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              IconData(0xe800, fontFamily: 'MyFlutterApp'),
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCar != null
                                ? '${selectedCar!.brand} ${selectedCar!.model}'
                                : 'Select Car',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                            const SizedBox(height: 2) ,
                          Text(
                            selectedCar != null
                                ? 'Year: ${selectedCar!.year}'
                                : 'Tap to choose vehicle',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCarSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.secondaryGreen.withOpacity(0.6),
                width: 1,
              ),
            ),
            boxShadow: AppTheme.glowShadow(elevated: true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Car list
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: userCars.length,
                  itemBuilder: (context, index) {
                    final car = userCars[index];
                    final isSelected = selectedCar?.id == car.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCar = car;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.darkAccentGreen,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.darkAccentGreen.withOpacity(0.5),
                                    AppTheme.backgroundGreen.withOpacity(0.5),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppTheme.primaryGreen, width: 2)
                              : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: car.imagePath != null && car.imagePath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(car.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                            color: Colors.white,
                                            size: 22,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                      color: Colors.white,
                                      size: 22,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.brand} ${car.model}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Orbitron',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Year: ${car.year}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontFamily: 'Orbitron',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
            filled: true,
            fillColor: AppTheme.backgroundGreen,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen.withOpacity(0.4), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
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
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showPrioritySelectionDialog(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPriorityIcon(selectedPriority),
                        color: _getPriorityColor(selectedPriority),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPriority.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getPriorityDescription(selectedPriority),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPriorityIcon(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Icons.arrow_downward;
      case ReminderPriority.medium:
        return Icons.remove;
      case ReminderPriority.high:
        return Icons.arrow_upward;
      case ReminderPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.blue;
      case ReminderPriority.medium:
        return Colors.orange;
      case ReminderPriority.high:
        return Colors.red;
      case ReminderPriority.urgent:
        return Colors.red.shade900;
    }
  }

  String _getPriorityDescription(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return 'Can be done later';
      case ReminderPriority.medium:
        return 'Normal priority';
      case ReminderPriority.high:
        return 'Important';
      case ReminderPriority.urgent:
        return 'Do immediately';
    }
  }

  void _showPrioritySelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.secondaryGreen.withOpacity(0.6),
                width: 1,
              ),
            ),
            boxShadow: AppTheme.glowShadow(elevated: true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Priority',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Priority list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: ReminderPriority.values.map((priority) {
                    final isSelected = selectedPriority == priority;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPriority = priority;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.darkAccentGreen,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.darkAccentGreen.withOpacity(0.5),
                                    AppTheme.backgroundGreen.withOpacity(0.5),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppTheme.primaryGreen, width: 2)
                              : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getPriorityIcon(priority),
                                color: _getPriorityColor(priority),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    priority.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Orbitron',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getPriorityDescription(priority),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontFamily: 'Orbitron',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveReminder() async {
    // Validate form fields
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return; // Form validation will show red borders
    }
    
    // Validate car selection
    if (selectedCar == null) {
      setState(() {
        _carError = 'Please select a car';
      });
      return;
    }
    
    // Validate target date (required)
    if (targetDate == null) {
      setState(() {
        _dateError = 'Please select a target date';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _carError = null;
      _dateError = null; // Clear any date errors
    });
    
    try {
      final result = await _reminderService.addReminder(
        carId: selectedCar!.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: selectedType,
        priority: selectedPriority,
        targetDate: targetDate,
        targetMileage: _targetMileageController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_targetMileageController.text.trim()),
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        if (result.isSuccess) {
          widget.onReminderAdded();
          AppSnackbar.show(context, 
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        } else {
          AppSnackbar.show(context, 
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
        AppSnackbar.show(context, 
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
  final _formKey = GlobalKey<FormState>();
  
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
  String? _dateError;

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
        child: Form(
          key: _formKey,
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
              _buildCarSelector(),
              const SizedBox(height: 16),
              
              // Title and Type
              Row(
                children: [
                  Expanded(child: _field(
                    label: 'Title*', 
                    initialValue: title, 
                    onChanged: (v) => title = v,
                    customValidator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters long';
                      }
                      if (value.trim().length > 100) {
                        return 'Title must be less than 100 characters';
                      }
                      return null;
                    },
                  )),
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
                label: 'Description (optional)',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Date*',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightBackground,
                    ),
                  ),
                    const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: targetDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (date != null) {
                        setState(() {
                          targetDate = date;
                          _dateError = null; // Clear error when date is selected
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dateError != null ? Colors.red : AppTheme.primaryGreen,
                          width: _dateError != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _dateError != null ? Colors.red : AppTheme.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            targetDate != null
                                ? 'Target Date: ${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                                : 'Select Target Date',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: _dateError != null ? Colors.red : AppTheme.lightBackground,
                            ),
                          ),
                          const Spacer(),
                          if (targetDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                targetDate = null;
                                _dateError = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_dateError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _dateError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ],
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
                        AppTheme.darkAccentGreen,
                        AppTheme.backgroundGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.6),
                      width: 1,
                    ),
                    boxShadow: AppTheme.glowShadow(elevated: true),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              const SizedBox(height: 8),
            ],
            ],
          ),
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
    String? Function(String?)? customValidator,
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
        const SizedBox(height: 6),
        // Shadow sits on a wrapper because the field paints its own fill.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.glowShadow(),
          ),
          child: TextFormField(
          initialValue: initialValue,
          keyboardType: keyboard,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Orbitron'),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.backgroundGreen,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen.withOpacity(0.4), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen.withOpacity(0.4), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          validator: customValidator ?? (label.contains('*')
              ? (value) => value?.isEmpty == true ? 'This field is required' : null
              : null),
        ),
        ),
      ],
    );
  }

  Widget _buildCarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Car*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
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
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCarSelectionDialog(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedCar != null && selectedCar!.imagePath != null && selectedCar!.imagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedCar!.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                    color: AppTheme.primaryGreen,
                                    size: 20,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              IconData(0xe800, fontFamily: 'MyFlutterApp'),
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCar != null
                                ? '${selectedCar!.brand} ${selectedCar!.model}'
                                : 'Select Car',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                            const SizedBox(height: 2),
                          Text(
                            selectedCar != null
                                ? 'Year: ${selectedCar!.year}'
                                : 'Tap to choose vehicle',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCarSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.secondaryGreen.withOpacity(0.6),
                width: 1,
              ),
            ),
            boxShadow: AppTheme.glowShadow(elevated: true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Car list
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: userCars.length,
                  itemBuilder: (context, index) {
                    final car = userCars[index];
                    final isSelected = selectedCar?.id == car.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCar = car;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.darkAccentGreen,
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.darkAccentGreen.withOpacity(0.5),
                                    AppTheme.backgroundGreen.withOpacity(0.5),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppTheme.primaryGreen, width: 2)
                              : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 65,
                              height: 45,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: car.imagePath != null && car.imagePath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(car.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                            color: Colors.white,
                                            size: 22,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                      color: Colors.white,
                                      size: 22,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.brand} ${car.model}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Orbitron',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Year: ${car.year.toString()}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontFamily: 'Orbitron',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
                const SizedBox(height: 16),
            ],
          ),
        );
      },
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
            filled: true,
            fillColor: AppTheme.backgroundGreen,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen.withOpacity(0.4), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.secondaryGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Future<void> _updateReminder() async {
    // Validate form fields
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return; // Form validation will show red borders
    }
    
    // Validate car selection
    if (selectedCar == null) {
      AppSnackbar.show(context, 
        const SnackBar(
          content: Text('Please select a car'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate target date (required)
    if (targetDate == null) {
      setState(() {
        _dateError = 'Please select a target date';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _dateError = null; // Clear any date errors
    });

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
        AppSnackbar.show(context, 
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, 
        SnackBar(content: Text('Error updating reminder: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}