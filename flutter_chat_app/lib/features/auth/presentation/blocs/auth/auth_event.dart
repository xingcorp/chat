part of 'auth_bloc.dart';

/// Abstract class cho các event của AuthBloc
abstract class AuthEvent extends Equatable {
  /// Constructor
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Event kiểm tra trạng thái đăng nhập
class AuthCheckRequested extends AuthEvent {
  /// Constructor
  const AuthCheckRequested();
}

/// Event đăng nhập thành công
class AuthLoggedIn extends AuthEvent {
  /// ID của người dùng
  final String userId;
  
  /// Access token
  final String accessToken;

  /// Constructor
  const AuthLoggedIn({
    required this.userId,
    required this.accessToken,
  });

  @override
  List<Object> get props => [userId, accessToken];
}

/// Event đăng xuất
class AuthLoggedOut extends AuthEvent {
  /// Constructor
  const AuthLoggedOut();
}

/// Event hoàn thành onboarding
class AuthOnboardingCompleted extends AuthEvent {
  /// Constructor
  const AuthOnboardingCompleted();
}

/// **Event đăng nhập với email và password**
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// **Event đăng ký tài khoản mới**
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String? displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.username,
    this.displayName,
  });

  @override
  List<Object> get props => [email, password, username, displayName ?? ''];
}