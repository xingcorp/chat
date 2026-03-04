part of 'realtime_connection_bloc.dart';

/// **Abstract class for RealtimeConnection BLoC states**
abstract class RealtimeConnectionState extends Equatable {
  const RealtimeConnectionState();

  @override
  List<Object?> get props => [];
}

/// **Semantic issue type for disconnected state**
enum RealtimeConnectionIssueType {
  network,
  server,
  auth,
  unknown,
}

/// **Initial state**
class RealtimeConnectionInitial extends RealtimeConnectionState {
  const RealtimeConnectionInitial();
}

/// **Connecting state**
class RealtimeConnectionConnecting extends RealtimeConnectionState {
  const RealtimeConnectionConnecting();
}

/// **Connected state**
class RealtimeConnectionConnected extends RealtimeConnectionState {
  const RealtimeConnectionConnected();
}

/// **Disconnecting state**
class RealtimeConnectionDisconnecting extends RealtimeConnectionState {
  const RealtimeConnectionDisconnecting();
}

/// **Disconnected state**
class RealtimeConnectionDisconnected extends RealtimeConnectionState {
  final String reason;
  final bool canRetry;
  final RealtimeConnectionIssueType issueType;

  const RealtimeConnectionDisconnected({
    required this.reason,
    required this.canRetry,
    this.issueType = RealtimeConnectionIssueType.unknown,
  });

  @override
  List<Object> get props => [reason, canRetry, issueType];
}

/// **Reconnecting state**
class RealtimeConnectionReconnecting extends RealtimeConnectionState {
  final int attempt;

  const RealtimeConnectionReconnecting({required this.attempt});

  @override
  List<Object> get props => [attempt];
}

/// **Health check completed state**
class RealtimeConnectionHealthChecked extends RealtimeConnectionState {
  final ConnectionHealth health;

  const RealtimeConnectionHealthChecked({required this.health});

  @override
  List<Object> get props => [health];
}

/// **Health check failed state**
class RealtimeConnectionHealthCheckFailed extends RealtimeConnectionState {
  final String reason;

  const RealtimeConnectionHealthCheckFailed({required this.reason});

  @override
  List<Object> get props => [reason];
}

/// **Extension for convenient state creation**
extension RealtimeConnectionStateX on RealtimeConnectionState {
  static const RealtimeConnectionInitial initial = RealtimeConnectionInitial();
  static const RealtimeConnectionConnecting connecting =
      RealtimeConnectionConnecting();
  static const RealtimeConnectionConnected connected =
      RealtimeConnectionConnected();
  static const RealtimeConnectionDisconnecting disconnecting =
      RealtimeConnectionDisconnecting();

  static RealtimeConnectionDisconnected disconnected({
    required String reason,
    required bool canRetry,
    RealtimeConnectionIssueType issueType = RealtimeConnectionIssueType.unknown,
  }) =>
      RealtimeConnectionDisconnected(
        reason: reason,
        canRetry: canRetry,
        issueType: issueType,
      );

  static RealtimeConnectionReconnecting reconnecting({required int attempt}) =>
      RealtimeConnectionReconnecting(attempt: attempt);

  static RealtimeConnectionHealthChecked healthChecked(
          {required ConnectionHealth health}) =>
      RealtimeConnectionHealthChecked(health: health);

  static RealtimeConnectionHealthCheckFailed healthCheckFailed(
          {required String reason}) =>
      RealtimeConnectionHealthCheckFailed(reason: reason);
}
