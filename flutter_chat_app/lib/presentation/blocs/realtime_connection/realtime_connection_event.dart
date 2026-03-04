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

  const ConnectToRealtime({this.autoReconnect = true});

  @override
  List<Object> get props => [autoReconnect];
}

/// **Disconnect from real-time server event**
class DisconnectFromRealtime extends RealtimeConnectionEvent {
  final String? reason;
  final RealtimeConnectionIssueType issueType;

  const DisconnectFromRealtime({
    this.reason,
    this.issueType = RealtimeConnectionIssueType.unknown,
  });

  @override
  List<Object?> get props => [reason, issueType];
}

/// **Reconnect to real-time server event**
class ReconnectToRealtime extends RealtimeConnectionEvent {
  const ReconnectToRealtime();
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

  const NetworkConnectivityChanged({required this.isConnected});

  @override
  List<Object> get props => [isConnected];
}
