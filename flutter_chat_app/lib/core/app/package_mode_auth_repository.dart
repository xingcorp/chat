import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';

/// A no-op implementation of [IAuthRepository] for package mode.
///
/// When the chat module runs embedded in a host app, authentication is handled
/// by the host app. This repository returns pre-configured values and no-ops
/// for all authentication operations.
///
/// ## Usage
/// Used internally by [ChatModuleInjection] when [ChatModule.initialize()] is called.
class PackageModeAuthRepository implements IAuthRepository {
  final User _currentUser;
  final String _accessToken;

  /// Creates a no-op repository with pre-authenticated state.
  ///
  /// [currentUser] is the user from [ChatConfig].
  /// [accessToken] is the token from [ChatConfig].
  PackageModeAuthRepository({
    required User currentUser,
    required String accessToken,
  })  : _currentUser = currentUser,
        _accessToken = accessToken;

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, User>> login(String phone, String password) async {
    // No-op: Login is handled by host app
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    // No-op: Registration is handled by host app
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    // No-op: Logout is handled by host app
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> resetPassword(String email) async {
    // No-op: Password reset is handled by host app
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> sendPasswordResetEmail(String email) async {
    // No-op: Password reset email is handled by host app
    return const Right(true);
  }

  @override
  Future<Either<Failure, String?>> getAccessToken() async {
    return Right(_accessToken);
  }

  @override
  Future<Either<Failure, String?>> refreshToken() async {
    // No-op: Token refresh is handled by host app via ChatConfig.onTokenRefresh
    return Right(_accessToken);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, User?>> refreshUser(String userId) async {
    // No-op: User refresh is handled by host app
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, bool>> verifyEmail(String code) async {
    // No-op: Email verification is handled by host app
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // No-op: Password change is handled by host app
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> updateDeviceToken(String deviceToken) async {
    // No-op: Device token update is handled by host app
    return const Right(true);
  }
}
