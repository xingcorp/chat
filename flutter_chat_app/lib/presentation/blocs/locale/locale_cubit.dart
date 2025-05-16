import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:injectable/injectable.dart';

part 'locale_state.dart';

const String _localeStorageKey = 'app_locale';

/// Cubit to manage application's locale state
@injectable
class LocaleCubit extends Cubit<LocaleState> {
  final LocalStorage _localStorage;

  /// Creates a LocaleCubit instance
  /// 
  /// [_localStorage] is used to persist the selected locale
  LocaleCubit(this._localStorage) : super(const LocaleState()) {
    _initLocale();
  }

  /// Initialize locale from storage
  Future<void> _initLocale() async {
    final savedLocaleCode = await _localStorage.getString(_localeStorageKey);
    
    if (savedLocaleCode != null) {
      // Find the locale in supported locales
      final locale = L10n.all.firstWhere(
        (locale) => locale.languageCode == savedLocaleCode,
        orElse: () => L10n.all.first,
      );
      emit(state.copyWith(locale: locale));
    } else {
      // Use system default
      emit(state.copyWith(locale: null));
    }
  }

  /// Changes the app locale
  /// 
  /// [locale] is the new locale to set, or null for system default
  Future<void> changeLocale(Locale? locale) async {
    // If null, use system default
    if (locale == null) {
      await _localStorage.remove(_localeStorageKey);
      emit(state.copyWith(locale: null));
      return;
    }
    
    // Check if locale is supported
    if (L10n.all.any((l) => l.languageCode == locale.languageCode)) {
      await _localStorage.saveString(_localeStorageKey, locale.languageCode);
      emit(state.copyWith(locale: locale));
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
} 