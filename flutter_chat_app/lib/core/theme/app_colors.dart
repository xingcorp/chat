import 'package:flutter/material.dart';

/// Defines application color palette
class AppColors {
  /// Primary brand color
  static const Color primary = Color(0xFF2196F3);
  
  /// Primary brand color (dark mode) - same as primary for consistency
  static const Color primaryDarkMode = Color(0xFF2196F3);
  
  /// Secondary brand color
  static const Color secondary = Color(0xFFFF9800);
  
  // Light mode colors
  /// Background color (light mode)
  static const Color background = Color(0xFFF5F5F5);
  
  /// Card background color (light mode)
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Primary text color (light mode)
  static const Color textPrimary = Color(0xFF212121);
  
  /// Secondary text color (light mode)
  static const Color textSecondary = Color(0xFF757575);
  
  /// Hint text color (light mode)
  static const Color textHint = Color(0xFF9E9E9E);

  /// Button text color
  static const Color textButton = Colors.white;
  
  /// Icon color (light mode)
  static const Color icon = Color(0xFF616161);
  
  /// Shadow color
  static const Color shadow = Color(0x1A000000);
  
  /// Border color (light mode)
  static const Color border = Color(0xFFE0E0E0);
  
  // Dark mode colors
  /// Background color (dark mode)
  static const Color backgroundDarkMode = Color(0xFF121212);
  
  /// Surface color (light mode)
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Surface color (dark mode)
  static const Color surfaceDarkMode = Color(0xFF1E1E1E);
  
  /// Input background color (light mode)
  static const Color inputBackground = Color(0xFFF0F0F0);
  
  /// Input background color (dark mode)
  static const Color inputBackgroundDarkMode = Color(0xFF2C2C2C);
  
  /// Divider color (light mode)
  static const Color divider = Color(0xFFE0E0E0);
  
  /// Divider color (dark mode)
  static const Color dividerDarkMode = Color(0xFF424242);
  
  /// Primary text color (dark mode)
  static const Color textPrimaryDarkMode = Color(0xFFFFFFFF);
  
  /// Secondary text color (dark mode)
  static const Color textSecondaryDarkMode = Color(0xFFBDBDBD);

  /// Hint text color (dark mode)
  static const Color textHintDarkMode = Color(0xFF757575);
  
  /// Icon color (dark mode)
  static const Color iconDarkMode = Color(0xFFE0E0E0);
  
  /// Border color (dark mode)
  static const Color borderDarkMode = Color(0xFF424242);
  
  // Status colors
  /// Success color
  static const Color success = Color(0xFF4CAF50);
  
  /// Error color
  static const Color error = Color(0xFFF44336);
  
  /// Warning color
  static const Color warning = Color(0xFFFFC107);
  
  /// Info color
  static const Color info = Color(0xFF2196F3);
  
  // Chat-specific colors
  /// Chat input field background color
  static const Color chatInputBackground = Color(0xFFF5F5F5);
  
  /// Sent message background color (light mode)
  static const Color sentMessageBackground = Color(0xFFE3F2FD);
  
  /// Sent message text color (light mode)
  static const Color sentMessageText = Color(0xFF000000);
  
  /// Received message background color (light mode)
  static const Color receivedMessageBackground = Color(0xFFFFFFFF);
  
  /// Received message text color (light mode)
  static const Color receivedMessageText = Color(0xFF000000);

  /// Message timestamp color
  static const Color messageTime = Color(0xFF9E9E9E);
  
  /// Sent message background color (dark mode)
  static const Color sentMessageBackgroundDark = Color(0xFF0D47A1);
  
  /// Received message background color (dark mode)
  static const Color receivedMessageBackgroundDark = Color(0xFF424242);
  
  // Grey scale
  /// Light grey
  static const Color greyLight = Color(0xFFE0E0E0);
  
  /// Dark grey
  static const Color greyDark = Color(0xFF9E9E9E);
  
  // Background variations
  /// Primary background color
  static const Color primaryBackground = Color(0xFFE3F2FD);
  
  /// Secondary background color
  static const Color secondaryBackground = Color(0xFFFFF3E0);

  // Additional properties for permissions UI
  /// Surface variant color
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Outline color
  static const Color outline = Color(0xFFE0E0E0);

  /// Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════
  // Premium V2 UI Tokens
  // ═══════════════════════════════════════════════════════════

  // Gradient Bubble Colors (own messages — Navy gradient)
  /// Own message bubble gradient start color
  static const Color bubbleOwnGradientStart = Color(0xFF1A237E);

  /// Own message bubble gradient end color
  static const Color bubbleOwnGradientEnd = Color(0xFF3F51B5);

  /// Own message bubble gradient
  static const LinearGradient bubbleOwnGradient = LinearGradient(
    colors: [bubbleOwnGradientStart, bubbleOwnGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Other's message bubble background (light mode)
  static const Color bubbleOtherLight = Color(0xFFF5F5F5);

  /// Other's message bubble background (dark mode)
  static const Color bubbleOtherDark = Color(0xFF2C2C2E);

  /// Other's message bubble border (light mode)
  static const Color bubbleOtherBorderLight = Color(0xFFE2E8F0);

  /// Other's message bubble border (dark mode)
  static const Color bubbleOtherBorderDark = Color(0xFF3A3A3C);

  // Glassmorphism
  /// Glass background (light mode) — 80% white opacity
  static const Color glassBgLight = Color(0xCCFFFFFF);

  /// Glass background (dark mode) — 80% dark opacity
  static const Color glassBgDark = Color(0xCC1C1C1E);

  // Mention Pill Tag Colors
  /// Mention pill background (light mode)
  static const Color mentionBgLight = Color(0xFFE3F2FD);

  /// Mention pill text (light mode)
  static const Color mentionTextLight = Color(0xFF1565C0);

  /// Mention pill background (dark mode)
  static const Color mentionBgDark = Color(0xFF1A237E);

  /// Mention pill text (dark mode)
  static const Color mentionTextDark = Color(0xFF90CAF9);

  // Presence Indicator
  /// Online presence glow color
  static const Color presenceOnline = Color(0xFF4CAF50);

  /// Online presence glow ring (semi-transparent)
  static const Color presenceGlow = Color(0x664CAF50);

  // Tab Pill
  /// Tab pill background (active tab)
  static const Color tabPillBg = Color(0x1A1976D2);

  /// Tab pill background (dark mode)
  static const Color tabPillBgDark = Color(0x332196F3);

  // Message Status Icons
  /// Message read status (double check blue)
  static const Color messageReadStatus = Color(0xFF4FC3F7);

  /// Message sent status (single check grey)
  static const Color messageSentStatus = Color(0xFF9E9E9E);

  // Bubble text on gradient
  /// Text color on own bubble (white for gradient background)
  static const Color bubbleOwnText = Color(0xFFFFFFFF);

  /// Time text on own bubble (semi-transparent white)
  static const Color bubbleOwnTimeText = Color(0xB3FFFFFF);

  // Helper methods
  /// Get message background color based on theme mode
  static Color getSentMessageBackgroundColor(bool isDarkMode) {
    return isDarkMode ? sentMessageBackgroundDark : sentMessageBackground;
  }

  /// Get received message background color based on theme mode
  static Color getReceivedMessageBackgroundColor(bool isDarkMode) {
    return isDarkMode ? receivedMessageBackgroundDark : receivedMessageBackground;
  }
  
  /// Get appropriate text color based on background for high contrast readability
  static Color getContrastColor(Color backgroundColor) {
    // Calculate luminance - darker colors have lower values
    final double luminance = backgroundColor.computeLuminance();
    // Use white text on dark backgrounds, black text on light backgrounds
    return luminance > 0.5 ? textPrimary : textPrimaryDarkMode;
  }
} 