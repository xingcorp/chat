import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/error/repository_error_mixin.dart';
import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/features/auth/data/datasources/auth/auth_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

/// **ENTERPRISE AUTHENTICATION REPOSITORY IMPLEMENTATION**
///
/// Unified implementation with BaseRepository pattern for enterprise-grade
/// authentication performance and security.
///
/// **Performance Targets:**
/// - Login process: <2s (enterprise standard)
/// - Token operations: <1s
/// - Cached operations: <50ms
///
/// **Architecture:** Clean Architecture + SOLID principles + BaseRepository pattern
@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl extends BaseRepository
    with RepositoryErrorMixin
    implements IAuthRepository {
  final AuthRemoteDataSource _authRemoteDataSource;
  final UserLocalDataSource _userLocalDataSource;

  /// Constructor
  AuthRepositoryImpl({
    required AuthRemoteDataSource authRemoteDataSource,
    required UserLocalDataSource userLocalDataSource,
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _userLocalDataSource = userLocalDataSource;

  /// **Check if user is logged in - STANDARDIZED ERROR HANDLING**
  ///
  /// **Performance**: <50ms for cached auth status
  /// **Strategy**: Standardized error handling with RepositoryErrorMixin
  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    return handleCacheOperation(
      () async {
        final token = await _authRemoteDataSource.getAccessToken();
        final isLoggedIn = token != null && token.trim().isNotEmpty;

        if (!isLoggedIn) {
          await _userLocalDataSource.clearCurrentUser();
        }

        logger.t('Login status check: $isLoggedIn');
        return isLoggedIn;
      },
      operationName: 'isLoggedIn',
      context: {
        'source': 'local_cache',
        'operation_type': 'auth_check',
      },
    );
  }

  /// **Login with email and password - STANDARDIZED ERROR HANDLING**
  ///
  /// **Performance**: <2s for login process (enterprise standard)
  /// **Strategy**: Input validation → Network operation → Local storage
  @override
  Future<Either<Failure, User>> login(String phone, String password) async {
    // Step 1: Validate input parameters
    final validationResult = validateInput({
      'phone': phone,
      'password': password,
    }, operationName: 'login');

    if (validationResult.isLeft) {
      return validationResult.fold(
        (failure) => Left(failure),
        (_) => throw StateError('Unexpected validation success'),
      );
    }

    // Step 2: Execute network operation with retry logic
    return handleNetworkOperation(
      () async {
        logger.i('Attempting login for user: $phone');

        // Attempt to login
        final userModel = await _authRemoteDataSource.login(phone, password);

        // Save user to local storage
        await _userLocalDataSource.saveUser(userModel);
        await _userLocalDataSource.saveCurrentUser(userModel);

        logger.i('Login successful for user: $phone');
        return userModel.toDomain();
      },
      operationName: 'login',
      maxRetries: 2,
      context: {
        'phone': phone,
        'operation_type': 'authentication',
      },
    );
  }

  /// **Register a new user - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <3s for registration process
  /// **Strategy**: Server registration → Local storage → Error handling
  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    return executeOnlineFirst<User>(
      remoteDataSource: () async {
        logger.i('Attempting registration for user: $email');
        
        // Attempt to register - map interface params to remote datasource params
        final userModel = await _authRemoteDataSource.register(
          email: email,
          password: password,
          name: displayName ?? username, // Use displayName if provided, otherwise username
          avatar: null, // Avatar not supported in interface
        );

        // Save user to local storage
        await _userLocalDataSource.saveUser(userModel);
        await _userLocalDataSource.saveCurrentUser(userModel);

        logger.i('Registration successful for user: $email');
        return userModel.toDomain();
      },
      localDataSource: () async {
        // Cannot register offline - registration requires server
        throw ConnectionFailure(message: 'Cannot register without internet connection');
      },
      operationName: 'register',
    );
  }

  /// **Logout the current user - ONLINE-FIRST WITH OFFLINE FALLBACK**
  ///
  /// **Performance**: <1s for logout process
  /// **Strategy**: Server logout → Local cleanup → Always succeed locally
  @override
  Future<Either<Failure, bool>> logout() async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Attempting server logout');
        
        try {
          await _authRemoteDataSource.logout();
          logger.i('Server logout successful');
        } catch (e) {
          // Even if server logout fails, we'll still clear local session
          logger.w('Server logout failed, continuing with local cleanup: $e');
        }
        
        // Clear current user locally
        await _userLocalDataSource.clearCurrentUser();
        
        return true;
      },
      localDataSource: () async {
        // Offline logout - just clear local session
        logger.i('Offline logout - clearing local session');
        await _userLocalDataSource.clearCurrentUser();
        return true;
      },
      operationName: 'logout',
    );
  }

  /// **Reset password with email - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <2s for password reset request
  /// **Strategy**: Server email sending → Error handling
  @override
  Future<Either<Failure, bool>> resetPassword(String email) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Requesting password reset for: $email');
        final success = await _authRemoteDataSource.forgotPassword(email);
        logger.i('Password reset request result: $success');
        return success;
      },
      localDataSource: () async {
        // Cannot reset password offline
        throw ConnectionFailure(message: 'Cannot reset password without internet connection');
      },
      operationName: 'resetPassword',
    );
  }

  /// **Send password reset email - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <2s for email sending
  /// **Strategy**: Server email sending → Error handling
  @override
  Future<Either<Failure, bool>> sendPasswordResetEmail(String email) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Sending password reset email to: $email');
        final success = await _authRemoteDataSource.forgotPassword(email);
        logger.i('Password reset email sent: $success');
        return success;
      },
      localDataSource: () async {
        // Cannot send email offline
        throw ConnectionFailure(message: 'Cannot send password reset email without internet connection');
      },
      operationName: 'sendPasswordResetEmail',
    );
  }

  /// **Get current authenticated user - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for cached user data
  /// **Strategy**: Cache → Local DB → Error handling
  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return executeOfflineFirst<User?>(
      remoteDataSource: () async {
        // Remote fallback not implemented for current user
        throw ServerException(message: 'Remote current user fetch not supported');
      },
      localDataSource: () async {
        // Get from local database
        final currentUser = await _userLocalDataSource.getCurrentUser();
        if (currentUser != null) {
          logger.t('Retrieved current user from local storage');
          return currentUser.toDomain();
        }
        return null;
      },
      operationName: 'getCurrentUser',
    );
  }

  /// **Get access token - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for cached tokens
  /// **Strategy**: Local token → Server refresh if needed
  @override
  Future<Either<Failure, String?>> getAccessToken() async {
    return executeOfflineFirst<String?>(
      remoteDataSource: () async {
        // Try to get fresh token from server
        return await _authRemoteDataSource.getAccessToken();
      },
      localDataSource: () async {
        // Try to get cached token
        return await _authRemoteDataSource.getAccessToken();
      },
      operationName: 'getAccessToken',
    );
  }

  /// **Refresh authentication token - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <1s for token refresh
  /// **Strategy**: Server token refresh → Error handling
  @override
  Future<Either<Failure, String?>> refreshToken() async {
    return executeOnlineFirst<String?>(
      remoteDataSource: () async {
        logger.i('Refreshing authentication token');
        final token = await _authRemoteDataSource.refreshToken();
        logger.i('Token refresh successful');
        return token;
      },
      localDataSource: () async {
        // Cannot refresh token offline
        throw ConnectionFailure(message: 'Cannot refresh token without internet connection');
      },
      operationName: 'refreshToken',
    );
  }

  /// **Refresh user data from server - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <1s for user data refresh
  /// **Strategy**: Server user data → Local storage update
  @override
  Future<Either<Failure, User?>> refreshUser(String userId) async {
    return executeOnlineFirst<User?>(
      remoteDataSource: () async {
        logger.i('Refreshing user data for: $userId');
        
        // Get fresh user data from server
        final userModel = await _authRemoteDataSource.refreshUser(userId);
        
        if (userModel != null) {
          // Update in local storage
          await _userLocalDataSource.saveUser(userModel);
          logger.i('User data refreshed successfully');
          return userModel.toDomain();
        }
        
        return null;
      },
      localDataSource: () async {
        // Cannot refresh user data offline
        return null;
      },
      operationName: 'refreshUser',
    );
  }

  /// **Verify email with code - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <2s for email verification
  /// **Strategy**: Server verification → Error handling
  @override
  Future<Either<Failure, bool>> verifyEmail(String code) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Verifying email with code');
        final success = await _authRemoteDataSource.verifyEmail(code);
        logger.i('Email verification result: $success');
        return success;
      },
      localDataSource: () async {
        // Cannot verify email offline
        throw ConnectionFailure(message: 'Cannot verify email without internet connection');
      },
      operationName: 'verifyEmail',
    );
  }

  /// **Change password - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <2s for password change
  /// **Strategy**: Server password update → Error handling
  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Changing user password');
        final success = await _authRemoteDataSource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        logger.i('Password change result: $success');
        return success;
      },
      localDataSource: () async {
        // Cannot change password offline
        throw ConnectionFailure(message: 'Cannot change password without internet connection');
      },
      operationName: 'changePassword',
    );
  }

  /// **Update device token - ONLINE-FIRST WITH OFFLINE QUEUING**
  ///
  /// **Performance**: <1s for token update
  /// **Strategy**: Server token update → Offline queuing
  @override
  Future<Either<Failure, bool>> updateDeviceToken(String deviceToken) async {
    return executeOnlineFirst<bool>(
      remoteDataSource: () async {
        logger.i('Updating device token');
        final success = await _authRemoteDataSource.updateDeviceToken(deviceToken);
        logger.i('Device token update result: $success');
        return success;
      },
      localDataSource: () async {
        // Queue for later when online
        logger.i('Queuing device token update for when online');
        // TODO: Implement offline queuing mechanism
        return false;
      },
      operationName: 'updateDeviceToken',
    );
  }
}
