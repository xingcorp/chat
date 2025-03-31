import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  const AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF5E60CE);
  static const Color primaryLight = Color(0xFF7A7CDB);
  static const Color primaryDark = Color(0xFF4547A9);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondary = Color(0xFF6499E9);
  static const Color secondaryLight = Color(0xFF87B1F3);
  static const Color secondaryDark = Color(0xFF3F73C3);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Accent Colors
  static const Color accent = Color(0xFF9170E7);
  static const Color accentLight = Color(0xFFAC8FEF);
  static const Color accentDark = Color(0xFF7750CD);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Error/Success Colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFAFAFA);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color mediumText = Color(0xFF424242);
  static const Color lightText = Color(0xFF757575);
  static const Color disabledLight = Color(0xFFBDBDBD);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color lightTextDark = Color(0xFFF5F5F5);
  static const Color mediumTextDark = Color(0xFFBDBDBD);
  static const Color darkTextDark = Color(0xFF9E9E9E);
  static const Color disabledDark = Color(0xFF616161);
  static const Color dividerDark = Color(0xFF424242);

  // Message Bubble Colors
  static const Color sentMessageBubble = Color(0xFF5E60CE);
  static const Color receivedMessageBubble = Color(0xFFEEEEEE);
  static const Color sentMessageText = Color(0xFFFFFFFF);
  static const Color receivedMessageText = Color(0xFF1E1E1E);
  
  // Message Bubble Colors (Dark Theme)
  static const Color sentMessageBubbleDark = Color(0xFF5E60CE);
  static const Color receivedMessageBubbleDark = Color(0xFF2A2A2A);
  static const Color sentMessageTextDark = Color(0xFFFFFFFF);
  static const Color receivedMessageTextDark = Color(0xFFE0E0E0);

  // Typing Indicator Colors
  static const Color typingDot1 = Color(0xFF90CAF9);
  static const Color typingDot2 = Color(0xFF64B5F6);
  static const Color typingDot3 = Color(0xFF42A5F5);

  // Online Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color away = Color(0xFFFFA726);
  static const Color busy = Color(0xFFE53935);
} 