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
  final ConnectivityResult connectivityResult;

  const ConnectivityChanged(this.connectivityResult);

  @override
  List<Object> get props => [connectivityResult];
} 