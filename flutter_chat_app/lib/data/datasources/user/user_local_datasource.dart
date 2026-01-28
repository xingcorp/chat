import 'dart:convert';

import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:injectable/injectable.dart';

/// Interface for local user data operations
abstract class UserLocalDataSource {
  /// Get the current logged-in user
  Future<UserModel?> getCurrentUser();
  
  /// Save the current user data
  Future<void> saveCurrentUser(UserModel user);
  
  /// Get a user by ID
  Future<UserModel?> getUserById(String userId);
  
  /// Get all stored users
  Future<List<UserModel>> getAllUsers();
  
  /// Save a user to local storage
  Future<void> saveUser(UserModel user);
  
  /// Save multiple users to local storage
  Future<void> saveUsers(List<UserModel> users);
  
  /// Delete a user from local storage
  Future<void> deleteUser(String userId);
  
  /// Clear user data (for logout)
  Future<void> clearCurrentUser();
  
  /// Get a stream of all users
  Stream<List<UserModel>> watchAllUsers();
  
  /// Get a stream for a specific user
  Stream<UserModel?> watchUser(String userId);
}

/// Implementation of [UserLocalDataSource]
@LazySingleton(as: UserLocalDataSource)
class UserLocalDataSourceImpl implements UserLocalDataSource {
  final LocalStorage _localStorage;
  
  /// The collection name for all users
  static const String _usersCollection = 'users';
  
  /// The key for current user
  static const String _currentUserKey = 'current_user';
  
  /// Constructor
  UserLocalDataSourceImpl(this._localStorage);
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = await _localStorage.getString(_currentUserKey);
      if (userJson == null) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromMap(userMap);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> saveCurrentUser(UserModel user) async {
    final userJson = jsonEncode(user.toMap());
    await _localStorage.saveString(_currentUserKey, userJson);

    // Also save to users collection
    await saveUser(user);
  }
  
  @override
  Future<UserModel?> getUserById(String userId) async {
    // TODO: Implement proper user retrieval by ID
    return null;
  }
  
  @override
  Future<List<UserModel>> getAllUsers() async {
    // TODO: Implement proper user collection retrieval
    return [];
  }

  @override
  Future<void> saveUser(UserModel user) async {
    // TODO: Implement proper user saving
  }
  
  @override
  Future<void> saveUsers(List<UserModel> users) async {
    // TODO: Implement proper bulk user saving
  }

  @override
  Future<void> deleteUser(String userId) async {
    // TODO: Implement proper user deletion
  }

  @override
  Future<void> clearCurrentUser() async {
    await _localStorage.remove(_currentUserKey);
  }

  @override
  Stream<List<UserModel>> watchAllUsers() {
    // TODO: Implement proper user collection watching
    return Stream.empty();
  }

  @override
  Stream<UserModel?> watchUser(String userId) {
    // TODO: Implement proper user watching
    return Stream.empty();
  }
}