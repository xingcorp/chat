import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

part 'locale_state.dart';

const String _localeStorageKey = 'app_locale';

/// **ENTERPRISE LOCALE CUBIT**
///
/// Manages application's locale state with performance optimization and advanced features
@injectable
class LocaleCubit extends Cubit<LocaleState> {
  final LocalStorage _localStorage;
  final Logger _logger = Logger();

  // Performance monitoring
  final Stopwatch _performanceStopwatch = Stopwatch();

  // Translation cache for performance
  final Map<String, Map<String, String>> _translationCache = {};

  // Constants
  static const Duration _performanceTarget = Duration(milliseconds: 50);

  /// Creates a LocaleCubit instance with enterprise features
  LocaleCubit(this._localStorage) : super(const LocaleState()) {
    _initLocale();
  }

  /// Initialize locale from storage with performance monitoring
  Future<void> _initLocale() async {
    try {
      _performanceStopwatch.start();
      _logger.i('🌍 Initializing locale system...');

      final savedLocaleCode = await _localStorage.getString(_localeStorageKey);

      if (savedLocaleCode != null) {
        // Find the locale in supported locales
        final locale = L10n.all.firstWhere(
          (locale) => locale.languageCode == savedLocaleCode,
          orElse: () => L10n.all.first,
        );

        // Pre-cache translations for performance
        await _precacheTranslations(locale);

        emit(state.copyWith(
          locale: locale,
          lastLocaleChange: DateTime.now(),
        ));
      } else {
        // Default to Vietnamese on first launch
        const defaultLocale = Locale('vi');
        await _precacheTranslations(defaultLocale);
        emit(state.copyWith(
          locale: defaultLocale,
          lastLocaleChange: DateTime.now(),
        ));
      }

      _performanceStopwatch.stop();
      _logger.i('✅ Locale initialized in ${_performanceStopwatch.elapsedMilliseconds}ms');

    } catch (e) {
      _logger.e('💥 Locale initialization failed: $e');
      emit(state.copyWith(locale: null, error: 'Failed to initialize locale: $e'));
    }
  }

  /// Changes the app locale with performance optimization
  Future<void> changeLocale(Locale? locale) async {
    try {
      _performanceStopwatch.reset();
      _performanceStopwatch.start();

      _logger.d('🌍 Changing locale to: ${locale?.languageCode ?? 'system'}');

      // If null, use system default
      if (locale == null) {
        await _localStorage.remove(_localeStorageKey);

        _performanceStopwatch.stop();
        final switchDuration = _performanceStopwatch.elapsed;

        emit(state.copyWith(
          locale: null,
          lastSwitchDuration: switchDuration,
          lastLocaleChange: DateTime.now(),
          error: null,
        ));

        _logger.i('✅ Locale switched to system in ${switchDuration.inMilliseconds}ms');
        return;
      }

      // Check if locale is supported
      if (L10n.all.any((l) => l.languageCode == locale.languageCode)) {
        await _localStorage.saveString(_localeStorageKey, locale.languageCode);

        // Pre-cache translations for performance
        await _precacheTranslations(locale);

        _performanceStopwatch.stop();
        final switchDuration = _performanceStopwatch.elapsed;

        emit(state.copyWith(
          locale: locale,
          lastSwitchDuration: switchDuration,
          lastLocaleChange: DateTime.now(),
          error: null,
        ));

        _logger.i('✅ Locale switched to ${locale.languageCode} in ${switchDuration.inMilliseconds}ms');

        // Performance warning if exceeds target
        if (switchDuration > _performanceTarget) {
          _logger.w('⚠️ Locale switch exceeded 50ms target: ${switchDuration.inMilliseconds}ms');
        }
      } else {
        throw Exception('Unsupported locale: ${locale.languageCode}');
      }

    } catch (e) {
      _logger.e('💥 Locale change failed: $e');
      emit(state.copyWith(error: 'Failed to change locale: $e'));
    }
  }

  /// Toggle between available locales
  /// 
  /// Cycles through the list of supported locales
  Future<void> toggleLocale() async {
    final currentLocale = state.locale;
    
    // If null or last locale, switch to first
    if (currentLocale == null || 
        currentLocale.languageCode == L10n.all.last.languageCode) {
      await changeLocale(L10n.all.first);
    } else {
      // Find next locale
      final currentIndex = L10n.all.indexWhere(
        (l) => l.languageCode == currentLocale.languageCode
      );
      
      if (currentIndex >= 0 && currentIndex < L10n.all.length - 1) {
        await changeLocale(L10n.all[currentIndex + 1]);
      } else {
        await changeLocale(L10n.all.first);
      }
    }
  }

  /// Get supported locales with display names
  List<Map<String, dynamic>> getSupportedLocales() {
    return L10n.all.map((locale) => {
      'locale': locale,
      'languageCode': locale.languageCode,
      'displayName': _getLocaleDisplayName(locale),
      'isRtl': ['ar', 'fa', 'he', 'ur'].contains(locale.languageCode),
    }).toList();
  }

  /// Check if locale is RTL
  bool isRtl(Locale locale) {
    return ['ar', 'fa', 'he', 'ur'].contains(locale.languageCode);
  }

  /// Get current performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'lastSwitchDuration': state.lastSwitchDuration?.inMilliseconds,
      'isPerformanceOptimal': state.isPerformanceOptimal,
      'cacheSize': _translationCache.length,
      'lastLocaleChange': state.lastLocaleChange?.toIso8601String(),
    };
  }

  /// Clear translation cache to free memory
  void clearCache() {
    _translationCache.clear();
    _logger.i('🧹 Translation cache cleared');
  }

  /// Pre-cache translations for performance
  Future<void> _precacheTranslations(Locale locale) async {
    try {
      _logger.d('🌍 Pre-caching translations for ${locale.languageCode}...');

      // This would integrate with actual translation system
      // For now, we'll just simulate the caching
      final cacheKey = locale.languageCode;
      _translationCache[cacheKey] = {};

      // In real implementation:
      // - Load common translations
      // - Cache frequently used strings
      // - Pre-process pluralization rules

    } catch (e) {
      _logger.w('⚠️ Translation pre-caching failed: $e');
    }
  }

  /// Get locale display name
  String _getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      case 'ar':
        return 'العربية';
      case 'fa':
        return 'فارسی';
      case 'he':
        return 'עברית';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}