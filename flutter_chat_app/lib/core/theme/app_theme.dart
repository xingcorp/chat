import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// Quản lý theme cho ứng dụng, bao gồm dark và light mode
class AppTheme {
  /// Theme sáng
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardBackground,
        background: AppColors.background,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
          foregroundColor: AppColors.primary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.icon,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }

  /// Theme tối
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineSmall: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.grey[300],
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
          foregroundColor: AppColors.primary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),
    );
  }

  /// Tạo ThemeData dựa trên ThemeMode
  static ThemeData getThemeByMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        final isPlatformDark =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
        return isPlatformDark ? darkTheme : lightTheme;
    }
  }
} 