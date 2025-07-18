part of 'connectivity_bloc.dart';

/// Base class for connectivity events
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when starting connectivity monitoring
class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

/// Event triggered when connectivity changes
class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> connectivityResults;

  const ConnectivityChanged(this.connectivityResults);

  @override
  List<Object> get props => [connectivityResults];
}