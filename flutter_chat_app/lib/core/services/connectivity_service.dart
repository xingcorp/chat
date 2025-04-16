import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service for monitoring and managing network connectivity
@singleton
class ConnectivityService {
  /// Current connection types
  List<ConnectivityResult> _connectionStatus = [];
  
  /// Stream that emits the current connections
  final _connectionController = StreamController<List<ConnectivityResult>>.broadcast();
  
  /// Stream that emits whether network is connected
  final _hasConnectionController = StreamController<bool>.broadcast();
  
  /// Logger
  final _logger = Logger();
  
  /// Connectivity Plus instance
  final Connectivity _connectivity;
  
  /// Subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  /// Time of last check
  DateTime _lastCheck = DateTime.now();
  
  /// Minimum interval between checks
  static const Duration _minCheckInterval = Duration(seconds: 2);
  
  /// Constructor
  ConnectivityService(this._connectivity) {
    _initialize();
  }
  
  /// Stream for connectivity status changes
  Stream<List<ConnectivityResult>> get onStatusChanged => 
      _connectionController.stream;
  
  /// Stream for connectivity availability changes
  Stream<bool> get onConnectivityChanged => 
      _hasConnectionController.stream;
  
  /// Getter for current connectivity types
  List<ConnectivityResult> get connectionStatus => _connectionStatus;
  
  /// Check if there is any connection
  bool get hasConnection => 
      _connectionStatus.isNotEmpty && _connectionStatus.any((result) => result != ConnectivityResult.none);
  
  /// Check if WiFi connection exists
  bool get isWifi => _connectionStatus.contains(ConnectivityResult.wifi);
  
  /// Check if mobile data connection exists
  bool get isMobile => _connectionStatus.contains(ConnectivityResult.mobile);
  
  /// Check if ethernet connection exists
  bool get isEthernet => _connectionStatus.contains(ConnectivityResult.ethernet);
  
  /// Initialize service and listen for events
  Future<void> _initialize() async {
    try {
      // Get initial connection status
      _connectionStatus = await _connectivity.checkConnectivity();
      _emitCurrentState();
      
      // Subscribe to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      
      _logger.i('Connectivity Service initialized. Initial status: $_connectionStatus');
    } catch (e) {
      _logger.e('Error initializing Connectivity Service: $e');
    }
  }
  
  /// Update connection status when changes occur
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final now = DateTime.now();
    if (now.difference(_lastCheck) < _minCheckInterval) {
      // Avoid too many events in a short time
      return;
    }
    
    _lastCheck = now;
    
    // Only update if actually changed - compare regardless of order
    if (!_areListsEqual(_connectionStatus, results)) {
      _logger.d('Connection status changed: $_connectionStatus -> $results');
      _connectionStatus = results;
      _emitCurrentState();
    }
  }
  
  /// Compare two lists regardless of order
  bool _areListsEqual(List<ConnectivityResult> list1, List<ConnectivityResult> list2) {
    if (list1.length != list2.length) return false;
    
    final sortedList1 = List<ConnectivityResult>.from(list1)..sort((a, b) => a.index.compareTo(b.index));
    final sortedList2 = List<ConnectivityResult>.from(list2)..sort((a, b) => a.index.compareTo(b.index));
    
    for (int i = 0; i < sortedList1.length; i++) {
      if (sortedList1[i] != sortedList2[i]) return false;
    }
    
    return true;
  }
  
  /// Emit current state
  void _emitCurrentState() {
    _connectionController.add(_connectionStatus);
    _hasConnectionController.add(hasConnection);
  }
  
  /// Manually check connectivity
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return results;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return [];
    }
  }
  
  /// Check if connected to any network
  Future<bool> isConnected() async {
    final results = await checkConnectivity();
    return results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
  }
  
  /// Release resources
  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
    _hasConnectionController.close();
    _logger.d('Connectivity Service disposed');
  }

}