import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

/// Manages network connectivity state
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
    final connectivityResults = await _connectivity.checkConnectivity();
    _emitConnectivityState(connectivityResults, emit);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) => add(ConnectivityChanged(results)),
    );
  }

  /// Handle connectivity change
  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    _emitConnectivityState(event.connectivityResults, emit);
  }

  /// Convert connectivity results to appropriate state
  void _emitConnectivityState(
    List<ConnectivityResult> results,
    Emitter<ConnectivityState> emit,
  ) {
    // Check if any result indicates connection
    final hasConnection = results.any((result) =>
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn ||
      result == ConnectivityResult.bluetooth ||
      result == ConnectivityResult.other
    );

    if (hasConnection) {
      emit(const ConnectivityConnected());
    } else {
      emit(const ConnectivityDisconnected());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
} 