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
  final StreamController<List<ConnectivityResult>> _connectionChangeController = 
      StreamController<List<ConnectivityResult>>.broadcast();
  
  /// Constructor (now empty)
  ConnectivityService();
  
  /// Stream of connectivity changes (now List)
  Stream<List<ConnectivityResult>> get onConnectivityChanged => 
      _connectionChangeController.stream;
  
  /// Current connection status (based on any active connection)
  bool get isConnected => _hasConnection;
  
  /// Initialize connectivity monitoring. Call after creating instance.
  Future<void> initialize() async {
    // Listen for connectivity changes first
    _connectivity.onConnectivityChanged
        .distinct() // Avoid duplicate events
        .listen(_updateConnectionStatus);
        
    // Then check initial status
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Could not check connectivity status: $e');
      // Assume no connection if initial check fails
      _updateConnectionStatus([ConnectivityResult.none]);
    }
  }
  
  /// Update connection status based on connectivity result list
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Handle empty list case
    if (results.isEmpty) {
      results = [ConnectivityResult.none];
    }
    
    debugPrint('Connectivity status changed: $results');
    
    // Update connection status: true if any result is not none
    _hasConnection = results.any((result) => result != ConnectivityResult.none);
    
    // Notify listeners with the list
    // Add check isClosed to avoid error after dispose
    if (!_connectionChangeController.isClosed) {
      _connectionChangeController.add(results);
    }
  }
  
  /// Check current network status
  Future<bool> checkNetworkStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Return true if any result is not none
      return results.any((result) => result != ConnectivityResult.none);
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