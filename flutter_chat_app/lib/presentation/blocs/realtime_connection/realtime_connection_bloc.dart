import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

part 'realtime_connection_event.dart';
part 'realtime_connection_state.dart';

/// **ENTERPRISE REAL-TIME CONNECTION BLOC**
///
/// Manages real-time connection state, automatic reconnection, and online/offline transitions
/// with RealtimeService and ConnectivityService integration using Either<Failure, T> pattern.
///
/// **Performance Targets:**
/// - Connection establishment: <2s
/// - Reconnection attempts: <5s with exponential backoff
/// - Connection health checks: <100ms
/// - Memory usage: <20MB for connection management
///
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
@injectable
class RealtimeConnectionBloc extends Bloc<RealtimeConnectionEvent, RealtimeConnectionState> {
  final RealtimeService _realtimeService;
  final ConnectivityService _connectivityService;
  final Logger _logger = Logger();

  // Active subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];
  
  // Reconnection management
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _baseReconnectionDelay = Duration(seconds: 2);

  /// Constructor
  RealtimeConnectionBloc({
    required RealtimeService realtimeService,
    required ConnectivityService connectivityService,
  }) : _realtimeService = realtimeService,
       _connectivityService = connectivityService,
       super(RealtimeConnectionStateX.initial) {
    on<ConnectToRealtime>(_onConnectToRealtime);
    on<DisconnectFromRealtime>(_onDisconnectFromRealtime);
    on<ReconnectToRealtime>(_onReconnectToRealtime);
    on<CheckConnectionHealth>(_onCheckConnectionHealth);
    on<RealtimeConnectionStateChanged>(_onConnectionStateChanged);
    on<NetworkConnectivityChanged>(_onNetworkConnectivityChanged);
    
    _initializeConnectionMonitoring();
  }

  /// **Connect to real-time server - ENTERPRISE CONNECTION**
  ///
  /// **Performance**: <2s connection establishment
  /// **Strategy**: Connection with comprehensive error handling
  Future<void> _onConnectToRealtime(
    ConnectToRealtime event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    if (state is RealtimeConnectionConnecting || state is RealtimeConnectionConnected) {
      _logger.d('Already connecting or connected');
      return;
    }

    _logger.i('Connecting to real-time server');
    emit(RealtimeConnectionStateX.connecting);

    final result = await _realtimeService.connect();

    result.fold(
      (failure) {
        _logger.e('Failed to connect to real-time server: ${failure.message}');
        emit(RealtimeConnectionStateX.disconnected(
          reason: _getErrorMessage(failure),
          canRetry: true,
        ));
        
        // Start automatic reconnection if enabled
        if (event.autoReconnect) {
          _startReconnectionTimer();
        }
      },
      (success) {
        _logger.i('Successfully connected to real-time server');
        _reconnectionAttempts = 0; // Reset attempts on successful connection
        emit(RealtimeConnectionStateX.connected);
      },
    );
  }

  /// **Disconnect from real-time server - CLEAN DISCONNECTION**
  ///
  /// **Performance**: <1s disconnection
  /// **Strategy**: Clean disconnection with resource cleanup
  Future<void> _onDisconnectFromRealtime(
    DisconnectFromRealtime event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    _logger.i('Disconnecting from real-time server');
    
    // Cancel reconnection timer
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _reconnectionAttempts = 0;

    emit(RealtimeConnectionStateX.disconnecting);

    final result = await _realtimeService.disconnect();

    result.fold(
      (failure) {
        _logger.e('Error during disconnection: ${failure.message}');
        // Still emit disconnected state even if there was an error
        emit(RealtimeConnectionStateX.disconnected(
          reason: event.reason ?? 'Disconnected by user',
          canRetry: false,
        ));
      },
      (success) {
        _logger.i('Successfully disconnected from real-time server');
        emit(RealtimeConnectionStateX.disconnected(
          reason: event.reason ?? 'Disconnected by user',
          canRetry: false,
        ));
      },
    );
  }

  /// **Reconnect to real-time server - AUTOMATIC RECONNECTION**
  ///
  /// **Performance**: <5s reconnection with exponential backoff
  /// **Strategy**: Intelligent reconnection with attempt limits
  Future<void> _onReconnectToRealtime(
    ReconnectToRealtime event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      _logger.w('Max reconnection attempts reached');
      emit(RealtimeConnectionStateX.disconnected(
        reason: 'Không thể kết nối lại sau ${_maxReconnectionAttempts} lần thử',
        canRetry: false,
      ));
      return;
    }

    _reconnectionAttempts++;
    _logger.i('Reconnection attempt $_reconnectionAttempts/$_maxReconnectionAttempts');

    emit(RealtimeConnectionStateX.reconnecting(attempt: _reconnectionAttempts));

    // Check network connectivity first
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      _logger.w('No network connectivity, delaying reconnection');
      _startReconnectionTimer();
      return;
    }

    final result = await _realtimeService.connect();

    result.fold(
      (failure) {
        _logger.e('Reconnection attempt $_reconnectionAttempts failed: ${failure.message}');
        
        if (_reconnectionAttempts < _maxReconnectionAttempts) {
          emit(RealtimeConnectionStateX.disconnected(
            reason: 'Đang thử kết nối lại... (${_reconnectionAttempts}/$_maxReconnectionAttempts)',
            canRetry: true,
          ));
          _startReconnectionTimer();
        } else {
          emit(RealtimeConnectionStateX.disconnected(
            reason: 'Không thể kết nối lại sau ${_maxReconnectionAttempts} lần thử',
            canRetry: false,
          ));
        }
      },
      (success) {
        _logger.i('Reconnection successful after $_reconnectionAttempts attempts');
        _reconnectionAttempts = 0;
        emit(RealtimeConnectionStateX.connected);
      },
    );
  }

  /// **Check connection health - HEALTH MONITORING**
  ///
  /// **Performance**: <100ms health check
  /// **Strategy**: Comprehensive connection diagnostics
  Future<void> _onCheckConnectionHealth(
    CheckConnectionHealth event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    _logger.t('Checking connection health');

    final result = await _realtimeService.getConnectionHealth();

    result.fold(
      (failure) {
        _logger.e('Failed to check connection health: ${failure.message}');
        emit(RealtimeConnectionStateX.healthCheckFailed(
          reason: _getErrorMessage(failure),
        ));
      },
      (health) {
        _logger.t('Connection health: latency=${health.latency}ms, connected=${health.isConnected}');
        emit(RealtimeConnectionStateX.healthChecked(health: health));
      },
    );
  }

  /// **Handle connection state changes from real-time service**
  Future<void> _onConnectionStateChanged(
    RealtimeConnectionStateChanged event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    final socketState = event.socketState;
    _logger.d('Socket connection state changed: $socketState');

    switch (socketState) {
      case SocketConnectionState.connected:
        _reconnectionAttempts = 0;
        emit(RealtimeConnectionStateX.connected);
        break;
      case SocketConnectionState.connecting:
        emit(RealtimeConnectionStateX.connecting);
        break;
      case SocketConnectionState.reconnecting:
        emit(RealtimeConnectionStateX.reconnecting(attempt: _reconnectionAttempts));
        break;
      case SocketConnectionState.disconnected:
      case SocketConnectionState.disconnectedByServer:
        emit(RealtimeConnectionStateX.disconnected(
          reason: 'Connection lost',
          canRetry: true,
        ));
        _startReconnectionTimer();
        break;
      case SocketConnectionState.disconnectedByUser:
        emit(RealtimeConnectionStateX.disconnected(
          reason: 'Disconnected by user',
          canRetry: false,
        ));
        break;
      case SocketConnectionState.error:
        emit(RealtimeConnectionStateX.disconnected(
          reason: 'Connection error',
          canRetry: true,
        ));
        _startReconnectionTimer();
        break;
    }
  }

  /// **Handle network connectivity changes**
  Future<void> _onNetworkConnectivityChanged(
    NetworkConnectivityChanged event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    _logger.d('Network connectivity changed: ${event.isConnected}');

    if (event.isConnected) {
      // Network restored, attempt reconnection if disconnected
      if (state is RealtimeConnectionDisconnected) {
        // Always reset attempts when real network comes back.
        // Previous attempts failed because there was no network,
        // not because the server is unreachable.
        _reconnectionAttempts = 0;
        _reconnectionTimer?.cancel();
        _logger.i('Network restored, resetting attempts and reconnecting');
        add(const ReconnectToRealtime());
      }
    } else {
      // Network lost
      if (state is RealtimeConnectionConnected || state is RealtimeConnectionConnecting) {
        emit(RealtimeConnectionStateX.disconnected(
          reason: 'Mất kết nối mạng',
          canRetry: true,
        ));
      }
    }
  }

  /// **Initialize connection monitoring - ENTERPRISE MONITORING**
  void _initializeConnectionMonitoring() {
    _logger.i('Initializing connection monitoring');

    // Monitor real-time service connection state
    _subscriptions.add(
      _realtimeService.connectionState.listen(
        (socketState) {
          add(RealtimeConnectionStateChanged(socketState: socketState));
        },
        onError: (error) {
          _logger.e('Error in connection state stream: $error');
        },
      ),
    );

    // Monitor network connectivity
    _subscriptions.add(
      _connectivityService.onConnectivityChanged.listen(
        (isConnected) {
          add(NetworkConnectivityChanged(isConnected: isConnected));
        },
        onError: (error) {
          _logger.e('Error in connectivity stream: $error');
        },
      ),
    );

    _logger.i('Connection monitoring initialized');
  }

  /// **Start reconnection timer with exponential backoff**
  void _startReconnectionTimer() {
    _reconnectionTimer?.cancel();
    
    final delay = Duration(
      milliseconds: _baseReconnectionDelay.inMilliseconds * 
          (1 << (_reconnectionAttempts - 1).clamp(0, 4)), // Max 32s delay
    );
    
    _logger.d('Starting reconnection timer: ${delay.inSeconds}s');
    
    _reconnectionTimer = Timer(delay, () {
      add(const ReconnectToRealtime());
    });
  }

  /// **Helper method to convert Failure to user-friendly error message**
  String _getErrorMessage(Failure failure) {
    if (failure is ConnectionFailure) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
    } else if (failure is ServerFailure) {
      return 'Lỗi server. Vui lòng thử lại sau.';
    } else {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Lỗi kết nối không xác định.';
    }
  }

  @override
  Future<void> close() {
    _logger.i('Closing RealtimeConnectionBloc');

    // Cancel reconnection timer
    _reconnectionTimer?.cancel();

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    return super.close();
  }
}
