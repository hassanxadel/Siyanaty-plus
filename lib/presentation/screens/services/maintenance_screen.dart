import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../domain/entities/maintenance_record.dart';

/// Screen for displaying and managing vehicle maintenance records
/// Shows maintenance history, costs, and allows filtering by service type
class MaintenanceRecordsScreen extends StatefulWidget {
  const MaintenanceRecordsScreen({super.key});

  @override
  State<MaintenanceRecordsScreen> createState() => _MaintenanceRecordsScreenState();
}

/// State class for maintenance records screen
/// Manages tab navigation, filtering, and mock data for demonstration
class _MaintenanceRecordsScreenState extends State<MaintenanceRecordsScreen> with TickerProviderStateMixin {
  /// Controller for managing tab navigation between different record views
  late TabController _tabController;
  
  /// Mock maintenance records data for demonstration purposes
  /// In production, this would come from a database or API
  final List<MaintenanceRecord> _records = [
    MaintenanceRecord(
      id: '1',
      carId: 'car1',
      userId: 'user1',
      title: 'Oil Change',
      description: 'Full synthetic oil change with new filter',
      type: 'Oil Change',
      cost: 45.99,
      mileage: 45230,
      date: DateTime(2024, 12, 15),
      serviceCenterName: 'Quick Lube Plus',
      parts: ['Oil Filter', 'Synthetic Oil'],
      receiptImageUrl: 'receipt1.jpg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MaintenanceRecord(
      id: '2',
      carId: 'car1',
      userId: 'user1',
      title: 'Tire Rotation',
      description: 'Rotated all four tires and balanced',
      type: 'Tire Rotation',
      cost: 25.00,
      mileage: 44850,
      date: DateTime(2024, 11, 20),
      serviceCenterName: 'Tire Center',
      parts: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MaintenanceRecord(
      id: '3',
      carId: 'car1',
      userId: 'user1',
      title: 'Brake Inspection',
      description: 'Annual brake system inspection',
      type: 'Brake Service',
      cost: 0.00,
      mileage: 44200,
      date: DateTime(2024, 10, 10),
      serviceCenterName: 'Self Inspection',
      parts: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  


  /// Initialize tab controller for navigation between record views
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  /// Clean up resources when widget is disposed
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Build the main screen layout with app bar, tabs, and content
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                _buildSummaryCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecordsList(_records),
                      _buildRecordsList(_records.where((r) => r.type == 'Oil Change' || r.type == 'Coolant Flush').toList()),
                      _buildRecordsList(_records.where((r) => r.type == 'Brake Service').toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _showAddRecordSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record', style: TextStyle(fontFamily: 'Orbitron')),
                ),
              ),
            ),
          ),
          BottomNavBar(currentIndex: 1, onTap: (i) {}),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 220,
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Maintenance Records',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Track and manage all your service history',
                  style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Orbitron'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'All (4)'),
                  Tab(text: 'Fluids (1)'),
                  Tab(text: 'Brakes (1)'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the summary statistics card showing financial and service overview
  Widget _buildSummaryCard() {
    /// Calculate total amount spent on all maintenance services
    final totalSpent = _records.fold(0.0, (sum, record) => sum + record.cost);
    /// Count of total maintenance services performed
    final servicesCount = _records.length;
    /// Date of the most recent maintenance service
    final lastService = _records.isNotEmpty ? _records.first.date : null;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context: context),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'EGP ${totalSpent.toStringAsFixed(0)}',
                  'Total Spent',
                  AppTheme.primaryGreen,
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  servicesCount.toString(),
                  'Services',
                  AppTheme.primaryGreen,
                  Icons.list,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  lastService != null ? '${lastService.day}/${lastService.month}' : 'N/A',
                  'Last Service',
                  AppTheme.primaryGreen,
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Track all services and get insights on your maintenance costs',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds individual statistic items for the summary card
  /// Each item shows an icon, value, and label
  Widget _buildStatItem(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the list view of maintenance records
  /// Shows empty state when no records are available
  Widget _buildRecordsList(List<MaintenanceRecord> records) {
    /// Display empty state when no maintenance records exist
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build,
              size: 80,
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordCard(record);
      },
    );
  }

  /// Builds individual maintenance record cards
  /// Shows service details, cost, KMs, and service center information
  Widget _buildRecordCard(MaintenanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(context: context),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.build,
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
                          record.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.getThemeAwareTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(record.date),
                          style: TextStyle(
                            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        record.formattedCost,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.getThemeAwareTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.formattedMileage,
                        style: TextStyle(
                          color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (record.serviceCenterName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.serviceCenterName!,
                      style: TextStyle(
                        color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (record.receiptImageUrl != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt,
                            size: 12,
                            color: AppTheme.primaryGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Receipt',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }



  void _showAddRecordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
        String title = '';
        String type = '';
        String cost = '';
        String mileage = '';
        String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String notes = '';
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: media.viewInsets.bottom + 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(3))),
                ),
                const SizedBox(height: 12),
                const Text('Add Maintenance Record', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                _field(label: 'Title', onChanged: (v) => title = v),
                const SizedBox(height: 12),
                _field(label: 'Type', onChanged: (v) => type = v),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(label: 'Cost', keyboard: TextInputType.number, onChanged: (v) => cost = v)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(label: 'Mileage (km)', keyboard: TextInputType.number, onChanged: (v) => mileage = v)),
                ]),
                const SizedBox(height: 12),
                _field(label: 'Date (YYYY-MM-DD)', onChanged: (v) => dateStr = v),
                const SizedBox(height: 12),
                _field(label: 'Notes (optional)', onChanged: (v) => notes = v),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (title.isEmpty || type.isEmpty || cost.isEmpty) { Navigator.pop(context); return; }
                      final rec = MaintenanceRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        carId: 'car1',
                        userId: 'user1',
                        title: title,
                        description: notes,
                        type: type,
                        cost: double.tryParse(cost) ?? 0,
                        mileage: double.tryParse(mileage) ?? 0.0,
                        date: DateTime.tryParse(dateStr) ?? DateTime.now(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        serviceCenterName: null,
                        parts: const [],
                        receiptImageUrl: null,
                      );
                      setState(() { _records.insert(0, rec); });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Save Record', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows detailed view of a maintenance record
  /// Displays all record information in a modal dialog
  void _showRecordDetails(MaintenanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record.title,
          style: TextStyle(
            color: AppTheme.getThemeAwareTextColor(context),
            fontFamily: 'Orbitron',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(record.date)}',
              style: TextStyle(color: AppTheme.getThemeAwareTextColor(context)),
            ),
            Text(
              'Cost: ${record.formattedCost}',
              style: TextStyle(color: AppTheme.getThemeAwareTextColor(context)),
            ),
            Text(
              'Mileage: ${record.formattedMileage}',
              style: TextStyle(color: AppTheme.getThemeAwareTextColor(context)),
            ),
            if (record.serviceCenterName != null)
              Text(
                'Service Center: ${record.serviceCenterName}',
                style: TextStyle(color: AppTheme.getThemeAwareTextColor(context)),
              ),
            if (record.description.isNotEmpty)
              Text(
                'Description: ${record.description}',
                style: TextStyle(color: AppTheme.getThemeAwareTextColor(context)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Edit functionality to be implemented
            },
            child: const Text(
              'Edit',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for creating form fields
  Widget _field({required String label, TextInputType keyboard = TextInputType.text, required ValueChanged<String> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontFamily: 'Orbitron', 
            fontSize: 12, 
            fontWeight: FontWeight.w600,
            color: AppTheme.getThemeAwareTextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboard,
          onChanged: onChanged,
          style: TextStyle(
            color: AppTheme.getThemeAwareTextColor(context),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: label,
            hintStyle: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.getThemeAwareCardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.getThemeAwareBorderColor(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.getThemeAwareBorderColor(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
} 