import 'package:flutter/material.dart';

/// **THEME EXTENSIONS**
///
/// Custom theme extensions for additional semantic colors not covered by Material Design.
/// Provides success, warning, info, and status indicator colors.
///
/// **Usage**:
/// ```dart
/// final extensions = Theme.of(context).appExtensions;
/// Container(color: extensions.successColor);
/// ```
class AppThemeExtensions extends ThemeExtension<AppThemeExtensions> {
  const AppThemeExtensions({
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.onlineColor,
    required this.awayColor,
    required this.offlineColor,
    required this.onSuccessColor,
    required this.onWarningColor,
    required this.onInfoColor,
    required this.primaryDarkMode,
  });

  /// Success color for positive actions and states
  final Color successColor;

  /// Warning color for cautionary messages
  final Color warningColor;

  /// Info color for informational messages
  final Color infoColor;

  /// Online status indicator color
  final Color onlineColor;

  /// Away status indicator color
  final Color awayColor;

  /// Offline status indicator color
  final Color offlineColor;
  
  /// Text color on success background
  final Color onSuccessColor;
  
  /// Text color on warning background
  final Color onWarningColor;
  
  /// Text color on info background
  final Color onInfoColor;
  
  /// Primary color for dark mode
  final Color primaryDarkMode;

  @override
  ThemeExtension<AppThemeExtensions> copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? onlineColor,
    Color? awayColor,
    Color? offlineColor,
    Color? onSuccessColor,
    Color? onWarningColor,
    Color? onInfoColor,
    Color? primaryDarkMode,
  }) {
    return AppThemeExtensions(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      onlineColor: onlineColor ?? this.onlineColor,
      awayColor: awayColor ?? this.awayColor,
      offlineColor: offlineColor ?? this.offlineColor,
      onSuccessColor: onSuccessColor ?? this.onSuccessColor,
      onWarningColor: onWarningColor ?? this.onWarningColor,
      onInfoColor: onInfoColor ?? this.onInfoColor,
      primaryDarkMode: primaryDarkMode ?? this.primaryDarkMode,
    );
  }

  @override
  ThemeExtension<AppThemeExtensions> lerp(
    covariant ThemeExtension<AppThemeExtensions>? other,
    double t,
  ) {
    if (other is! AppThemeExtensions) {
      return this;
    }
    return AppThemeExtensions(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      onlineColor: Color.lerp(onlineColor, other.onlineColor, t)!,
      awayColor: Color.lerp(awayColor, other.awayColor, t)!,
      offlineColor: Color.lerp(offlineColor, other.offlineColor, t)!,
      onSuccessColor: Color.lerp(onSuccessColor, other.onSuccessColor, t)!,
      onWarningColor: Color.lerp(onWarningColor, other.onWarningColor, t)!,
      onInfoColor: Color.lerp(onInfoColor, other.onInfoColor, t)!,
      primaryDarkMode: Color.lerp(primaryDarkMode, other.primaryDarkMode, t)!,
    );
  }

  /// Light theme extensions
  static const light = AppThemeExtensions(
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFFC107),
    infoColor: Color(0xFF2196F3),
    onlineColor: Color(0xFF4CAF50),
    awayColor: Color(0xFFFFC107),
    offlineColor: Color(0xFF9E9E9E),
    onSuccessColor: Color(0xFFFFFFFF),
    onWarningColor: Color(0xFF000000),
    onInfoColor: Color(0xFFFFFFFF),
    primaryDarkMode: Color(0xFF1976D2),
  );

  /// Dark theme extensions
  static const dark = AppThemeExtensions(
    successColor: Color(0xFF66BB6A),
    warningColor: Color(0xFFFFCA28),
    infoColor: Color(0xFF42A5F5),
    onlineColor: Color(0xFF66BB6A),
    awayColor: Color(0xFFFFCA28),
    offlineColor: Color(0xFFBDBDBD),
    onSuccessColor: Color(0xFF000000),
    onWarningColor: Color(0xFF000000),
    onInfoColor: Color(0xFF000000),
    primaryDarkMode: Color(0xFF90CAF9),
  );
}

/// Extension to access custom theme properties easily
extension ThemeExtensionsGetter on ThemeData {
  /// Get app-specific theme extensions
  AppThemeExtensions get appExtensions =>
      extension<AppThemeExtensions>() ?? AppThemeExtensions.light;
}
