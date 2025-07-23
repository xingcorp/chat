import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// Provides theme data for the application
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Returns the light theme data
  static ThemeData get lightTheme {
    return _createTheme(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      backgroundColor: AppColors.background,
      isDark: false,
    );
  }

  /// Returns the dark theme data
  static ThemeData get darkTheme {
    return _createTheme(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      backgroundColor: AppColors.backgroundDarkMode,
      isDark: true,
    );
  }

  /// Creates a theme with the specified parameters
  static ThemeData _createTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required bool isDark,
  }) {
    // Create color scheme based on theme mode
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      onSurface: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
    );

    // System overlay style based on theme mode
    final SystemUiOverlayStyle systemOverlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.backgroundDarkMode,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        foregroundColor: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: systemOverlayStyle,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.inputBackgroundDarkMode : AppColors.inputBackground,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.error, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      cardTheme: CardTheme(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDarkMode : Colors.grey[800],
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? AppColors.inputBackgroundDarkMode : Colors.white;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey[400]! : Colors.grey[50]!;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.4);
          }
          return isDark ? Colors.grey[700]! : Colors.grey[300]!;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: isDark ? AppColors.backgroundDarkMode : AppColors.background,
        linearTrackColor: isDark ? AppColors.backgroundDarkMode : AppColors.background,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withOpacity(0.3),
        selectionHandleColor: primaryColor,
      ),
      // Set default text theme for the app
      textTheme: _buildTextTheme(isDark),
    );
  }

  /// Builds the text theme based on light or dark mode
  static TextTheme _buildTextTheme(bool isDark) {
    final Color textColor = isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final Color secondaryTextColor = isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return TextTheme(
      // Display styles
      displayLarge: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
      
      // Headline styles
      headlineLarge: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
      
      // Title styles
      titleLarge: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
      
      // Body styles
      bodyLarge: TextStyle(color: textColor, fontSize: 16),
      bodyMedium: TextStyle(color: textColor, fontSize: 14),
      bodySmall: TextStyle(color: secondaryTextColor, fontSize: 12),
      
      // Label styles
      labelLarge: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w500),
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