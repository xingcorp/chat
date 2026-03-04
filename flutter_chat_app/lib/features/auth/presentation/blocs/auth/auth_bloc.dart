import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/sso_auth_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// **ENTERPRISE AUTHENTICATION BLOC**
///
/// Manages authentication state with IAuthRepository integration
/// and Either<Failure, T> error handling for enterprise-grade reliability.
///
/// **Performance**: <100ms for auth state changes
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
///
/// Note: In package mode, AuthBloc is created manually via AuthBloc.authenticated()
/// so this injectable registration is only for standalone mode.
@Injectable(env: [Environment.dev, Environment.prod, 'standalone'])
class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocErrorMixin {
  final IAuthRepository _authRepository;
  final SharedPreferences _preferences;
  final SsoAuthService? _ssoAuthService;

  /// Constructor - starts with AuthInitial state
  AuthBloc({
    required IAuthRepository authRepository,
    required SharedPreferences preferences,
    SsoAuthService? ssoAuthService,
  }) : _authRepository = authRepository,
       _preferences = preferences,
       _ssoAuthService = ssoAuthService,
       super(const AuthInitial.initial()) {
    _registerEventHandlers();
  }

  /// Factory constructor for package mode - starts already authenticated.
  ///
  /// In package mode, the host app handles authentication. The chat module
  /// receives user info via ChatConfig, so AuthBloc should start in
  /// AuthAuthenticated state immediately (no async check needed).
  ///
  /// This ensures child widgets can read AuthBloc.state synchronously
  /// in didChangeDependencies without waiting for async auth check.
  AuthBloc.authenticated({
    required IAuthRepository authRepository,
    required SharedPreferences preferences,
    required User user,
    bool isOnboarded = true,
    SsoAuthService? ssoAuthService,
  }) : _authRepository = authRepository,
       _preferences = preferences,
       _ssoAuthService = ssoAuthService,
       super(AuthAuthenticated(user: user, isOnboarded: isOnboarded)) {
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthOnboardingCompleted>(_onAuthOnboardingCompleted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthSsoLoginRequested>(_onAuthSsoLoginRequested);
  }
  
  /// **Check authentication status - STANDARDIZED ERROR HANDLING**
  ///
  /// **Performance**: <100ms for auth status check
  /// **Strategy**: BlocErrorMixin with Either error handling
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Emit loading state
    emit(const AuthLoading(operation: 'check'));

    try {
      // Run isLoggedIn and getCurrentUser in parallel since getCurrentUser
      // is a local cache read that's safe to call even if unauthenticated.
      final futures = await Future.wait([
        _authRepository.isLoggedIn(),
        _authRepository.getCurrentUser(),
      ]);

      final result = futures[0] as Either<Failure, bool>;
      final userResult = futures[1] as Either<Failure, User?>;

      if (result.isLeft) {
        if (emit.isDone) return;
        emit(
          AuthError(
            failure: result.left,
            operation: 'isLoggedIn',
            retryAction: () => add(const AuthCheckRequested()),
          ),
        );
        return;
      }

      final isAuthenticated = result.right;
      if (!isAuthenticated) {
        if (emit.isDone) return;
        emit(const AuthUnauthenticated());
        return;
      }

      // Already have user result from parallel call
      if (emit.isDone) return;

      if (userResult.isLeft) {
        emit(
          AuthError(
            failure: userResult.left,
            operation: 'getCurrentUser',
            retryAction: () => add(const AuthCheckRequested()),
          ),
        );
        return;
      }

      final user = userResult.right;
      final isOnboarded = _preferences.getBool('isOnboarded') ?? false;

      if (user != null) {
        emit(
          AuthAuthenticated(
            user: user,
            isOnboarded: isOnboarded,
          ),
        );
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (exception, stackTrace) {
      logger.e('Auth check exception', error: exception, stackTrace: stackTrace);

      emit(AuthError(
        failure: UnexpectedFailure(
          message: 'Unexpected error during auth check: $exception',
          code: 'auth_check_exception',
        ),
        operation: 'authCheck',
        retryAction: () => add(const AuthCheckRequested()),
      ));
    }
  }
  
  /// **Handle successful login - STANDARDIZED ERROR HANDLING**
  ///
  /// **Performance**: <100ms for auth data persistence
  /// **Strategy**: Local storage persistence → Get user → State update
  Future<void> _onAuthLoggedIn(
    AuthLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _preferences.setBool('isAuthenticated', true);
      await _preferences.setString('userId', event.userId);
      await _preferences.setString('accessToken', event.accessToken);

      final isOnboarded = _preferences.getBool('isOnboarded') ?? false;

      // Get current user from local cache first
      final userResult = await _authRepository.getCurrentUser();

      final user = userResult.isRight ? userResult.right : null;

      if (user != null) {
        emit(AuthAuthenticated(
          user: user,
          isOnboarded: isOnboarded,
        ));
        return;
      }

      // Local cache empty (e.g. after logout cleared data) — fetch from server
      final refreshResult = await _authRepository.refreshUser(event.userId);

      if (emit.isDone) return;

      refreshResult.fold(
        (failure) {
          emit(AuthError(
            failure: failure,
            operation: 'refreshUser',
            retryAction: () => add(event),
          ));
        },
        (refreshedUser) {
          if (refreshedUser != null) {
            emit(AuthAuthenticated(
              user: refreshedUser,
              isOnboarded: isOnboarded,
            ));
          } else {
            emit(AuthError(
              failure: UnexpectedFailure(
                message: 'User not found after login',
                code: 'user_not_found',
              ),
              operation: 'login',
            ));
          }
        },
      );
    } catch (exception, stackTrace) {
      logger.e('Login data save exception', error: exception, stackTrace: stackTrace);

      emit(AuthError(
        failure: UnexpectedFailure(
          message: 'Failed to save login data: $exception',
          code: 'login_save_exception',
        ),
        operation: 'saveLoginData',
        retryAction: () => add(event),
      ));
    }
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
        emit(const AuthUnauthenticated.unauthenticated());
      },
      (success) {
        // Logout successful - clear local preferences
        _preferences.setBool('isAuthenticated', false);
        _preferences.remove('userId');
        _preferences.remove('accessToken');
        emit(const AuthUnauthenticated.unauthenticated());
      },
    );
  }
  
  /// **Complete onboarding - STANDARDIZED ERROR HANDLING**
  ///
  /// **Performance**: <50ms for onboarding completion
  /// **Strategy**: BlocErrorMixin with Either error handling
  Future<void> _onAuthOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _preferences.setBool('isOnboarded', true);

      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(AuthAuthenticated(
          user: currentState.user,
          isOnboarded: true,
        ));
      }
    } catch (e) {
      emit(AuthError(
        failure: UnexpectedFailure(
          message: 'Failed to complete onboarding: $e',
          code: 'onboarding_failed',
        ),
        operation: 'onboarding',
        retryAction: () => add(event),
      ));
    }
  }

  /// **Handle login request using IAuthRepository**
  ///
  /// **Performance**: <2s for login process (enterprise standard)
  /// **Strategy**: Repository-based login with Either error handling
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Emit loading state
    emit(const AuthLoading(operation: 'login'));

    // Perform login via repository
    final result = await _authRepository.login(event.phone, event.password);

    result.fold(
      (failure) {
        emit(AuthError(
          failure: failure,
          operation: 'login',
          retryAction: () => add(event),
          fieldErrors: failure is ValidationFailure ? failure.fieldErrors : null,
        ));
      },
      (user) {
        // Login successful - save to preferences and emit authenticated state
        _preferences.setBool('isAuthenticated', true);
        _preferences.setString('userId', user.id);

        final isOnboarded = _preferences.getBool('isOnboarded') ?? false;

        emit(AuthAuthenticated(
          user: user,
          isOnboarded: isOnboarded,
        ));
      },
    );
  }

  /// **Handle register request using IAuthRepository**
  ///
  /// **Performance**: <3s for registration process
  /// **Strategy**: Repository-based registration with Either error handling
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Emit loading state
    emit(const AuthLoading(operation: 'register'));

    // Perform registration via repository
    final result = await _authRepository.register(
      email: event.email,
      password: event.password,
      username: event.username,
      displayName: event.displayName,
    );

    result.fold(
      (failure) {
        // Registration failed - emit unauthenticated state
        emit(const AuthUnauthenticated.unauthenticated());
      },
      (user) {
        // Registration successful - save to preferences and emit authenticated state
        _preferences.setBool('isAuthenticated', true);
        _preferences.setString('userId', user.id);

        final isOnboarded = _preferences.getBool('isOnboarded') ?? false;

        emit(AuthAuthenticated(
          user: user,
          isOnboarded: isOnboarded,
        ));
      },
    );
  }

  /// **Handle SSO login request (Google, Keycloak)**
  ///
  /// **Performance**: <5s for SSO flow (includes browser redirect)
  /// **Strategy**: SsoAuthService → Token exchange → User lookup
  Future<void> _onAuthSsoLoginRequested(
    AuthSsoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_ssoAuthService == null) {
      emit(AuthError(
        failure: UnexpectedFailure(
          message: 'SSO service not configured',
          code: 'sso_not_configured',
        ),
        operation: 'sso_login',
      ));
      return;
    }

    // Emit loading state
    emit(const AuthLoading(operation: 'sso_login'));

    try {
      // Perform SSO authentication based on provider
      final ssoResult = switch (event.provider) {
        SsoProvider.google => await _ssoAuthService!.authenticateWithGoogle(),
        SsoProvider.keycloak => await _ssoAuthService!.authenticateWithKeycloak(),
      };

      if (ssoResult.isLeft) {
        if (emit.isDone) return;
        emit(AuthError(
          failure: ssoResult.left,
          operation: 'sso_login',
          retryAction: () => add(event),
        ));
        return;
      }

      final tokens = ssoResult.right;

      // Save SSO tokens
      await _preferences.setBool('isAuthenticated', true);
      await _preferences.setString('accessToken', tokens.accessToken);
      if (tokens.refreshToken != null) {
        await _preferences.setString('refreshToken', tokens.refreshToken!);
      }
      if (tokens.idToken != null) {
        await _preferences.setString('idToken', tokens.idToken!);
      }

      // Get user info from repository (should use the new token)
      final userResult = await _authRepository.getCurrentUser();

      if (emit.isDone) return;

      User? user;
      if (userResult.isRight) {
        user = userResult.right;
      }

      // Local cache empty — fetch from server using userId from preferences
      if (user == null) {
        final userId = _preferences.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          final refreshResult = await _authRepository.refreshUser(userId);
          if (emit.isDone) return;
          if (refreshResult.isRight) {
            user = refreshResult.right;
          }
        }
      }

      if (user != null) {
        _preferences.setString('userId', user.id);
        final isOnboarded = _preferences.getBool('isOnboarded') ?? false;

        emit(AuthAuthenticated(
          user: user,
          isOnboarded: isOnboarded,
        ));
      } else {
        emit(AuthError(
          failure: UnexpectedFailure(
            message: 'User not found after SSO login',
            code: 'sso_user_not_found',
          ),
          operation: 'sso_login',
          retryAction: () => add(event),
        ));
      }
    } catch (exception, stackTrace) {
      logger.e('SSO login exception', error: exception, stackTrace: stackTrace);

      if (emit.isDone) return;
      emit(AuthError(
        failure: UnexpectedFailure(
          message: 'SSO login failed: $exception',
          code: 'sso_exception',
        ),
        operation: 'sso_login',
        retryAction: () => add(event),
      ));
    }
  }
}