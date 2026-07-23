import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../models/backup_maintenance.dart';
import '../../../services/maintenance_service.dart';
import '../../../models/backup_reminder.dart';

/// Screen for displaying and managing vehicle maintenance records
/// Shows maintenance history, costs, and allows filtering by service type
class MaintenanceRecordsScreen extends StatefulWidget {
  const MaintenanceRecordsScreen({super.key});

  @override
  State<MaintenanceRecordsScreen> createState() => _MaintenanceRecordsScreenState();
}

class _MaintenanceRecordsScreenState extends State<MaintenanceRecordsScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  
  List<MaintenanceWithInfo> _allMaintenance = [];
  List<MaintenanceWithInfo> _filteredMaintenance = [];
  
  int _selectedIndex = 0; // 0: All, 1: Mechanics, 2: Electrical, 3: Suspension
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  double _totalCost = 0.0;
  
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaintenance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenance() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final maintenanceList = await _maintenanceService.getAllMaintenanceWithInfo();
      final totalCost = await _maintenanceService.getTotalMaintenanceCost();
      
      if (mounted) {
        setState(() {
          _allMaintenance = maintenanceList;
          _totalCost = totalCost;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.show(context, 
          SnackBar(content: Text('Error loading maintenance: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<MaintenanceWithInfo> filtered = _allMaintenance;
    
    // Apply type filter
    if (_selectedIndex > 0) {
      final type = MaintenanceType.values[_selectedIndex - 1];
      filtered = filtered.where((m) => m.maintenance.type == type).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final query = _searchQuery.toLowerCase();
        return m.maintenance.title.toLowerCase().contains(query) ||
               m.maintenance.description.toLowerCase().contains(query) ||
               m.maintenance.mechanicName?.toLowerCase().contains(query) == true ||
               m.reminderDisplayName.toLowerCase().contains(query) ||
               m.carDisplayName.toLowerCase().contains(query);
      }).toList();
    }
    
    setState(() => _filteredMaintenance = filtered);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _applyFilters();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _applyFilters();
  }

  List<MaintenanceWithInfo> get _mechanicsMaintenance => 
      _allMaintenance.where((m) => m.maintenance.type == MaintenanceType.mechanics).toList();
  
  List<MaintenanceWithInfo> get _electricalMaintenance => 
      _allMaintenance.where((m) => m.maintenance.type == MaintenanceType.electrical).toList();
  
  List<MaintenanceWithInfo> get _suspensionMaintenance => 
      _allMaintenance.where((m) => m.maintenance.type == MaintenanceType.suspension).toList();
  
  List<MaintenanceWithInfo> get _othersMaintenance => 
      _allMaintenance.where((m) => m.maintenance.type == MaintenanceType.others).toList();

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
        backgroundColor: AppTheme.getThemeAwareBackground(context),
        body: Column(
        children: [
          _buildHeaderWithBackground(),
          _buildTotalSpentSection(),
          if (_isSearching) _buildSearchBar(),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _filteredMaintenance.isEmpty 
                    ? _buildEmptyState() 
                    : _buildMaintenanceList(),
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Maintenance Records',
                      style: TextStyle(
                        fontSize: 22,
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
                  'Track your vehicle maintenance history and costs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Add Maintenance button in header
              Center(
                child: Container(
                  width: 200,
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
                    onTap: _showAddMaintenanceSheet,
                    borderRadius: BorderRadius.circular(28),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Maintenance',
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
              ),
              const SizedBox(height: 14),
              // Statistics cards
              Row(
                children: [
                  _buildClickableStatCard('All', _allMaintenance.length, Colors.blue, 0),
                  const SizedBox(width: 2),
                  _buildClickableStatCard('Mech', _mechanicsMaintenance.length, Colors.orange, 1),
                  const SizedBox(width: 2),
                  _buildClickableStatCard('Elec', _electricalMaintenance.length, Colors.red, 2),
                  const SizedBox(width: 2),
                  _buildClickableStatCard('Susp', _suspensionMaintenance.length, Colors.purple, 3),
                  const SizedBox(width: 2),
                  _buildClickableStatCard('Others', _othersMaintenance.length, Colors.green, 4),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSpentSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Maintenance Cost',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EGP ${_totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStatCard(String title, int count, Color color, int index) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = index);
          _applyFilters();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.white70,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
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
        decoration: const InputDecoration(
          hintText: 'Search maintenance records...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildMaintenanceList() {
    return RefreshIndicator(
      onRefresh: _loadMaintenance,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMaintenance.length,
        itemBuilder: (context, index) {
          return _buildMaintenanceCard(_filteredMaintenance[index]);
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(MaintenanceWithInfo maintenanceWithInfo) {
    final maintenance = maintenanceWithInfo.maintenance;
    final typeColor = _getTypeColor(maintenance.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          onTap: () => _showMaintenanceDetails(maintenanceWithInfo),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMaintenanceIcon(maintenance.type),
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maintenance.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Car info
                          Row(
                            children: [
                              Icon(Icons.directions_car, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                maintenanceWithInfo.carDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Type and date row
                Row(
                  children: [
                    Text(
                      maintenance.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy').format(maintenance.maintenanceDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  maintenance.description.isNotEmpty 
                    ? maintenance.description 
                    : 'No description provided',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Cost and action button row
                Row(
                  children: [
                    // Cost is amber so money reads differently from the green
                    // used for status and health elsewhere in the app.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.costHighlight.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.costHighlight.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.costHighlight.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        'EGP ${maintenance.cost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.costHighlight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Matches the home screen's "View All" pill.
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.backgroundGreen,
                            AppTheme.darkAccentGreen,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.secondaryGreen.withOpacity(0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryGreen.withOpacity(0.3),
                            blurRadius: 18,
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showMaintenanceDetails(maintenanceWithInfo),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Orbitron',
                                  color: AppTheme.lightBackground,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 11,
                                color: AppTheme.secondaryGreen,
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFA5D6A7), // Muted light green
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFFC8E6C9), // Light green text
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMaintenanceIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Icons.build_circle;
      case MaintenanceType.electrical:
        return Icons.electrical_services;
      case MaintenanceType.suspension:
        return Icons.car_repair;
      case MaintenanceType.others:
        return Icons.miscellaneous_services;
    }
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty;
    final String message = isSearching 
        ? 'No maintenance records found'
        : _selectedIndex > 0 
            ? 'No ${MaintenanceType.values[_selectedIndex - 1].displayName.toLowerCase()} maintenance records'
            : 'No maintenance records yet';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.build_circle_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Start tracking your vehicle maintenance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Colors.orange;
      case MaintenanceType.electrical:
        return Colors.red;
      case MaintenanceType.suspension:
        return Colors.purple;
      case MaintenanceType.others:
        return Colors.green;
    }
  }

  void _showAddMaintenanceSheet() {
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
        builder: (context, scrollController) => AddMaintenanceForm(
          onMaintenanceAdded: () {
            _loadMaintenance();
          },
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showMaintenanceDetails(MaintenanceWithInfo maintenanceWithInfo) {
    showDialog(
      context: context,
      builder: (context) => MaintenanceDetailsDialog(
        maintenanceWithInfo: maintenanceWithInfo,
        onEdit: () {
          Navigator.pop(context);
          _showEditMaintenanceSheet(maintenanceWithInfo.maintenance);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteMaintenanceRecord(maintenanceWithInfo.maintenance);
        },
      ),
    );
  }

  void _showEditMaintenanceSheet(BackupMaintenance maintenance) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditMaintenanceForm(
        maintenance: maintenance,
        onMaintenanceUpdated: () {},
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      await _loadMaintenance();
      AppSnackbar.show(context, 
        const SnackBar(content: Text('Maintenance updated successfully')),
      );
    }
  }

  Future<void> _deleteMaintenanceRecord(BackupMaintenance maintenance) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Maintenance Record',
      message:
          'Are you sure you want to delete "${maintenance.title}"? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed != true) return;

    final result = await _maintenanceService.deleteMaintenance(maintenance.id!);
    if (!mounted) return;

    AppSnackbar.show(context,
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
    if (result.success) {
      _loadMaintenance();
    }
  }
}

// Add Maintenance Form
class AddMaintenanceForm extends StatefulWidget {
  final VoidCallback onMaintenanceAdded;
  final ScrollController? scrollController;

  const AddMaintenanceForm({
    super.key,
    required this.onMaintenanceAdded,
    this.scrollController,
  });

  @override
  State<AddMaintenanceForm> createState() => _AddMaintenanceFormState();
}

class _AddMaintenanceFormState extends State<AddMaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _invoiceController = TextEditingController();
  
  final MaintenanceService _maintenanceService = MaintenanceService();
  
  DateTime _selectedDate = DateTime.now();
  MaintenanceType _selectedType = MaintenanceType.mechanics;
  BackupReminder? _selectedReminder;
  List<BackupReminder> _availableReminders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _mechanicController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final reminders = await _maintenanceService.getAvailableReminders();
    setState(() {
      _availableReminders = reminders;
      // Start with "Without a Reminder" (null) as default
      _selectedReminder = null;
    });
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
            const Text('Add Maintenance Record', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text('* Required fields', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 16),
            // Reminder selection
            _buildReminderDropdown(),
            const SizedBox(height: 16),
            
            // Title and Type row
            Row(
              children: [
                Expanded(child: _field(label: 'Title*', controller: _titleController)),
                const SizedBox(width: 10),
                Expanded(child: _buildTypeDropdown()),
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
            
            // Cost and Date row
            Row(
              children: [
                Expanded(child: _field(
                  label: 'Cost (EGP)*', 
                  controller: _costController,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  customValidator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    final cost = double.tryParse(value.trim());
                    if (cost == null) {
                      return 'Please enter a valid number';
                    }
                    if (cost < 0) {
                      return 'Cost cannot be negative';
                    }
                    return null;
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildDatePicker()),
              ],
            ),
            const SizedBox(height: 16),
            
            // Optional fields row
            Row(
              children: [
                Expanded(child: _field(
                  label: 'Mechanic/Service Center (optional)', 
                  controller: _mechanicController,
                )),
                const SizedBox(width: 10),
                Expanded(child: _field(
                  label: 'Invoice Number (optional)', 
                  controller: _invoiceController,
                )),
              ],
            ),
            const SizedBox(height: 20),
            
            // Save button with gradient
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
                  onPressed: _isLoading ? null : _saveMaintenance,
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.transparent,
                     shadowColor: Colors.transparent,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    : const Text('Save Maintenance', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _saveMaintenance() async {
    // Validate form fields
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return; // Form validation will show red borders
    }
    
    // Validate reminder selection
    if (_selectedReminder == null) {
      setState(() {
        // Show error for reminder selection
      });
      AppSnackbar.show(context, 
        const SnackBar(
          content: Text('Please select a reminder'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedReminder!.id == null) {
      AppSnackbar.show(context, 
        const SnackBar(
          content: Text('Invalid reminder selected. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Date is always set (initialized to DateTime.now()), but validate anyway
    // This check is kept for safety but should never trigger

    setState(() {
      _isLoading = true;
      _dateError = null; // Clear any date errors
    });

    try {
      final result = await _maintenanceService.addMaintenance(
        reminderId: _selectedReminder!.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: double.parse(_costController.text.trim()),
        maintenanceDate: _selectedDate,
        type: _selectedType,
        mechanicName: _mechanicController.text.trim().isEmpty ? null : _mechanicController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, 
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          widget.onMaintenanceAdded();
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 
          SnackBar(
            content: Text('Error: $e'),
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
            color: AppTheme.lightBackground,
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
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: AppTheme.lightBackground,
          ),
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

  Widget _buildReminderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Reminder*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
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
              onTap: () => _showReminderSelectionDialog(),
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
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppTheme.lightBackground,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedReminder != null
                                ? _selectedReminder!.title
                                : 'Without a Reminder',
                            style: const TextStyle(
                              color: AppTheme.lightBackground,
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedReminder != null
                                ? 'Tap to change'
                                : 'Standalone maintenance',
                            style: TextStyle(
                              color: AppTheme.lightBackground.withOpacity(0.7),
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
                        color: AppTheme.lightBackground,
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

  void _showReminderSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Related Reminder',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightBackground,
                      ),
                    ),
                  ],
                ),
              ),
              
              // "Without a Reminder" option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReminder = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _selectedReminder == null
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
                      border: _selectedReminder == null
                          ? Border.all(color: AppTheme.primaryGreen, width: 2)
                          : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.block,
                            color: Colors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Without a Reminder',
                                style: TextStyle(
                                  color: AppTheme.lightBackground,
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Standalone maintenance record',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedReminder == null)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Reminder list
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: _availableReminders.map((reminder) {
                      final isSelected = _selectedReminder?.id == reminder.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReminder = reminder;
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
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: AppTheme.lightBackground,
                                  size: 22,
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
                                        color: AppTheme.lightBackground,
                                        fontFamily: 'Orbitron',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reminder.description.isNotEmpty
                                          ? reminder.description
                                          : 'No description',
                                      style: TextStyle(
                                        color: AppTheme.lightBackground.withOpacity(0.7),
                                        fontFamily: 'Orbitron',
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.lightBackground,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightBackground,
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
              onTap: () => _showTypeSelectionDialog(),
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
                        _getTypeIcon(_selectedType),
                        color: AppTheme.lightBackground,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedType.displayName,
                            style: const TextStyle(
                              color: AppTheme.lightBackground,
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
                        color: AppTheme.lightBackground,
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

  IconData _getTypeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Icons.build;
      case MaintenanceType.electrical:
        return Icons.electrical_services;
      case MaintenanceType.suspension:
        return Icons.settings;
      case MaintenanceType.others:
        return Icons.more_horiz;
    }
  }

  String _getTypeDescription(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return 'Engine, transmission, etc.';
      case MaintenanceType.electrical:
        return 'Battery, wiring, etc.';
      case MaintenanceType.suspension:
        return 'Shocks, struts, etc.';
      case MaintenanceType.others:
        return 'Other maintenance';
    }
  }

  void _showTypeSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
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
                      Icons.category,
                      color: AppTheme.lightBackground,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Type',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightBackground,
                      ),
                    ),
                  ],
                ),
              ),
              // Type list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: MaintenanceType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
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
                              child: Icon(
                                _getTypeIcon(type),
                                color: AppTheme.lightBackground,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.displayName,
                                    style: const TextStyle(
                                      color: AppTheme.lightBackground,
                                      fontFamily: 'Orbitron',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getTypeDescription(type),
                                    style: TextStyle(
                                      color: AppTheme.lightBackground.withOpacity(0.7),
                                      fontFamily: 'Orbitron',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.lightBackground,
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

  String? _dateError;

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maintenance Date*',
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
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    color: AppTheme.lightBackground,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: _dateError != null ? Colors.red : AppTheme.primaryGreen,
                  size: 20,
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
    );
  }
}

// Placeholder classes for other forms and dialogs
class EditMaintenanceForm extends StatefulWidget {
  final BackupMaintenance maintenance;
  final VoidCallback onMaintenanceUpdated;

  const EditMaintenanceForm({
    super.key,
    required this.maintenance,
    required this.onMaintenanceUpdated,
  });

  @override
  State<EditMaintenanceForm> createState() => _EditMaintenanceFormState();
}

class _EditMaintenanceFormState extends State<EditMaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _invoiceController = TextEditingController();

  final MaintenanceService _maintenanceService = MaintenanceService();

  late DateTime _selectedDate;
  late MaintenanceType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _titleController.text = m.title;
    _descriptionController.text = m.description;
    _costController.text = m.cost.toStringAsFixed(0);
    _mechanicController.text = m.mechanicName ?? '';
    _invoiceController.text = m.invoiceNumber ?? '';
    _selectedDate = m.maintenanceDate;
    _selectedType = m.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _mechanicController.dispose();
    _invoiceController.dispose();
    super.dispose();
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
                const SizedBox(height: 16),
              const Text('Edit Maintenance Record', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 16),

              // Title and Type row
              Row(
                children: [
                  Expanded(child: _field(label: 'Title*', controller: _titleController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTypeDropdown()),
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

              // Cost and Date row
              Row(
                children: [
                  Expanded(child: _field(
                    label: 'Cost (EGP)*',
                    controller: _costController,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                    customValidator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      final cost = double.tryParse(value.trim());
                      if (cost == null) {
                        return 'Please enter a valid number';
                      }
                      if (cost < 0) {
                        return 'Cost cannot be negative';
                      }
                      return null;
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDatePicker()),
                ],
              ),
              const SizedBox(height: 16),

              // Optional fields row
              Row(
                children: [
                  Expanded(child: _field(
                    label: 'Mechanic/Service Center (optional)',
                    controller: _mechanicController,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _field(
                    label: 'Invoice Number (optional)',
                    controller: _invoiceController,
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // Save button with gradient
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
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        : const Text('Update Maintenance', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // Validate form fields
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return; // Form validation will show red borders
    }

    // Validate cost is a valid number
    final costText = _costController.text.trim();
    final cost = double.tryParse(costText);
    if (cost == null) {
      // This should be caught by form validation, but double-check
      return;
    }
    if (cost < 0) {
      // This should be caught by form validation, but double-check
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _maintenanceService.updateMaintenance(
        maintenanceId: widget.maintenance.id!.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: cost, // Use validated cost, not tryParse with fallback
        maintenanceDate: _selectedDate,
        type: _selectedType,
        mechanicName: _mechanicController.text.trim().isEmpty ? null : _mechanicController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, true);
      } else {
        AppSnackbar.show(context, 
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, 
        SnackBar(content: Text('Error updating maintenance: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            color: AppTheme.lightBackground,
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
          style: const TextStyle(
            fontFamily: 'Orbitron',
            color: AppTheme.lightBackground,
          ),
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

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<MaintenanceType>(
          value: _selectedType,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: MaintenanceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName, style: const TextStyle(fontFamily: 'Orbitron')),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedType = value);
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maintenance Date*',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(fontFamily: 'Orbitron'),
                ),
                const Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MaintenanceDetailsDialog extends StatelessWidget {
  final MaintenanceWithInfo maintenanceWithInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MaintenanceDetailsDialog({
    super.key,
    required this.maintenanceWithInfo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final maintenance = maintenanceWithInfo.maintenance;
    final typeColor = _getMaintenanceTypeColor(maintenance.type);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 800),
        // Matches AppDialogPanel so the details card reads as the same
        // component family as every other pop-up.
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
                  child: Icon(
                    _getMaintenanceTypeIcon(maintenance.type),
                    color: AppTheme.secondaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maintenance.title,
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
                        '${maintenance.type.displayName} · ${DateFormat('MMM dd, yyyy').format(maintenance.maintenanceDate)}',
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
                  _buildModernDetailRow('Type', maintenance.type.displayName, Icons.category, typeColor),
                  // Amber, matching the cost chip on the maintenance list card.
                  _buildModernDetailRow('Cost', 'EGP ${maintenance.cost.toStringAsFixed(2)}', Icons.attach_money, AppTheme.costHighlight),
                  _buildModernDetailRow('Date', DateFormat('MMM dd, yyyy').format(maintenance.maintenanceDate), Icons.calendar_today, Colors.blue),
                  _buildModernDetailRow('Car', maintenanceWithInfo.carDisplayName, Icons.directions_car, Colors.orange),
                  _buildModernDetailRow('Reminder', maintenanceWithInfo.reminderDisplayName, Icons.notification_important, Colors.purple),
                  if (maintenance.description.isNotEmpty)
                    _buildModernDetailRow('Description', maintenance.description, Icons.description, Colors.grey),
                  if (maintenance.mechanicName != null)
                    _buildModernDetailRow('Mechanic', maintenance.mechanicName!, Icons.person, Colors.cyan),
                  if (maintenance.invoiceNumber != null)
                    _buildModernDetailRow('Invoice', maintenance.invoiceNumber!, Icons.receipt, Colors.teal),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Modern action buttons
            Column(
              children: [
                // Top row - Edit and Delete
                Row(
                  children: [
                    Expanded(
                      child: _buildModernButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: AppTheme.infoBlue,
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: AppDialog.destructive,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 12),
                
               
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon, Color color) {
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
  Widget _buildModernButton({
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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

  Color _getMaintenanceTypeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Colors.orange;
      case MaintenanceType.electrical:
        return Colors.red;
      case MaintenanceType.suspension:
        return Colors.purple;
      case MaintenanceType.others:
        return Colors.green;
    }
  }

  IconData _getMaintenanceTypeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.mechanics:
        return Icons.build_circle;
      case MaintenanceType.electrical:
        return Icons.electrical_services;
      case MaintenanceType.suspension:
        return Icons.car_repair;
      case MaintenanceType.others:
        return Icons.miscellaneous_services;
    }
  }
}
