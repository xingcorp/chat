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
      query IdentityProfile {
        identityProfile {
          id
          name
          phone
          email
          avatar { location }
        }
      }
      ''',
      operationName: 'IdentityProfile',
    );

    final profile = result['identityProfile'] as Map<String, dynamic>?;
    if (profile == null) {
      throw Exception('Failed to get current user profile');
    }

    return UserModel.fromMap(profile);
  }
  
  @override
  Future<UserModel> getUserProfile(String userId) async {
    final result = await _client.query(
      '''
      query ManagementGetEmployee(\$id: String!) {
        managementGetEmployee(id: \$id) {
          id
          fullname
          phone
          email
          status
          imageUrls
        }
      }
      ''',
      variables: {'id': userId},
      operationName: 'ManagementGetEmployee',
    );

    final profile = result['managementGetEmployee'] as Map<String, dynamic>?;
    if (profile == null) {
      throw Exception('Failed to get user profile');
    }

    return UserModel.fromMap(profile);
  }
  
  @override
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final result = await _client.query(
      '''
      query OfficeEmployeeFullOrgChartList(\$filter: UserOrgChartFilter!) {
        officeEmployeeFullOrgChartList(filter: \$filter) {
          officeUsers {
            id
            fullname
            phone
            email
            status
            imageUrls
          }
          count
        }
      }
      ''',
      variables: {
        'filter': {
          'page': 0,
          'size': limit,
          'keyword': query,
          'onlyActive': true,
        }
      },
      operationName: 'OfficeEmployeeFullOrgChartList',
    );

    final response = result['officeEmployeeFullOrgChartList'] as Map<String, dynamic>?;
    if (response == null) return [];

    final usersData = response['officeUsers'] as List<dynamic>?;
    if (usersData == null) return [];

    return usersData.map((userData) => UserModel.fromMap(userData)).toList();
  }
  
  @override
  Future<List<UserModel>> getUserContacts() async {
    final result = await _client.query(
      '''
      query OfficeEmployeeFullOrgChartList(\$filter: UserOrgChartFilter!) {
        officeEmployeeFullOrgChartList(filter: \$filter) {
          officeUsers {
            id
            fullname
            phone
            email
            status
            imageUrls
          }
          count
        }
      }
      ''',
      variables: {
        'filter': {
          'page': 0,
          'size': 100,
        }
      },
      operationName: 'OfficeEmployeeFullOrgChartList',
    );

    final response = result['officeEmployeeFullOrgChartList'] as Map<String, dynamic>?;
    if (response == null) return [];

    final contactsData = response['officeUsers'] as List<dynamic>?;
    if (contactsData == null) return [];

    return contactsData.map((contactData) => UserModel.fromMap(contactData)).toList();
  }
  
  @override
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    // Note: Server does not have a direct updateUserProfile mutation
    // Avatar update should use officeEmployeeAvatarUpdate mutation
    // For now, return current profile as this feature is not fully supported
    return await getCurrentUserProfile();
  }

  @override
  Future<bool> setUserStatus(bool isOnline) async {
    // Note: Server does not have setUserStatus mutation
    // User status is managed differently in this system
    // Return true as a no-op for now
    return true;
  }
} 