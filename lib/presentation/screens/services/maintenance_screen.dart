import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/bottom_nav_bar.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
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
    return Scaffold(
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Maintenance screen index
        onTap: (int i) {},
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
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
                  _buildClickableStatCard('Mechanics', _mechanicsMaintenance.length, Colors.orange, 1),
                  const SizedBox(width: 2),
                  _buildClickableStatCard('Electrical', _electricalMaintenance.length, Colors.red, 2),
                  const SizedBox(width: 2),
                  _buildClickableStatCard('Suspension', _suspensionMaintenance.length, Colors.purple, 3),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMaintenanceDetails(maintenanceWithInfo),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      maintenance.type.displayName,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(maintenance.maintenanceDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                maintenance.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Car info
              Row(
                children: [
                  Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    maintenanceWithInfo.carDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Reminder info
              Row(
                children: [
                  Icon(Icons.notification_important, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Related to: ${maintenanceWithInfo.reminderDisplayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (maintenance.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  maintenance.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'EGP ${maintenance.cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (maintenance.mechanicName != null) ...[
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      maintenance.mechanicName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMaintenanceForm(
        onMaintenanceAdded: () {
          _loadMaintenance();
        },
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

  void _showEditMaintenanceSheet(BackupMaintenance maintenance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditMaintenanceForm(
        maintenance: maintenance,
        onMaintenanceUpdated: () {
          _loadMaintenance();
        },
      ),
    );
  }

  void _deleteMaintenanceRecord(BackupMaintenance maintenance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Maintenance Record'),
        content: Text('Are you sure you want to delete "${maintenance.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _maintenanceService.deleteMaintenance(maintenance.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
                if (result.success) {
                  _loadMaintenance();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Add Maintenance Form
class AddMaintenanceForm extends StatefulWidget {
  final VoidCallback onMaintenanceAdded;

  const AddMaintenanceForm({
    super.key,
    required this.onMaintenanceAdded,
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
      if (reminders.isNotEmpty) {
        _selectedReminder = reminders.first;
      }
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
            const Text('Add Maintenance Record', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
              label: 'Description*', 
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
                  keyboard: TextInputType.number,
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
                      AppTheme.primaryGreen,
                      AppTheme.darkAccentGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMaintenance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0c3c24),
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
                    : const Text('Save Maintenance Record', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
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
    if (_formKey.currentState == null || !_formKey.currentState!.validate() || _selectedReminder == null) return;
    
    if (_selectedReminder!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid reminder selected. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
          controller: controller,
          keyboardType: keyboard,
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
          validator: label.contains('*') 
            ? (value) => value?.isEmpty == true ? 'This field is required' : null
            : null,
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
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<BackupReminder>(
          value: _selectedReminder,
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
          items: _availableReminders.map((reminder) {
            return DropdownMenuItem(
              value: reminder,
              child: Text(
                reminder.title,
                style: const TextStyle(fontFamily: 'Orbitron'),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedReminder = value);
          },
          validator: (value) => value == null ? 'Please select a reminder' : null,
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
          items: MaintenanceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.displayName,
                style: const TextStyle(fontFamily: 'Orbitron'),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
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
            if (date != null) {
              setState(() => _selectedDate = date);
            }
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
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Placeholder classes for other forms and dialogs
class EditMaintenanceForm extends StatelessWidget {
  final BackupMaintenance maintenance;
  final VoidCallback onMaintenanceUpdated;

  const EditMaintenanceForm({
    super.key,
    required this.maintenance,
    required this.onMaintenanceUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.white,
      child: const Center(
        child: Text('Edit Maintenance Form - To be implemented'),
      ),
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
    
    return AlertDialog(
      title: Text(maintenance.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${maintenance.type.displayName}'),
          Text('Cost: EGP ${maintenance.cost.toStringAsFixed(2)}'),
          Text('Date: ${DateFormat('MMM dd, yyyy').format(maintenance.maintenanceDate)}'),
          Text('Car: ${maintenanceWithInfo.carDisplayName}'),
          Text('Reminder: ${maintenanceWithInfo.reminderDisplayName}'),
          if (maintenance.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Description: ${maintenance.description}'),
          ],
          if (maintenance.mechanicName != null) ...[
            const SizedBox(height: 4),
            Text('Mechanic: ${maintenance.mechanicName}'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
