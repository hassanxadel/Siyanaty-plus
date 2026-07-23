import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../models/mileage_entry.dart';
import '../../../services/mileage_service.dart';
import '../../../services/car_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

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
  TripFrequency _selectedTripFrequency = TripFrequency.oneTime;

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
    return ScreenWithNavBar(
      child: Scaffold(
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
    ),
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
                          'Mileage Tracking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
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
            'Select Your Car',
            'Choose the car you\'re tracking from your saved vehicles.',
            Icons.directions_car,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Choose Trip Frequency',
            'Set if this is a one-time, daily, weekly, or monthly trip for automatic mileage updates.',
            Icons.repeat,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Record Trip Details',
            'Enter the trip distance, fuel used, and cost. Your car\'s mileage updates automatically!',
            Icons.speed,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap the info icon (ⓘ) above the form to learn more about automated mileage tracking!',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
          ),
        ],
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
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
          color: color.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 16,
          ),
        ],
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                onPressed: _showAutomatedMileageInfo,
                tooltip: 'Learn about automated mileage tracking',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _entryNameController,
            hintText: 'Entry Name (e.g., Weekly Fill-up)',
          ),
          const SizedBox(height: 12),
          _buildCarDropdown(),
          const SizedBox(height: 12),
          _buildTripFrequencySelector(),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.25),
            blurRadius: 14,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppTheme.lightBackground,
          fontFamily: 'Orbitron',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.lightBackground.withOpacity(0.45),
            fontFamily: 'Orbitron',
          ),
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.secondaryGreen.withOpacity(0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.secondaryGreen.withOpacity(0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.secondaryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarDropdown() {
    return Container(
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
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showCarSelectionDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedCarId != null && _cars.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _cars
                                      .firstWhere((car) =>
                                          car.id.toString() == _selectedCarId)
                                      .imagePath !=
                                  null
                              ? Image.file(
                                  File(_cars
                                      .firstWhere((car) =>
                                          car.id.toString() == _selectedCarId)
                                      .imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 24,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        )
                      : const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCarId != null && _cars.isNotEmpty
                            ? '${_cars.firstWhere((car) => car.id.toString() == _selectedCarId).brand} ${_cars.firstWhere((car) => car.id.toString() == _selectedCarId).model}'
                            : 'Select Car',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCarId != null && _cars.isNotEmpty
                            ? 'Year: ${_cars.firstWhere((car) => car.id.toString() == _selectedCarId).year}'
                            : 'Tap to choose vehicle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCarSelectionDialog() {
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 22,
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
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    final isSelected = _selectedCarId == car.id.toString();
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCarId = car.id.toString();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: car.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(car.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.directions_car,
                                            color: Colors.white,
                                            size: isSelected ? 28 : 24,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: isSelected ? 28 : 24,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.brand} ${car.model}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: isSelected ? 18 : 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Year: ${car.year}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (car.licensePlate != null &&
                                      car.licensePlate!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'License: ${car.licensePlate}',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripFrequencySelector() {
    return Container(
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
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showTripFrequencyDialog(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTripFrequencyIcon(_selectedTripFrequency),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTripFrequency.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                              const SizedBox(height: 4),
                      Text(
                        _selectedTripFrequency.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTripFrequencyIcon(TripFrequency frequency) {
    switch (frequency) {
      case TripFrequency.oneTime:
        return Icons.looks_one;
      case TripFrequency.daily:
        return Icons.today;
      case TripFrequency.weekly:
        return Icons.date_range;
      case TripFrequency.monthly:
        return Icons.calendar_month;
    }
  }

  List<Color> _getTripFrequencyColors(TripFrequency frequency) {
    switch (frequency) {
      case TripFrequency.oneTime:
        return [Colors.blue.shade600, Colors.blue.shade800];
      case TripFrequency.daily:
        return [Colors.green.shade600, Colors.green.shade800];
      case TripFrequency.weekly:
        return [Colors.orange.shade600, Colors.orange.shade800];
      case TripFrequency.monthly:
        return [Colors.purple.shade600, Colors.purple.shade800];
    }
  }

  Widget _buildEditCarSelector(String? selectedCarId, Function(String?) onCarSelected) {
    return Container(
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
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.pop(context); // Close edit sheet
            _showCarSelectionDialogForEdit(selectedCarId, onCarSelected);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: selectedCarId != null && _cars.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _cars
                                      .firstWhere((car) =>
                                          car.id.toString() == selectedCarId)
                                      .imagePath !=
                                  null
                              ? Image.file(
                                  File(_cars
                                      .firstWhere((car) =>
                                          car.id.toString() == selectedCarId)
                                      .imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 24,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        )
                      : const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCarId != null && _cars.isNotEmpty
                            ? '${_cars.firstWhere((car) => car.id.toString() == selectedCarId).brand} ${_cars.firstWhere((car) => car.id.toString() == selectedCarId).model}'
                            : 'Select Car',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCarId != null && _cars.isNotEmpty
                            ? 'Year: ${_cars.firstWhere((car) => car.id.toString() == selectedCarId).year}'
                            : 'Tap to choose vehicle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCarSelectionDialogForEdit(String? currentCarId, Function(String?) onCarSelected) {
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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    final car = _cars[index];
                    final isSelected = currentCarId == car.id.toString();
                    
                    return GestureDetector(
                      onTap: () {
                        onCarSelected(car.id.toString());
                        Navigator.pop(context);
                        // Re-open edit dialog
                        Future.delayed(const Duration(milliseconds: 100), () {
                          // The edit dialog will be re-opened by the caller
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: car.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(car.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.directions_car,
                                            color: Colors.white,
                                            size: isSelected ? 28 : 24,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: isSelected ? 28 : 24,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${car.brand} ${car.model}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: isSelected ? 18 : 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Year: ${car.year}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditTripFrequencySelector(TripFrequency selectedFrequency, Function(TripFrequency) onFrequencySelected) {
    return Container(
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
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.pop(context); // Close edit sheet
            _showTripFrequencyDialogForEdit(selectedFrequency, onFrequencySelected);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTripFrequencyIcon(selectedFrequency),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFrequency.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedFrequency.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTripFrequencyDialogForEdit(TripFrequency currentFrequency, Function(TripFrequency) onFrequencySelected) {
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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.repeat, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Trip Frequency',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ...TripFrequency.values.map((frequency) {
                final isSelected = currentFrequency == frequency;
                return GestureDetector(
                  onTap: () {
                    onFrequencySelected(frequency);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : AppTheme.primaryGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTripFrequencyIcon(frequency),
                            color: Colors.white,
                            size: isSelected ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                frequency.displayName,
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: isSelected ? 18 : 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                frequency.description,
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showTripFrequencyDialog() {
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
                      Icons.repeat,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Trip Frequency',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Frequency list
              ...TripFrequency.values.map((frequency) {
                final isSelected = _selectedTripFrequency == frequency;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTripFrequency = frequency;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : AppTheme.primaryGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTripFrequencyIcon(frequency),
                            color: Colors.white,
                            size: isSelected ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                frequency.displayName,
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: isSelected ? 18 : 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                frequency.description,
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAutomatedMileageInfo() {
    AppDialog.custom<void>(
      context,
      title: 'Automated Mileage Tracking',
      icon: Icons.auto_awesome,
      closeLabel: 'Got It!',
      content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How It Works:',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: AppTheme.lightBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.looks_one,
                'One-Time Trip',
                'The mileage is added to your car immediately, just once.',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.today,
                'Daily Trip',
                'For regular commutes. The app automatically adds this mileage to your car every day.',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.date_range,
                'Weekly Trip',
                'For trips you make once a week. Mileage is added weekly to your car.',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.calendar_month,
                'Monthly Trip',
                'For monthly trips. The app adds this mileage to your car once per month.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.secondaryGreen.withOpacity(0.45),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.costHighlight,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No need to manually update your car\'s mileage anymore! The app does it automatically based on your trip entries.',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: AppTheme.lightBackground.withOpacity(0.85),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
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
          BoxShadow(
            color: AppTheme.secondaryGreen.withOpacity(0.3),
            blurRadius: 18,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getTripFrequencyColors(entry.tripFrequency),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getTripFrequencyColors(entry.tripFrequency)[0].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTripFrequencyIcon(entry.tripFrequency),
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.tripFrequency.displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

    if (_selectedCarId == null) {
      _showMessage('Please select a car');
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
        carId: _selectedCarId,
        tripFrequency: _selectedTripFrequency,
    );

      // Use the new method that automatically updates car mileage
      await _mileageService.addEntryWithAutoMileageUpdate(newEntry);

    // Clear inputs
    _mileageController.clear();
    _fuelController.clear();
    _costController.clear();
      _notesController.clear();
      _entryNameController.clear();
      setState(() {
        _selectedTripFrequency = TripFrequency.oneTime; // Reset to default
      });

      // Reload data
      await _loadData();

    HapticFeedback.lightImpact();
    
    // Show appropriate message based on trip frequency
    String message = 'Mileage entry added successfully!';
    if (_selectedTripFrequency != TripFrequency.oneTime) {
      message += '\nCar mileage will be automatically updated based on trip frequency.';
    } else {
      message += '\nCar mileage updated.';
    }
    _showMessage(message);
    } catch (e) {
      _showErrorDialog('Failed to add entry: $e');
    } finally {
    setState(() {
        _isAddingEntry = false;
      });
    }
  }


  void _editEntry(MileageEntry entry) {
    // Set initial values
    _mileageController.text = entry.mileage.toString();
    _fuelController.text = entry.fuel.toString();
    _costController.text = entry.cost.toString();
    _notesController.text = entry.notes ?? '';
    _entryNameController.text = entry.entryName ?? '';
    
    // Set selected car and trip frequency
    String? editSelectedCarId = entry.carId;
    TripFrequency editSelectedTripFrequency = entry.tripFrequency;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
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
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Edit Mileage Entry',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form fields
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _entryNameController,
                              hintText: 'Entry Name (e.g., Weekly Fill-up)',
                            ),
                            const SizedBox(height: 12) ,
                            // Car selector
                            _buildEditCarSelector(editSelectedCarId, (newCarId) {
                              setModalState(() {
                                editSelectedCarId = newCarId;
                              });
                            }),
                            const SizedBox(height: 12) ,
                            // Trip frequency selector
                            _buildEditTripFrequencySelector(editSelectedTripFrequency, (newFrequency) {
                              setModalState(() {
                                editSelectedTripFrequency = newFrequency;
                              });
                            }),
                            const SizedBox(height: 12) ,
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
                            const SizedBox(height: 12) ,
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
                            const SizedBox(height: 20) ,
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.grey.shade700, Colors.grey.shade900],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _clearInputs();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Orbitron',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
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
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _updateEntry(entry, editSelectedCarId, editSelectedTripFrequency);
                                      },
                                      icon: const Icon(Icons.save, color: Colors.white),
                                      label: const Text(
                                        'Update',
                                        style: TextStyle(
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
                                const SizedBox(height: 20) ,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateEntry(MileageEntry entry, String? carId, TripFrequency tripFrequency) async {
    final mileage = double.tryParse(_mileageController.text);
    final fuel = double.tryParse(_fuelController.text);
    final cost = double.tryParse(_costController.text);

    if (mileage == null || fuel == null || cost == null) {
      _showMessage('Please enter valid values');
      return;
    }

    if (carId == null) {
      _showMessage('Please select a car');
      return;
    }

    try {
      final updatedEntry = entry.copyWith(
        mileage: mileage,
        fuel: fuel,
        cost: cost,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        entryName: _entryNameController.text.trim().isEmpty ? null : _entryNameController.text.trim(),
        carId: carId,
        tripFrequency: tripFrequency,
      );

      await _mileageService.updateEntry(updatedEntry);
      await _loadData();
      _clearInputs();
      _showMessage('Entry updated successfully!');
    } catch (e) {
      _showErrorDialog('Failed to update entry: $e');
    }
  }

  Future<void> _confirmDeleteEntry(MileageEntry entry) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Delete Entry',
      message:
          'Are you sure you want to delete this entry? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      _deleteEntry(entry);
    }
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
      if (!mounted) return;

      AppDialog.custom<void>(
        context,
        title: 'Export Data (CSV)',
        icon: Icons.table_chart_outlined,
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glowFieldDecoration(),
          child: Text(
            csvData,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.5,
              color: AppTheme.lightBackground.withOpacity(0.9),
            ),
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Export failed: $e');
    }
  }

  void _showMessage(String message) {
    AppSnackbar.show(context, 
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
    AppDialog.message(
      context,
      title: 'Error',
      message: message,
      icon: Icons.error_outline,
      isError: true,
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
                  child: const Icon(
                    Icons.speed,
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
                        entry.entryName != null && entry.entryName!.isNotEmpty
                            ? entry.entryName!
                            : 'Mileage Entry',
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
                        'Mileage Entry · ${_formatDate(entry.date)}',
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
                  _buildModernDetailRow('Mileage', '${entry.mileage.toStringAsFixed(0)} km', Icons.speed, AppTheme.secondaryGreen),
                  _buildModernDetailRow('Fuel', '${entry.fuel.toStringAsFixed(1)} L', Icons.local_gas_station, Colors.orange),
                  // Amber for money, matching the maintenance cost styling.
                  _buildModernDetailRow('Cost', 'EGP ${entry.cost.toStringAsFixed(2)}', Icons.attach_money, AppTheme.costHighlight),
                  _buildModernDetailRow('Date', _formatDate(entry.date), Icons.calendar_today, AppTheme.infoBlue),
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
                      child: _buildModernButton(
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
                      child: _buildModernButton(
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}