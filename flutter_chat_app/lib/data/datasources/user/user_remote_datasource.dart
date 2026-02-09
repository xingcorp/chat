import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:injectable/injectable.dart';

/// Interface for remote user data operations
abstract class UserRemoteDataSource {
  /// Get user profile for the current authenticated user
  Future<UserModel> getCurrentUserProfile();
  
  /// Get user profile by ID
  Future<UserModel> getUserProfile(String userId);
  
  /// Search for users by name or username
  Future<List<UserModel>> searchUsers(String query, {int limit = 20});
  
  /// Get user contacts/friends
  Future<List<UserModel>> getUserContacts();
  
  /// Update user profile
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  });
  
  /// Set user online/offline status
  Future<bool> setUserStatus(bool isOnline);
}

/// Implementation of [UserRemoteDataSource]
@lazySingleton
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final GraphQLClientWrapper _client;
  
  /// Constructor
  UserRemoteDataSourceImpl(this._client);
  
  @override
  Future<UserModel> getCurrentUserProfile() async {
    final result = await _client.query(
      '''
      query GetCurrentUserProfile {
        me {
          id
          username
          displayName
          email
          bio
          avatar { location }
          isOnline
          lastSeen
          createdAt
        }
      }
      ''',
      operationName: 'GetCurrentUserProfile',
    );

    final me = result['me'] as Map<String, dynamic>?;
    if (me == null) {
      throw Exception('Failed to get current user profile');
    }

    return UserModel.fromMap(me);
  }
  
  @override
  Future<UserModel> getUserProfile(String userId) async {
    final result = await _client.query(
      '''
      query GetUserProfile(\$userId: ID!) {
        getUserProfile(userId: \$userId) {
          id
          username
          displayName
          bio
          avatar { location }
          isOnline
          lastSeen
          createdAt
        }
      }
      ''',
      variables: {'userId': userId},
      operationName: 'GetUserProfile',
    );

    final profile = result['getUserProfile'] as Map<String, dynamic>?;
    if (profile == null) {
      throw Exception('Failed to get user profile');
    }

    return UserModel.fromMap(profile);
  }
  
  @override
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final result = await _client.query(
      '''
      query SearchUsers(\$query: String!, \$limit: Int!) {
        searchUsers(query: \$query, limit: \$limit) {
          id
          username
          displayName
          avatar { location }
          isOnline
          lastSeen
        }
      }
      ''',
      variables: {'query': query, 'limit': limit},
      operationName: 'SearchUsers',
    );

    final usersData = result['searchUsers'] as List<dynamic>?;
    if (usersData == null) return [];

    return usersData.map((userData) => UserModel.fromMap(userData)).toList();
  }
  
  @override
  Future<List<UserModel>> getUserContacts() async {
    final result = await _client.query(
      '''
      query GetUserContacts {
        getUserContacts {
          id
          username
          displayName
          avatar { location }
          isOnline
          lastSeen
        }
      }
      ''',
      operationName: 'GetUserContacts',
    );

    final contactsData = result['getUserContacts'] as List<dynamic>?;
    if (contactsData == null) return [];

    return contactsData.map((contactData) => UserModel.fromMap(contactData)).toList();
  }
  
  @override
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    // Build variables map with non-null values
    final variables = <String, dynamic>{};
    if (displayName != null) variables['displayName'] = displayName;
    if (bio != null) variables['bio'] = bio;
    if (avatarUrl != null) variables['avatarUrl'] = avatarUrl;
    
    // If no fields to update, return current profile
    if (variables.isEmpty) {
      return await getCurrentUserProfile();
    }
    
    final result = await _client.mutate(
      '''
      mutation UpdateUserProfile(\$displayName: String, \$bio: String, \$avatarUrl: String) {
        updateUserProfile(
          input: {
            displayName: \$displayName,
            bio: \$bio,
            avatarUrl: \$avatarUrl
          }
        ) {
          id
          username
          displayName
          email
          bio
          avatar { location }
          isOnline
          lastSeen
          createdAt
        }
      }
      ''',
      variables: variables,
      operationName: 'UpdateUserProfile',
    );

    final updated = result['updateUserProfile'] as Map<String, dynamic>?;
    if (updated == null) {
      throw Exception('Failed to update user profile');
    }

    return UserModel.fromMap(updated);
  }
  
  @override
  Future<bool> setUserStatus(bool isOnline) async {
    final result = await _client.mutate(
      '''
      mutation SetUserStatus(\$isOnline: Boolean!) {
        setUserStatus(isOnline: \$isOnline)
      }
      ''',
      variables: {'isOnline': isOnline},
      operationName: 'SetUserStatus',
    );

    return result['setUserStatus'] == true;
  }
} 