import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';

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
      return await _localStorage.getItem<UserModel>(
        _currentUserKey,
        _currentUserKey,
        fromJson: UserModel.fromJson,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> saveCurrentUser(UserModel user) async {
    await _localStorage.saveItem<UserModel>(
      _currentUserKey,
      _currentUserKey,
      user,
      toJson: (user) => user.toJson(),
    );
    
    // Also save to users collection
    await saveUser(user);
  }
  
  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      return await _localStorage.getItem<UserModel>(
        _usersCollection,
        userId,
        fromJson: UserModel.fromJson,
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final users = await _localStorage.getCollection<UserModel>(
        _usersCollection,
        fromJson: UserModel.fromJson,
      );
      return users;
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> saveUser(UserModel user) async {
    await _localStorage.saveItem<UserModel>(
      _usersCollection,
      user.id,
      user,
      toJson: (user) => user.toJson(),
    );
  }
  
  @override
  Future<void> saveUsers(List<UserModel> users) async {
    if (users.isEmpty) return;
    
    await _localStorage.saveItems<UserModel>(
      _usersCollection,
      {for (var user in users) user.id: user},
      toJson: (user) => user.toJson(),
    );
  }
  
  @override
  Future<void> deleteUser(String userId) async {
    await _localStorage.deleteItem(_usersCollection, userId);
  }
  
  @override
  Future<void> clearCurrentUser() async {
    await _localStorage.deleteItem(_currentUserKey, _currentUserKey);
  }
  
  @override
  Stream<List<UserModel>> watchAllUsers() {
    return _localStorage.watchCollection<UserModel>(
      _usersCollection,
      fromJson: UserModel.fromJson,
    );
  }
  
  @override
  Stream<UserModel?> watchUser(String userId) {
    return _localStorage.watchItem<UserModel>(
      _usersCollection,
      userId,
      fromJson: UserModel.fromJson,
    );
  }
} 