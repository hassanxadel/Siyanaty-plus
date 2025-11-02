import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../models/mileage_entry.dart';
import '../../../services/mileage_service.dart';
import '../../../services/car_service.dart';
import '../../widgets/bottom_nav_bar.dart';

class MileageTrackScreen extends StatefulWidget {
  const MileageTrackScreen({super.key});

  @override
  State<MileageTrackScreen> createState() => _MileageTrackScreenState();
}

class _MileageTrackScreenState extends State<MileageTrackScreen> {
  final MileageService _mileageService = MileageService();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _fuelController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _entryNameController = TextEditingController();
  
  List<MileageEntry> _mileageEntries = [];
  Map<String, double> _statistics = {};
  Map<String, double> _efficiencyStats = {};
  bool _isLoading = true;
  bool _isAddingEntry = false;
  String? _userId;
  String? _selectedCarId;
  List<dynamic> _cars = [];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadData();
    _loadCars();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  Future<void> _loadCars() async {
    try {
      final carService = CarService();
      final cars = await carService.getAllCars();
      if (mounted) {
                        setState(() {
                          _cars = cars;
                          if (_cars.isNotEmpty) {
                            _selectedCarId = _cars.first.id.toString();
                          }
                        });
      }
    } catch (e) {
      print('Error loading cars: $e');
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _fuelController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _entryNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _mileageService.getAllEntries(userId: _userId);
      final stats = await _mileageService.getStatistics(userId: _userId);
      final effStats = await _mileageService.calculateEfficiencyStats(userId: _userId);
      
      setState(() {
        _mileageEntries = entries;
        _statistics = stats;
        _efficiencyStats = effStats;
      });
    } catch (e) {
      _showErrorDialog('Failed to load data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionsCard(),
                  const SizedBox(height: 24),
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildAddEntryCard(),
                  const SizedBox(height: 24),
                  if (_mileageEntries.isNotEmpty) _buildEntriesList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (i) {}),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                    'Mileage Track',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'sync_to_cloud',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_upload, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Sync to Cloud',
                              style: TextStyle(fontFamily: 'Orbitron'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sync_from_cloud',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_download, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Sync from Cloud',
                              style: TextStyle(fontFamily: 'Orbitron'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_csv',
                        child: Row(
                          children: [
                            Icon(Icons.file_download, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Export CSV',
                              style: TextStyle(fontFamily: 'Orbitron'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Track fuel consumption and efficiency',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How to Use Mileage Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '1',
            'Record Mileage',
            'Enter your current odometer reading and fuel information after each fill-up.',
            Icons.speed,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Track Efficiency',
            'Monitor your vehicle\'s fuel efficiency and identify consumption patterns.',
            Icons.local_gas_station,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Sync to Cloud',
            'Use the menu to sync your data to Firebase for backup and access across devices.',
            Icons.cloud_upload,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
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
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mileage Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Distance',
                  '${(_efficiencyStats['totalDistance'] ?? 0).toStringAsFixed(0)} km',
                  Icons.speed,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Avg L/100km',
                  (_efficiencyStats['averageEfficiency'] ?? 0) > 0 
                      ? (_efficiencyStats['averageEfficiency'] ?? 0).toStringAsFixed(1)
                      : '0.0',
                  Icons.local_gas_station,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Cost',
                  'EGP ${(_statistics['totalCost'] ?? 0).toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Entries',
                  '${(_statistics['entryCount'] ?? 0).toInt()}',
                  Icons.list,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontFamily: 'Orbitron',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddEntryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Entry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _entryNameController,
            hintText: 'Entry Name (e.g., Weekly Fill-up)',
          ),
          const SizedBox(height: 12),
          _buildCarDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _mileageController,
                  hintText: 'Mileage (km)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _fuelController,
                  hintText: 'Fuel (L)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _costController,
                  hintText: 'Cost (EGP)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _notesController,
                  hintText: 'Notes (optional)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundGreen,
                    AppTheme.primaryGreen,
                    AppTheme.darkAccentGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isAddingEntry ? null : _addEntry,
                icon: _isAddingEntry
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white),
                label: Text(
                  _isAddingEntry ? 'Adding...' : 'Add Entry',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
            decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white54,
                fontFamily: 'Orbitron',
              ),
              filled: true,
        fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
            color: Colors.white,
                  width: 2,
                ),
              ),
            ),
    );
  }

  Widget _buildCarDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCarId,
          hint: const Text(
            'Select Car',
                style: TextStyle(
              color: Colors.white54,
                  fontFamily: 'Orbitron',
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          dropdownColor: AppTheme.darkAccentGreen,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontSize: 14,
          ),
                        items: _cars.map((car) {
                          return DropdownMenuItem<String>(
                            value: car.id.toString(),
                            child: Text(
                              '${car.brand} ${car.model} (${car.year})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          );
                        }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCarId = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mileage History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._mileageEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final entryData = entry.value;
            return _buildEntryItem(index, entryData);
          }),
        ],
      ),
    );
  }

  Widget _buildEntryItem(int index, MileageEntry entry) {
    // Calculate efficiency if possible
    double? efficiency;
    if (index < _mileageEntries.length - 1) {
      final nextEntry = _mileageEntries[index + 1];
      final distance = entry.mileage - nextEntry.mileage;
      if (distance > 0) {
        efficiency = entry.calculateEfficiency(distance);
      }
    }

    return InkWell(
      onTap: () => _showMileageEntryDetails(entry),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.entryName != null && entry.entryName!.isNotEmpty
                            ? 'Entry ${index + 1}: ${entry.entryName}'
                            : 'Entry ${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.date.toLocal().toString().split(' ')[0],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEntryDetail('Mileage', '${entry.mileage.toStringAsFixed(0)} km'),
              ),
              Expanded(
                child: _buildEntryDetail('Fuel', '${entry.fuel.toStringAsFixed(1)} L'),
              ),
              Expanded(
                child: _buildEntryDetail('Cost', 'EGP ${entry.cost.toStringAsFixed(2)}'),
              ),
            ],
          ),
          if (efficiency != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Efficiency: ${efficiency.toStringAsFixed(1)} L/100km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${entry.notes}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildEntryDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  Future<void> _addEntry() async {
    final mileage = double.tryParse(_mileageController.text);
    final fuel = double.tryParse(_fuelController.text);
    final cost = double.tryParse(_costController.text);

    if (mileage == null || mileage <= 0) {
      _showMessage('Please enter a valid mileage');
      return;
    }

    if (fuel == null || fuel <= 0) {
      _showMessage('Please enter a valid fuel amount');
      return;
    }

    if (cost == null || cost < 0) {
      _showMessage('Please enter a valid cost');
      return;
    }

    setState(() {
      _isAddingEntry = true;
    });

    try {
    final newEntry = MileageEntry(
      mileage: mileage,
      fuel: fuel,
      cost: cost,
        date: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        entryName: _entryNameController.text.trim().isEmpty ? null : _entryNameController.text.trim(),
        userId: _userId,
    );

      await _mileageService.addEntry(newEntry);

    // Clear inputs
    _mileageController.clear();
    _fuelController.clear();
    _costController.clear();
      _notesController.clear();
      _entryNameController.clear();

      // Reload data
      await _loadData();

    HapticFeedback.lightImpact();
    _showMessage('Mileage entry added successfully!');
    } catch (e) {
      _showErrorDialog('Failed to add entry: $e');
    } finally {
    setState(() {
        _isAddingEntry = false;
      });
    }
  }


  void _editEntry(MileageEntry entry) {
    _mileageController.text = entry.mileage.toString();
    _fuelController.text = entry.fuel.toString();
    _costController.text = entry.cost.toString();
    _notesController.text = entry.notes ?? '';
    _entryNameController.text = entry.entryName ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundGreen,
        title: const Text(
          'Edit Entry',
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _entryNameController,
              hintText: 'Entry Name (optional)',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _mileageController,
              hintText: 'Mileage (km)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _fuelController,
              hintText: 'Fuel (L)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _costController,
              hintText: 'Cost (EGP)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              hintText: 'Notes (optional)',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearInputs();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateEntry(entry);
              },
              child: const Text(
                'Update',
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEntry(MileageEntry entry) async {
    final mileage = double.tryParse(_mileageController.text);
    final fuel = double.tryParse(_fuelController.text);
    final cost = double.tryParse(_costController.text);

    if (mileage == null || fuel == null || cost == null) {
      _showMessage('Please enter valid values');
      return;
    }

    try {
      final updatedEntry = entry.copyWith(
        mileage: mileage,
        fuel: fuel,
        cost: cost,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        entryName: _entryNameController.text.trim().isEmpty ? null : _entryNameController.text.trim(),
      );

      await _mileageService.updateEntry(updatedEntry);
      await _loadData();
      _clearInputs();
      _showMessage('Entry updated successfully!');
    } catch (e) {
      _showErrorDialog('Failed to update entry: $e');
    }
  }

  void _confirmDeleteEntry(MileageEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundGreen,
        title: const Text(
          'Delete Entry',
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteEntry(entry);
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(MileageEntry entry) async {
    if (entry.id == null) return;

    try {
      await _mileageService.deleteEntry(entry.id!);
      await _loadData();
      HapticFeedback.lightImpact();
      _showMessage('Entry deleted successfully');
    } catch (e) {
      _showErrorDialog('Failed to delete entry: $e');
    }
  }

  void _clearInputs() {
    _mileageController.clear();
    _fuelController.clear();
    _costController.clear();
    _notesController.clear();
    _entryNameController.clear();
  }

  void _showMileageEntryDetails(MileageEntry entry) {
    showDialog(
      context: context,
      builder: (context) => MileageEntryDetailsDialog(
        entry: entry,
        onEdit: () => _editEntry(entry),
        onDelete: () {
          Navigator.pop(context);
          _confirmDeleteEntry(entry);
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sync_to_cloud':
        _syncToCloud();
        break;
      case 'sync_from_cloud':
        _syncFromCloud();
        break;
      case 'export_csv':
        _exportToCsv();
        break;
    }
  }

  Future<void> _syncToCloud() async {
    if (_userId == null) {
      _showMessage('Please sign in to sync to cloud');
      return;
    }

    try {
      _showMessage('Syncing to cloud...');
      final success = await _mileageService.syncToFirebase(userId: _userId);
      if (success) {
        _showMessage('Successfully synced to cloud');
      } else {
        _showMessage('Failed to sync to cloud');
      }
    } catch (e) {
      _showErrorDialog('Sync failed: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    if (_userId == null) {
      _showMessage('Please sign in to sync from cloud');
      return;
    }

    try {
      _showMessage('Syncing from cloud...');
      final success = await _mileageService.syncFromFirebase(userId: _userId);
      if (success) {
        await _loadData();
        _showMessage('Successfully synced from cloud');
      } else {
        _showMessage('Failed to sync from cloud');
      }
    } catch (e) {
      _showErrorDialog('Sync failed: $e');
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final csvData = await _mileageService.exportToCsv(userId: _userId);
      if (csvData.isEmpty) {
        _showMessage('No data to export');
        return;
      }
      
      // For now, just show the CSV data in a dialog
      // In a real app, you'd save this to a file or share it
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.backgroundGreen,
          title: const Text(
            'Export Data (CSV)',
            style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              csvData,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Export failed: $e');
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundGreen,
        title: const Text(
          'Error',
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Mileage Entry Details Dialog
class MileageEntryDetailsDialog extends StatelessWidget {
  final MileageEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MileageEntryDetailsDialog({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
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
              AppTheme.darkAccentGreen,
              AppTheme.backgroundGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
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
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.speed,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.entryName != null && entry.entryName!.isNotEmpty
                                  ? entry.entryName!
                                  : 'Mileage Entry',
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
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Mileage Entry - ${_formatDate(entry.date)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
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
                  _buildModernDetailRow('Mileage', '${entry.mileage.toStringAsFixed(0)} km', Icons.speed, AppTheme.primaryGreen),
                  _buildModernDetailRow('Fuel', '${entry.fuel.toStringAsFixed(1)} L', Icons.local_gas_station, Colors.orange),
                  _buildModernDetailRow('Cost', 'EGP ${entry.cost.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
                  _buildModernDetailRow('Date', _formatDate(entry.date), Icons.calendar_today, Colors.blue),
                  _buildModernDetailRow('Created', _formatDate(entry.createdAt), Icons.schedule, Colors.purple),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    _buildModernDetailRow('Notes', entry.notes!, Icons.description, Colors.grey),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Modern action buttons
            Column(
              children: [
                // Top row - Edit
                Row(
                  children: [
                    Expanded(
                      child: _buildModernButton(
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
                      child: _buildModernButton(
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
                      child: _buildModernButton(
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

  Widget _buildModernButton({
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}