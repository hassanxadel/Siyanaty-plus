import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';  // Temporarily disabled
// Use stub
import '../../../shared/constants/app_theme.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../services/bluetooth/bluetooth_service.dart';
import '../../../services/obd/obd_service.dart';
import '../../../services/obd/obd_models.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

class OBDDashboardScreen extends StatefulWidget {
  const OBDDashboardScreen({super.key});

  @override
  State<OBDDashboardScreen> createState() => _OBDDashboardScreenState();
}

class _OBDDashboardScreenState extends State<OBDDashboardScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final ObdService _obdService = ObdService();
  
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isInitializing = false;
  ObdConnectionState _connectionState = ObdConnectionState.disconnected;
  ObdData _currentData = ObdData();
  List<BluetoothDevice> _availableDevices = [];
  BluetoothDevice? _connectedDevice;
  StreamSubscription<ObdData>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _listenToObdData();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _obdService.stopPolling();
    super.dispose();
  }

  /// Check Bluetooth state on init
  Future<void> _checkBluetoothState() async {
    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled && mounted) {
      _showBluetoothDisabledDialog();
    }
  }

  /// Listen to OBD data stream
  void _listenToObdData() {
    _dataSubscription = _obdService.obdDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentData = data;
        });
      }
    });
  }

  /// Show dialog to enable Bluetooth
  Future<void> _showBluetoothDisabledDialog() async {
    final enable = await AppDialog.show(
      context,
      title: 'Bluetooth Disabled',
      message:
          'Please enable Bluetooth to connect to your OBD-II adapter and read live vehicle data.',
      icon: Icons.bluetooth_disabled,
      confirmLabel: 'Enable',
    );

    if (enable != true) return;

    await _bluetoothService.requestEnableBluetooth();
  }

  /// Scan for OBD devices
  Future<void> _scanForDevices() async {
    if (_isScanning) return;

    // Check if Bluetooth is enabled
    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      _showBluetoothDisabledDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      _availableDevices = [];
    });

    try {
      // First, get bonded (paired) devices
      final bondedDevices = await _bluetoothService.getBondedDevices();
      final obdDevices = _bluetoothService.filterObdDevices(bondedDevices);
      
      if (obdDevices.isNotEmpty && mounted) {
        setState(() {
          _availableDevices = obdDevices;
        });
        _showDeviceSelectionDialog();
      } else {
        // No paired OBD devices, start discovery
        final discoveryStream = _bluetoothService.startDiscovery();
        final devices = <BluetoothDevice>[];
        
        await for (final result in discoveryStream.timeout(const Duration(seconds: 10))) {
          if (result.device.name != null) {
            devices.add(result.device);
          }
        }
        
        if (mounted) {
          final obdDevicesDiscovered = _bluetoothService.filterObdDevices(devices);
          setState(() {
            _availableDevices = obdDevicesDiscovered;
          });
          
          if (obdDevicesDiscovered.isNotEmpty) {
            _showDeviceSelectionDialog();
          } else {
            _showNoDevicesFoundDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.instance.showErrorNotification(
          context,
          message: 'Failed to scan for devices: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Show device selection dialog
  void _showDeviceSelectionDialog() {
    AppDialog.custom<void>(
      context,
      title: 'Select OBD-II Device',
      message: 'Choose the adapter to connect to',
      icon: Icons.bluetooth_searching,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final device in _availableDevices) ...[
            _buildDeviceTile(device),
            const SizedBox(height: 10),
          ],
        ],
      ),
      actionsBuilder: (dialogContext) => [
        AppDialogAction(
          label: 'Cancel',
          onTap: () => Navigator.pop(dialogContext),
        ),
      ],
    );
  }

  /// A single selectable adapter inside the device-selection pop-up.
  Widget _buildDeviceTile(BluetoothDevice device) {
    return Container(
      decoration: AppTheme.glowFieldDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _connectToDevice(device);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth,
                  color: AppTheme.secondaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name ?? 'Unknown Device',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.address,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 10,
                          color: AppTheme.lightBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppTheme.secondaryGreen.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show no devices found dialog
  Future<void> _showNoDevicesFoundDialog() async {
    final retry = await AppDialog.show(
      context,
      title: 'No Devices Found',
      message: 'No OBD-II devices found. Please ensure:\n'
          '• Your OBD adapter is plugged in\n'
          '• Your vehicle ignition is on\n'
          '• The adapter is paired with your phone',
      icon: Icons.bluetooth_disabled,
      cancelLabel: 'OK',
      confirmLabel: 'Retry',
    );

    if (retry == true && mounted) {
      _scanForDevices();
    }
  }

  /// Connect to selected device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionState = ObdConnectionState.connecting;
    });

    try {
      // Connect via Bluetooth
      final result = await _bluetoothService.connectToDevice(device);
      
      if (!result.success) {
        throw Exception(result.message);
      }

      // Initialize OBD
      setState(() {
        _isInitializing = true;
        _connectionState = ObdConnectionState.initializing;
      });

      final initialized = await _obdService.initialize();
      
      if (!initialized) {
        throw Exception('Failed to initialize OBD connection');
      }

      // Start polling data
      _obdService.startPolling();

      if (mounted) {
        setState(() {
          _connectedDevice = device;
          _connectionState = ObdConnectionState.connected;
        });

        NotificationService.instance.showSuccessNotification(
          context,
          message: 'Connected to ${device.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionState = ObdConnectionState.error;
        });

        NotificationService.instance.showErrorNotification(
          context,
          message: 'Connection failed: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isInitializing = false;
        });
      }
    }
  }

  /// Disconnect from device
  Future<void> _disconnect() async {
    await _obdService.disconnect();
    
    if (mounted) {
      setState(() {
        _connectionState = ObdConnectionState.disconnected;
        _connectedDevice = null;
        _currentData = ObdData();
      });

      NotificationService.instance.showInfoNotification(
        context,
        message: 'Disconnected from OBD device',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return ScreenWithNavBar(
      currentIndex: 2,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Padding(
                  padding: ResponsiveUtils.responsivePadding(context, horizontal: 20, vertical: 0),
                  child: Column(
                    children: [
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      _buildConnectionCard(context),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      if (_connectionState != ObdConnectionState.connected)
                        _buildConnectionInstructions(context),
                      if (_connectionState == ObdConnectionState.connected) ...[
                        _buildRealTimeDataSection(context),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      ],
                      SizedBox(height: isSmallScreen ? 60 : 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.responsivePadding(context, horizontal: 0, vertical: 16),
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
      child: Padding(
        padding: ResponsiveUtils.responsivePadding(context, horizontal: 20, vertical: 0),
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OBD-II Diagnostics',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _connectionState == ObdConnectionState.connected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth,
                  ),
                  onPressed: _connectionState == ObdConnectionState.connected
                      ? _disconnect
                      : _scanForDevices,
                  color: _connectionState == ObdConnectionState.connected
                      ? AppTheme.lightBackground
                      : Colors.white70,
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Monitor your vehicle\'s health in real-time',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    final isConnected = _connectionState == ObdConnectionState.connected;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 48,
            color: isConnected ? AppTheme.successColor : AppTheme.darkAccentGreen,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            isConnected
                ? 'OBD-II Adapter Connected'
                : _connectionState == ObdConnectionState.connecting
                    ? 'Connecting...'
                    : _connectionState == ObdConnectionState.initializing
                        ? 'Initializing...'
                        : 'No OBD-II Connection',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: AppTheme.getThemeAwareTextColor(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            isConnected
                ? 'Device: ${_connectedDevice?.name ?? "Unknown"}'
                : 'Connect your OBD-II adapter to get started',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.glowShadow(
                accent: isConnected ? AppTheme.errorColor : AppTheme.secondaryGreen,
                elevated: true,
              ),
            ),
            child: ElevatedButton.icon(
            onPressed: (_isScanning || _isConnecting || _isInitializing)
                ? null
                : isConnected
                    ? _disconnect
                    : _scanForDevices,
            icon: (_isScanning || _isConnecting || _isInitializing)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isConnected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_searching),
            label: Text(
              (_isScanning || _isConnecting || _isInitializing)
                  ? (_isInitializing ? 'Initializing...' : 'Scanning...')
                  : isConnected
                      ? 'Disconnect'
                      : 'Scan & Connect',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isConnected ? AppTheme.errorColor : AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: (isConnected
                          ? AppTheme.errorColor
                          : AppTheme.secondaryGreen)
                      .withOpacity(0.7),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 20),
                vertical: ResponsiveUtils.spacing(context, 12),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Real-Time Engine Data',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              crossAxisSpacing: ResponsiveUtils.spacing(context, 12),
              mainAxisSpacing: ResponsiveUtils.spacing(context, 12),
              children: [
                _buildDataCard(
                  context,
                  'RPM',
                  _currentData.rpm?.toString() ?? 'N/A',
                  'rpm',
                  Icons.rotate_right,
                  AppTheme.primaryGreen,
                ),
                _buildDataCard(
                  context,
                  'Speed',
                  _currentData.speed != null
                      ? '${_currentData.speed}'
                      : 'N/A',
                  'km/h',
                  Icons.speed,
                  AppTheme.secondaryGreen,
                ),
                _buildDataCard(
                  context,
                  'Engine Temp',
                  _currentData.coolantTempF != null
                      ? '${_currentData.coolantTempF!.toStringAsFixed(0)}°F'
                      : 'N/A',
                  _currentData.coolantTempStatus,
                  Icons.thermostat,
                  _currentData.isCoolantTempNormal
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
                _buildDataCard(
                  context,
                  'Fuel Level',
                  _currentData.fuelLevel != null
                      ? '${_currentData.fuelLevel!.toStringAsFixed(0)}%'
                      : 'N/A',
                  _currentData.fuelLevel != null &&
                          _currentData.fuelLevel! < 20
                      ? 'Low'
                      : 'Good',
                  Icons.local_gas_station,
                  _currentData.fuelLevel != null && _currentData.fuelLevel! < 20
                      ? AppTheme.warningColor
                      : AppTheme.primaryGreen,
                ),
                _buildDataCard(
                  context,
                  'Battery',
                  _currentData.batteryVoltage != null
                      ? '${_currentData.batteryVoltage!.toStringAsFixed(1)}V'
                      : 'N/A',
                  _currentData.batteryStatus,
                  Icons.battery_full,
                  _currentData.isBatteryHealthy
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                ),
                _buildDataCard(
                  context,
                  'Throttle',
                  _currentData.throttlePosition != null
                      ? '${_currentData.throttlePosition!.toStringAsFixed(0)}%'
                      : 'N/A',
                  'Position',
                  Icons.tune,
                  AppTheme.secondaryGreen,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: ResponsiveUtils.fontSize(context, 9),
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 2)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: ResponsiveUtils.fontSize(context, 8),
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionInstructions(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = AppTheme.darkGray.withOpacity(0.3);
    final Color primaryText =
        isDark ? AppTheme.lightBackground : Colors.black87;
    final Color secondaryText =
        isDark ? AppTheme.lightBackground : Colors.black54;

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryGreen.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline,
            size: 40,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            'How to Connect OBD-II Adapter',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          _buildInstructionStep(
              '1', 'Locate your vehicle\'s OBD-II port (usually under dashboard)'),
          _buildInstructionStep('2', 'Plug in your Bluetooth OBD-II adapter'),
          _buildInstructionStep('3', 'Turn on your vehicle\'s ignition'),
          _buildInstructionStep('4', 'Tap "Scan & Connect" above'),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black12
                  : AppTheme.darkAccentGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppTheme.secondaryGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compatible with ELM327 Bluetooth adapters. Available at auto parts stores.',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: secondaryText,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 6),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: stepText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
