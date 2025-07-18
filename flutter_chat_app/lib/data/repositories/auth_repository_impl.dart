import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/auth/auth_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';
import 'package:logger/logger.dart';

/// Implementation of the [AuthRepository] interface
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authRemoteDataSource;
  final UserLocalDataSource _userLocalDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger = Logger();

  /// Constructor
  AuthRepositoryImpl(
    this._authRemoteDataSource,
    this._userLocalDataSource,
    this._networkInfo,
  );

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Try to get the current user from local storage
      final currentUser = await _userLocalDataSource.getCurrentUser();
      if (currentUser != null) {
        return currentUser.toDomain();
      }
      return null;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<User> login(String email, String password) async {
    if (!(await _networkInfo.isConnected)) {
      // Can't login when offline
      throw Exception('No internet connection');
    }

    try {
      // Attempt to login
      final userModel = await _authRemoteDataSource.login(email, password);

      // Save user to local storage
      await _userLocalDataSource.saveUser(userModel);
      await _userLocalDataSource.saveCurrentUser(userModel);

      return userModel.toDomain();
    } catch (e) {
      _logger.e('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      // Can't register when offline
      throw Exception('No internet connection');
    }

    try {
      // Attempt to register - map interface params to remote datasource params
      final userModel = await _authRemoteDataSource.register(
        email: email,
        password: password,
        name: displayName ?? username, // Use displayName if provided, otherwise username
        avatar: null, // Avatar not supported in interface
      );

      // Save user to local storage
      await _userLocalDataSource.saveUser(userModel);
      await _userLocalDataSource.saveCurrentUser(userModel);

      return userModel.toDomain();
    } catch (e) {
      _logger.e('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      // If we're online, tell the server we're logging out
      if (await _networkInfo.isConnected) {
        try {
          await _authRemoteDataSource.logout();
        } catch (e) {
          // Even if server logout fails, we'll still clear local session
          print('Error logging out from server: $e');
        }
      }
      
      // Clear current user
      await _userLocalDataSource.clearCurrentUser();
      
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      // Check if there's a current user in local storage
      final currentUser = await _userLocalDataSource.getCurrentUser();
      return currentUser != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> sendPasswordResetEmail(String email) async {
    if (!(await _networkInfo.isConnected)) {
      throw Exception('No internet connection');
    }

    try {
      // Request password reset
      return await _authRemoteDataSource.forgotPassword(email);
    } catch (e) {
      print('Error sending password reset: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  @override
  Future<User?> refreshUser(String userId) async {
    if (!(await _networkInfo.isConnected)) {
      return null; // Can't refresh when offline
    }

    try {
      // Get fresh user data from server
      final userModel = await _authRemoteDataSource.refreshUser(userId);
      
      if (userModel != null) {
        // Update in local storage
        await _userLocalDataSource.saveUser(userModel);
        return userModel.toDomain();
      }
      
      return null;
    } catch (e) {
      print('Error refreshing user: $e');
      return null;
    }
  }

  @override
  Future<bool> verifyEmail(String code) async {
    if (!(await _networkInfo.isConnected)) {
      throw Exception('No internet connection');
    }

    try {
      return await _authRemoteDataSource.verifyEmail(code);
    } catch (e) {
      print('Error verifying email: $e');
      throw Exception('Failed to verify email: $e');
    }
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw Exception('No internet connection');
    }

    try {
      return await _authRemoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _logger.e('Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _authRemoteDataSource.getAccessToken();
    } catch (e) {
      _logger.e('Error getting access token: $e');
      return null;
    }
  }

  @override
  Future<String?> refreshToken() async {
    try {
      return await _authRemoteDataSource.refreshToken();
    } catch (e) {
      _logger.e('Error refreshing token: $e');
      return null;
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    if (!(await _networkInfo.isConnected)) {
      throw Exception('No internet connection');
    }

    try {
      return await _authRemoteDataSource.forgotPassword(email);
    } catch (e) {
      _logger.e('Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<bool> updateDeviceToken(String deviceToken) async {
    try {
      if (await _networkInfo.isConnected) {
        return await _authRemoteDataSource.updateDeviceToken(deviceToken);
      }
      return false;
    } catch (e) {
      _logger.e('Error updating device token: $e');
      return false;
    }
  }
}