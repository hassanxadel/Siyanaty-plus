import 'dart:async';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../shared/utils/app_logger.dart';
import '../presentation/widgets/app_dialog.dart';

/// Service to check and monitor internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Current connectivity status
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Stream of connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isConnected = _hasInternetConnection(result);
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final hasConnection = _hasInternetConnection(results);
        if (_isConnected != hasConnection) {
          _isConnected = hasConnection;
          _connectivityController.add(_isConnected);
          AppLogger.info('Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
        }
      });
    } catch (e) {
      AppLogger.error('Failed to initialize connectivity service', error: e);
    }
  }

  /// Check if any of the connectivity results indicate internet connection
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = _hasInternetConnection(result);
      return _isConnected;
    } catch (e) {
      AppLogger.error('Failed to check connectivity', error: e);
      return false;
    }
  }

  /// Show no internet dialog
  static void showNoInternetDialog(BuildContext context) {
    AppDialog.message(
      context,
      title: 'No Internet',
      message:
          'This feature requires an internet connection. Please check your connection and try again.',
      icon: Icons.wifi_off,
      isWarning: true,
    );
  }

  /// Show no internet snackbar (less intrusive)
  static void showNoInternetSnackbar(BuildContext context) {
    AppSnackbar.show(context, 
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No internet connection',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

/// Extension to easily check connectivity in widgets
extension ConnectivityCheck on BuildContext {
  Future<bool> checkInternet() async {
    return await ConnectivityService().checkConnectivity();
  }
  
  Future<bool> requireInternet({bool showDialog = true}) async {
    final hasInternet = await ConnectivityService().checkConnectivity();
    if (!hasInternet && mounted) {
      if (showDialog) {
        ConnectivityService.showNoInternetDialog(this);
      } else {
        ConnectivityService.showNoInternetSnackbar(this);
      }
    }
    return hasInternet;
  }
}
