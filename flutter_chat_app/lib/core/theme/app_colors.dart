import 'package:flutter/material.dart';

/// Màu sắc được sử dụng trong ứng dụng
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryBackground = Color(0xFFE3F2FD);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF03A9F4);
  static const Color secondaryLight = Color(0xFF4FC3F7);
  static const Color secondaryDark = Color(0xFF0288D1);
  static const Color secondaryBackground = Color(0xFFE1F5FE);
  
  // Accent Colors
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color accentDark = Color(0xFF0097A7);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  
  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textButton = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF2196F3);
  
  // Icon Colors
  static const Color iconPrimary = Color(0xFF212121);
  static const Color iconSecondary = Color(0xFF757575);
  static const Color iconDisabled = Color(0xFFBDBDBD);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Chat Colors
  static const Color sentMessageBackground = Color(0xFFE3F2FD);
  static const Color receivedMessageBackground = Color(0xFFFFFFFF);
  static const Color sentMessageText = Color(0xFF212121);
  static const Color receivedMessageText = Color(0xFF212121);
  static const Color messageTime = Color(0xFF9E9E9E);
  static const Color typing = Color(0xFF4CAF50);
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color chatInputBackground = Color(0xFFFFFFFF);
  
  // Shadow
  static const Color shadowColor = Color(0x1A000000);
  
  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF2196F3),
    Color(0xFF03A9F4),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
  ];
  
  static const List<Color> errorGradient = [
    Color(0xFFF44336),
    Color(0xFFE57373),
  ];
  
  // Dark Mode Colors
  static const Color primaryDarkMode = Color(0xFF90CAF9);
  static const Color backgroundDarkMode = Color(0xFF121212);
  static const Color surfaceDarkMode = Color(0xFF1E1E1E);
  static const Color errorDarkMode = Color(0xFFCF6679);
  
  static const Color textPrimaryDarkMode = Color(0xFFFFFFFF);
  static const Color textSecondaryDarkMode = Color(0xFFB0B0B0);
  
  static const Color sentMessageBackgroundDarkMode = Color(0xFF2979FF);
  static const Color receivedMessageBackgroundDarkMode = Color(0xFF424242);
  static const Color sentMessageTextDarkMode = Color(0xFFFFFFFF);
  static const Color receivedMessageTextDarkMode = Color(0xFFFFFFFF);
  
  // Functions to get color based on theme
  static Color getTextPrimaryColor(bool isDarkMode) => 
      isDarkMode ? textPrimaryDarkMode : textPrimary;
      
  static Color getTextSecondaryColor(bool isDarkMode) => 
      isDarkMode ? textSecondaryDarkMode : textSecondary;
      
  static Color getBackgroundColor(bool isDarkMode) => 
      isDarkMode ? backgroundDarkMode : background;
      
  static Color getSentMessageBackgroundColor(bool isDarkMode) => 
      isDarkMode ? sentMessageBackgroundDarkMode : sentMessageBackground;
      
  static Color getReceivedMessageBackgroundColor(bool isDarkMode) => 
      isDarkMode ? receivedMessageBackgroundDarkMode : receivedMessageBackground;
} 