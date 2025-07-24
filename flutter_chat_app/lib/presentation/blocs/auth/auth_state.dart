part of 'auth_bloc.dart';

/// **MODERNIZED AUTH STATE - ERROR HANDLING STANDARDIZATION**
///
/// Professional auth state with comprehensive error handling:
/// - Loading states for better UX
/// - Error states with Vietnamese messages
/// - Proper state transitions
/// - Recovery actions support
///
/// **Architecture:** Clean Architecture + BLoC + Either<Failure, T>

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  /// **Check if user is authenticated**
  bool get isAuthenticated => false;

  /// **Check if user has completed onboarding**
  bool get isOnboarded => false;
}

/// **Initial State** - App startup, checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();

  /// **Named constructor for convenience**
  const AuthInitial.initial() : this();
}

/// **Loading State** - Authentication operation in progress
class AuthLoading extends AuthState {
  final String? operation; // 'login', 'register', 'logout', 'check'

  const AuthLoading({this.operation});

  @override
  List<Object?> get props => [operation];
}

/// **Authenticated State** - User is logged in
class AuthAuthenticated extends AuthState {
  final User user;
  final bool _isOnboarded;

  const AuthAuthenticated({
    required this.user,
    required bool isOnboarded,
  }) : _isOnboarded = isOnboarded;

  @override
  bool get isAuthenticated => true;

  @override
  bool get isOnboarded => _isOnboarded;

  @override
  List<Object?> get props => [user, _isOnboarded];
}

/// **Unauthenticated State** - User is not logged in
class AuthUnauthenticated extends AuthState {
  final bool _isOnboarded;

  const AuthUnauthenticated({bool isOnboarded = false}) : _isOnboarded = isOnboarded;

  /// **Named constructor for convenience**
  const AuthUnauthenticated.unauthenticated({bool isOnboarded = false}) : _isOnboarded = isOnboarded;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isOnboarded => _isOnboarded;

  @override
  List<Object?> get props => [_isOnboarded];
}

/// **Error State** - Authentication error occurred
class AuthError extends AuthState {
  final Failure failure;
  final String? operation;
  final VoidCallback? retryAction;
  final VoidCallback? authAction;
  final Map<String, String>? fieldErrors;

  const AuthError({
    required this.failure,
    this.operation,
    this.retryAction,
    this.authAction,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [failure, operation, fieldErrors];
}

/// **Registration State** - User registration in progress
class AuthRegistering extends AuthState {
  const AuthRegistering();
}

/// **Registration Success** - User registered successfully
class AuthRegistrationSuccess extends AuthState {
  final User user;

  const AuthRegistrationSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// **Password Reset State** - Password reset in progress
class AuthPasswordResetLoading extends AuthState {
  const AuthPasswordResetLoading();
}

/// **Password Reset Success** - Password reset email sent
class AuthPasswordResetSuccess extends AuthState {
  final String email;

  const AuthPasswordResetSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}