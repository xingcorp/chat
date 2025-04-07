import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';

part 'app_event.dart';
part 'app_state.dart';

/// Manages application-wide state
class AppBloc extends Bloc<AppEvent, AppState> {
  final SocketManager _socketManager;
  StreamSubscription<SocketConnectionState>? _socketConnectionSubscription;

  AppBloc({required SocketManager socketManager}) 
      : _socketManager = socketManager,
        super(const AppState()) {
    on<AppInitialized>(_onAppInitialized);
    on<ThemeChanged>(_onThemeChanged);
    on<LocaleChanged>(_onLocaleChanged);
    on<AppEnteredForeground>(_onAppEnteredForeground);
    on<AppEnteredBackground>(_onAppEnteredBackground);
    on<SocketConnectionRequested>(_onSocketConnectionRequested);
    on<SocketConnectionClosed>(_onSocketConnectionClosed);
    on<SocketConnectionStateChanged>(_onSocketConnectionStateChanged);
    
    // Lắng nghe sự thay đổi trạng thái socket
    _socketConnectionSubscription = _socketManager.connectionState.listen((socketState) {
      add(SocketConnectionStateChanged(socketState));
    });
  }

  /// Initialize app state
  void _onAppInitialized(AppInitialized event, Emitter<AppState> emit) {
    // Thêm các khởi tạo cần thiết
    emit(state.copyWith(isAppInitialized: true));
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
  
  /// App entered foreground
  void _onAppEnteredForeground(AppEnteredForeground event, Emitter<AppState> emit) {
    _socketManager.enterForegroundMode();
    if (state.isAuthenticated) {
      _socketManager.connect();
    }
    emit(state.copyWith(isInBackground: false));
  }
  
  /// App entered background
  void _onAppEnteredBackground(AppEnteredBackground event, Emitter<AppState> emit) {
    _socketManager.enterBackgroundMode();
    emit(state.copyWith(isInBackground: true));
  }
  
  /// Socket connection was requested
  void _onSocketConnectionRequested(SocketConnectionRequested event, Emitter<AppState> emit) {
    _socketManager.connect();
  }
  
  /// Socket connection was closed
  void _onSocketConnectionClosed(SocketConnectionClosed event, Emitter<AppState> emit) {
    _socketManager.disconnect();
  }
  
  /// Socket connection state changed
  void _onSocketConnectionStateChanged(SocketConnectionStateChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(socketConnectionState: event.state));
  }
  
  @override
  Future<void> close() {
    _socketConnectionSubscription?.cancel();
    return super.close();
  }
} 