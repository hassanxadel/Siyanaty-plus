import 'dart:async';
import '../bluetooth/bluetooth_service.dart';
import 'obd_parser.dart';
import 'obd_models.dart';
import '../../shared/utils/app_logger.dart';

/// Service for communicating with OBD-II devices
/// Handles command queuing, data polling, and response parsing
class ObdService {
  static final ObdService _instance = ObdService._internal();
  factory ObdService() => _instance;
  ObdService._internal();

  final BluetoothService _bluetoothService = BluetoothService();
  
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isInitialized = false;

  /// Stream controller for real-time OBD data
  final _obdDataController = StreamController<ObdData>.broadcast();
  Stream<ObdData> get obdDataStream => _obdDataController.stream;

  /// Current OBD data
  ObdData _currentData = ObdData();

  /// Get Bluetooth service instance
  BluetoothService get bluetoothService => _bluetoothService;

  /// Initialize OBD connection
  /// Sends initialization commands to prepare the ELM327 adapter
  Future<bool> initialize() async {
    if (!_bluetoothService.isConnected) {
      AppLogger.error('Cannot initialize OBD: Bluetooth not connected');
      return false;
    }

    try {
      AppLogger.info('Initializing OBD connection...');

      // Reset the ELM327 adapter
      await _sendCommandWithDelay('ATZ', delay: 1500);
      
      // Turn off echo
      await _sendCommandWithDelay('ATE0', delay: 100);
      
      // Set line feeds off
      await _sendCommandWithDelay('ATL0', delay: 100);
      
      // Set spaces on (easier to parse)
      await _sendCommandWithDelay('ATS1', delay: 100);
      
      // Set headers off
      await _sendCommandWithDelay('ATH0', delay: 100);
      
      // Set adaptive timing mode 1 (auto)
      await _sendCommandWithDelay('ATAT1', delay: 100);
      
      // Set protocol to auto
      await _sendCommandWithDelay('ATSP0', delay: 500);

      AppLogger.info('OBD initialization complete');
      _isInitialized = true;
      return true;
    } catch (e) {
      AppLogger.error('Error initializing OBD', error: e);
      _isInitialized = false;
      return false;
    }
  }

  /// Start polling for real-time data
  /// Continuously requests data from the vehicle at specified interval
  void startPolling({Duration interval = const Duration(milliseconds: 800)}) {
    if (_isPolling) {
      AppLogger.warning('Already polling, skipping start request');
      return;
    }

    if (!_isInitialized) {
      AppLogger.error('Cannot start polling: OBD not initialized');
      return;
    }

    AppLogger.info('Starting OBD data polling');
    _isPolling = true;

    _pollingTimer = Timer.periodic(interval, (_) async {
      if (!_bluetoothService.isConnected) {
        stopPolling();
        return;
      }

      await _pollAllData();
    });
  }

  /// Stop polling for data
  void stopPolling() {
    AppLogger.info('Stopping OBD data polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  /// Poll all supported PIDs and update data
  Future<void> _pollAllData() async {
    try {
      // Engine RPM
      final rpmResponse = await _sendCommand('010C');
      final rpm = ObdParser.parseEngineRpm(rpmResponse);
      if (rpm != null) _currentData = _currentData.copyWith(rpm: rpm);

      // Small delay between commands
      await Future.delayed(const Duration(milliseconds: 50));

      // Vehicle speed
      final speedResponse = await _sendCommand('010D');
      final speed = ObdParser.parseVehicleSpeed(speedResponse);
      if (speed != null) _currentData = _currentData.copyWith(speed: speed);

      await Future.delayed(const Duration(milliseconds: 50));

      // Coolant temperature
      final tempResponse = await _sendCommand('0105');
      final temp = ObdParser.parseCoolantTemperature(tempResponse);
      if (temp != null) _currentData = _currentData.copyWith(coolantTemp: temp);

      await Future.delayed(const Duration(milliseconds: 50));

      // Throttle position
      final throttleResponse = await _sendCommand('0111');
      final throttle = ObdParser.parseThrottlePosition(throttleResponse);
      if (throttle != null) _currentData = _currentData.copyWith(throttlePosition: throttle);

      await Future.delayed(const Duration(milliseconds: 50));

      // Fuel level
      final fuelResponse = await _sendCommand('012F');
      final fuel = ObdParser.parseFuelLevel(fuelResponse);
      if (fuel != null) _currentData = _currentData.copyWith(fuelLevel: fuel);

      await Future.delayed(const Duration(milliseconds: 50));

      // Battery voltage
      final voltageResponse = await _sendCommand('ATRV');
      final voltage = ObdParser.parseBatteryVoltage(voltageResponse);
      if (voltage != null) _currentData = _currentData.copyWith(batteryVoltage: voltage);

      // Update timestamp
      _currentData = _currentData.copyWith(timestamp: DateTime.now());

      // Emit updated data
      _obdDataController.add(_currentData);
    } catch (e) {
      AppLogger.error('Error polling OBD data', error: e);
    }
  }

  /// Get specific PID value
  Future<T?> getPidValue<T>(String pid, T? Function(String) parser) async {
    try {
      final response = await _sendCommand(pid);
      return parser(response);
    } catch (e) {
      AppLogger.error('Error getting PID $pid', error: e);
      return null;
    }
  }

  /// Read diagnostic trouble codes
  Future<List<String>> readDiagnosticCodes() async {
    try {
      AppLogger.info('Reading diagnostic trouble codes...');
      
      // Request stored DTCs
      final response = await _sendCommand('03');
      
      // Parse DTCs from response
      final codes = ObdParser.parseDiagnosticCodes(response);
      
      AppLogger.info('Found ${codes.length} diagnostic codes');
      return codes;
    } catch (e) {
      AppLogger.error('Error reading diagnostic codes', error: e);
      return [];
    }
  }

  /// Clear diagnostic trouble codes
  Future<bool> clearDiagnosticCodes() async {
    try {
      AppLogger.info('Clearing diagnostic trouble codes...');
      
      final response = await _sendCommand('04');
      
      // Check if clear was successful
      final success = !ObdParser.isErrorResponse(response);
      
      if (success) {
        AppLogger.info('Successfully cleared diagnostic codes');
      } else {
        AppLogger.warning('Failed to clear diagnostic codes');
      }
      
      return success;
    } catch (e) {
      AppLogger.error('Error clearing diagnostic codes', error: e);
      return false;
    }
  }

  /// Check which PIDs are supported by the vehicle
  /// PID 0100 returns supported PIDs 01-20
  /// PID 0120 returns supported PIDs 21-40
  Future<Set<String>> getSupportedPids() async {
    try {
      final supportedPids = <String>{};
      
      // Check PIDs 01-20
      final response1 = await _sendCommand('0100');
      if (!ObdParser.isNoDataResponse(response1)) {
        // Parse bitmap to determine supported PIDs
        // This is a simplified version - full implementation would decode the bitmap
        supportedPids.add('01-20');
      }
      
      // Check PIDs 21-40
      final response2 = await _sendCommand('0120');
      if (!ObdParser.isNoDataResponse(response2)) {
        supportedPids.add('21-40');
      }
      
      return supportedPids;
    } catch (e) {
      AppLogger.error('Error getting supported PIDs', error: e);
      return {};
    }
  }

  /// Send a command to the OBD device
  Future<String> _sendCommand(String command) async {
    if (!_bluetoothService.isConnected) {
      throw Exception('Bluetooth not connected');
    }

    return await _bluetoothService.sendCommand(command);
  }

  /// Send a command with a delay after
  Future<String> _sendCommandWithDelay(String command, {int delay = 100}) async {
    final response = await _sendCommand(command);
    await Future.delayed(Duration(milliseconds: delay));
    return response;
  }

  /// Get current OBD data snapshot
  ObdData getCurrentData() => _currentData;

  /// Reset current data
  void resetData() {
    _currentData = ObdData();
    _obdDataController.add(_currentData);
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    stopPolling();
    await _bluetoothService.disconnect();
    _isInitialized = false;
    resetData();
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
    _obdDataController.close();
    _bluetoothService.dispose();
  }
}
