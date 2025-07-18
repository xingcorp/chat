import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';

/// **ENTERPRISE AUTHENTICATION REPOSITORY INTERFACE**
///
/// Unified interface for authentication operations with comprehensive error handling
/// and performance optimization for enterprise-grade authentication.
///
/// **Error Handling**: All methods return Either<Failure, T> for consistent error management
/// **Performance**: Optimized for enterprise authentication standards
/// **Architecture**: Clean Architecture with SOLID principles
abstract class IAuthRepository {
  /// **Check if the user is logged in**
  ///
  /// **Strategy**: executeOfflineFirst (cached auth state priority)
  /// **Performance**: <50ms for cached auth status
  /// **Returns**: Either<Failure, bool> - null-safe with proper error handling
  Future<Either<Failure, bool>> isLoggedIn();

  /// **Login with email and password - CRITICAL AUTHENTICATION OPERATION**
  ///
  /// **Strategy**: executeOnlineFirst (server authentication required)
  /// **Performance**: <2s for login process (enterprise standard)
  /// **Security**: Proper credential validation and token management
  /// **Critical**: Core authentication functionality
  Future<Either<Failure, User>> login(String email, String password);

  /// **Register a new user**
  ///
  /// **Strategy**: executeOnlineFirst (server registration required)
  /// **Performance**: <3s for registration process
  /// **Security**: Email validation, password strength, duplicate checking
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  });

  /// **Logout the current user**
  ///
  /// **Strategy**: executeOnlineFirst with offline fallback
  /// **Performance**: <1s for logout process
  /// **Security**: Proper token invalidation and session cleanup
  Future<Either<Failure, bool>> logout();

  /// **Reset password with email**
  ///
  /// **Strategy**: executeOnlineFirst (server email sending required)
  /// **Performance**: <2s for password reset request
  /// **Security**: Email validation and rate limiting
  Future<Either<Failure, bool>> resetPassword(String email);

  /// **Send password reset email**
  ///
  /// **Strategy**: executeOnlineFirst (server email sending required)
  /// **Performance**: <2s for email sending
  /// **Use Case**: Password recovery flow
  Future<Either<Failure, bool>> sendPasswordResetEmail(String email);

  /// **Get the current user's access token**
  ///
  /// **Strategy**: executeOfflineFirst (cached token priority)
  /// **Performance**: <50ms for cached tokens
  /// **Security**: Token validation and refresh if needed
  Future<Either<Failure, String?>> getAccessToken();

  /// **Refresh the authentication token**
  ///
  /// **Strategy**: executeOnlineFirst (server token refresh)
  /// **Performance**: <1s for token refresh
  /// **Security**: Secure token rotation and validation
  Future<Either<Failure, String?>> refreshToken();

  /// **Get the current authenticated user**
  ///
  /// **Strategy**: executeOfflineFirst (cached user data priority)
  /// **Performance**: <50ms for cached user data
  /// **Use Case**: User profile, authentication state
  Future<Either<Failure, User?>> getCurrentUser();

  /// **Refresh user data from server**
  ///
  /// **Strategy**: executeOnlineFirst (fresh user data)
  /// **Performance**: <1s for user data refresh
  /// **Use Case**: Profile updates, data synchronization
  Future<Either<Failure, User?>> refreshUser(String userId);

  /// **Verify email with verification code**
  ///
  /// **Strategy**: executeOnlineFirst (server verification required)
  /// **Performance**: <2s for email verification
  /// **Security**: Code validation and account activation
  Future<Either<Failure, bool>> verifyEmail(String code);

  /// **Change user password**
  ///
  /// **Strategy**: executeOnlineFirst (server password update)
  /// **Performance**: <2s for password change
  /// **Security**: Current password validation, new password strength
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// **Update device token for push notifications**
  ///
  /// **Strategy**: executeOnlineFirst with offline queuing
  /// **Performance**: <1s for token update
  /// **Use Case**: Push notification registration
  Future<Either<Failure, bool>> updateDeviceToken(String deviceToken);
}