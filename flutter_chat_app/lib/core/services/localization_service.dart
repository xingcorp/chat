import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:intl/intl.dart';

const String _localeKey = 'app_locale';

/// Service to manage localization and language preferences
@lazySingleton
class LocalizationService {
  final LocalStorage _localStorage;

  /// Creates a LocalizationService instance
  /// 
  /// [_localStorage] is used to persist locale preferences
  LocalizationService(this._localStorage);

  /// Get the stored locale or null for system default
  Future<Locale?> getStoredLocale() async {
    final String? localeCode = await _localStorage.getString(_localeKey);
    
    if (localeCode == null) {
      return null;
    }
    
    // Check if locale is supported
    try {
      return L10n.all.firstWhere((locale) => locale.languageCode == localeCode);
    } catch (_) {
      // If not found, return null (system default)
      return null;
    }
  }

  /// Save locale preference
  Future<bool> setLocale(Locale locale) async {
    return _localStorage.saveString(_localeKey, locale.languageCode);
  }

  /// Reset locale to system default
  Future<bool> resetToSystemLocale() async {
    return _localStorage.remove(_localeKey);
  }

  /// Get all supported locales with their display names
  List<LocaleInfo> getSupportedLocales() {
    return L10n.all.map((locale) => LocaleInfo(
      locale: locale,
      name: L10n.getLanguageName(locale),
      flag: L10n.getLocaleFlag(locale),
    )).toList();
  }
  
  /// Check if a specific locale is supported
  bool isSupported(Locale locale) {
    return L10n.all.any((l) => l.languageCode == locale.languageCode);
  }
  
  /// Get the next locale in the list of supported locales
  /// Returns the first locale if the current locale is the last one
  /// or if the current locale is not found
  Locale getNextLocale(Locale? currentLocale) {
    if (currentLocale == null) {
      return L10n.all.first;
    }
    
    final index = L10n.all.indexWhere(
      (l) => l.languageCode == currentLocale.languageCode
    );
    
    if (index < 0 || index >= L10n.all.length - 1) {
      return L10n.all.first;
    } else {
      return L10n.all[index + 1];
    }
  }
  
  /// Get available language options with system default
  List<LocaleOption> getAvailableOptions(BuildContext context) {
    return [
      // System default option
      LocaleOption(
        isSystemDefault: true,
        name: 'System Default',
        flag: '🌐',
      ),
      // Add all supported locales
      ...getSupportedLocales().map((info) => LocaleOption(
        locale: info.locale,
        name: info.name,
        flag: info.flag,
      )),
    ];
  }
  
  /// Get the display name for the current locale
  String getCurrentLocaleName(Locale? locale, BuildContext context) {
    if (locale == null) {
      return 'System Default';
    }
    return L10n.getLanguageName(locale);
  }
  
  /// Check if the locale reads from right to left
  bool isRtl(Locale locale) {
    return ['ar', 'fa', 'he', 'ur'].contains(locale.languageCode);
  }
  
  /// Get the appropriate text direction for a locale
  TextDirection getTextDirection(Locale locale) {
    return isRtl(locale) ? TextDirection.RTL : TextDirection.LTR;
  }
  
  /// Returns the full locale name with country code when available
  String getFullLocaleName(Locale locale) {
    final countryCode = locale.countryCode;
    final languageName = L10n.getLanguageName(locale);
    
    if (countryCode != null && countryCode.isNotEmpty) {
      return '$languageName ($countryCode)';
    } else {
      return languageName;
    }
  }
  
  /// Find the best matching locale from the supported locales
  Locale findBestMatchingLocale(Locale deviceLocale) {
    // Try exact match first
    if (isSupported(deviceLocale)) {
      return deviceLocale;
    }
    
    // Try matching just the language
    try {
      return L10n.all.firstWhere(
        (locale) => locale.languageCode == deviceLocale.languageCode,
      );
    } catch (_) {
      // Default to first supported locale (usually English)
      return L10n.all.first;
    }
  }
  
  /// Get display format for dates based on locale
  DateFormat getDateFormat(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return DateFormat('dd/MM/yyyy'); // Vietnamese format
      case 'en': 
      default:
        return DateFormat.yMd(locale.toString());
    }
  }
  
  /// Get display format for time based on locale
  DateFormat getTimeFormat(Locale locale) {
    switch (locale.languageCode) {
      case 'en': 
        return DateFormat.jm(locale.toString()); // 12-hour format with AM/PM
      default:
        return DateFormat.Hm(locale.toString()); // 24-hour format
    }
  }
  
  /// Format a date according to the locale's conventions
  String formatDate(DateTime date, Locale locale) {
    try {
      return getDateFormat(locale).format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  /// Format a time according to the locale's conventions
  String formatTime(DateTime time, Locale locale) {
    try {
      return getTimeFormat(locale).format(time);
    } catch (_) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Class to hold locale information for UI display
class LocaleInfo {
  /// The locale identifier
  final Locale locale;
  
  /// The display name of the locale (e.g., "English", "Tiếng Việt")
  final String name;
  
  /// The flag emoji for the locale (e.g., "🇺🇸", "🇻🇳")
  final String flag;

  /// Creates a LocaleInfo instance
  LocaleInfo({
    required this.locale,
    required this.name,
    required this.flag,
  });
}

/// Class to represent a locale option in the UI (including system default)
class LocaleOption {
  /// The locale identifier (null for system default)
  final Locale? locale;
  
  /// Whether this option represents the system default
  final bool isSystemDefault;
  
  /// The display name of the locale
  final String name;
  
  /// The flag emoji for the locale
  final String flag;
  
  /// Creates a LocaleOption instance
  LocaleOption({
    this.locale,
    this.isSystemDefault = false,
    required this.name,
    required this.flag,
  });
} 