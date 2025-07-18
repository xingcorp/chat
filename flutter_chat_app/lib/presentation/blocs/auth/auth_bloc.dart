import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// **ENTERPRISE AUTHENTICATION BLOC**
///
/// Manages authentication state with IAuthRepository integration
/// and Either<Failure, T> error handling for enterprise-grade reliability.
///
/// **Performance**: <100ms for auth state changes
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  final SharedPreferences _preferences;
  
  /// Constructor
  AuthBloc({
    required IAuthRepository authRepository,
    required SharedPreferences preferences,
  }) : _authRepository = authRepository,
       _preferences = preferences,
       super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthOnboardingCompleted>(_onAuthOnboardingCompleted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
  }
  
  /// **Check authentication status using IAuthRepository**
  ///
  /// **Performance**: <100ms for auth status check
  /// **Strategy**: Repository-based auth check with Either error handling
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check authentication status via repository
    final result = await _authRepository.isLoggedIn();

    result.fold(
      (failure) {
        // Authentication check failed - assume unauthenticated
        emit(const AuthState.unauthenticated());
      },
      (isAuthenticated) async {
        if (isAuthenticated) {
          // Get current user details
          final userResult = await _authRepository.getCurrentUser();

          userResult.fold(
            (failure) {
              // Failed to get user details - assume unauthenticated
              emit(const AuthState.unauthenticated());
            },
            (user) {
              final isOnboarded = _preferences.getBool('isOnboarded') ?? false;

              if (user != null) {
                emit(AuthState.authenticated(
                  userId: user.id,
                  isOnboarded: isOnboarded,
                ));
              } else {
                emit(const AuthState.unauthenticated());
              }
            },
          );
        } else {
          emit(const AuthState.unauthenticated());
        }
      },
    );
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
  
  /// **Handle logout using IAuthRepository**
  ///
  /// **Performance**: <1s for logout process
  /// **Strategy**: Repository-based logout with Either error handling
  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    // Perform logout via repository
    final result = await _authRepository.logout();

    result.fold(
      (failure) {
        // Even if logout fails, clear local state
        _preferences.setBool('isAuthenticated', false);
        _preferences.remove('userId');
        _preferences.remove('accessToken');
        emit(const AuthState.unauthenticated());
      },
      (success) {
        // Logout successful - clear local preferences
        _preferences.setBool('isAuthenticated', false);
        _preferences.remove('userId');
        _preferences.remove('accessToken');
        emit(const AuthState.unauthenticated());
      },
    );
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