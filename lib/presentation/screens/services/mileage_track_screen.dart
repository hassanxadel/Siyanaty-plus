import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';

class MileageTrackScreen extends StatefulWidget {
  const MileageTrackScreen({super.key});

  @override
  State<MileageTrackScreen> createState() => _MileageTrackScreenState();
}

class _MileageTrackScreenState extends State<MileageTrackScreen> {
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _fuelController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  
  List<MileageEntry> _mileageEntries = [];
  double _totalKm = 0;
  double _averageLPer100km = 0;
  double _totalFuelCost = 0;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _fuelController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
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
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tracking & Predictive Alerts',
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
        color: AppTheme.darkAccentGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How to Use Mileage Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
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
            'Enter your current odometer reading and fuel information after each fill-up or trip.',
            Icons.speed,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '2',
            'Track Fuel Economy',
            'Monitor your vehicle\'s fuel efficiency and identify patterns in consumption.',
            Icons.local_gas_station,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '3',
            'Get Alerts',
            'Receive predictive maintenance alerts based on mileage milestones and usage patterns.',
            Icons.notifications_active,
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
            color: AppTheme.primaryGreen,
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
                    color: AppTheme.secondaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.8) : Colors.black54,
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
        color: AppTheme.darkAccentGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mileage Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total KMs',
                  _totalKm.toStringAsFixed(0),
                  Icons.speed,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Avg L/100km',
                  _averageLPer100km.toStringAsFixed(1),
                  Icons.local_gas_station,
                  AppTheme.secondaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Fuel Cost',
                  'EGP${_totalFuelCost.toStringAsFixed(2)}',
                  Icons.attach_money,
                  const Color.fromARGB(255, 159, 105, 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Entries',
                  '${_mileageEntries.length}',
                  Icons.list,
                  AppTheme.infoColor,
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
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.lightBackground.withOpacity(0.7),
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
        color: AppTheme.darkAccentGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Entry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mileageController,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mileage',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.6) : Colors.black45,
                      fontFamily: 'Orbitron',
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.backgroundGreen.withOpacity(0.3) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fuelController,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Liters',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.6) : Colors.black45,
                      fontFamily: 'Orbitron',
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.backgroundGreen.withOpacity(0.3) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Fuel Cost (\$)',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.6) : Colors.black45,
                fontFamily: 'Orbitron',
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.backgroundGreen.withOpacity(0.3) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.primaryGreen.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: const Text(
                'Add Entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkAccentGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mileage History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
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
                      'Entry ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.date,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground.withOpacity(0.7) : Colors.black54,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteEntry(index),
                icon: const Icon(
                  Icons.delete,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEntryDetail('KMs', '${entry.mileage} KMs'),
              ),
              Expanded(
                child: _buildEntryDetail('Fuel', '${entry.fuel} liters'),
              ),
              Expanded(
                child: _buildEntryDetail('Cost', 'EGP${entry.cost}'),
              ),
            ],
          ),
          if (entry.mpg > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'MPG: ${entry.mpg.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryGreen,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.secondaryGreen : Colors.black,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.lightBackground : Colors.black,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  void _addEntry() {
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

    final newEntry = MileageEntry(
      mileage: mileage,
      fuel: fuel,
      cost: cost,
      date: DateTime.now().toString().substring(0, 10),
    );

    setState(() {
      _mileageEntries.insert(0, newEntry);
      _updateStats();
    });

    // Clear inputs
    _mileageController.clear();
    _fuelController.clear();
    _costController.clear();

    HapticFeedback.lightImpact();
    _showMessage('Mileage entry added successfully!');
  }

  void _deleteEntry(int index) {
    setState(() {
      _mileageEntries.removeAt(index);
      _updateStats();
    });

    HapticFeedback.lightImpact();
    _showMessage('Entry deleted');
  }

  void _updateStats() {
    if (_mileageEntries.isEmpty) {
      setState(() {
        _totalKm = 0;
        _averageLPer100km = 0;
        _totalFuelCost = 0;
      });
      return;
    }

          double totalKm = 0;
    double totalFuel = 0;
    double totalCost = 0;
          double totalLPer100km = 0;
          int lPer100kmCount = 0;

    for (int i = 0; i < _mileageEntries.length - 1; i++) {
      final current = _mileageEntries[i];
      final next = _mileageEntries[i + 1];
      
              final kmDriven = (current.mileage - next.mileage).abs();
              totalKm += kmDriven;
      
      if (current.fuel > 0) {
                  final lPer100km = (current.fuel / kmDriven) * 100;
                  totalLPer100km += lPer100km;
                  lPer100kmCount++;
      }
    }

    totalFuel = _mileageEntries.fold(0.0, (sum, entry) => sum + entry.fuel);
    totalCost = _mileageEntries.fold(0.0, (sum, entry) => sum + entry.cost);

    setState(() {
              _totalKm = totalKm;
              _averageLPer100km = lPer100kmCount > 0 ? totalLPer100km / lPer100kmCount : 0;
      _totalFuelCost = totalCost;
    });
  }

  void _loadSampleData() {
    _mileageEntries = [
      MileageEntry(
        mileage: 45000,
        fuel: 10.5,
        cost: 455.00,
        date: '2025-08-15',
      ),
      MileageEntry(
        mileage: 44800,
        fuel: 11.8,
        cost: 620.50,
        date: '2024-08-08',
      ),
      MileageEntry(
        mileage: 44600,
        fuel: 12.2,
        cost: 339.75,
        date: '2025-08-01',
      ),
    ];
    _updateStats();
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
}

class MileageEntry {
  final double mileage;
  final double fuel;
  final double cost;
  final String date;
  late final double mpg;

  MileageEntry({
    required this.mileage,
    required this.fuel,
    required this.cost,
    required this.date,
  }) {
    // Calculate MPG based on previous entry (this would be calculated when adding entries)
    mpg = 0; // Will be calculated in the main logic
  }
}
