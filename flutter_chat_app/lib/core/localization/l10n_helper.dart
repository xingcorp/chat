/// **L10N HELPER - LOCALIZATION WITHOUT CONTEXT**
///
/// Helper functions for accessing localized strings without BuildContext
/// Useful for:
/// - Service classes
/// - Utility functions  
/// - Error messages in repositories
/// - Background tasks
///
/// **Architecture:** Clean Architecture + Localization

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations_en.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations_vi.dart';

/// Global localization helper
class L10nHelper {
  static AppLocalizations? _instance;
  
  /// Initialize with current locale
  static void initialize(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        _instance = AppLocalizationsVi();
        break;
      case 'en':
      default:
        _instance = AppLocalizationsEn();
        break;
    }
  }
  
  /// Get current localization instance
  static AppLocalizations get current {
    if (_instance == null) {
      // Fallback to English if not initialized
      _instance = AppLocalizationsEn();
    }
    return _instance!;
  }
  
  /// Update locale
  static void updateLocale(Locale locale) {
    initialize(locale);
  }
}

/// Extension for easy access
extension L10nHelperExtension on String {
  /// Get localized string by key
  String get l10n {
    final localizations = L10nHelper.current;
    
    // Map common keys to localization methods
    switch (this) {
      case 'loading':
        return localizations.loading;
      case 'error':
        return localizations.errorOccurred;
      case 'retry':
        return localizations.retry;
      case 'send':
        return localizations.send;
      case 'cancel':
        return localizations.cancel;
      case 'save':
        return localizations.save;
      case 'delete':
        return localizations.delete;
      case 'close':
        return localizations.close;
      case 'ok':
        return localizations.ok;
      case 'online':
        return localizations.online;
      case 'offline':
        return localizations.offline;
      case 'today':
        return localizations.today;
      case 'yesterday':
        return localizations.yesterday;
      case 'newMessage':
        return localizations.newMessage;
      case 'typeMessage':
        return localizations.typeMessage;
      case 'noMessages':
        return localizations.noMessages;
      case 'login':
        return localizations.login;
      case 'register':
        return localizations.register;
      case 'forgotPassword':
        return localizations.forgotPassword;
      case 'username':
        return localizations.username;
      case 'password':
        return localizations.password;
      case 'email':
        return localizations.email;
      default:
        return this; // Return original string if no mapping found
    }
  }
}

/// Static helper methods for common use cases
class L10n {
  /// Get loading text
  static String get loading => L10nHelper.current.loading;
  
  /// Get error text
  static String get error => L10nHelper.current.errorOccurred;
  
  /// Get retry text
  static String get retry => L10nHelper.current.retry;
  
  /// Get send text
  static String get send => L10nHelper.current.send;
  
  /// Get cancel text
  static String get cancel => L10nHelper.current.cancel;
  
  /// Get save text
  static String get save => L10nHelper.current.save;
  
  /// Get delete text
  static String get delete => L10nHelper.current.delete;
  
  /// Get close text
  static String get close => L10nHelper.current.close;
  
  /// Get OK text
  static String get ok => L10nHelper.current.ok;
  
  /// Get online text
  static String get online => L10nHelper.current.online;
  
  /// Get offline text
  static String get offline => L10nHelper.current.offline;
  
  /// Get today text
  static String get today => L10nHelper.current.today;
  
  /// Get yesterday text
  static String get yesterday => L10nHelper.current.yesterday;
  
  /// Get new message text
  static String get newMessage => L10nHelper.current.newMessage;
  
  /// Get type message text
  static String get typeMessage => L10nHelper.current.typeMessage;
  
  /// Get no messages text
  static String get noMessages => L10nHelper.current.noMessages;
}
