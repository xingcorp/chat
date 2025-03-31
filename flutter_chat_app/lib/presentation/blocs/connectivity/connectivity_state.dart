part of 'connectivity_bloc.dart';

/// Base class for connectivity states
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();
  
  @override
  List<Object> get props => [];
}

/// Initial loading state
class ConnectivityLoading extends ConnectivityState {
  const ConnectivityLoading();
}

/// Connected to network state
class ConnectivityConnected extends ConnectivityState {
  const ConnectivityConnected();
}

/// Disconnected from network state
class ConnectivityDisconnected extends ConnectivityState {
  const ConnectivityDisconnected();
} 