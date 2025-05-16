import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Extension on BuildContext for easy access to generated localizations
extension LocalizationExt on BuildContext {
  /// Get the generated AppLocalizations for this context
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Get the current locale
  Locale get locale => Localizations.localeOf(this);
  
  /// Check if current locale is RTL
  bool get isRtl => L10n.isRtl(locale);
  
  /// Get text direction based on current locale
  TextDirection get textDirection {
    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Get text alignment based on current locale
  TextAlign get textAlign => isRtl ? TextAlign.right : TextAlign.left;
  
  /// Get start alignment based on current locale (for Flex widgets)
  MainAxisAlignment get startAlignment => 
      isRtl ? MainAxisAlignment.end : MainAxisAlignment.start;
      
  /// Get end alignment based on current locale (for Flex widgets)
  MainAxisAlignment get endAlignment => 
      isRtl ? MainAxisAlignment.start : MainAxisAlignment.end;
      
  /// Get start padding
  EdgeInsets startPadding(double value) => 
      isRtl ? EdgeInsets.only(right: value) : EdgeInsets.only(left: value);
      
  /// Get end padding
  EdgeInsets endPadding(double value) => 
      isRtl ? EdgeInsets.only(left: value) : EdgeInsets.only(right: value);
      
  /// Get horizontal directional padding
  EdgeInsets horizontalPadding({required double start, required double end}) => 
      isRtl ? EdgeInsets.only(right: start, left: end) : EdgeInsets.only(left: start, right: end);
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
  static String formatRelativeDate(BuildContext context, DateTime? date) {
    if (date == null) {
      return '-';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return context.l10n.today;
    } else if (dateDay == yesterday) {
      return context.l10n.yesterday;
    } else {
      return formatDateForLocale(date, Localizations.localeOf(context).toString());
    }
  }
  
  /// Format a date according to the current locale
  static String formatDateForLocale(DateTime date, String localeCode) {
    try {
      return DateFormat.yMd(localeCode).format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  /// Format a time as HH:MM (24-hour format)
  static String formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  /// Format a relative time (X minutes/hours ago or time)
  static String formatRelativeTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now'; // Replace with actual translation when added
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago'; // Replace with actual translation when added
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago'; // Replace with actual translation when added
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago'; // Replace with actual translation when added
    } else {
      return formatDateForLocale(dateTime, Localizations.localeOf(context).toString());
    }
  }
  
  /// Format a date in a standardized way based on locale
  static String formatDate(DateTime? date, {String? localeCode}) {
    if (date == null) return '-';
    
    try {
      return DateFormat('dd/MM/yyyy', localeCode).format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  /// Format currency with proper localization
  static String formatCurrency(BuildContext context, double? amount, String currencyCode) {
    if (amount == null) return '-';
    
    try {
      final format = NumberFormat.currency(
        locale: Localizations.localeOf(context).toString(),
        symbol: currencyCode,
        decimalDigits: 2,
      );
      return format.format(amount);
    } catch (_) {
      try {
        // Fallback to simple formatting with direction awareness
        if (context.isRtl) {
          return '${amount.toStringAsFixed(2)} $currencyCode';
        } else {
          return '$currencyCode ${amount.toStringAsFixed(2)}';
        }
      } catch (_) {
        return '$currencyCode ${amount.toStringAsFixed(2)}';
      }
    }
  }
  
  /// Format a number with thousand separators based on locale
  static String formatNumber(BuildContext context, num? number) {
    if (number == null) return '-';
    
    try {
      final format = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toString(),
      );
      return format.format(number);
    } catch (_) {
      return number.toString();
    }
  }
  
  /// Format a file size (bytes to KB/MB/GB)
  static String formatFileSize(BuildContext context, int? bytes) {
    if (bytes == null || bytes < 0) return '-';
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Format a phone number for display
  static String formatPhoneNumber(String? phoneNumber, {String? countryCode}) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '-';
    
    // Basic formatting for international numbers
    if (phoneNumber.startsWith('+')) {
      // Format international number with groups of digits
      if (phoneNumber.length > 7) {
        return '${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
      }
      return phoneNumber;
    }
    
    // Add country code if provided and needed
    if (countryCode != null && !phoneNumber.startsWith('+')) {
      return '+$countryCode $phoneNumber';
    }
    
    return phoneNumber;
  }
  
  /// Check if a locale is RTL
  static bool isRtl(Locale locale) {
    return ['ar', 'fa', 'he', 'ur'].contains(locale.languageCode);
  }
  
  /// Check if a locale is supported
  static bool isSupported(Locale locale) {
    return all.any((supported) => supported.languageCode == locale.languageCode);
  }
  
  /// Get ISO639-1 language code from a locale
  static String getLanguageCode(Locale locale) {
    return locale.languageCode;
  }
  
  /// Get a display name with emoji flag prefix
  static String getLanguageDisplayName(Locale locale) {
    return '${getLocaleFlag(locale)} ${getLanguageName(locale)}';
  }
  
  /// Get the best matching supported locale
  static Locale? findSupportedLocale(Locale locale) {
    // Try exact match first
    if (isSupported(locale)) {
      return locale;
    }
    
    // Try matching just the language code
    final matchingLocale = all.firstWhere(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      orElse: () => all.first, // Default to first supported locale
    );
    
    return matchingLocale;
  }
} 