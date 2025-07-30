import 'package:flutter/material.dart';

/// Defines application color palette
class AppColors {
  /// Primary brand color
  static const Color primary = Color(0xFF2196F3);
  
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