part of 'app_bloc.dart';

/// Represents the application-wide state
class AppState extends Equatable {
  final ThemeMode themeMode;
  final Locale? locale;
  final bool isAppInitialized;

  /// Default constructor
  const AppState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.isAppInitialized = false,
  });

  /// Create a copy of the state with updated values
  AppState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isAppInitialized,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isAppInitialized: isAppInitialized ?? this.isAppInitialized,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, isAppInitialized];
} 