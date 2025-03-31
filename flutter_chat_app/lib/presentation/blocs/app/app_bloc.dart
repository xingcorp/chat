import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/config/theme/app_theme.dart';

part 'app_event.dart';
part 'app_state.dart';

/// Manages application-wide state
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AppInitialized>(_onAppInitialized);
    on<ThemeChanged>(_onThemeChanged);
    on<LocaleChanged>(_onLocaleChanged);
  }

  /// Initialize app state
  void _onAppInitialized(AppInitialized event, Emitter<AppState> emit) {
    // TODO: Load saved settings from storage
    emit(const AppState());
  }

  /// Change theme mode
  void _onThemeChanged(ThemeChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
    // TODO: Save theme preference to storage
  }

  /// Change app locale
  void _onLocaleChanged(LocaleChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(locale: event.locale));
    // TODO: Save locale preference to storage
  }
} 