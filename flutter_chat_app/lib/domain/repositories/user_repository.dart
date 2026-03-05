import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';

/// **ENTERPRISE USER REPOSITORY INTERFACE**
///
/// Defines user repository operations using Either pattern for comprehensive
/// error handling and enterprise-grade reliability.
///
/// **Error Handling**: All operations return Either<Failure, T> for proper error management
/// **Performance**: Operations are monitored and optimized for enterprise scale
/// **Caching**: Supports offline-first and online-first strategies
abstract class UserRepository {
  /// Get the current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Get user by ID with online-first strategy
  Future<Either<Failure, User?>> getUserById(String userId);

  /// Get all users with offline-first strategy (cached data)
  Future<Either<Failure, List<User>>> getUsers([int limit = 50]);

  /// Search for users by query string with online-first strategy
  Future<Either<Failure, List<User>>> searchUsers(
    String query, {
    int limit = 20,
    int page = 0,
  });

  /// Update user status with remote-only strategy
  Future<Either<Failure, User?>> updateUserStatus(String userId, String status);

  /// Update current user profile with remote-only strategy
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  });

  /// Get the user's contacts/friends with offline-first strategy
  Future<Either<Failure, List<User>>> getUserContacts();

  /// Save user to local storage (local-only strategy)
  Future<Either<Failure, void>> saveUserLocally(User user);

  /// Save current user to local storage (local-only strategy)
  Future<Either<Failure, void>> saveCurrentUser(User user);

  /// Clear current user (for logout) - local-only strategy
  Future<Either<Failure, void>> clearCurrentUser();

  /// Set user online status with remote-only strategy
  Future<Either<Failure, bool>> setUserStatus(bool isOnline);

  /// Subscribe to user status changes (real-time stream)
  Stream<Either<Failure, User>> subscribeToUserStatus(String userId);
}
