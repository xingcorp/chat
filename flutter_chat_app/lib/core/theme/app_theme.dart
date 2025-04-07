import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// Quản lý theme cho ứng dụng, bao gồm dark và light mode
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primaryColor: AppColors.primary,
        primaryColorLight: AppColors.primaryLight,
        primaryColorDark: AppColors.primaryDark,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          background: AppColors.background,
          surface: AppColors.cardBackground,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onBackground: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        cardColor: AppColors.cardBackground,
        dividerColor: AppColors.greyLight,
        disabledColor: AppColors.textDisabled,
        shadowColor: AppColors.shadowColor,
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.iconPrimary),
          actionsIconTheme: IconThemeData(color: AppColors.iconPrimary),
          titleTextStyle: AppTextStyles.heading5(),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: AppConstants.kDefaultElevation,
          selectedLabelStyle: AppTextStyles.caption(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          unselectedLabelStyle: AppTextStyles.caption(),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
          ),
          labelStyle: AppTextStyles.tabLabel(),
          unselectedLabelStyle: AppTextStyles.tabLabel(
            color: AppColors.textSecondary,
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
          buttonColor: AppColors.primary,
          disabledColor: AppColors.textDisabled,
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.buttonMedium(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.kDefaultBorderRadius,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonMedium(color: AppColors.white),
            elevation: AppConstants.kDefaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.kDefaultBorderRadius,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.buttonMedium(),
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.kDefaultBorderRadius,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AppColors.white,
          filled: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.greyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.greyLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTextStyles.inputHint(),
          labelStyle: AppTextStyles.bodyMedium(),
          errorStyle: AppTextStyles.bodySmall(color: AppColors.error),
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.heading1(),
          displayMedium: AppTextStyles.heading2(),
          displaySmall: AppTextStyles.heading3(),
          headlineMedium: AppTextStyles.heading4(),
          headlineSmall: AppTextStyles.heading5(),
          bodyLarge: AppTextStyles.bodyLarge(),
          bodyMedium: AppTextStyles.bodyMedium(),
          bodySmall: AppTextStyles.bodySmall(),
          labelLarge: AppTextStyles.buttonLarge(),
          labelMedium: AppTextStyles.buttonMedium(),
          labelSmall: AppTextStyles.buttonSmall(),
        ),
        iconTheme: IconThemeData(
          color: AppColors.iconPrimary,
          size: AppConstants.kDefaultIconSize,
        ),
        cardTheme: CardTheme(
          color: AppColors.cardBackground,
          elevation: AppConstants.kDefaultElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.dialogBackground,
          elevation: AppConstants.kDefaultElevation * 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryBackground,
          disabledColor: AppColors.greyLight,
          selectedColor: AppColors.primary,
          secondarySelectedColor: AppColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          labelStyle: AppTextStyles.bodySmall(),
          secondaryLabelStyle: AppTextStyles.bodySmall(color: AppColors.white),
          brightness: Brightness.light,
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.greyLight,
          thickness: 1,
          space: 1,
        ),
        useMaterial3: true,
      );

  static ThemeData get darkTheme => ThemeData(
        primaryColor: AppColors.primaryDarkMode,
        primaryColorLight: AppColors.primaryLight,
        primaryColorDark: AppColors.primary,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryDarkMode,
          secondary: AppColors.secondary,
          error: AppColors.errorDarkMode,
          background: AppColors.backgroundDarkMode,
          surface: AppColors.surfaceDarkMode,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onBackground: AppColors.textPrimaryDarkMode,
          onSurface: AppColors.textPrimaryDarkMode,
          onError: AppColors.white,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDarkMode,
        cardColor: AppColors.surfaceDarkMode,
        dividerColor: AppColors.greyDark,
        disabledColor: AppColors.greyDark,
        shadowColor: Colors.black.withOpacity(0.3),
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceDarkMode,
          foregroundColor: AppColors.textPrimaryDarkMode,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimaryDarkMode),
          actionsIconTheme: IconThemeData(color: AppColors.textPrimaryDarkMode),
          titleTextStyle: AppTextStyles.heading5(color: AppColors.textPrimaryDarkMode),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDarkMode,
          selectedItemColor: AppColors.primaryDarkMode,
          unselectedItemColor: AppColors.textSecondaryDarkMode,
          type: BottomNavigationBarType.fixed,
          elevation: AppConstants.kDefaultElevation,
          selectedLabelStyle: AppTextStyles.caption(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDarkMode,
          ),
          unselectedLabelStyle: AppTextStyles.caption(
            color: AppColors.textSecondaryDarkMode,
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: AppColors.primaryDarkMode,
          unselectedLabelColor: AppColors.textSecondaryDarkMode,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.primaryDarkMode,
                width: 2.0,
              ),
            ),
          ),
          labelStyle: AppTextStyles.tabLabel(color: AppColors.primaryDarkMode),
          unselectedLabelStyle: AppTextStyles.tabLabel(
            color: AppColors.textSecondaryDarkMode,
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
          buttonColor: AppColors.primaryDarkMode,
          disabledColor: AppColors.greyDark,
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDarkMode,
            textStyle: AppTextStyles.buttonMedium(color: AppColors.primaryDarkMode),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.kDefaultBorderRadius,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDarkMode,
            foregroundColor: AppColors.white,
            textStyle: AppTextStyles.buttonMedium(color: AppColors.white),
            elevation: AppConstants.kDefaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.kDefaultBorderRadius,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDarkMode,
            textStyle: AppTextStyles.buttonMedium(color: AppColors.primaryDarkMode),
            side: BorderSide(color: AppColors.primaryDarkMode),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.kDefaultBorderRadius,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AppColors.surfaceDarkMode,
          filled: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.greyDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.greyDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.primaryDarkMode),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.errorDarkMode),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
            borderSide: BorderSide(color: AppColors.errorDarkMode),
          ),
          hintStyle: AppTextStyles.inputHint(color: AppColors.textSecondaryDarkMode),
          labelStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDarkMode),
          errorStyle: AppTextStyles.bodySmall(color: AppColors.errorDarkMode),
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.heading1(color: AppColors.textPrimaryDarkMode),
          displayMedium: AppTextStyles.heading2(color: AppColors.textPrimaryDarkMode),
          displaySmall: AppTextStyles.heading3(color: AppColors.textPrimaryDarkMode),
          headlineMedium: AppTextStyles.heading4(color: AppColors.textPrimaryDarkMode),
          headlineSmall: AppTextStyles.heading5(color: AppColors.textPrimaryDarkMode),
          bodyLarge: AppTextStyles.bodyLarge(color: AppColors.textPrimaryDarkMode),
          bodyMedium: AppTextStyles.bodyMedium(color: AppColors.textPrimaryDarkMode),
          bodySmall: AppTextStyles.bodySmall(color: AppColors.textSecondaryDarkMode),
          labelLarge: AppTextStyles.buttonLarge(color: AppColors.textPrimaryDarkMode),
          labelMedium: AppTextStyles.buttonMedium(color: AppColors.textPrimaryDarkMode),
          labelSmall: AppTextStyles.buttonSmall(color: AppColors.textPrimaryDarkMode),
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryDarkMode,
          size: AppConstants.kDefaultIconSize,
        ),
        cardTheme: CardTheme(
          color: AppColors.surfaceDarkMode,
          elevation: AppConstants.kDefaultElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.surfaceDarkMode,
          elevation: AppConstants.kDefaultElevation * 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceDarkMode,
          contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.textPrimaryDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.kDefaultBorderRadius,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.backgroundDarkMode,
          disabledColor: AppColors.greyDark,
          selectedColor: AppColors.primaryDarkMode,
          secondarySelectedColor: AppColors.primaryDarkMode,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          labelStyle: AppTextStyles.bodySmall(color: AppColors.textPrimaryDarkMode),
          secondaryLabelStyle: AppTextStyles.bodySmall(color: AppColors.white),
          brightness: Brightness.dark,
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.greyDark,
          thickness: 1,
          space: 1,
        ),
        useMaterial3: true,
      );
      
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