import 'dart:async';
import 'dart:typed_data';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';  // Temporarily disabled
import '../../shared/utils/app_logger.dart';

// Temporary stub classes until flutter_bluetooth_serial is fixed
class BluetoothConnection {
  bool get isConnected => false;
  Stream<Uint8List>? get input => null;
  IOSink get output => throw UnimplementedError('Bluetooth not available');
  Future<void> close() async {}
  static Future<BluetoothConnection> toAddress(String address) {
    throw UnimplementedError('Bluetooth Classic not available - flutter_bluetooth_serial disabled');
  }
}

class BluetoothDevice {
  final String? name;
  final String address;
  BluetoothDevice({this.name, required this.address});
}

class BluetoothDiscoveryResult {
  final BluetoothDevice device;
  BluetoothDiscoveryResult({required this.device});
}

enum BluetoothState { STATE_ON, STATE_OFF }

class FlutterBluetoothSerial {
  static final FlutterBluetoothSerial instance = FlutterBluetoothSerial._();
  FlutterBluetoothSerial._();
  
  Future<BluetoothState> get state async => BluetoothState.STATE_OFF;
  Future<void> requestEnable() async {}
  Future<List<BluetoothDevice>> getBondedDevices() async => [];
  Stream<BluetoothDiscoveryResult> startDiscovery() => const Stream.empty();
  Future<void> cancelDiscovery() async {}
}

class IOSink {
  void add(List<int> data) {}
  Future<void> get allSent async {}
}

/// Service for managing Bluetooth connections to OBD-II devices
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  StreamSubscription<Uint8List>? _inputSubscription;
  
  /// Stream controller for connection state changes
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// Stream controller for incoming data
  final _dataController = StreamController<Uint8List>.broadcast();

  /// Current connection state
  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Check if Bluetooth is enabled on the device
  Future<bool> isBluetoothEnabled() async {
    try {
      final state = await FlutterBluetoothSerial.instance.state;
      return state == BluetoothState.STATE_ON;
    } catch (e) {
      AppLogger.error('Error checking Bluetooth state', error: e);
      return false;
    }
  }

  /// Request to enable Bluetooth
  Future<bool> requestEnableBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      return await isBluetoothEnabled();
    } catch (e) {
      AppLogger.error('Error enabling Bluetooth', error: e);
      return false;
    }
  }

  /// Get list of bonded (paired) Bluetooth devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      AppLogger.error('Error getting bonded devices', error: e);
      return [];
    }
  }

  /// Start discovering nearby Bluetooth devices
  /// Returns a stream of discovered devices
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    try {
      _discoverySubscription?.cancel();
      return FlutterBluetoothSerial.instance.startDiscovery();
    } catch (e) {
      AppLogger.error('Error starting discovery', error: e);
      return const Stream.empty();
    }
  }

  /// Stop discovering Bluetooth devices
  Future<void> stopDiscovery() async {
    try {
      await _discoverySubscription?.cancel();
      await FlutterBluetoothSerial.instance.cancelDiscovery();
    } catch (e) {
      AppLogger.error('Error stopping discovery', error: e);
    }
  }

  /// Filter OBD-II compatible devices from a list
  /// OBD devices typically have names containing: OBD, ELM327, OBDII, etc.
  List<BluetoothDevice> filterObdDevices(List<BluetoothDevice> devices) {
    final obdKeywords = ['obd', 'elm', 'vlink', 'vgate', 'bafx', 'scan'];
    
    return devices.where((device) {
      if (device.name == null) return false;
      final nameLower = device.name!.toLowerCase();
      return obdKeywords.any((keyword) => nameLower.contains(keyword));
    }).toList();
  }

  /// Connect to a Bluetooth OBD-II device
  Future<BluetoothConnectionResult> connectToDevice(BluetoothDevice device) async {
    try {
      // Disconnect if already connected
      if (_connection != null && _connection!.isConnected) {
        await disconnect();
      }

      AppLogger.info('Attempting to connect to ${device.name} (${device.address})');
      
      // Establish connection with timeout
      _connection = await BluetoothConnection.toAddress(device.address)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      AppLogger.info('Successfully connected to ${device.name}');
      
      // Listen to input stream once and broadcast it
      _inputSubscription?.cancel();
      _inputSubscription = _connection!.input!.listen(
        (data) {
          // Broadcast incoming data to the data controller
          _dataController.add(data);
        },
        onDone: () {
          AppLogger.info('Bluetooth connection closed');
          _connectionStateController.add(BluetoothConnectionState.disconnected);
        },
        onError: (error) {
          AppLogger.error('Bluetooth connection error', error: error);
          _connectionStateController.add(BluetoothConnectionState.error);
        },
      );

      _connectionStateController.add(BluetoothConnectionState.connected);
      
      return BluetoothConnectionResult(
        success: true,
        message: 'Connected to ${device.name}',
      );
    } on TimeoutException {
      return BluetoothConnectionResult(
        success: false,
        message: 'Connection timeout. Make sure the device is powered on and in range.',
      );
    } catch (e) {
      AppLogger.error('Error connecting to device', error: e);
      return BluetoothConnectionResult(
        success: false,
        message: 'Failed to connect: ${e.toString()}',
      );
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _inputSubscription?.cancel();
      _inputSubscription = null;
      await _connection?.close();
      _connection = null;
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      AppLogger.info('Disconnected from Bluetooth device');
    } catch (e) {
      AppLogger.error('Error disconnecting', error: e);
    }
  }

  /// Send a command to the connected OBD device
  /// Returns the raw response string
  Future<String> sendCommand(String command) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('Not connected to any device');
    }

    try {
      // Add carriage return to command as required by OBD-II protocol
      final commandWithCR = command.endsWith('\r') ? command : '$command\r';
      
      AppLogger.info('Sending OBD command: ${command.trim()}');
      
      // Send command
      _connection!.output.add(Uint8List.fromList(commandWithCR.codeUnits));
      await _connection!.output.allSent;

      // Wait for and collect response
      final completer = Completer<String>();
      final responseBuffer = StringBuffer();
      late StreamSubscription subscription;

      // Listen to the broadcast stream instead of the raw input
      subscription = _dataController.stream.listen(
        (data) {
          final chunk = String.fromCharCodes(data);
          responseBuffer.write(chunk);

          // OBD responses typically end with '>' prompt
          if (chunk.contains('>')) {
            subscription.cancel();
            completer.complete(responseBuffer.toString());
          }
        },
        onError: (error) {
          subscription.cancel();
          completer.completeError(error);
        },
        cancelOnError: true,
      );

      // Wait for response with timeout
      final response = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('Command response timeout');
        },
      );

      AppLogger.info('Received OBD response: ${response.trim()}');
      return response;
    } catch (e) {
      AppLogger.error('Error sending command', error: e);
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _inputSubscription?.cancel();
    _connectionStateController.close();
    _dataController.close();
    _discoverySubscription?.cancel();
    disconnect();
  }
}

/// Result of a Bluetooth connection attempt
class BluetoothConnectionResult {
  final bool success;
  final String message;

  BluetoothConnectionResult({
    required this.success,
    required this.message,
  });
}

/// Bluetooth connection states
enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
