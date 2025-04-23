import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interface cho dịch vụ xác thực
abstract class IAuthService {
  /// Kiểm tra xem người dùng đã đăng nhập chưa
  Future<bool> isLoggedIn();
  
  /// Lấy access token hiện tại
  Future<String?> getAccessToken();
  
  /// Lấy refresh token hiện tại
  Future<String?> getRefreshToken();
  
  /// Làm mới token
  Future<bool> refreshToken();
  
  /// Đăng xuất khỏi ứng dụng
  Future<void> logout();
}

/// Service quản lý xác thực của ứng dụng
@lazySingleton
class AuthService implements IAuthService {
  /// Logger
  final Logger _logger = Logger();
  
  /// Key cho access token trong shared preferences
  static const String _accessTokenKey = 'access_token';
  
  /// Key cho refresh token trong shared preferences
  static const String _refreshTokenKey = 'refresh_token';
  
  /// Stream controller cho sự kiện đăng nhập/đăng xuất
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  
  /// Stream theo dõi trạng thái đăng nhập
  Stream<bool> get authStateStream => _authStateController.stream;
  
  /// Constructor
  AuthService();
  
  @override
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  @override
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      _logger.e('Lỗi khi lấy access token: $e');
      return null;
    }
  }
  
  @override
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      _logger.e('Lỗi khi lấy refresh token: $e');
      return null;
    }
  }
  
  /// Lưu access token
  Future<bool> saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
      return true;
    } catch (e) {
      _logger.e('Lỗi khi lưu access token: $e');
      return false;
    }
  }
  
  /// Lưu refresh token
  Future<bool> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
      return true;
    } catch (e) {
      _logger.e('Lỗi khi lưu refresh token: $e');
      return false;
    }
  }
  
  @override
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('Không thể làm mới token: Refresh token không tồn tại');
        return false;
      }
      
      // TODO: Gọi API để làm mới token
      // Đây chỉ là mã giả, cần thay thế bằng logic thực tế
      final newAccessToken = 'new_access_token';
      final newRefreshToken = 'new_refresh_token';
      
      await saveAccessToken(newAccessToken);
      await saveRefreshToken(newRefreshToken);
      
      _logger.i('Đã làm mới token thành công');
      return true;
    } catch (e) {
      _logger.e('Lỗi khi làm mới token: $e');
      return false;
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      
      _authStateController.add(false);
      _logger.i('Đã đăng xuất thành công');
    } catch (e) {
      _logger.e('Lỗi khi đăng xuất: $e');
    }
  }
  
  /// Gửi thông báo trạng thái đăng nhập
  void notifyLoggedIn() {
    _authStateController.add(true);
  }
  
  /// Đóng tài nguyên
  void dispose() {
    _authStateController.close();
  }
} 