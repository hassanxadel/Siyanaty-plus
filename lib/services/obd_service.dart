import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/obd_scan.dart';
import '../database/database_helper.dart';

/// Service for OBD-II communication and data management
class OBDService {
  static final OBDService _instance = OBDService._internal();
  factory OBDService() => _instance;
  OBDService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Bluetooth connection state
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  
  // Stream controllers
  final _connectionStateController = StreamController<bool>.broadcast();
  final _scanDataController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get scanData => _scanDataController.stream;
  
  bool get isConnected => _connectedDevice != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // OBD-II PID Commands
  static const String CMD_ENGINE_RPM = '010C';
  static const String CMD_VEHICLE_SPEED = '010D';
  static const String CMD_COOLANT_TEMP = '0105';
  static const String CMD_FUEL_LEVEL = '012F';
  static const String CMD_THROTTLE_POSITION = '0111';
  static const String CMD_ENGINE_LOAD = '0104';
  static const String CMD_GET_DTC = '03';
  static const String CMD_CLEAR_DTC = '04';
  static const String CMD_RESET = 'ATZ';
  static const String CMD_ECHO_OFF = 'ATE0';
  static const String CMD_LINE_FEED_OFF = 'ATL0';
  static const String CMD_PROTOCOL_AUTO = 'ATSP0';

  /// Scan for available OBD-II devices
  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isAvailable) {
        throw Exception('Bluetooth is not available on this device');
      }

      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        throw Exception('Please turn on Bluetooth');
      }

      List<BluetoothDevice> devices = [];

      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Filter for OBD-II devices (common names)
          final deviceName = result.device.name.toLowerCase();
          if (deviceName.contains('obd') || 
              deviceName.contains('elm') || 
              deviceName.contains('vlink') ||
              deviceName.contains('veepeak') ||
              deviceName.contains('bafx')) {
            if (!devices.contains(result.device)) {
              devices.add(result.device);
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);
      await subscription.cancel();
      await FlutterBluePlus.stopScan();

      return devices;
    } catch (e) {
      print('[OBD] Error scanning for devices: $e');
      rethrow;
    }
  }

  /// Connect to an OBD-II device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      print('[OBD] Connecting to ${device.name}...');

      // Disconnect if already connected
      if (_connectedDevice != null) {
        await disconnect();
      }

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the serial port service (common UUID for OBD-II)
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Look for write characteristic
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
          // Look for read/notify characteristic
          if (characteristic.properties.notify || characteristic.properties.read) {
            _readCharacteristic = characteristic;
            // Enable notifications
            await characteristic.setNotifyValue(true);
          }
        }
      }

      if (_writeCharacteristic == null || _readCharacteristic == null) {
        throw Exception('Could not find required characteristics');
      }

      // Initialize OBD-II adapter
      await _initializeAdapter();

      _connectionStateController.add(true);
      print('[OBD] Connected successfully');
      return true;
    } catch (e) {
      print('[OBD] Connection error: $e');
      _connectedDevice = null;
      _connectionStateController.add(false);
      return false;
    }
  }

  /// Initialize OBD-II adapter with AT commands
  Future<void> _initializeAdapter() async {
    try {
      await _sendCommand(CMD_RESET);
      await Future.delayed(const Duration(milliseconds: 500));
      await _sendCommand(CMD_ECHO_OFF);
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendCommand(CMD_LINE_FEED_OFF);
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendCommand(CMD_PROTOCOL_AUTO);
      await Future.delayed(const Duration(milliseconds: 200));
      print('[OBD] Adapter initialized');
    } catch (e) {
      print('[OBD] Initialization error: $e');
    }
  }

  /// Send a command to the OBD-II adapter
  Future<String> _sendCommand(String command) async {
    if (_writeCharacteristic == null || _readCharacteristic == null) {
      throw Exception('Not connected to device');
    }

    try {
      // Send command
      final commandBytes = utf8.encode('$command\r');
      await _writeCharacteristic!.write(commandBytes, withoutResponse: false);

      // Wait for response
      await Future.delayed(const Duration(milliseconds: 300));

      // Read response (this is simplified - real implementation needs proper response handling)
      final response = await _readCharacteristic!.read();
      return utf8.decode(response);
    } catch (e) {
      print('[OBD] Command error: $e');
      return '';
    }
  }

  /// Read engine RPM
  Future<double?> readRPM() async {
    try {
      final response = await _sendCommand(CMD_ENGINE_RPM);
      final rpm = _parseRPM(response);
      _scanDataController.add({'rpm': rpm});
      return rpm;
    } catch (e) {
      print('[OBD] Error reading RPM: $e');
      return null;
    }
  }

  /// Read vehicle speed
  Future<double?> readSpeed() async {
    try {
      final response = await _sendCommand(CMD_VEHICLE_SPEED);
      final speed = _parseSpeed(response);
      _scanDataController.add({'speed': speed});
      return speed;
    } catch (e) {
      print('[OBD] Error reading speed: $e');
      return null;
    }
  }

  /// Read coolant temperature
  Future<double?> readCoolantTemp() async {
    try {
      final response = await _sendCommand(CMD_COOLANT_TEMP);
      final temp = _parseCoolantTemp(response);
      _scanDataController.add({'coolantTemp': temp});
      return temp;
    } catch (e) {
      print('[OBD] Error reading coolant temp: $e');
      return null;
    }
  }

  /// Read fuel level
  Future<double?> readFuelLevel() async {
    try {
      final response = await _sendCommand(CMD_FUEL_LEVEL);
      final fuel = _parseFuelLevel(response);
      _scanDataController.add({'fuelLevel': fuel});
      return fuel;
    } catch (e) {
      print('[OBD] Error reading fuel level: $e');
      return null;
    }
  }

  /// Read throttle position
  Future<double?> readThrottlePosition() async {
    try {
      final response = await _sendCommand(CMD_THROTTLE_POSITION);
      final throttle = _parseThrottlePosition(response);
      _scanDataController.add({'throttlePosition': throttle});
      return throttle;
    } catch (e) {
      print('[OBD] Error reading throttle position: $e');
      return null;
    }
  }

  /// Read engine load
  Future<double?> readEngineLoad() async {
    try {
      final response = await _sendCommand(CMD_ENGINE_LOAD);
      final load = _parseEngineLoad(response);
      _scanDataController.add({'engineLoad': load});
      return load;
    } catch (e) {
      print('[OBD] Error reading engine load: $e');
      return null;
    }
  }

  /// Read diagnostic trouble codes (DTCs)
  Future<List<String>> readDTCs() async {
    try {
      final response = await _sendCommand(CMD_GET_DTC);
      return _parseDTCs(response);
    } catch (e) {
      print('[OBD] Error reading DTCs: $e');
      return [];
    }
  }

  /// Clear diagnostic trouble codes
  Future<bool> clearDTCs() async {
    try {
      await _sendCommand(CMD_CLEAR_DTC);
      return true;
    } catch (e) {
      print('[OBD] Error clearing DTCs: $e');
      return false;
    }
  }

  /// Perform a complete scan and save to database
  Future<OBDScan?> performFullScan(int carId, {String? notes}) async {
    try {
      if (!isConnected) {
        throw Exception('Not connected to OBD device');
      }

      print('[OBD] Starting full scan...');

      // Read all parameters
      final rpm = await readRPM();
      final speed = await readSpeed();
      final coolantTemp = await readCoolantTemp();
      final fuelLevel = await readFuelLevel();
      final throttlePosition = await readThrottlePosition();
      final engineLoad = await readEngineLoad();
      final dtcs = await readDTCs();

      // Create OBD scan object
      final scan = OBDScan(
        carId: carId,
        scanDate: DateTime.now(),
        rpm: rpm,
        speed: speed,
        coolantTemp: coolantTemp,
        fuelLevel: fuelLevel,
        throttlePosition: throttlePosition,
        engineLoad: engineLoad,
        errorCodes: dtcs,
        notes: notes,
      );

      // Save to database
      final id = await _dbHelper.insertOBDScan(scan.toMap());
      print('[OBD] Scan saved with ID: $id');

      return scan.copyWith(id: id);
    } catch (e) {
      print('[OBD] Error performing full scan: $e');
      return null;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        _readCharacteristic = null;
        _connectionStateController.add(false);
        print('[OBD] Disconnected');
      }
    } catch (e) {
      print('[OBD] Disconnect error: $e');
    }
  }

  // ==================== PARSING METHODS ====================

  double? _parseRPM(String response) {
    try {
      final bytes = _extractBytes(response);
      if (bytes.length >= 2) {
        return ((bytes[0] * 256) + bytes[1]) / 4.0;
      }
    } catch (e) {
      print('[OBD] RPM parse error: $e');
    }
    return null;
  }

  double? _parseSpeed(String response) {
    try {
      final bytes = _extractBytes(response);
      if (bytes.isNotEmpty) {
        return bytes[0].toDouble();
      }
    } catch (e) {
      print('[OBD] Speed parse error: $e');
    }
    return null;
  }

  double? _parseCoolantTemp(String response) {
    try {
      final bytes = _extractBytes(response);
      if (bytes.isNotEmpty) {
        return bytes[0] - 40.0;
      }
    } catch (e) {
      print('[OBD] Coolant temp parse error: $e');
    }
    return null;
  }

  double? _parseFuelLevel(String response) {
    try {
      final bytes = _extractBytes(response);
      if (bytes.isNotEmpty) {
        return (bytes[0] * 100) / 255.0;
      }
    } catch (e) {
      print('[OBD] Fuel level parse error: $e');
    }
    return null;
  }

  double? _parseThrottlePosition(String response) {
    try {
      final bytes = _extractBytes(response);
      if (bytes.isNotEmpty) {
        return (bytes[0] * 100) / 255.0;
      }
    } catch (e) {
      print('[OBD] Throttle position parse error: $e');
    }
    return null;
  }

  double? _parseEngineLoad(String response) {
    try {
      final bytes = _extractBytes(response);
      if (bytes.isNotEmpty) {
        return (bytes[0] * 100) / 255.0;
      }
    } catch (e) {
      print('[OBD] Engine load parse error: $e');
    }
    return null;
  }

  List<String> _parseDTCs(String response) {
    try {
      List<String> dtcs = [];
      // Simplified DTC parsing - real implementation needs proper parsing
      final lines = response.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.length >= 4 && RegExp(r'^[A-Z0-9]{4,5}$').hasMatch(line)) {
          dtcs.add(line);
        }
      }
      return dtcs;
    } catch (e) {
      print('[OBD] DTC parse error: $e');
      return [];
    }
  }

  List<int> _extractBytes(String response) {
    try {
      // Remove whitespace and split by space
      final cleaned = response.replaceAll('\r', '').replaceAll('\n', '').trim();
      final parts = cleaned.split(' ');
      
      List<int> bytes = [];
      for (var part in parts) {
        if (part.length == 2) {
          try {
            bytes.add(int.parse(part, radix: 16));
          } catch (e) {
            // Skip invalid hex values
          }
        }
      }
      return bytes;
    } catch (e) {
      print('[OBD] Byte extraction error: $e');
      return [];
    }
  }

  // ==================== DATABASE METHODS ====================

  /// Get all scans for a specific car
  Future<List<OBDScan>> getScansByCar(int carId) async {
    try {
      final maps = await _dbHelper.getOBDScansByCar(carId);
      return maps.map((map) => OBDScan.fromMap(map)).toList();
    } catch (e) {
      print('[OBD] Error getting scans: $e');
      return [];
    }
  }

  /// Get all scans
  Future<List<OBDScan>> getAllScans() async {
    try {
      final maps = await _dbHelper.getAllOBDScans();
      return maps.map((map) => OBDScan.fromMap(map)).toList();
    } catch (e) {
      print('[OBD] Error getting all scans: $e');
      return [];
    }
  }

  /// Get latest scan for a car
  Future<OBDScan?> getLatestScan(int carId) async {
    try {
      final map = await _dbHelper.getLatestOBDScan(carId);
      return map != null ? OBDScan.fromMap(map) : null;
    } catch (e) {
      print('[OBD] Error getting latest scan: $e');
      return null;
    }
  }

  /// Delete a scan
  Future<bool> deleteScan(int id) async {
    try {
      await _dbHelper.deleteOBDScan(id);
      return true;
    } catch (e) {
      print('[OBD] Error deleting scan: $e');
      return false;
    }
  }

  /// Delete all scans for a car
  Future<bool> deleteScansByCar(int carId) async {
    try {
      await _dbHelper.deleteOBDScansByCar(carId);
      return true;
    } catch (e) {
      print('[OBD] Error deleting scans: $e');
      return false;
    }
  }

  /// Get scans count for a car
  Future<int> getScansCount(int carId) async {
    try {
      return await _dbHelper.getOBDScansCount(carId);
    } catch (e) {
      print('[OBD] Error getting scans count: $e');
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectionStateController.close();
    _scanDataController.close();
  }
}

