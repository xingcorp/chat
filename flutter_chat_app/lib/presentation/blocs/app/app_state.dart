part of 'app_bloc.dart';

/// Represents the application-wide state
class AppState extends Equatable {
  final ThemeMode themeMode;
  final Locale? locale;
  final bool isAppInitialized;
  final bool isAuthenticated;
  final bool isInBackground;
  final SocketConnectionState socketConnectionState;

  /// Default constructor
  const AppState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.isAppInitialized = false,
    this.isAuthenticated = false,
    this.isInBackground = false,
    this.socketConnectionState = SocketConnectionState.disconnected,
  });

  /// Create a copy of the state with updated values
  AppState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isAppInitialized,
    bool? isAuthenticated,
    bool? isInBackground,
    SocketConnectionState? socketConnectionState,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isAppInitialized: isAppInitialized ?? this.isAppInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInBackground: isInBackground ?? this.isInBackground,
      socketConnectionState: socketConnectionState ?? this.socketConnectionState,
    );
  }

  @override
  List<Object?> get props => [
    themeMode, 
    locale, 
    isAppInitialized,
    isAuthenticated,
    isInBackground,
    socketConnectionState,
  ];
} 