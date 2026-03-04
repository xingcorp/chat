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
/// with RealtimeService and ConnectivityService integration using `Either<Failure, T>`.
///
/// **Performance Targets:**
/// - Connection establishment: <2s
/// - Reconnection attempts: <5s with exponential backoff
/// - Connection health checks: <100ms
/// - Memory usage: <20MB for connection management
///
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
@injectable
class RealtimeConnectionBloc
    extends Bloc<RealtimeConnectionEvent, RealtimeConnectionState> {
  final RealtimeService _realtimeService;
  final ConnectivityService _connectivityService;
  final Logger _logger = Logger();

  // Active subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  // Reconnection management
  Timer? _reconnectionTimer;
  int? _scheduledReconnectionAttempt;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _baseReconnectionDelay = Duration(seconds: 2);

  /// Constructor
  RealtimeConnectionBloc({
    required RealtimeService realtimeService,
    required ConnectivityService connectivityService,
  })  : _realtimeService = realtimeService,
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

  @override
  void onEvent(RealtimeConnectionEvent event) {
    _logger.d(
      '[RTC][event] ${event.runtimeType} '
      '${_describeEvent(event)} current=${state.runtimeType}',
    );
    super.onEvent(event);
  }

  @override
  void onTransition(
    Transition<RealtimeConnectionEvent, RealtimeConnectionState> transition,
  ) {
    _logger.d(
      '[RTC][transition] ${transition.currentState.runtimeType} '
      '-> ${transition.nextState.runtimeType} '
      'via ${transition.event.runtimeType} ${_describeEvent(transition.event)}',
    );
    super.onTransition(transition);
  }

  /// **Connect to real-time server - ENTERPRISE CONNECTION**
  ///
  /// **Performance**: <2s connection establishment
  /// **Strategy**: Connection with comprehensive error handling
  Future<void> _onConnectToRealtime(
    ConnectToRealtime event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    if (state is RealtimeConnectionConnecting ||
        state is RealtimeConnectionConnected ||
        state is RealtimeConnectionReconnecting) {
      _logger.d(
        '[RTC] Skip connect (source=${event.source}) '
        'because state=${state.runtimeType}',
      );
      return;
    }

    _logger.i('[RTC] Connecting to real-time server (source=${event.source})');
    _emitIfChanged(
      emit,
      RealtimeConnectionStateX.connecting,
      reason: 'connect requested',
    );

    final result = await _realtimeService.connect();

    result.fold(
      (failure) {
        _logger.e('Failed to connect to real-time server: ${failure.message}');
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: _getErrorMessage(failure),
            canRetry: true,
            issueType: _mapIssueType(failure),
          ),
          reason: 'connect failed',
        );

        // Start automatic reconnection if enabled
        if (event.autoReconnect) {
          _startReconnectionTimer();
        }
      },
      (success) {
        _logger.i('Successfully connected to real-time server');
        _cancelReconnectionTimer(reason: 'connected');
        _reconnectionAttempts = 0; // Reset attempts on successful connection
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.connected,
          reason: 'connect success',
        );
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
    _logger.i(
      '[RTC] Disconnecting from real-time server '
      '(source=${event.source}, issueType=${event.issueType})',
    );

    _cancelReconnectionTimer(reason: 'manual disconnect');
    _reconnectionAttempts = 0;

    _emitIfChanged(
      emit,
      RealtimeConnectionStateX.disconnecting,
      reason: 'disconnect requested',
    );

    final result = await _realtimeService.disconnect();

    result.fold(
      (failure) {
        _logger.e('Error during disconnection: ${failure.message}');
        // Still emit disconnected state even if there was an error
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: event.reason ?? 'Disconnected by user',
            canRetry: false,
            issueType: event.issueType,
          ),
          reason: 'disconnect completed with error',
        );
      },
      (success) {
        _logger.i('Successfully disconnected from real-time server');
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: event.reason ?? 'Disconnected by user',
            canRetry: false,
            issueType: event.issueType,
          ),
          reason: 'disconnect completed',
        );
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
    if (state is RealtimeConnectionConnected ||
        state is RealtimeConnectionConnecting ||
        state is RealtimeConnectionReconnecting) {
      _logger.d(
        '[RTC] Skip reconnect (source=${event.source}) '
        'because state=${state.runtimeType}',
      );
      return;
    }

    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      _logger.w(
        '[RTC] Max reconnection attempts reached '
        '(source=${event.source})',
      );
      emit(RealtimeConnectionStateX.disconnected(
        reason: 'Không thể kết nối lại sau $_maxReconnectionAttempts lần thử',
        canRetry: false,
        issueType: RealtimeConnectionIssueType.server,
      ));
      return;
    }

    _reconnectionAttempts++;
    _cancelReconnectionTimer(reason: 'reconnect in progress');
    _logger.i(
      '[RTC] Reconnection attempt '
      '$_reconnectionAttempts/$_maxReconnectionAttempts '
      '(source=${event.source})',
    );

    _emitIfChanged(
      emit,
      RealtimeConnectionStateX.reconnecting(attempt: _reconnectionAttempts),
      reason: 'reconnect attempt started',
    );

    // Check network connectivity first
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      _logger.w(
        '[RTC] No network connectivity, delaying reconnection '
        '(source=${event.source})',
      );
      _emitIfChanged(
        emit,
        RealtimeConnectionStateX.disconnected(
          reason: 'No internet connection',
          canRetry: true,
          issueType: RealtimeConnectionIssueType.network,
        ),
        reason: 'reconnect blocked by offline',
      );
      _startReconnectionTimer();
      return;
    }

    final result = await _realtimeService.connect();

    result.fold(
      (failure) {
        _logger.e(
            'Reconnection attempt $_reconnectionAttempts failed: ${failure.message}');

        if (_reconnectionAttempts < _maxReconnectionAttempts) {
          _emitIfChanged(
            emit,
            RealtimeConnectionStateX.disconnected(
              reason:
                  'Đang thử kết nối lại... ($_reconnectionAttempts/$_maxReconnectionAttempts)',
              canRetry: true,
              issueType: _mapIssueType(failure),
            ),
            reason: 'reconnect failed, scheduling next',
          );
          _startReconnectionTimer();
        } else {
          _emitIfChanged(
            emit,
            RealtimeConnectionStateX.disconnected(
              reason:
                  'Không thể kết nối lại sau $_maxReconnectionAttempts lần thử',
              canRetry: false,
              issueType: _mapIssueType(failure),
            ),
            reason: 'reconnect exhausted',
          );
        }
      },
      (success) {
        _logger
            .i('Reconnection successful after $_reconnectionAttempts attempts');
        _reconnectionAttempts = 0;
        _cancelReconnectionTimer(reason: 'reconnect success');
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.connected,
          reason: 'reconnect success',
        );
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
        _logger.t(
            'Connection health: latency=${health.latency}ms, connected=${health.isConnected}');
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
    if (_shouldIgnoreSocketState(socketState)) {
      return;
    }

    switch (socketState) {
      case SocketConnectionState.connected:
        _reconnectionAttempts = 0;
        _cancelReconnectionTimer(reason: 'socket connected');
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.connected,
          reason: 'socket connected',
        );
        break;
      case SocketConnectionState.connecting:
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.connecting,
          reason: 'socket connecting',
        );
        break;
      case SocketConnectionState.reconnecting:
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.reconnecting(
            attempt: _reconnectionAttempts > 0 ? _reconnectionAttempts : 1,
          ),
          reason: 'socket reconnecting',
        );
        break;
      case SocketConnectionState.disconnected:
      case SocketConnectionState.disconnectedByServer:
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: 'Connection lost',
            canRetry: true,
            issueType: RealtimeConnectionIssueType.server,
          ),
          reason: 'socket disconnected',
        );
        _startReconnectionTimer();
        break;
      case SocketConnectionState.disconnectedByUser:
        _cancelReconnectionTimer(reason: 'socket disconnected by user');
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: 'Disconnected by user',
            canRetry: false,
            issueType: RealtimeConnectionIssueType.unknown,
          ),
          reason: 'socket disconnected by user',
        );
        break;
      case SocketConnectionState.error:
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: 'Connection error',
            canRetry: true,
            issueType: RealtimeConnectionIssueType.server,
          ),
          reason: 'socket error',
        );
        _startReconnectionTimer();
        break;
    }
  }

  /// **Handle network connectivity changes**
  Future<void> _onNetworkConnectivityChanged(
    NetworkConnectivityChanged event,
    Emitter<RealtimeConnectionState> emit,
  ) async {
    _logger.d(
      '[RTC] Network connectivity changed: '
      'isConnected=${event.isConnected}, source=${event.source}, '
      'state=${state.runtimeType}',
    );

    if (event.isConnected) {
      // Network restored, attempt reconnection if disconnected
      if (state is RealtimeConnectionDisconnected) {
        final disconnected = state as RealtimeConnectionDisconnected;
        if (!disconnected.canRetry) {
          _logger.d(
            '[RTC] Skip reconnect on network restore because canRetry=false '
            '(issueType=${disconnected.issueType})',
          );
          return;
        }
        if (disconnected.issueType == RealtimeConnectionIssueType.auth) {
          _logger.d(
            '[RTC] Skip reconnect on network restore due to auth disconnect',
          );
          return;
        }

        // Always reset attempts when real network comes back.
        // Previous attempts failed because there was no network,
        // not because the server is unreachable.
        _reconnectionAttempts = 0;
        _cancelReconnectionTimer(reason: 'network restored');
        _logger.i('Network restored, resetting attempts and reconnecting');
        add(const ReconnectToRealtime(source: 'network_restored'));
      }
    } else {
      // Network lost
      if (state is RealtimeConnectionConnected ||
          state is RealtimeConnectionConnecting) {
        _emitIfChanged(
          emit,
          RealtimeConnectionStateX.disconnected(
            reason: 'Mất kết nối mạng',
            canRetry: true,
            issueType: RealtimeConnectionIssueType.network,
          ),
          reason: 'network offline',
        );
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
          add(
            NetworkConnectivityChanged(
              isConnected: isConnected,
              source: 'connectivity_stream',
            ),
          );
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
    if (state is RealtimeConnectionDisconnected) {
      final disconnected = state as RealtimeConnectionDisconnected;
      if (!disconnected.canRetry) {
        _logger.d(
          '[RTC] Skip reconnect timer because current state is non-retryable '
          '(issueType=${disconnected.issueType})',
        );
        return;
      }
    }

    final attemptForDelay =
        _reconnectionAttempts <= 0 ? 1 : _reconnectionAttempts;
    if (_reconnectionTimer?.isActive == true &&
        _scheduledReconnectionAttempt == attemptForDelay) {
      _logger.d(
        '[RTC] Reconnection timer already scheduled '
        '(attempt=$attemptForDelay)',
      );
      return;
    }
    _reconnectionTimer?.cancel();

    final delay = Duration(
      milliseconds: _baseReconnectionDelay.inMilliseconds *
          (1 << (attemptForDelay - 1).clamp(0, 4)), // Max 32s delay
    );

    _scheduledReconnectionAttempt = attemptForDelay;
    _logger.d(
      'Starting reconnection timer: ${delay.inSeconds}s '
      '(attempt=$attemptForDelay)',
    );

    _reconnectionTimer = Timer(delay, () {
      _reconnectionTimer = null;
      _scheduledReconnectionAttempt = null;
      add(const ReconnectToRealtime(source: 'auto_timer'));
    });
  }

  bool _isSocketDisconnectedState(SocketConnectionState socketState) {
    return socketState == SocketConnectionState.disconnected ||
        socketState == SocketConnectionState.disconnectedByServer ||
        socketState == SocketConnectionState.disconnectedByUser ||
        socketState == SocketConnectionState.error;
  }

  bool _shouldIgnoreSocketState(SocketConnectionState socketState) {
    if (state is RealtimeConnectionInitial &&
        _isSocketDisconnectedState(socketState)) {
      _logger.d('[RTC] Ignore initial disconnected socket event');
      return true;
    }

    if (state is RealtimeConnectionDisconnecting &&
        _isSocketDisconnectedState(socketState)) {
      _logger.d(
        '[RTC] Ignore disconnected socket event during explicit disconnect',
      );
      return true;
    }

    if (state is RealtimeConnectionDisconnected &&
        _isSocketDisconnectedState(socketState)) {
      final disconnected = state as RealtimeConnectionDisconnected;
      if (!disconnected.canRetry) {
        _logger.d(
          '[RTC] Ignore disconnected socket event because reconnect is disabled '
          '(issueType=${disconnected.issueType})',
        );
        return true;
      }
    }

    return false;
  }

  void _cancelReconnectionTimer({required String reason}) {
    if (_reconnectionTimer?.isActive == true) {
      _logger.d('[RTC] Cancel reconnection timer ($reason)');
    }
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _scheduledReconnectionAttempt = null;
  }

  void _emitIfChanged(
    Emitter<RealtimeConnectionState> emit,
    RealtimeConnectionState nextState, {
    required String reason,
  }) {
    if (state == nextState) {
      _logger.d(
        '[RTC] Ignore duplicate state ${nextState.runtimeType} ($reason)',
      );
      return;
    }
    emit(nextState);
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

  RealtimeConnectionIssueType _mapIssueType(Failure failure) {
    if (failure is ConnectionFailure) {
      return RealtimeConnectionIssueType.network;
    }
    if (failure is ServerFailure) {
      return RealtimeConnectionIssueType.server;
    }
    return RealtimeConnectionIssueType.unknown;
  }

  String _describeEvent(RealtimeConnectionEvent event) {
    if (event is ConnectToRealtime) {
      return '(source=${event.source}, autoReconnect=${event.autoReconnect})';
    }
    if (event is DisconnectFromRealtime) {
      return '(source=${event.source}, issueType=${event.issueType}, reason=${event.reason})';
    }
    if (event is ReconnectToRealtime) {
      return '(source=${event.source})';
    }
    if (event is NetworkConnectivityChanged) {
      return '(source=${event.source}, isConnected=${event.isConnected})';
    }
    return '';
  }

  @override
  Future<void> close() {
    _logger.i('Closing RealtimeConnectionBloc');

    // Cancel reconnection timer
    _cancelReconnectionTimer(reason: 'bloc closed');

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    return super.close();
  }
}
