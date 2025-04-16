import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Các text style chuẩn hóa cho toàn bộ ứng dụng
class AppTextStyles {
  /// Cache commonly used text styles
  static final Map<String, TextStyle> _styleCache = {};

  /// Default font family
  static const String fontFamily = 'Roboto';

  /// Base font size
  static const double baseFontSize = 14.0;
  
  /// Default text height
  static const double defaultHeight = 1.5;

  /// Clear cache
  static void clearCache() {
    _styleCache.clear();
  }

  /// Heading lớn nhất - H1
  static TextStyle heading1({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 32.sp,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height,
        letterSpacing: -0.5,
      );

  static TextStyle heading2({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 26.sp,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height,
        letterSpacing: -0.5,
      );

  static TextStyle heading3({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 22.sp,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height,
      );

  static TextStyle heading4({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 20.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height,
      );

  static TextStyle heading5({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 18.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height,
      );

  // Body styles
  static TextStyle bodyLarge({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height ?? 1.5,
      );

  static TextStyle bodyMedium({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
        height: height ?? 1.4,
      );

  static TextStyle bodySmall({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
  }) =>
      TextStyle(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textSecondary,
        decoration: decoration,
        height: height ?? 1.4,
      );

  // Button styles
  static TextStyle buttonLarge({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textButton,
        decoration: decoration,
        letterSpacing: 0.5,
      );

  static TextStyle buttonMedium({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textButton,
        decoration: decoration,
        letterSpacing: 0.5,
      );

  static TextStyle buttonSmall({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.textButton,
        decoration: decoration,
        letterSpacing: 0.5,
      );

  // Caption and specific styles
  static TextStyle caption({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 11.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textSecondary,
        decoration: decoration,
        letterSpacing: 0.4,
      );

  static TextStyle overline({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 10.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textSecondary,
        decoration: decoration,
        letterSpacing: 1.5,
      );

  // Chat specific styles
  static TextStyle chatMessage({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 15.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.sentMessageText,
        decoration: decoration,
        height: 1.3,
      );

  static TextStyle chatTime({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 10.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.messageTime,
        decoration: decoration,
      );

  static TextStyle chatUserName({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 13.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.primary,
        decoration: decoration,
      );

  // Input styles
  static TextStyle inputText({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
      );

  static TextStyle inputHint({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textHint,
        decoration: decoration,
      );

  // Tab & Navigation styles
  static TextStyle tabLabel({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? AppColors.primary,
        decoration: decoration,
      );

  static TextStyle navigationLabel({
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        decoration: decoration,
      );

  // Chuyển đổi màu sắc dựa vào light/dark mode
  static TextStyle getTextStyle(
    bool isDarkMode,
    TextStyle style, {
    Color? darkModeColor,
    Color? lightModeColor,
  }) {
    final Color textColor = isDarkMode 
        ? (darkModeColor ?? AppColors.textPrimaryDarkMode)
        : (lightModeColor ?? AppColors.textPrimary);
    
    return style.copyWith(color: textColor);
  }

  /// Returns a text style scaled for the specified device type
  /// 
  /// Adjusts font sizes for different device types while maintaining readability
  static TextStyle getScaledTextStyle(
    TextStyle baseStyle,
    BuildContext context, {
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    double scaleFactor = 1.0;
    
    if (isTablet) {
      scaleFactor = 1.1;
    } else if (isDesktop) {
      scaleFactor = 1.15;
    }
    
    final bool shouldScale = isTablet || isDesktop;
    if (!shouldScale) return baseStyle;
    
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize != null 
          ? baseStyle.fontSize! * scaleFactor
          : null,
    );
  }
} 