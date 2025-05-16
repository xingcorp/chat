import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

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