import 'package:flutter_chat_app/domain/entities/user.dart';

/// Interface for user repository operations
abstract class UserRepository {
  /// Get the current authenticated user
  Future<User?> getCurrentUser();
  
  /// Get user by ID
  Future<User?> getUserById(String userId);
  
  /// Get all users from the local database
  Future<List<User>> getAllUsers();
  
  /// Search for users by query string
  Future<List<User>> searchUsers(String query, {int limit = 20});
  
  /// Update current user profile
  Future<User> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  });
  
  /// Get the user's contacts/friends
  Future<List<User>> getUserContacts();
  
  /// Save user to local storage
  Future<void> saveUserLocally(User user);
  
  /// Save current user to local storage
  Future<void> saveCurrentUser(User user);
  
  /// Clear current user (for logout)
  Future<void> clearCurrentUser();
  
  /// Set user online status
  Future<bool> setUserStatus(bool isOnline);
  
  /// Subscribe to user status changes
  Stream<User> subscribeToUserStatus(String userId);
} 