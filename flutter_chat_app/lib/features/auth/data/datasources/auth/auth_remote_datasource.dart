import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:injectable/injectable.dart';

/// Interface for remote authentication operations
abstract class AuthRemoteDataSource {
  /// Login with email and password
  Future<UserModel> login(String phone, String password);
  
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
@lazySingleton
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GraphQLClientWrapper _client;
  final TokenRepository _tokenRepository;
  
  /// Constructor
  AuthRemoteDataSourceImpl(this._client, this._tokenRepository);

  UserModel _mapApiUserToUserModel(Map<String, dynamic> user) {
    final serverId = (user['id'] ?? '').toString();
    final email = user['email'] as String?;
    final username = (user['username'] as String?) ??
        (email != null && email.contains('@') ? email.split('@').first : null) ??
        serverId;
    final displayName = (user['fullname'] as String?) ??
        (user['name'] as String?) ??
        (user['displayName'] as String?) ??
        username;
    String? avatarUrl = user['avatarUrl'] as String?;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final avatarRaw = user['avatar'];
      if (avatarRaw is String) {
        avatarUrl = avatarRaw;
      } else if (avatarRaw is Map) {
        final location = avatarRaw['location'];
        avatarUrl = location is String ? location : location?.toString();
      }
    }
    // Ưu tiên imageUrls từ officeUser nếu có
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final imageUrls = user['imageUrls'];
      if (imageUrls is List && imageUrls.isNotEmpty) {
        avatarUrl = imageUrls.first?.toString();
      }
    }
    final isOnline = user['isOnline'] as bool? ?? false;

    final lastSeenRaw = user['lastSeen'];
    DateTime lastSeen;
    if (lastSeenRaw is String) {
      lastSeen = DateTime.tryParse(lastSeenRaw) ?? DateTime.now();
    } else {
      lastSeen = DateTime.now();
    }

    final statusRaw = user['statusMessage'] ?? user['status'];
    final statusMessage = statusRaw is String ? statusRaw : statusRaw?.toString();

    final rolesRaw = user['roles'];
    final roles = rolesRaw is List
        ? rolesRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return UserModel(
      serverId: serverId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      isOnline: isOnline,
      lastSeen: lastSeen,
      statusMessage: statusMessage,
      roles: roles,
    );
  }
  
  @override
  Future<UserModel> login(String phone, String password) async {
    try {
      final result = await _client.mutate(
        '''
        mutation IdentityOfficeLogin(\$credential: UserLoginArgs!) {
          identityOfficeLogin(credential: \$credential) {
            accessToken
            refreshToken
            user {
              id
              fullname
              phone
              email
              avatar { location }
            }
          }
        }
        ''',
        variables: {
          'credential': {
            'phone': phone,
            'password': password,
          },
        },
        operationName: 'IdentityOfficeLogin',
      );

      final loginData = result['identityOfficeLogin'] as Map<String, dynamic>?;
      if (loginData == null) {
        throw ServerException(message: 'Login failed');
      }

      final accessToken = loginData['accessToken'] as String?;
      final refreshToken = loginData['refreshToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw ServerException(message: 'Login failed');
      }

      await _tokenRepository.saveTokens(
        AuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken ?? '',
        ),
      );

      // Login response chỉ có avatar { location } (IAM), không có officeUser.
      // Gọi identityProfile để lấy full profile với officeUser (avatar + name chính xác).
      final userData = loginData['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw ServerException(message: 'Login failed');
      }
      final userId = (userData['id'] ?? '').toString().trim();

      if (userId.isNotEmpty) {
        try {
          final fullProfile = await refreshUser(userId);
          if (fullProfile != null) {
            return fullProfile;
          }
        } catch (_) {
          // Fallback to login response nếu refresh thất bại
        }
      }

      return _mapApiUserToUserModel(userData);
    } catch (e) {
      if (e is AppException) rethrow;
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

      final registerData = result['register'] as Map<String, dynamic>?;
      if (registerData == null) {
        throw ServerException(message: 'Registration failed');
      }

      final token = registerData['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _tokenRepository.saveAccessToken(token);
      }

      final userData = registerData['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw ServerException(message: 'Registration failed');
      }

      return _mapApiUserToUserModel(userData);
    } catch (e) {
      if (e is AppException) rethrow;
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
        operationName: 'Logout',
      );
      
      await _tokenRepository.clear();

      return result['logout'] == true;
    } catch (e) {
      await _tokenRepository.clear();
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
        operationName: 'ForgotPassword',
      );

      return result['forgotPassword'] == true;
    } catch (e) {
      if (e is AppException) rethrow;
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
        operationName: 'ResetPassword',
      );

      return result['resetPassword'] == true;
    } catch (e) {
      if (e is AppException) rethrow;
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
        operationName: 'ChangePassword',
      );

      return result['changePassword'] == true;
    } catch (e) {
      if (e is AppException) rethrow;
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
        operationName: 'VerifyEmail',
      );

      return result['verifyEmail'] == true;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to verify email: $e');
    }
  }
  
  @override
  Future<UserModel?> refreshUser(String userId) async {
    try {
      final result = await _client.query(
        '''
        query IdentityProfile {
          identityProfile {
            id
            name
            phone
            email
            avatar { location }
            officeUser {
              id
              fullname
              phone
              email
              imageUrls
              status
            }
          }
        }
        ''',
        operationName: 'IdentityProfile',
      );

      final profile = result['identityProfile'] as Map<String, dynamic>?;
      if (profile == null) {
        return null;
      }

      // Lấy avatar và name từ officeUser (nguồn chính xác nhất).
      final officeUser = profile['officeUser'] as Map<String, dynamic>?;
      final officeFullName = (officeUser?['fullname'] as String?)?.trim();
      final officeImageUrls = officeUser?['imageUrls'];
      final hasOfficeImageUrls =
          officeImageUrls is List && officeImageUrls.isNotEmpty;

      final mergedProfile = <String, dynamic>{
        ...profile,
        if (officeUser != null) ...officeUser,
        'id': (profile['id'] ?? '').toString().trim(),
        if (officeFullName != null && officeFullName.isNotEmpty) ...{
          'fullname': officeFullName,
          'name': officeFullName,
        },
        if (hasOfficeImageUrls) ...{
          'imageUrls': officeImageUrls,
          'avatar': null,
          'avatarUrl': null,
        },
      };

      return UserModel.fromMap(mergedProfile);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to refresh user: $e');
    }
  }
  
  @override
  Future<String?> getAccessToken() async {
    return _tokenRepository.getAccessToken();
  }
  
  @override
  Future<String?> refreshToken() async {
    try {
      final currentRefreshToken = await _tokenRepository.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        return null;
      }

      Future<String?> attemptStorePair(
        Map<String, dynamic>? data,
        String refreshFallback,
      ) async {
        final accessToken = data?['accessToken'] as String?;
        final refreshToken = data?['refreshToken'] as String?;
        if (accessToken == null || accessToken.isEmpty) {
          return null;
        }

        await _tokenRepository.saveTokens(
          AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken ?? refreshFallback,
          ),
        );
        return accessToken;
      }

      try {
        final result = await _client.mutate(
          '''
          mutation RefreshToken(\$refreshToken: String!) {
            refreshToken(refreshToken: \$refreshToken) {
              accessToken
              refreshToken
            }
          }
          ''',
          variables: {
            'refreshToken': currentRefreshToken,
          },
          operationName: 'RefreshToken',
        );

        final refreshData = result['refreshToken'] as Map<String, dynamic>?;
        final token = await attemptStorePair(refreshData, currentRefreshToken);
        if (token != null) {
          return token;
        }
      } catch (_) {}

      try {
        final result = await _client.mutate(
          '''
          mutation IdentityRefreshToken(\$refreshToken: String!) {
            identityRefreshToken(refreshToken: \$refreshToken) {
              accessToken
              refreshToken
            }
          }
          ''',
          variables: {
            'refreshToken': currentRefreshToken,
          },
          operationName: 'IdentityRefreshToken',
        );

        final refreshData = result['identityRefreshToken'] as Map<String, dynamic>?;
        final token = await attemptStorePair(refreshData, currentRefreshToken);
        if (token != null) {
          return token;
        }
      } catch (_) {}

      try {
        final result = await _client.mutate(
          '''
          mutation RefreshToken {
            refreshToken {
              token
            }
          }
          ''',
          operationName: 'RefreshTokenNoArgs',
        );

        final token = (result['refreshToken'] as Map<String, dynamic>?)?['token'] as String?;
        if (token == null || token.isEmpty) {
          return null;
        }

        await _tokenRepository.saveAccessToken(token);
        return token;
      } catch (_) {}

      return null;
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
        operationName: 'UpdateDeviceToken',
      );

      return result['updateDeviceToken'] == true;
    } catch (e) {
      return false;
    }
  }
} 