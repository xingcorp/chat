import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Service responsible for monitoring device connectivity
@singleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _hasConnection = false;
  
  /// Stream controller for connectivity status changes
  final StreamController<ConnectivityResult> _connectionChangeController = 
      StreamController<ConnectivityResult>.broadcast();
  
  /// Constructor that initializes connectivity monitoring
  ConnectivityService() {
    // Initialize connectivity monitoring
    _initConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  /// Stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged => 
      _connectionChangeController.stream;
  
  /// Current connection status
  bool get isConnected => _hasConnection;
  
  /// Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Could not check connectivity status: $e');
    }
  }
  
  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    debugPrint('Connectivity status changed: $result');
    
    // Update connection status
    if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
      _hasConnection = true;
    } else {
      _hasConnection = false;
    }
    
    // Notify listeners
    _connectionChangeController.add(result);
  }
  
  /// Check current network status
  Future<bool> checkNetworkStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
    } catch (e) {
      debugPrint('Failed to check network status: $e');
      return false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectionChangeController.close();
  }
} 