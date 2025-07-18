import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
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
        // TODO: Implement proper remote user fetching
        final remoteUsers = <UserModel>[];
        
        // Save to local cache
        await _localDataSource.saveUsers(remoteUsers);
        
        // Return as domain entities
        return remoteUsers.map((model) => model.toDomain()).toList();
      } catch (e) {
        // Fall back to local data
        final localUsers = await _localDataSource.getAllUsers();
        return localUsers.map((model) => model.toDomain()).toList();
      }
    } else {
      // No internet, use local data
      final localUsers = await _localDataSource.getAllUsers();
      return localUsers.map((model) => model.toDomain()).toList();
    }
  }

  @override
  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    if (await _networkInfo.isConnected) {
      try {
        // Search on server
        final remoteUsers = await _remoteDataSource.searchUsers(query);
        
        // Cache results
        await _localDataSource.saveUsers(remoteUsers);
        
        return remoteUsers.map((model) => model.toDomain()).toList();
      } catch (e) {
        // Fall back to local search - filter from all users
        final allUsers = await _localDataSource.getAllUsers();
        final filteredUsers = allUsers.where((user) =>
          user.username.toLowerCase().contains(query.toLowerCase()) ||
          (user.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).take(limit).toList();
        return filteredUsers.map((model) => model.toDomain()).toList();
      }
    } else {
      // Offline - search locally - filter from all users
      final allUsers = await _localDataSource.getAllUsers();
      final filteredUsers = allUsers.where((user) =>
        user.username.toLowerCase().contains(query.toLowerCase()) ||
        (user.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).take(limit).toList();
      return filteredUsers.map((model) => model.toDomain()).toList();
    }
  }

  @override
  Future<User?> updateUserStatus(String userId, String status) async {
    if (!(await _networkInfo.isConnected)) {
      // Can't update status when offline
      return null;
    }

    try {
      // TODO: Implement proper remote user status update
      final updatedUser = null; // Placeholder
      
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
  Future<User> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      // Can't update profile when offline
      throw Exception('No internet connection');
    }

    try {
      // TODO: Implement proper user profile update
      // For now, get current user and return it
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        return currentUser;
      }

      throw Exception('No current user found');
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Helper method for syncing users (not part of interface)
  Future<void> syncUsers() async {
    if (!(await _networkInfo.isConnected)) {
      return; // Can't sync when offline
    }

    try {
      // TODO: Implement proper user syncing
      print('User syncing not yet implemented');
    } catch (e) {
      // Log error but don't throw
      print('Error syncing users: $e');
    }
  }

  // Missing interface methods - implement with placeholders for compilation success

  @override
  Future<User?> getCurrentUser() async {
    try {
      final currentUser = await _localDataSource.getCurrentUser();
      return currentUser?.toDomain();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final users = await _localDataSource.getAllUsers();
      return users.map((model) => model.toDomain()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<User>> getUserContacts() async {
    // TODO: Implement proper user contacts retrieval
    return [];
  }

  @override
  Future<void> saveUserLocally(User user) async {
    // TODO: Implement proper user local saving
    // Would need UserModel.fromDomain() method
  }

  @override
  Future<void> saveCurrentUser(User user) async {
    // TODO: Implement proper current user saving
    // Would need UserModel.fromDomain() method
  }

  @override
  Future<void> clearCurrentUser() async {
    await _localDataSource.clearCurrentUser();
  }

  @override
  Future<bool> setUserStatus(bool isOnline) async {
    // TODO: Implement proper user status setting
    return false;
  }

  @override
  Stream<User> subscribeToUserStatus(String userId) {
    // TODO: Implement proper user status subscription
    return Stream.empty();
  }
}