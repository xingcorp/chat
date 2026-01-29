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

  @override
  ThemeExtension<AppThemeExtensions> copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? onlineColor,
    Color? awayColor,
    Color? offlineColor,
  }) {
    return AppThemeExtensions(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      onlineColor: onlineColor ?? this.onlineColor,
      awayColor: awayColor ?? this.awayColor,
      offlineColor: offlineColor ?? this.offlineColor,
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
  );

  /// Dark theme extensions
  static const dark = AppThemeExtensions(
    successColor: Color(0xFF66BB6A),
    warningColor: Color(0xFFFFCA28),
    infoColor: Color(0xFF42A5F5),
    onlineColor: Color(0xFF66BB6A),
    awayColor: Color(0xFFFFCA28),
    offlineColor: Color(0xFFBDBDBD),
  );
}

/// Extension to access custom theme properties easily
extension ThemeExtensionsGetter on ThemeData {
  /// Get app-specific theme extensions
  AppThemeExtensions get appExtensions =>
      extension<AppThemeExtensions>() ?? AppThemeExtensions.light;
}
