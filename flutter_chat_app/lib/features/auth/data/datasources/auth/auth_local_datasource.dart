import 'dart:convert';

import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';

/// Interface for local authentication data source operations
abstract class AuthLocalDataSource {
  /// Save user authentication token
  Future<void> saveAuthToken(String token);
  
  /// Get stored authentication token
  Future<String?> getAuthToken();
  
  /// Remove authentication token
  Future<void> removeAuthToken();
  
  /// Save refresh token
  Future<void> saveRefreshToken(String token);
  
  /// Get stored refresh token
  Future<String?> getRefreshToken();
  
  /// Remove refresh token
  Future<void> removeRefreshToken();
  
  /// Save current user data
  Future<void> saveCurrentUser(UserModel user);
  
  /// Get current user data
  Future<UserModel?> getCurrentUser();
  
  /// Remove current user data
  Future<void> removeCurrentUser();
  
  /// Check if user is logged in
  Future<bool> isLoggedIn();
  
  /// Clear all authentication data
  Future<void> clearAuthData();
}

/// Implementation of [AuthLocalDataSource] using secure storage
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage _secureStorage;
  
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _currentUserKey = 'current_user';
  
  /// Constructor
  AuthLocalDataSourceImpl(this._secureStorage);
  
  @override
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.setString(_authTokenKey, token);
  }

  @override
  Future<String?> getAuthToken() async {
    return await _secureStorage.getString(_authTokenKey);
  }

  @override
  Future<void> removeAuthToken() async {
    await _secureStorage.remove(_authTokenKey);
  }
  
  @override
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.setString(_refreshTokenKey, token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.getString(_refreshTokenKey);
  }

  @override
  Future<void> removeRefreshToken() async {
    await _secureStorage.remove(_refreshTokenKey);
  }
  
  @override
  Future<void> saveCurrentUser(UserModel user) async {
    final userMap = user.toMap();
    await _secureStorage.setString(_currentUserKey, json.encode(userMap));
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJsonString = await _secureStorage.getString(_currentUserKey);
      if (userJsonString == null) return null;
      
      // Parse JSON string back to Map and create UserModel
      final userMap = json.decode(userJsonString) as Map<String, dynamic>;
      return UserModel.fromMap(userMap);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> removeCurrentUser() async {
    await _secureStorage.remove(_currentUserKey);
  }
  
  @override
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
  
  @override
  Future<void> clearAuthData() async {
    await Future.wait([
      removeAuthToken(),
      removeRefreshToken(),
      removeCurrentUser(),
    ]);
  }
}
