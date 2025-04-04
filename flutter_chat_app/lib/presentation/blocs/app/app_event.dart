part of 'app_bloc.dart';

/// Base class for all app events
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when the app initializes
class AppInitialized extends AppEvent {
  const AppInitialized();
}

/// Event triggered when the theme mode is changed
class ThemeChanged extends AppEvent {
  final ThemeMode themeMode;
  
  const ThemeChanged(this.themeMode);
  
  @override
  List<Object> get props => [themeMode];
}

/// Event triggered when the locale is changed
class LocaleChanged extends AppEvent {
  final Locale locale;
  
  const LocaleChanged(this.locale);
  
  @override
  List<Object> get props => [locale];
}

/// Event triggered when app enters foreground
class AppEnteredForeground extends AppEvent {
  const AppEnteredForeground();
}

/// Event triggered when app enters background
class AppEnteredBackground extends AppEvent {
  const AppEnteredBackground();
}

/// Event triggered when a socket connection is requested
class SocketConnectionRequested extends AppEvent {
  const SocketConnectionRequested();
}

/// Event triggered when a socket connection is closed
class SocketConnectionClosed extends AppEvent {
  const SocketConnectionClosed();
}

/// Event triggered when socket connection state changes
class SocketConnectionStateChanged extends AppEvent {
  final SocketConnectionState state;
  
  const SocketConnectionStateChanged(this.state);
  
  @override
  List<Object> get props => [state];
} 