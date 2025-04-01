part of 'auth_bloc.dart';

/// State cho AuthBloc
class AuthState extends Equatable {
  /// Đã đăng nhập hay chưa
  final bool isAuthenticated;
  
  /// ID của người dùng
  final String? userId;
  
  /// Đã hoàn thành onboarding chưa
  final bool isOnboarded;
  
  /// Đang trong trạng thái chưa xác định
  final bool isInitializing;

  /// Constructor
  const AuthState({
    required this.isAuthenticated,
    this.userId,
    required this.isOnboarded,
    required this.isInitializing,
  });

  /// Unknown state - Chưa biết trạng thái
  const AuthState.unknown()
      : isAuthenticated = false,
        userId = null,
        isOnboarded = false,
        isInitializing = true;

  /// Authenticated state - Đã đăng nhập
  const AuthState.authenticated({
    required String userId,
    required bool isOnboarded,
  }) : isAuthenticated = true,
       userId = userId,
       isOnboarded = isOnboarded,
       isInitializing = false;

  /// Unauthenticated state - Chưa đăng nhập
  const AuthState.unauthenticated()
      : isAuthenticated = false,
        userId = null,
        isOnboarded = false,
        isInitializing = false;

  /// Copy with
  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    bool? isOnboarded,
    bool? isInitializing,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, userId, isOnboarded, isInitializing];
} 