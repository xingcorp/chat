import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();
  
  @override
  List<Object?> get props => [];
}

class ConnectRequested extends ConnectionEvent {
  const ConnectRequested();
}

class DisconnectRequested extends ConnectionEvent {
  const DisconnectRequested();
}

class ConnectionStateChanged extends ConnectionEvent {
  final ConnectionState connectionState;
  final ConnectionType connectionType;
  
  const ConnectionStateChanged({
    required this.connectionState,
    required this.connectionType,
  });
  
  @override
  List<Object?> get props => [connectionState, connectionType];
}

class NetworkQualityChanged extends ConnectionEvent {
  final NetworkQuality networkQuality;
  
  const NetworkQualityChanged({
    required this.networkQuality,
  });
  
  @override
  List<Object?> get props => [networkQuality];
}

// States
class ConnectionState extends Equatable {
  final bool isConnected;
  final bool isConnecting;
  final ConnectionType connectionType;
  final NetworkQuality networkQuality;
  final String? errorMessage;
  
  const ConnectionState({
    required this.isConnected,
    required this.isConnecting,
    required this.connectionType,
    required this.networkQuality,
    this.errorMessage,
  });
  
  factory ConnectionState.initial() => const ConnectionState(
    isConnected: false,
    isConnecting: false,
    connectionType: ConnectionType.none,
    networkQuality: NetworkQuality.none,
  );
  
  ConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    ConnectionType? connectionType,
    NetworkQuality? networkQuality,
    String? errorMessage,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      connectionType: connectionType ?? this.connectionType,
      networkQuality: networkQuality ?? this.networkQuality,
      errorMessage: errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    isConnected,
    isConnecting,
    connectionType,
    networkQuality,
    errorMessage,
  ];
}

// BLoC
@injectable
class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final RealtimeConnectionService _realtimeConnectionService;
  final ConnectivityAnalyzerService _connectivityAnalyzerService;
  
  late final StreamSubscription<dynamic> _connectionStateSubscription;
  late final StreamSubscription<dynamic> _connectionTypeSubscription;
  late final StreamSubscription<dynamic> _networkQualitySubscription;
  
  ConnectionBloc({
    required RealtimeConnectionService realtimeConnectionService,
    required ConnectivityAnalyzerService connectivityAnalyzerService,
  }) : _realtimeConnectionService = realtimeConnectionService,
       _connectivityAnalyzerService = connectivityAnalyzerService,
       super(ConnectionState.initial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<NetworkQualityChanged>(_onNetworkQualityChanged);
    
    // Lắng nghe sự thay đổi trạng thái kết nối
    _connectionStateSubscription = _realtimeConnectionService.connectionStateStream
        .listen(_handleConnectionStateChange);
    
    // Lắng nghe sự thay đổi loại kết nối
    _connectionTypeSubscription = _realtimeConnectionService.connectionTypeStream
        .listen(_handleConnectionTypeChange);
    
    // Lắng nghe sự thay đổi chất lượng mạng
    _networkQualitySubscription = _connectivityAnalyzerService.qualityStream
        .listen(_handleNetworkQualityChange);
  }
  
  @override
  Future<void> close() {
    _connectionStateSubscription.cancel();
    _connectionTypeSubscription.cancel();
    _networkQualitySubscription.cancel();
    return super.close();
  }
  
  void _handleConnectionStateChange(core.services.realtime_connection_service.ConnectionState state) {
    final bool isConnected = state == core.services.realtime_connection_service.ConnectionState.connected;
    final bool isConnecting = state == core.services.realtime_connection_service.ConnectionState.connecting || 
                              state == core.services.realtime_connection_service.ConnectionState.reconnecting;
    
    add(ConnectionStateChanged(
      connectionState: state,
      connectionType: _realtimeConnectionService.connectionType,
    ));
  }
  
  void _handleConnectionTypeChange(ConnectionType type) {
    add(ConnectionStateChanged(
      connectionState: _realtimeConnectionService.connectionState,
      connectionType: type,
    ));
  }
  
  void _handleNetworkQualityChange(NetworkQuality quality) {
    add(NetworkQualityChanged(networkQuality: quality));
  }
  
  Future<void> _onConnectRequested(
    ConnectRequested event,
    Emitter<ConnectionState> emit,
  ) async {
    try {
      emit(state.copyWith(
        isConnecting: true,
        errorMessage: null,
      ));
      
      await _realtimeConnectionService.connect();
    } catch (e) {
      emit(state.copyWith(
        isConnecting: false,
        errorMessage: 'Không thể kết nối: $e',
      ));
    }
  }
  
  Future<void> _onDisconnectRequested(
    DisconnectRequested event,
    Emitter<ConnectionState> emit,
  ) async {
    try {
      await _realtimeConnectionService.disconnect();
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Lỗi ngắt kết nối: $e',
      ));
    }
  }
  
  void _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<ConnectionState> emit,
  ) {
    final bool isConnected = event.connectionState == core.services.realtime_connection_service.ConnectionState.connected;
    final bool isConnecting = event.connectionState == core.services.realtime_connection_service.ConnectionState.connecting || 
                              event.connectionState == core.services.realtime_connection_service.ConnectionState.reconnecting;
    
    emit(state.copyWith(
      isConnected: isConnected,
      isConnecting: isConnecting,
      connectionType: event.connectionType,
      errorMessage: null,
    ));
  }
  
  void _onNetworkQualityChanged(
    NetworkQualityChanged event,
    Emitter<ConnectionState> emit,
  ) {
    emit(state.copyWith(
      networkQuality: event.networkQuality,
    ));
  }
} 