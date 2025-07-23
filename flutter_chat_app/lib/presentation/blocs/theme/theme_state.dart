part of 'theme_cubit.dart';

/// **THEME STATE**
/// 
/// Represents the current theme state of the application
class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;
  
  /// Default constructor
  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.isLoading = false,
  });
  
  /// Create a copy with updated values
  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ThemeState &&
        other.themeMode == themeMode &&
        other.isLoading == isLoading;
  }
  
  @override
  int get hashCode => themeMode.hashCode ^ isLoading.hashCode;
  
  @override
  String toString() {
    return 'ThemeState(themeMode: $themeMode, isLoading: $isLoading)';
  }
}
