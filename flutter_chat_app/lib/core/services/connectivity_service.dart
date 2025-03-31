import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Service to monitor and handle network connectivity
@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityStreamController = StreamController<bool>.broadcast();
  bool _isConnected = true;

  /// Constructor
  ConnectivityService() {
    // Initial connectivity check
    _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Stream that emits connectivity status changes
  Stream<bool> get onConnectivityChanged => _connectivityStreamController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Initial connectivity check
  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _connectivityStreamController.add(_isConnected);
  }

  /// Check if the device is currently connected
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Clean up resources
  void dispose() {
    _connectivityStreamController.close();
  }
} 