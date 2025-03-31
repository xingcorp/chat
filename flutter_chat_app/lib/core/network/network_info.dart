import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract interface for checking network connectivity
abstract class NetworkInfo {
  /// Returns true if the device is connected to the internet
  Future<bool> get isConnected;
  
  /// Returns the current connectivity status
  Future<ConnectivityResult> get connectivityResult;
  
  /// Stream of connectivity status changes
  Stream<ConnectivityResult> get onConnectivityChanged;
}

/// Implementation of the NetworkInfo interface
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  /// Constructor
  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  @override
  Future<ConnectivityResult> get connectivityResult async {
    return await _connectivity.checkConnectivity();
  }
  
  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
} 