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
    final results = await _connectivity.checkConnectivity();
    // Consider connected if any of the results is not "none"
    return results.any((result) => result != ConnectivityResult.none);
  }
  
  @override
  Future<ConnectivityResult> get connectivityResult async {
    final results = await _connectivity.checkConnectivity();
    // Return the first result, or none if list is empty
    return results.isNotEmpty ? results.first : ConnectivityResult.none;
  }
  
  @override
  Stream<ConnectivityResult> get onConnectivityChanged {
    // Map the list of results to a single result by taking the first one
    return _connectivity.onConnectivityChanged
        .map((results) => results.isNotEmpty ? results.first : ConnectivityResult.none);
  }
} 