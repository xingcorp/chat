part of 'theme_cubit.dart';

/// **ENTERPRISE THEME STATE**
///
/// Represents the current theme state with performance metrics and enterprise features
class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;
  final bool isDynamicColorsEnabled;
  final Duration? lastSwitchDuration;
  final DateTime? lastThemeChange;
  final String? error;

  /// Default constructor
  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.isLoading = false,
    this.isDynamicColorsEnabled = false,
    this.lastSwitchDuration,
    this.lastThemeChange,
    this.error,
  });
  
  /// Create a copy with updated values
  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
    bool? isDynamicColorsEnabled,
    Duration? lastSwitchDuration,
    DateTime? lastThemeChange,
    String? error,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
      isDynamicColorsEnabled: isDynamicColorsEnabled ?? this.isDynamicColorsEnabled,
      lastSwitchDuration: lastSwitchDuration ?? this.lastSwitchDuration,
      lastThemeChange: lastThemeChange ?? this.lastThemeChange,
      error: error,
    );
  }
  
  /// Check if current theme is dark
  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  /// Check if performance is optimal (<100ms)
  bool get isPerformanceOptimal {
    return lastSwitchDuration == null || lastSwitchDuration!.inMilliseconds <= 100;
  }

  /// Check if there's an error
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeState &&
        other.themeMode == themeMode &&
        other.isLoading == isLoading &&
        other.isDynamicColorsEnabled == isDynamicColorsEnabled &&
        other.lastSwitchDuration == lastSwitchDuration &&
        other.lastThemeChange == lastThemeChange &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    isLoading,
    isDynamicColorsEnabled,
    lastSwitchDuration,
    lastThemeChange,
    error,
  );

  @override
  String toString() {
    return 'ThemeState('
        'themeMode: $themeMode, '
        'isLoading: $isLoading, '
        'isDynamicColors: $isDynamicColorsEnabled, '
        'performance: ${lastSwitchDuration?.inMilliseconds}ms, '
        'error: $error'
        ')';
  }
}
