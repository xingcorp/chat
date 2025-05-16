import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension on BuildContext for easy access to generated localizations
extension LocalizationExt on BuildContext {
  /// Get the generated AppLocalizations for this context
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Get the current locale
  Locale get locale => Localizations.localeOf(this);
}

/// Helper class for localization
class L10n {
  /// Private constructor to prevent instantiation
  L10n._();
  
  /// List of all supported locales
  static const all = [
    Locale('en'), // English
    Locale('vi'), // Vietnamese
  ];

  /// Get the display name for a locale
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      default:
        return locale.languageCode;
    }
  }
  
  /// Get locale flag emoji
  static String getLocaleFlag(Locale locale) {
    // Flag emoji are created by converting each letter to a regional indicator symbol
    // For example, 'U' is converted to Unicode character U+1F1FA (regional indicator symbol letter U)
    // 'S' is converted to Unicode character U+1F1F8 (regional indicator symbol letter S)
    // Together they form the US flag emoji 🇺🇸
    
    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸'; // US flag for English
      case 'vi':
        return '🇻🇳'; // Vietnam flag
      default:
        return '🏳️'; // Default flag
    }
  }
  
  /// Format a date relative to now (today, yesterday, or date)
  static String formatRelativeDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return context.l10n.today;
    } else if (dateDay == yesterday) {
      return context.l10n.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  /// Format a time as HH:MM (24-hour format)
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 