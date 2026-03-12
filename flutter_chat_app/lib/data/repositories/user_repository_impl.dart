import 'package:flutter_chat_app/core/base/base_repository.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:injectable/injectable.dart';

/// **ENTERPRISE USER REPOSITORY IMPLEMENTATION**
///
/// Implements UserRepository using BaseRepository patterns with:
/// - Offline-first strategy for user profiles (cached data)
/// - Online-first strategy for user search (fresh results)
/// - Remote-only strategy for user updates (server confirmation)
/// - Comprehensive error handling and performance monitoring
@LazySingleton(as: UserRepository)
class UserRepositoryImpl extends BaseRepository implements UserRepository {
  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource _remoteDataSource;

  /// Constructor with enterprise dependencies
  UserRepositoryImpl({
    required UserLocalDataSource localDataSource,
    required UserRemoteDataSource remoteDataSource,
    required super.networkInfo,
    required super.logger,
    required super.performanceMonitor,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, User?>> getUserById(String userId) async {
    return executeOnlineFirst<User?>(
      remoteDataSource: () async {
        final remoteUser = await _remoteDataSource.getUserProfile(userId);
        return remoteUser?.toDomain();
      },
      localDataSource: () async {
        final localUser = await _localDataSource.getUserById(userId);
        return localUser?.toDomain();
      },
      cacheData: (user) async {
        if (user != null) {
          final userModel = UserModel.fromDomain(user);
          await _localDataSource.saveUser(userModel);
        }
      },
      operationName: 'getUserById',
    );
  }

  @override
  Future<Either<Failure, List<User>>> getUsers([int limit = 50]) async {
    return executeOfflineFirst<List<User>>(
      localDataSource: () async {
        final localUsers = await _localDataSource.getAllUsers();
        return localUsers.map((model) => model.toDomain()).toList();
      },
      remoteDataSource: () async {
        // Get user contacts as the list of users (limited implementation)
        final remoteUsers = await _remoteDataSource.getUserContacts();
        return remoteUsers.map((model) => model.toDomain()).toList();
      },
      cacheData: (users) async {
        final userModels =
            users.map((user) => UserModel.fromDomain(user)).toList();
        await _localDataSource.saveUsers(userModels);
      },
      operationName: 'getUsers',
    );
  }

  @override
  Future<Either<Failure, List<User>>> searchUsers(
    String query, {
    int limit = 20,
    int page = 0,
  }) async {
    return executeOnlineFirst<List<User>>(
      remoteDataSource: () async {
        final remoteUsers = await _remoteDataSource.searchUsers(
          query,
          limit: limit,
          page: page,
        );
        return remoteUsers.map((model) => model.toDomain()).toList();
      },
      localDataSource: () async {
        // Local search - filter from all users
        final allUsers = await _localDataSource.getAllUsers();
        final filteredUsers = allUsers
            .where((user) =>
                user.username.toLowerCase().contains(query.toLowerCase()) ||
                (user.displayName
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .skip(page * limit)
            .take(limit)
            .toList();
        return filteredUsers.map((model) => model.toDomain()).toList();
      },
      cacheData: (users) async {
        final userModels =
            users.map((user) => UserModel.fromDomain(user)).toList();
        await _localDataSource.saveUsers(userModels);
      },
      operationName: 'searchUsers',
    );
  }

  @override
  Future<Either<Failure, User?>> updateUserStatus(
      String userId, String status) async {
    return executeRemoteOnly<User?>(
      remoteDataSource: () async {
        // TODO: Implement proper remote user status update
        final isOnline =
            await _remoteDataSource.setUserStatus(status == 'online');
        if (isOnline) {
          // Get updated user profile
          final updatedUser = await _remoteDataSource.getUserProfile(userId);
          return updatedUser.toDomain();
        }
        return null;
      },
      cacheData: (user) async {
        if (user != null) {
          final userModel = UserModel.fromDomain(user);
          await _localDataSource.saveUser(userModel);
        }
      },
      operationName: 'updateUserStatus',
    );
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    return executeRemoteOnly<User>(
      remoteDataSource: () async {
        final updatedUser = await _remoteDataSource.updateUserProfile(
          displayName: displayName,
          bio: bio,
          avatarUrl: avatarUrl,
        );
        return updatedUser.toDomain();
      },
      cacheData: (user) async {
        final userModel = UserModel.fromDomain(user);
        await _localDataSource.saveUser(userModel);
        await _localDataSource.saveCurrentUser(userModel);
      },
      operationName: 'updateUserProfile',
    );
  }

  /// **ENTERPRISE SYNC STRATEGY**
  ///
  /// Background synchronization of user data using BaseRepository sync pattern
  Future<Either<Failure, void>> syncUsers() async {
    return executeSyncStrategy(
      syncOperation: () async {
        logger.d('Starting user synchronization...');

        // Get latest users from remote
        final remoteUsers = await _remoteDataSource.getUserContacts();

        // Update local cache
        await _localDataSource.saveUsers(remoteUsers);

        logger.i('User synchronization completed successfully');
      },
      operationName: 'syncUsers',
    );
  }

  // Missing interface methods - implement with placeholders for compilation success

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return executeOnlineFirst<User?>(
      remoteDataSource: () async {
        final remoteUser = await _remoteDataSource.getCurrentUserProfile();
        return remoteUser.toDomain();
      },
      localDataSource: () async {
        final currentUser = await _localDataSource.getCurrentUser();
        return currentUser?.toDomain();
      },
      cacheData: (user) async {
        if (user != null) {
          final userModel = UserModel.fromDomain(user);
          await _localDataSource.saveCurrentUser(userModel);
        }
      },
      operationName: 'getCurrentUser',
    );
  }

  @override
  Future<Either<Failure, List<User>>> getUserContacts() async {
    return executeOfflineFirst<List<User>>(
      localDataSource: () async {
        // Get all users as contacts (simplified implementation)
        final localUsers = await _localDataSource.getAllUsers();
        return localUsers.map((model) => model.toDomain()).toList();
      },
      remoteDataSource: () async {
        final remoteContacts = await _remoteDataSource.getUserContacts();
        return remoteContacts.map((model) => model.toDomain()).toList();
      },
      cacheData: (contacts) async {
        final contactModels =
            contacts.map((user) => UserModel.fromDomain(user)).toList();
        await _localDataSource.saveUsers(contactModels);
      },
      operationName: 'getUserContacts',
    );
  }

  @override
  Future<Either<Failure, void>> saveUserLocally(User user) async {
    return executeLocalOnly<void>(
      localDataSource: () async {
        final userModel = UserModel.fromDomain(user);
        await _localDataSource.saveUser(userModel);
      },
      operationName: 'saveUserLocally',
    );
  }

  @override
  Future<Either<Failure, void>> saveCurrentUser(User user) async {
    return executeLocalOnly<void>(
      localDataSource: () async {
        final userModel = UserModel.fromDomain(user);
        await _localDataSource.saveCurrentUser(userModel);
      },
      operationName: 'saveCurrentUser',
    );
  }

  @override
  Future<Either<Failure, void>> clearCurrentUser() async {
    return executeLocalOnly<void>(
      localDataSource: () async {
        await _localDataSource.clearCurrentUser();
      },
      operationName: 'clearCurrentUser',
    );
  }

  @override
  Future<Either<Failure, bool>> setUserStatus(bool isOnline) async {
    return executeRemoteOnly<bool>(
      remoteDataSource: () async {
        return await _remoteDataSource.setUserStatus(isOnline);
      },
      operationName: 'setUserStatus',
    );
  }

  @override
  Stream<Either<Failure, User>> subscribeToUserStatus(String userId) {
    try {
      // TODO: Implement proper real-time user status subscription
      // For now, return empty stream with proper error handling
      return Stream<Either<Failure, User>>.empty();
    } catch (e) {
      logger.e('Error subscribing to user status: $e');
      return Stream.value(Left(ServerFailure(
          message: 'Failed to subscribe to user status: ${e.toString()}')));
    }
  }
}
