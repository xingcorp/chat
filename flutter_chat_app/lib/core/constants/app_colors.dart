/// **APP COLORS - CENTRALIZED COLOR PALETTE**
///
/// Professional color management following enterprise standards:
/// - No hardcoded color values in UI components
/// - Consistent color palette across the application
/// - Support for light and dark themes
/// - Semantic color naming for better maintainability
///
/// **Architecture:** Clean Architecture + Design System

import 'package:flutter/material.dart';

/// **APPLICATION COLORS**
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// **Primary Brand Colors**
  static const Color PRIMARY_BLUE = Color(0xFF2196F3);
  static const Color PRIMARY_BLUE_DARK = Color(0xFF1976D2);
  static const Color PRIMARY_BLUE_LIGHT = Color(0xFF64B5F6);
  
  static const Color SECONDARY_GREEN = Color(0xFF4CAF50);
  static const Color SECONDARY_GREEN_DARK = Color(0xFF388E3C);
  static const Color SECONDARY_GREEN_LIGHT = Color(0xFF81C784);

  /// **Accent Colors**
  static const Color ACCENT_ORANGE = Color(0xFFFF9800);
  static const Color ACCENT_PURPLE = Color(0xFF9C27B0);
  static const Color ACCENT_TEAL = Color(0xFF009688);

  /// **Neutral Colors**
  static const Color WHITE = Color(0xFFFFFFFF);
  static const Color BLACK = Color(0xFF000000);
  static const Color TRANSPARENT = Color(0x00000000);
  
  static const Color GREY_50 = Color(0xFFFAFAFA);
  static const Color GREY_100 = Color(0xFFF5F5F5);
  static const Color GREY_200 = Color(0xFFEEEEEE);
  static const Color GREY_300 = Color(0xFFE0E0E0);
  static const Color GREY_400 = Color(0xFFBDBDBD);
  static const Color GREY_500 = Color(0xFF9E9E9E);
  static const Color GREY_600 = Color(0xFF757575);
  static const Color GREY_700 = Color(0xFF616161);
  static const Color GREY_800 = Color(0xFF424242);
  static const Color GREY_900 = Color(0xFF212121);

  /// **Semantic Colors**
  static const Color SUCCESS = Color(0xFF4CAF50);
  static const Color SUCCESS_LIGHT = Color(0xFFE8F5E8);
  static const Color SUCCESS_DARK = Color(0xFF2E7D32);

  static const Color WARNING = Color(0xFFFF9800);
  static const Color WARNING_LIGHT = Color(0xFFFFF3E0);
  static const Color WARNING_DARK = Color(0xFFE65100);

  static const Color ERROR = Color(0xFFF44336);
  static const Color ERROR_LIGHT = Color(0xFFFFEBEE);
  static const Color ERROR_DARK = Color(0xFFD32F2F);

  static const Color INFO = Color(0xFF2196F3);
  static const Color INFO_LIGHT = Color(0xFFE3F2FD);
  static const Color INFO_DARK = Color(0xFF1565C0);

  /// **Chat-Specific Colors**
  static const Color MESSAGE_SENT = Color(0xFF2196F3);
  static const Color MESSAGE_RECEIVED = Color(0xFFE0E0E0);
  static const Color MESSAGE_SYSTEM = Color(0xFFFFEB3B);
  
  static const Color ONLINE_STATUS = Color(0xFF4CAF50);
  static const Color OFFLINE_STATUS = Color(0xFF9E9E9E);
  static const Color AWAY_STATUS = Color(0xFFFF9800);
  static const Color BUSY_STATUS = Color(0xFFF44336);

  /// **Connection Quality Colors**
  static const Color CONNECTION_EXCELLENT = Color(0xFF4CAF50);
  static const Color CONNECTION_GOOD = Color(0xFF8BC34A);
  static const Color CONNECTION_POOR = Color(0xFFFF9800);
  static const Color CONNECTION_DISCONNECTED = Color(0xFFF44336);

  /// **Background Colors**
  static const Color BACKGROUND_LIGHT = Color(0xFFFFFFFF);
  static const Color BACKGROUND_DARK = Color(0xFF121212);
  static const Color SURFACE_LIGHT = Color(0xFFFFFFFF);
  static const Color SURFACE_DARK = Color(0xFF1E1E1E);

  /// **Text Colors**
  static const Color TEXT_PRIMARY_LIGHT = Color(0xFF212121);
  static const Color TEXT_PRIMARY_DARK = Color(0xFFFFFFFF);
  static const Color TEXT_SECONDARY_LIGHT = Color(0xFF757575);
  static const Color TEXT_SECONDARY_DARK = Color(0xFFB3B3B3);
  static const Color TEXT_DISABLED_LIGHT = Color(0xFFBDBDBD);
  static const Color TEXT_DISABLED_DARK = Color(0xFF616161);

  /// **Border Colors**
  static const Color BORDER_LIGHT = Color(0xFFE0E0E0);
  static const Color BORDER_DARK = Color(0xFF424242);
  static const Color DIVIDER_LIGHT = Color(0xFFE0E0E0);
  static const Color DIVIDER_DARK = Color(0xFF424242);

  /// **Shadow Colors**
  static const Color SHADOW_LIGHT = Color(0x1F000000);
  static const Color SHADOW_DARK = Color(0x3F000000);

  /// **Overlay Colors**
  static const Color OVERLAY_LIGHT = Color(0x66000000);
  static const Color OVERLAY_DARK = Color(0x80000000);
  static const Color MODAL_BARRIER = Color(0x80000000);

  /// **Priority Colors**
  static const Color PRIORITY_LOW = Color(0xFF4CAF50);
  static const Color PRIORITY_NORMAL = Color(0xFF2196F3);
  static const Color PRIORITY_HIGH = Color(0xFFFF9800);
  static const Color PRIORITY_CRITICAL = Color(0xFFF44336);

  /// **Usage Examples:**
  /// 
  /// ```dart
  /// // ✅ CORRECT - Using color constants
  /// Container(
  ///   color: AppColors.PRIMARY_BLUE,
  ///   child: Text(
  ///     'Hello',
  ///     style: TextStyle(color: AppColors.TEXT_PRIMARY_LIGHT),
  ///   ),
  /// )
  /// 
  /// // ❌ INCORRECT - Hardcoded colors
  /// Container(
  ///   color: Color(0xFF2196F3),
  ///   child: Text(
  ///     'Hello',
  ///     style: TextStyle(color: Color(0xFF212121)),
  ///   ),
  /// )
  /// ```
}

/// **Theme-Aware Color Scheme**
class AppColorScheme {
  final bool isDark;
  
  const AppColorScheme({required this.isDark});

  /// **Primary Colors**
  Color get primary => isDark ? AppColors.PRIMARY_BLUE_LIGHT : AppColors.PRIMARY_BLUE;
  Color get primaryVariant => isDark ? AppColors.PRIMARY_BLUE : AppColors.PRIMARY_BLUE_DARK;
  Color get onPrimary => isDark ? AppColors.BLACK : AppColors.WHITE;

  /// **Secondary Colors**
  Color get secondary => isDark ? AppColors.SECONDARY_GREEN_LIGHT : AppColors.SECONDARY_GREEN;
  Color get secondaryVariant => isDark ? AppColors.SECONDARY_GREEN : AppColors.SECONDARY_GREEN_DARK;
  Color get onSecondary => isDark ? AppColors.BLACK : AppColors.WHITE;

  /// **Background Colors**
  Color get background => isDark ? AppColors.BACKGROUND_DARK : AppColors.BACKGROUND_LIGHT;
  Color get surface => isDark ? AppColors.SURFACE_DARK : AppColors.SURFACE_LIGHT;
  Color get onBackground => isDark ? AppColors.TEXT_PRIMARY_DARK : AppColors.TEXT_PRIMARY_LIGHT;
  Color get onSurface => isDark ? AppColors.TEXT_PRIMARY_DARK : AppColors.TEXT_PRIMARY_LIGHT;

  /// **Text Colors**
  Color get textPrimary => isDark ? AppColors.TEXT_PRIMARY_DARK : AppColors.TEXT_PRIMARY_LIGHT;
  Color get textSecondary => isDark ? AppColors.TEXT_SECONDARY_DARK : AppColors.TEXT_SECONDARY_LIGHT;
  Color get textDisabled => isDark ? AppColors.TEXT_DISABLED_DARK : AppColors.TEXT_DISABLED_LIGHT;

  /// **Border Colors**
  Color get border => isDark ? AppColors.BORDER_DARK : AppColors.BORDER_LIGHT;
  Color get divider => isDark ? AppColors.DIVIDER_DARK : AppColors.DIVIDER_LIGHT;

  /// **Shadow Colors**
  Color get shadow => isDark ? AppColors.SHADOW_DARK : AppColors.SHADOW_LIGHT;

  /// **Light Color Scheme**
  static const AppColorScheme light = AppColorScheme(isDark: false);

  /// **Dark Color Scheme**
  static const AppColorScheme dark = AppColorScheme(isDark: true);
}

/// **Material Color Palette Generator**
class AppMaterialColors {
  /// **Generate Material Color from Primary Color**
  static MaterialColor generateMaterialColor(Color color) {
    return MaterialColor(color.value, {
      50: _tintColor(color, 0.9),
      100: _tintColor(color, 0.8),
      200: _tintColor(color, 0.6),
      300: _tintColor(color, 0.4),
      400: _tintColor(color, 0.2),
      500: color,
      600: _shadeColor(color, 0.1),
      700: _shadeColor(color, 0.2),
      800: _shadeColor(color, 0.3),
      900: _shadeColor(color, 0.4),
    });
  }

  /// **Tint Color (Lighter)**
  static Color _tintColor(Color color, double factor) {
    return Color.fromRGBO(
      color.red + ((255 - color.red) * factor).round(),
      color.green + ((255 - color.green) * factor).round(),
      color.blue + ((255 - color.blue) * factor).round(),
      1,
    );
  }

  /// **Shade Color (Darker)**
  static Color _shadeColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red * (1 - factor)).round(),
      (color.green * (1 - factor)).round(),
      (color.blue * (1 - factor)).round(),
      1,
    );
  }

  /// **Primary Material Color**
  static final MaterialColor primarySwatch = generateMaterialColor(AppColors.PRIMARY_BLUE);
}
