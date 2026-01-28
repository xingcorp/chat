import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/services/graphql/graphql_client_wrapper.dart';
import 'package:injectable/injectable.dart';

/// Interface for remote authentication operations
abstract class AuthRemoteDataSource {
  /// Login with email and password
  Future<UserModel> login(String email, String password);
  
  /// Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? avatar,
  });
  
  /// Logout the current user
  Future<bool> logout();
  
  /// Send a password reset email
  Future<bool> forgotPassword(String email);
  
  /// Reset password with reset code
  Future<bool> resetPassword(String code, String newPassword);
  
  /// Change password for authenticated user
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Verify email with verification code
  Future<bool> verifyEmail(String code);
  
  /// Refresh user data
  Future<UserModel?> refreshUser(String userId);
  
  /// Get access token
  Future<String?> getAccessToken();
  
  /// Refresh authentication token
  Future<String?> refreshToken();
  
  /// Update device token for push notifications
  Future<bool> updateDeviceToken(String token);
}

/// Implementation of [AuthRemoteDataSource] using GraphQL
@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GraphQLClientWrapper _client;
  
  /// Constructor
  AuthRemoteDataSourceImpl(this._client);
  
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final result = await _client.mutate(
        '''
        mutation Login(\$email: String!, \$password: String!) {
          login(email: \$email, password: \$password) {
            user {
              id
              email
              name
              avatar
              status
              createdAt
              updatedAt
            }
            token
          }
        }
        ''',
        variables: {
          'email': email,
          'password': password,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Login failed',
        );
      }
      
      final token = result.data?['login']['token'] as String;
      // Store token for future requests
      await _client.setToken(token);
      
      return UserModel.fromJson(result.data?['login']['user']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Login failed: $e');
    }
  }
  
  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? avatar,
  }) async {
    try {
      final result = await _client.mutate(
        '''
        mutation Register(\$input: RegisterInput!) {
          register(input: \$input) {
            user {
              id
              email
              name
              avatar
              status
              createdAt
              updatedAt
            }
            token
          }
        }
        ''',
        variables: {
          'input': {
            'email': email,
            'password': password,
            'name': name,
            if (avatar != null) 'avatar': avatar,
          },
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Registration failed',
        );
      }
      
      final token = result.data?['register']['token'] as String;
      // Store token for future requests
      await _client.setToken(token);
      
      return UserModel.fromJson(result.data?['register']['user']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Registration failed: $e');
    }
  }
  
  @override
  Future<bool> logout() async {
    try {
      final result = await _client.mutate(
        '''
        mutation Logout {
          logout
        }
        ''',
      );
      
      // Clear the stored token
      await _client.clearToken();
      
      if (result.hasException) {
        return false;
      }
      
      return result.data?['logout'] ?? false;
    } catch (e) {
      // Even if server logout fails, clear the token
      await _client.clearToken();
      return false;
    }
  }
  
  @override
  Future<bool> forgotPassword(String email) async {
    try {
      final result = await _client.mutate(
        '''
        mutation ForgotPassword(\$email: String!) {
          forgotPassword(email: \$email)
        }
        ''',
        variables: {
          'email': email,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to send reset email',
        );
      }
      
      return result.data?['forgotPassword'] ?? false;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to send reset email: $e');
    }
  }
  
  @override
  Future<bool> resetPassword(String code, String newPassword) async {
    try {
      final result = await _client.mutate(
        '''
        mutation ResetPassword(\$code: String!, \$newPassword: String!) {
          resetPassword(code: \$code, newPassword: \$newPassword)
        }
        ''',
        variables: {
          'code': code,
          'newPassword': newPassword,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to reset password',
        );
      }
      
      return result.data?['resetPassword'] ?? false;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to reset password: $e');
    }
  }
  
  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final result = await _client.mutate(
        '''
        mutation ChangePassword(\$currentPassword: String!, \$newPassword: String!) {
          changePassword(currentPassword: \$currentPassword, newPassword: \$newPassword)
        }
        ''',
        variables: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to change password',
        );
      }
      
      return result.data?['changePassword'] ?? false;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to change password: $e');
    }
  }
  
  @override
  Future<bool> verifyEmail(String code) async {
    try {
      final result = await _client.mutate(
        '''
        mutation VerifyEmail(\$code: String!) {
          verifyEmail(code: \$code)
        }
        ''',
        variables: {
          'code': code,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to verify email',
        );
      }
      
      return result.data?['verifyEmail'] ?? false;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to verify email: $e');
    }
  }
  
  @override
  Future<UserModel?> refreshUser(String userId) async {
    try {
      final result = await _client.query(
        '''
        query GetUser(\$id: ID!) {
          user(id: \$id) {
            id
            email
            name
            avatar
            status
            createdAt
            updatedAt
          }
        }
        ''',
        variables: {
          'id': userId,
        },
      );
      
      if (result.hasException) {
        throw ServerException(
          message: result.exception?.graphqlErrors.first.message ?? 'Failed to refresh user',
        );
      }
      
      if (result.data?['user'] == null) {
        return null;
      }
      
      return UserModel.fromJson(result.data?['user']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to refresh user: $e');
    }
  }
  
  @override
  Future<String?> getAccessToken() async {
    return _client.getToken();
  }
  
  @override
  Future<String?> refreshToken() async {
    try {
      final result = await _client.mutate(
        '''
        mutation RefreshToken {
          refreshToken {
            token
          }
        }
        ''',
      );
      
      if (result.hasException) {
        return null;
      }
      
      final token = result.data?['refreshToken']['token'] as String?;
      if (token != null) {
        await _client.setToken(token);
      }
      
      return token;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<bool> updateDeviceToken(String token) async {
    try {
      final result = await _client.mutate(
        '''
        mutation UpdateDeviceToken(\$token: String!) {
          updateDeviceToken(token: \$token)
        }
        ''',
        variables: {
          'token': token,
        },
      );
      
      if (result.hasException) {
        return false;
      }
      
      return result.data?['updateDeviceToken'] ?? false;
    } catch (e) {
      return false;
    }
  }
} 