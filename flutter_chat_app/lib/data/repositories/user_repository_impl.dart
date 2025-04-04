import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';

/// Implementation of [UserRepository]
class UserRepositoryImpl implements UserRepository {
  final NetworkInfo _networkInfo;
  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource _remoteDataSource;

  /// Constructor
  UserRepositoryImpl(
    this._networkInfo,
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<User?> getUserById(String userId) async {
    try {
      // Try to get user from local storage first
      final user = await _localDataSource.getUserById(userId);
      if (user != null) {
        return user.toDomain();
      }

      // If not in local storage and we're online, fetch from remote
      if (await _networkInfo.isConnected) {
        final remoteUser = await _remoteDataSource.getUserProfile(userId);
        if (remoteUser != null) {
          // Save to local storage
          await _localDataSource.saveUser(remoteUser);
          return remoteUser.toDomain();
        }
      }

      return null;
    } catch (e) {
      // Log error and return null
      print('Error getting user: $e');
      return null;
    }
  }

  @override
  Future<List<User>> getUsers([int limit = 50]) async {
    if (await _networkInfo.isConnected) {
      try {
        // Get users from remote
        final remoteUsers = await _remoteDataSource.getUsers(limit);
        
        // Save to local cache
        await _localDataSource.saveUsers(remoteUsers);
        
        // Return as domain entities
        return remoteUsers.map((model) => model.toDomain()).toList();
      } catch (e) {
        // Fall back to local data
        final localUsers = await _localDataSource.getUsers();
        return localUsers.map((model) => model.toDomain()).toList();
      }
    } else {
      // No internet, use local data
      final localUsers = await _localDataSource.getUsers();
      return localUsers.map((model) => model.toDomain()).toList();
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    if (await _networkInfo.isConnected) {
      try {
        // Search on server
        final remoteUsers = await _remoteDataSource.searchUsers(query);
        
        // Cache results
        await _localDataSource.saveUsers(remoteUsers);
        
        return remoteUsers.map((model) => model.toDomain()).toList();
      } catch (e) {
        // Fall back to local search
        final localUsers = await _localDataSource.searchUsers(query);
        return localUsers.map((model) => model.toDomain()).toList();
      }
    } else {
      // Offline - search locally
      final localUsers = await _localDataSource.searchUsers(query);
      return localUsers.map((model) => model.toDomain()).toList();
    }
  }

  @override
  Future<User?> updateUserStatus(String userId, String status) async {
    if (!(await _networkInfo.isConnected)) {
      // Can't update status when offline
      return null;
    }

    try {
      // Update on server
      final updatedUser = await _remoteDataSource.updateUserStatus(userId, status);
      
      if (updatedUser != null) {
        // Update local cache
        await _localDataSource.saveUser(updatedUser);
        return updatedUser.toDomain();
      }
      
      return null;
    } catch (e) {
      print('Error updating user status: $e');
      return null;
    }
  }

  @override
  Future<User?> updateUserProfile({
    required String userId,
    String? name,
    String? avatar,
    String? bio,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      // Can't update profile when offline
      return null;
    }

    try {
      // Update on server
      final updatedUser = await _remoteDataSource.updateUserProfile(
        userId: userId,
        name: name,
        avatar: avatar,
        bio: bio,
      );
      
      if (updatedUser != null) {
        // Update local cache
        await _localDataSource.saveUser(updatedUser);
        return updatedUser.toDomain();
      }
      
      return null;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  @override
  Stream<List<User>> getUsersStream() {
    // This would typically combine local and remote streams
    // For simplicity, we'll just return the local stream
    return _localDataSource.getUsersStream()
      .map((models) => models.map((model) => model.toDomain()).toList());
  }

  @override
  Stream<User?> getUserStream(String userId) {
    // Listen to updates for a specific user
    return _localDataSource.getUserStream(userId)
      .map((model) => model?.toDomain());
  }

  @override
  Future<void> syncUsers() async {
    if (!(await _networkInfo.isConnected)) {
      return; // Can't sync when offline
    }

    try {
      // Get users from server
      final remoteUsers = await _remoteDataSource.getUsers(100);
      
      // Save to local storage
      await _localDataSource.saveUsers(remoteUsers);
    } catch (e) {
      // Log error but don't throw
      print('Error syncing users: $e');
    }
  }
} 