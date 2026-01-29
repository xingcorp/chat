import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/theme/app_theme_data.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Provides theme data for the application
///
/// This class wraps [AppThemeData] and provides additional utility methods
/// for theme management and system UI configuration.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Returns the light theme data with custom extensions
  static ThemeData get lightTheme {
    return AppThemeData.lightTheme.copyWith(
      extensions: [AppThemeExtensions.light],
    );
  }

  /// Returns the dark theme data with custom extensions
  static ThemeData get darkTheme {
    return AppThemeData.darkTheme.copyWith(
      extensions: [AppThemeExtensions.dark],
    );
  }



  /// Updates the status bar to match the theme
  static void setStatusBarColor(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.backgroundDarkMode,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.background,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }
} 