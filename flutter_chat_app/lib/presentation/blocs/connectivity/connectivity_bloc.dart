import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

/// Manages network connectivity state
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityBloc(this._connectivity) : super(const ConnectivityLoading()) {
    on<ConnectivityStarted>(_onConnectivityStarted);
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  /// Start monitoring connectivity
  Future<void> _onConnectivityStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _connectivitySubscription?.cancel();
    
    // Initialize with current connectivity state
    final connectivityResult = await _connectivity.checkConnectivity();
    _emitConnectivityState(connectivityResult, emit);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) => add(ConnectivityChanged(result)),
    );
  }

  /// Handle connectivity change
  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    _emitConnectivityState(event.connectivityResult, emit);
  }

  /// Convert connectivity result to appropriate state
  void _emitConnectivityState(
    ConnectivityResult result,
    Emitter<ConnectivityState> emit,
  ) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        emit(const ConnectivityConnected());
        break;
      case ConnectivityResult.none:
        emit(const ConnectivityDisconnected());
        break;
      default:
        emit(const ConnectivityDisconnected());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
} 