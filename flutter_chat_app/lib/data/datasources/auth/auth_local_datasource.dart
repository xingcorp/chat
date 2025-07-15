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
    await _secureStorage.write(_authTokenKey, token);
  }
  
  @override
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(_authTokenKey);
  }
  
  @override
  Future<void> removeAuthToken() async {
    await _secureStorage.delete(_authTokenKey);
  }
  
  @override
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(_refreshTokenKey, token);
  }
  
  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(_refreshTokenKey);
  }
  
  @override
  Future<void> removeRefreshToken() async {
    await _secureStorage.delete(_refreshTokenKey);
  }
  
  @override
  Future<void> saveCurrentUser(UserModel user) async {
    final userJson = user.toJson();
    await _secureStorage.write(_currentUserKey, userJson.toString());
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJsonString = await _secureStorage.read(_currentUserKey);
      if (userJsonString == null) return null;
      
      // Parse JSON string back to Map
      // Note: This is a simplified implementation
      // In production, use proper JSON serialization
      return null; // TODO: Implement proper JSON parsing
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> removeCurrentUser() async {
    await _secureStorage.delete(_currentUserKey);
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
