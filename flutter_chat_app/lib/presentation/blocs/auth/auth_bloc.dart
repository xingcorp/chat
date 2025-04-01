import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc quản lý trạng thái đăng nhập
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SharedPreferences _preferences;
  
  /// Constructor
  AuthBloc(this._preferences) : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthOnboardingCompleted>(_onAuthOnboardingCompleted);
  }
  
  // Khởi tạo bloc
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event, 
    Emitter<AuthState> emit,
  ) async {
    final isAuthenticated = _preferences.getBool('isAuthenticated') ?? false;
    final isOnboarded = _preferences.getBool('isOnboarded') ?? false;
    final userId = _preferences.getString('userId');
    
    if (isAuthenticated && userId != null) {
      emit(AuthState.authenticated(
        userId: userId, 
        isOnboarded: isOnboarded,
      ));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }
  
  // Đăng nhập
  Future<void> _onAuthLoggedIn(
    AuthLoggedIn event, 
    Emitter<AuthState> emit,
  ) async {
    await _preferences.setBool('isAuthenticated', true);
    await _preferences.setString('userId', event.userId);
    await _preferences.setString('accessToken', event.accessToken);
    
    final isOnboarded = _preferences.getBool('isOnboarded') ?? false;
    
    emit(AuthState.authenticated(
      userId: event.userId, 
      isOnboarded: isOnboarded,
    ));
  }
  
  // Đăng xuất
  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event, 
    Emitter<AuthState> emit,
  ) async {
    await _preferences.setBool('isAuthenticated', false);
    await _preferences.remove('userId');
    await _preferences.remove('accessToken');
    
    emit(const AuthState.unauthenticated());
  }
  
  // Hoàn thành onboarding
  Future<void> _onAuthOnboardingCompleted(
    AuthOnboardingCompleted event, 
    Emitter<AuthState> emit,
  ) async {
    await _preferences.setBool('isOnboarded', true);
    
    if (state.isAuthenticated) {
      emit(state.copyWith(isOnboarded: true));
    }
  }
} 