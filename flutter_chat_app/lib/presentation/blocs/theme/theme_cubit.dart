/// **THEME CUBIT**
/// 
/// Manages theme state with persistence for the Flutter chat app.
/// Provides WhatsApp/Telegram-level theme switching experience.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';

part 'theme_state.dart';

/// **THEME CUBIT**
/// 
/// Manages application theme state with persistence
@injectable
class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorage _localStorage;
  
  /// Creates a ThemeCubit instance
  ThemeCubit(this._localStorage) : super(const ThemeState()) {
    _initTheme();
  }
  
  /// Initialize theme from storage
  Future<void> _initTheme() async {
    final savedThemeMode = await _localStorage.getString(AppConstants.kPrefsKeyThemeMode);
    
    if (savedThemeMode != null) {
      final themeMode = _parseThemeMode(savedThemeMode);
      emit(state.copyWith(themeMode: themeMode));
    } else {
      // Use system default
      emit(state.copyWith(themeMode: ThemeMode.system));
    }
  }
  
  /// Change theme mode
  Future<void> changeTheme(ThemeMode themeMode) async {
    // Save to storage
    await _localStorage.saveString(
      AppConstants.kPrefsKeyThemeMode, 
      themeMode.toString(),
    );
    
    // Update state
    emit(state.copyWith(themeMode: themeMode));
  }
  
  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final currentMode = state.themeMode;
    
    switch (currentMode) {
      case ThemeMode.light:
        await changeTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await changeTheme(ThemeMode.light);
        break;
      case ThemeMode.system:
        // Toggle to light first
        await changeTheme(ThemeMode.light);
        break;
    }
  }
  
  /// Set theme to system default
  Future<void> useSystemTheme() async {
    await changeTheme(ThemeMode.system);
  }
  
  /// Set light theme
  Future<void> useLightTheme() async {
    await changeTheme(ThemeMode.light);
  }
  
  /// Set dark theme
  Future<void> useDarkTheme() async {
    await changeTheme(ThemeMode.dark);
  }
  
  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String themeModeString) {
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }
  
  /// Get theme mode display name
  String getThemeModeDisplayName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Check if current theme is dark
  bool get isDarkMode {
    return state.themeMode == ThemeMode.dark;
  }
  
  /// Check if current theme is light
  bool get isLightMode {
    return state.themeMode == ThemeMode.light;
  }
  
  /// Check if using system theme
  bool get isSystemMode {
    return state.themeMode == ThemeMode.system;
  }
}
