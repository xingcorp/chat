import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:logger/logger.dart';

/// Service for monitoring and managing network connectivity.
///
/// Uses 2 layers:
/// - Transport connectivity (wifi/mobile/ethernet) via `connectivity_plus`
/// - Real internet reachability via `internet_connection_checker`
@lazySingleton
class ConnectivityService {
  /// Current transport connection types.
  List<ConnectivityResult> _connectionStatus = [];

  /// Stream that emits the current transport connections.
  final _connectionController =
      StreamController<List<ConnectivityResult>>.broadcast();

  /// Stream that emits whether internet is reachable.
  final _hasConnectionController = StreamController<bool>.broadcast();

  /// Logger.
  final _logger = Logger();

  /// Connectivity Plus instance.
  final Connectivity _connectivity;

  /// Internet reachability checker.
  final InternetConnectionChecker _internetConnectionChecker;

  /// Subscription for transport connectivity changes.
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Subscription for internet reachability changes.
  StreamSubscription<InternetConnectionStatus>? _internetStatusSubscription;

  /// Time of last transport check.
  DateTime _lastCheck = DateTime.fromMillisecondsSinceEpoch(0);

  /// Minimum interval between transport checks.
  static const Duration _minCheckInterval = Duration(seconds: 2);

  /// Whether internet is currently reachable.
  bool _hasInternetAccess = false;

  /// Monotonic token to drop stale async internet checks.
  int _internetCheckToken = 0;

  /// Constructor.
  ConnectivityService(
    this._connectivity, [
    InternetConnectionChecker? internetConnectionChecker,
  ]) : _internetConnectionChecker =
            internetConnectionChecker ?? InternetConnectionChecker.instance {
    _initialize();
  }

  /// Stream for transport connectivity changes.
  Stream<List<ConnectivityResult>> get onStatusChanged =>
      _connectionController.stream;

  /// Stream for internet availability changes.
  Stream<bool> get onConnectivityChanged => _hasConnectionController.stream;

  /// Getter for current transport connectivity types.
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  /// Whether real internet is reachable.
  bool get hasConnection => _hasInternetAccess;

  /// Check if WiFi transport exists.
  bool get isWifi => _connectionStatus.contains(ConnectivityResult.wifi);

  /// Check if mobile transport exists.
  bool get isMobile => _connectionStatus.contains(ConnectivityResult.mobile);

  /// Check if ethernet transport exists.
  bool get isEthernet =>
      _connectionStatus.contains(ConnectivityResult.ethernet);

  /// Initialize service and listen for events.
  Future<void> _initialize() async {
    try {
      // Get initial transport status and initial internet reachability.
      _connectionStatus = await _connectivity.checkConnectivity();
      await _refreshInternetStatus();
      _emitCurrentState();

      // Subscribe to transport changes.
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) => unawaited(_updateConnectionStatus(results)),
      );

      // Subscribe to internet reachability changes (captured portal, DNS, etc).
      _internetStatusSubscription =
          _internetConnectionChecker.onStatusChange.listen(
        _handleInternetStatus,
      );

      _logger.i(
        'Connectivity Service initialized. '
        'transport=$_connectionStatus, internet=$_hasInternetAccess',
      );
    } catch (e) {
      _logger.e('Error initializing Connectivity Service: $e');
    }
  }

  /// Handle transport connectivity changes.
  Future<void> _updateConnectionStatus(
    List<ConnectivityResult> results, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force && now.difference(_lastCheck) < _minCheckInterval) {
      // Avoid too many events in a short time.
      return;
    }

    _lastCheck = now;

    final statusChanged = !_areListsEqual(_connectionStatus, results);
    if (statusChanged) {
      _logger.d('Transport changed: $_connectionStatus -> $results');
      _connectionStatus = results;
    }

    if (!statusChanged && !force) {
      return;
    }

    await _refreshInternetStatus();
    _emitCurrentState();
  }

  /// Handle internet reachability stream updates.
  void _handleInternetStatus(InternetConnectionStatus status) {
    final hasTransport = _hasNetworkTransport(_connectionStatus);
    final hasInternet =
        hasTransport && status == InternetConnectionStatus.connected;
    if (_hasInternetAccess == hasInternet) {
      return;
    }

    _hasInternetAccess = hasInternet;
    if (!_hasConnectionController.isClosed) {
      _hasConnectionController.add(_hasInternetAccess);
    }
    _logger.d(
      'Internet reachability changed: $_hasInternetAccess '
      '(transport=$_connectionStatus)',
    );
  }

  /// Refresh real internet reachability.
  Future<void> _refreshInternetStatus() async {
    final hasTransport = _hasNetworkTransport(_connectionStatus);
    if (!hasTransport) {
      _hasInternetAccess = false;
      return;
    }

    final checkToken = ++_internetCheckToken;
    bool hasInternet = false;
    try {
      hasInternet = await _internetConnectionChecker.hasConnection;
    } catch (e) {
      _logger.w('Internet reachability check failed: $e');
    }

    // Drop stale async result.
    if (checkToken != _internetCheckToken) {
      return;
    }
    _hasInternetAccess = hasInternet;
  }

  /// Emit current connectivity state.
  void _emitCurrentState() {
    if (!_connectionController.isClosed) {
      _connectionController.add(_connectionStatus);
    }
    if (!_hasConnectionController.isClosed) {
      _hasConnectionController.add(_hasInternetAccess);
    }
  }

  /// Manually check transport connectivity and internet reachability.
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results, force: true);
      return results;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      _connectionStatus = [];
      _hasInternetAccess = false;
      _emitCurrentState();
      return [];
    }
  }

  /// Check if real internet is reachable.
  Future<bool> isConnected() async {
    await checkConnectivity();
    return _hasInternetAccess;
  }

  /// Compare two lists regardless of order.
  bool _areListsEqual(
    List<ConnectivityResult> list1,
    List<ConnectivityResult> list2,
  ) {
    if (list1.length != list2.length) return false;

    final sortedList1 = List<ConnectivityResult>.from(list1)
      ..sort((a, b) => a.index.compareTo(b.index));
    final sortedList2 = List<ConnectivityResult>.from(list2)
      ..sort((a, b) => a.index.compareTo(b.index));

    for (int i = 0; i < sortedList1.length; i++) {
      if (sortedList1[i] != sortedList2[i]) return false;
    }

    return true;
  }

  /// Check whether any non-none network transport exists.
  bool _hasNetworkTransport(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
  }

  /// Release resources.
  void dispose() {
    _subscription?.cancel();
    _internetStatusSubscription?.cancel();
    _connectionController.close();
    _hasConnectionController.close();
    _logger.d('Connectivity Service disposed');
  }
}
