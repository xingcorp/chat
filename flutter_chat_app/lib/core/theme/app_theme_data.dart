import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';

/// **ENHANCED THEME DATA**
///
/// Provides comprehensive theme configuration with custom extensions.
/// All Material components are configured for consistency.
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Factory Pattern + Theme Extensions
///
/// **Features**:
/// - Complete Material 3 theme configuration
/// - Uses [AppDimens] for all dimensions
/// - Uses [AppColors] for all colors
/// - Uses [AppTextStyles] for typography
/// - Custom theme extensions for additional properties
/// - Light and dark theme variants
///
/// **Usage**:
/// ```dart
/// MaterialApp(
///   theme: AppThemeData.lightTheme,
///   darkTheme: AppThemeData.darkTheme,
///   themeMode: ThemeMode.system,
/// )
/// ```
class AppThemeData {
  /// Private constructor to prevent instantiation
  AppThemeData._();

  /// Light theme data
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        backgroundColor: AppColors.background,
        surfaceColor: AppColors.surface,
        textPrimaryColor: AppColors.textPrimary,
        textSecondaryColor: AppColors.textSecondary,
        extensions: [AppThemeExtensions.light],
      );

  /// Dark theme data
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        backgroundColor: AppColors.backgroundDarkMode,
        surfaceColor: AppColors.surfaceDarkMode,
        textPrimaryColor: AppColors.textPrimaryDarkMode,
        textSecondaryColor: AppColors.textSecondaryDarkMode,
        extensions: [AppThemeExtensions.dark],
      );

  /// Build theme with custom configuration
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required List<ThemeExtension<dynamic>> extensions,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      extensions: extensions,
      
      // Typography
      textTheme: _buildTextTheme(textPrimaryColor, textSecondaryColor),
      primaryTextTheme: _buildTextTheme(textPrimaryColor, textSecondaryColor),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: AppDimens.elevationNone,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading5(color: textPrimaryColor),
        iconTheme: IconThemeData(
          color: textPrimaryColor,
          size: AppDimens.iconMedium,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimens.elevationMedium,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: AppDimens.elevationButton,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          minimumSize: const Size(
            AppDimens.buttonMinWidth,
            AppDimens.buttonHeightMedium,
          ),
          textStyle: AppTextStyles.buttonMedium(),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          minimumSize: const Size(
            AppDimens.buttonMinWidth,
            AppDimens.buttonHeightMedium,
          ),
          textStyle: AppTextStyles.buttonMedium(),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          minimumSize: const Size(
            AppDimens.buttonMinWidth,
            AppDimens.buttonHeightMedium,
          ),
          textStyle: AppTextStyles.buttonMedium(),
        ),
      ),
      
      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimaryColor,
          minimumSize: const Size(
            AppDimens.iconButtonSize,
            AppDimens.iconButtonSize,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: AppDimens.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? AppColors.inputBackgroundDarkMode 
            : AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textHintDarkMode : AppColors.textHint,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: AppDimens.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(AppDimens.marginSmall),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: AppDimens.elevationDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusDialog),
        ),
        titleTextStyle: AppTextStyles.heading4(color: textPrimaryColor),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textPrimaryColor),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: AppDimens.elevationBottomSheet,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDarkMode : Colors.grey[800],
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        elevation: AppDimens.elevationMedium,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
        thickness: AppDimens.dividerThin,
        space: AppDimens.dividerThin,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: surfaceColor.withOpacity(0.5),
        labelStyle: AppTextStyles.bodySmall.copyWith(color: textPrimaryColor),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSmall,
          vertical: AppDimens.paddingXSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
        ),
        minVerticalPadding: AppDimens.paddingSmall,
        iconColor: textPrimaryColor,
        textColor: textPrimaryColor,
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(color: textPrimaryColor),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: backgroundColor,
        linearTrackColor: backgroundColor,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey[400] : Colors.grey[50];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return isDark ? Colors.grey[700] : Colors.grey[300];
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXSmall),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
    );
  }

  /// Build text theme
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: AppTextStyles.heading1(color: primaryColor),
      displayMedium: AppTextStyles.heading2(color: primaryColor),
      displaySmall: AppTextStyles.heading3(color: primaryColor),
      headlineLarge: AppTextStyles.heading4(color: primaryColor),
      headlineMedium: AppTextStyles.heading5(color: primaryColor),
      headlineSmall: AppTextStyles.heading5(color: primaryColor),
      titleLarge: AppTextStyles.heading5(color: primaryColor),
      titleMedium: AppTextStyles.bodyLargeCustom(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: AppTextStyles.bodyMediumCustom(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primaryColor),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primaryColor),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primaryColor),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondaryColor),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondaryColor),
    );
  }
}
