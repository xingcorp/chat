part of 'realtime_connection_bloc.dart';

/// **Abstract class for RealtimeConnection BLoC events**
abstract class RealtimeConnectionEvent extends Equatable {
  const RealtimeConnectionEvent();

  @override
  List<Object?> get props => [];
}

/// **Connect to real-time server event**
class ConnectToRealtime extends RealtimeConnectionEvent {
  final bool autoReconnect;
  final String source;

  const ConnectToRealtime({
    this.autoReconnect = true,
    this.source = 'unknown',
  });

  @override
  List<Object> get props => [autoReconnect, source];
}

/// **Disconnect from real-time server event**
class DisconnectFromRealtime extends RealtimeConnectionEvent {
  final String? reason;
  final RealtimeConnectionIssueType issueType;
  final String source;

  const DisconnectFromRealtime({
    this.reason,
    this.issueType = RealtimeConnectionIssueType.unknown,
    this.source = 'unknown',
  });

  @override
  List<Object?> get props => [reason, issueType, source];
}

/// **Reconnect to real-time server event**
class ReconnectToRealtime extends RealtimeConnectionEvent {
  final String source;

  const ReconnectToRealtime({this.source = 'unknown'});

  @override
  List<Object> get props => [source];
}

/// **Check connection health event**
class CheckConnectionHealth extends RealtimeConnectionEvent {
  const CheckConnectionHealth();
}

/// **Connection state changed event (internal)**
class RealtimeConnectionStateChanged extends RealtimeConnectionEvent {
  final SocketConnectionState socketState;

  const RealtimeConnectionStateChanged({required this.socketState});

  @override
  List<Object> get props => [socketState];
}

/// **Network connectivity changed event (internal)**
class NetworkConnectivityChanged extends RealtimeConnectionEvent {
  final bool isConnected;
  final String source;

  const NetworkConnectivityChanged({
    required this.isConnected,
    this.source = 'connectivity_stream',
  });

  @override
  List<Object> get props => [isConnected, source];
}
