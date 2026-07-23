import 'package:flutter/material.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../services/obd_service.dart';
import '../../../services/car_service.dart';
import '../../../models/obd_scan.dart';
import '../../../models/backup_car.dart';
import '../../../shared/constants/app_theme.dart';
import '../../widgets/app_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class OBDScreen extends StatefulWidget {
  const OBDScreen({super.key});

  @override
  State<OBDScreen> createState() => _OBDScreenState();
}

class _OBDScreenState extends State<OBDScreen> {
  final OBDService _obdService = OBDService();
  final CarService _carService = CarService();
  
  List<BluetoothDevice> _availableDevices = [];
  List<OBDScan> _scanHistory = [];
  BackupCar? _selectedCar;
  List<BackupCar> _cars = [];
  
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isPerformingScan = false;
  bool _isLoadingHistory = false;
  
  OBDScan? _currentScanData;

  @override
  void initState() {
    super.initState();
    _loadCars();
    _obdService.connectionState.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
        if (connected) {
          _showSuccessSnackBar('Connected to OBD device');
        }
      }
    });
  }

  Future<void> _loadCars() async {
    final cars = await _carService.getAllCars();
    setState(() {
      _cars = cars;
      if (_cars.isNotEmpty && _selectedCar == null) {
        _selectedCar = _cars.first;
        _loadScanHistory();
      }
    });
  }

  Future<void> _loadScanHistory() async {
    if (_selectedCar == null) return;
    
    setState(() => _isLoadingHistory = true);
    try {
      final scans = await _obdService.getScansByCar(_selectedCar!.id!);
      setState(() {
        _scanHistory = scans;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      _showErrorSnackBar('Failed to load scan history');
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        _showErrorSnackBar('Bluetooth permissions are required for OBD scanning');
        return;
      }
    } catch (e) {
      _showErrorSnackBar('Failed to request permissions: $e');
    }
  }

  Future<void> _scanForDevices() async {
    await _requestBluetoothPermissions();
    
    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });

    try {
      final devices = await _obdService.scanForDevices(timeout: const Duration(seconds: 10));
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });

      if (devices.isEmpty) {
        _showInfoSnackBar('No OBD devices found. Make sure your device is powered on and in range.');
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showErrorSnackBar('Scan failed: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _showInfoSnackBar('Connecting to ${device.name}...');
      final success = await _obdService.connectToDevice(device);
      
      if (success) {
        setState(() => _isConnected = true);
      } else {
        _showErrorSnackBar('Failed to connect to device');
      }
    } catch (e) {
      _showErrorSnackBar('Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    await _obdService.disconnect();
    setState(() {
      _isConnected = false;
      _currentScanData = null;
    });
  }

  Future<void> _performFullScan() async {
    if (_selectedCar == null) {
      _showErrorSnackBar('Please select a car first');
      return;
    }

    if (!_isConnected) {
      _showErrorSnackBar('Please connect to an OBD device first');
      return;
    }

    setState(() => _isPerformingScan = true);

    try {
      final scan = await _obdService.performFullScan(_selectedCar!.id!);
      
      if (scan != null) {
        setState(() {
          _currentScanData = scan;
          _isPerformingScan = false;
        });
        _showSuccessSnackBar('Scan completed successfully');
        _loadScanHistory(); // Refresh history
      } else {
        setState(() => _isPerformingScan = false);
        _showErrorSnackBar('Scan failed');
      }
    } catch (e) {
      setState(() => _isPerformingScan = false);
      _showErrorSnackBar('Scan error: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    AppSnackbar.show(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: Column(
        children: [
          _buildHeaderWithBackground(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCarSelector(),
                  const SizedBox(height: 16),
                  _buildConnectionCard(),
                  const SizedBox(height: 16),
                  if (!_isConnected) ...[
                    _buildInstructionsCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_isConnected) ...[
                    _buildScanButton(),
                    const SizedBox(height: 16),
                    if (_currentScanData != null) _buildCurrentScanData(),
                    const SizedBox(height: 16),
                  ],
                  _buildScanHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'OBD-II Diagnostics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connect and scan your vehicle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isConnected)
                    IconButton(
                      icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                      onPressed: _disconnect,
                      tooltip: 'Disconnect',
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Select Vehicle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showCarSelectionDialog(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCar != null
                          ? '${_selectedCar!.brand} ${_selectedCar!.model} (${_selectedCar!.year})'
                          : 'Select a vehicle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCarSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getThemeAwareCardBackground(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Vehicle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _cars.length,
              itemBuilder: (context, index) {
                final car = _cars[index];
                final isSelected = _selectedCar?.id == car.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCar = car;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.getThemeAwareTextColor(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${car.brand} ${car.model}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getThemeAwareTextColor(context),
                                ),
                              ),
                              Text(
                                '${car.year} • ${car.licensePlate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getThemeAwareTextColor(context)
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryGreen,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getThemeAwareCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected ? AppTheme.primaryGreen : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: _isConnected ? AppTheme.primaryGreen : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected ? 'Connected' : 'Not Connected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isConnected ? AppTheme.primaryGreen : AppTheme.getThemeAwareTextColor(context),
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    if (_isConnected && _obdService.connectedDevice != null)
                      Text(
                        _obdService.connectedDevice!.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
          if (!_isConnected) ...[
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
              ),
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanForDevices,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isScanning ? 'Scanning...' : 'Scan for Devices',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ),
            if (_availableDevices.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Available Devices:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._availableDevices.map((device) => ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(device.name.isEmpty ? 'Unknown Device' : device.name),
                    subtitle: Text(device.id.toString()),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _connectToDevice(device),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton() {
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isPerformingScan ? null : _performFullScan,
        icon: _isPerformingScan
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.radar),
        label: Text(
          _isPerformingScan ? 'Scanning...' : 'Perform Full Scan',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScanData() {
    if (_currentScanData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Scan Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDataRow('Engine RPM', _currentScanData!.rpm?.toStringAsFixed(0), 'rpm'),
          _buildDataRow('Speed', _currentScanData!.speed?.toStringAsFixed(0), 'km/h'),
          _buildDataRow('Coolant Temp', _currentScanData!.coolantTemp?.toStringAsFixed(1), '°C'),
          _buildDataRow('Fuel Level', _currentScanData!.fuelLevel?.toStringAsFixed(1), '%'),
          _buildDataRow('Throttle', _currentScanData!.throttlePosition?.toStringAsFixed(1), '%'),
          _buildDataRow('Engine Load', _currentScanData!.engineLoad?.toStringAsFixed(1), '%'),
          if (_currentScanData!.errorCodes.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Error Codes:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ..._currentScanData!.errorCodes.map((code) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $code',
                    style: const TextStyle(color: Colors.red),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String? value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value != null ? '$value $unit' : 'N/A',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = AppTheme.getThemeAwareCardBackground(context);
    final Color primaryText = AppTheme.getThemeAwareTextColor(context);
    final Color secondaryText = AppTheme.getThemeAwareTextColor(context).withOpacity(0.7);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 48,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'How to Connect OBD-II Adapter',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildInstructionStep('1', 'Locate your vehicle\'s OBD-II port (usually under dashboard)'),
          _buildInstructionStep('2', 'Plug in your Bluetooth OBD-II adapter'),
          _buildInstructionStep('3', 'Turn on your vehicle\'s ignition'),
          _buildInstructionStep('4', 'Tap "Scan & Connect" above'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : AppTheme.darkAccentGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.secondaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compatible with ELM327 Bluetooth adapters. Available at auto parts stores.',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: secondaryText,
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

  Widget _buildInstructionStep(String number, String instruction) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color stepText = isDark ? AppTheme.lightBackground : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                color: stepText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
            const SizedBox(height: 16),
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_scanHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No scan history available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scanHistory.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final scan = _scanHistory[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scan.errorCodes.isNotEmpty
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    child: Icon(
                      scan.errorCodes.isNotEmpty ? Icons.warning : Icons.check_circle,
                      color: scan.errorCodes.isNotEmpty ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    '${scan.scanDate.day}/${scan.scanDate.month}/${scan.scanDate.year} ${scan.scanDate.hour}:${scan.scanDate.minute.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Text(
                    scan.errorCodes.isNotEmpty
                        ? '${scan.errorCodes.length} error(s)'
                        : 'No errors',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await AppDialog.show(
                        context,
                        title: 'Delete Scan',
                        message:
                            'Are you sure you want to delete this scan? This action cannot be undone.',
                        icon: Icons.delete_outline,
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );

                      if (confirm == true && scan.id != null) {
                        await _obdService.deleteScan(scan.id!);
                        _loadScanHistory();
                        _showSuccessSnackBar('Scan deleted');
                      }
                    },
                  ),
                  onTap: () {
                    setState(() => _currentScanData = scan);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _obdService.dispose();
    super.dispose();
  }
}

