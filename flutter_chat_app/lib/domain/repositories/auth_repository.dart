import 'package:flutter_chat_app/domain/entities/user.dart';

/// Interface for authentication repository operations
abstract class AuthRepository {
  /// Check if the user is logged in
  Future<bool> isLoggedIn();
  
  /// Login with email and password
  Future<User> login(String email, String password);
  
  /// Register a new user
  Future<User> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  });
  
  /// Logout the current user
  Future<void> logout();
  
  /// Reset password with email
  Future<bool> resetPassword(String email);
  
  /// Get the current user's access token
  Future<String?> getAccessToken();
  
  /// Refresh the authentication token
  Future<String?> refreshToken();
  
  /// Get the current authenticated user
  Future<User?> getCurrentUser();
  
  /// Update device token for push notifications
  Future<bool> updateDeviceToken(String deviceToken);
} 