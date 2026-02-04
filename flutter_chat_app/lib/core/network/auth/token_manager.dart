import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/constants/storage_keys.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý token xác thực trong ứng dụng
@lazySingleton
class TokenManager {
  /// Keys dùng trong SharedPreferences
  static const String _accessTokenKey = StorageKeys.accessToken;
  static const String _refreshTokenKey = StorageKeys.refreshToken;
  static const String _legacyAccessTokenKey = 'auth_access_token';
  static const String _legacyRefreshTokenKey = 'auth_refresh_token';
  static const String _expiryTimeKey = 'auth_expiry_time';
  static const String _userDataKey = 'auth_user_data';
  
  /// Instance của SharedPreferences
  final SharedPreferences _prefs;
  
  /// Stream controller để thông báo khi có thay đổi về token
  final StreamController<bool> _authChangedController = StreamController<bool>.broadcast();
  
  /// Đối tượng quản lý callback refresh token
  Completer<bool>? _refreshingCompleter;
  
  /// Flag đánh dấu đang refresh token
  bool _isRefreshing = false;
  
  /// Constructor
  TokenManager(this._prefs);
  
  /// Stream để theo dõi thay đổi token
  Stream<bool> get authChanges => _authChangedController.stream;
  
  /// Lưu access token
  Future<void> setAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
    _notifyAuthChanged(true);
  }
  
  /// Lưu cả access token và refresh token
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiryTime,
    Map<String, dynamic>? userData,
  }) async {
    await Future.wait([
      _prefs.setString(_accessTokenKey, accessToken),
      _prefs.setString(_refreshTokenKey, refreshToken),
    ]);
    
    if (expiryTime != null) {
      await _prefs.setInt(_expiryTimeKey, expiryTime.millisecondsSinceEpoch);
    }
    
    if (userData != null) {
      await _prefs.setString(_userDataKey, jsonEncode(userData));
    }
    
    _notifyAuthChanged(true);
  }
  
  /// Lấy access token
  Future<String?> getAccessToken() async {
    // Nếu token sắp hết hạn, tự động refresh
    if (await _shouldRefreshToken()) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        return _prefs.getString(_accessTokenKey);
      }
    }
    
    final token = _prefs.getString(_accessTokenKey);
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final legacy = _prefs.getString(_legacyAccessTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await Future.wait([
        _prefs.setString(_accessTokenKey, legacy),
        _prefs.remove(_legacyAccessTokenKey),
      ]);
      return legacy;
    }

    return null;
  }
  
  /// Lấy refresh token
  Future<String?> getRefreshToken() async {
    final token = _prefs.getString(_refreshTokenKey);
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final legacy = _prefs.getString(_legacyRefreshTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await Future.wait([
        _prefs.setString(_refreshTokenKey, legacy),
        _prefs.remove(_legacyRefreshTokenKey),
      ]);
      return legacy;
    }

    return null;
  }
  
  /// Lấy thời gian hết hạn của token
  Future<DateTime?> getExpiryTime() async {
    final timestamp = _prefs.getInt(_expiryTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  /// Kiểm tra token còn hạn không
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    
    final expiryTime = await getExpiryTime();
    if (expiryTime == null) return true; // Không có expiry time, coi như còn hạn
    
    return expiryTime.isAfter(DateTime.now());
  }
  
  /// Kiểm tra có token không
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Kiểm tra có nên refresh token không
  Future<bool> _shouldRefreshToken() async {
    final expiryTime = await getExpiryTime();
    if (expiryTime == null) return false;
    
    // Refresh token nếu ít hơn 5 phút nữa sẽ hết hạn
    final threshold = DateTime.now().add(const Duration(minutes: 5));
    return expiryTime.isBefore(threshold);
  }
  
  /// Refresh token
  /// Trả về true nếu refresh thành công
  Future<bool> refreshToken() async {
    // Nếu đang refresh rồi, chờ kết quả
    if (_isRefreshing) {
      if (_refreshingCompleter != null) {
        return _refreshingCompleter!.future;
      }
      return false;
    }
    
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('Cannot refresh token: No refresh token');
      return false;
    }
    
    _isRefreshing = true;
    final completer = Completer<bool>();
    _refreshingCompleter = completer;
    
    try {
      // TODO: Gọi API refresh token
      // Đây là phần giả lập, khi triển khai thực tế,
      // cần gọi API endpoint để refresh token
      
      debugPrint('Refreshing token...');
      
      completer.complete(false);
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      completer.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshingCompleter = null;
    }
  }
  
  /// Xóa tất cả token, đăng xuất
  Future<void> clearTokens() async {
    await Future.wait([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_legacyAccessTokenKey),
      _prefs.remove(_refreshTokenKey),
      _prefs.remove(_legacyRefreshTokenKey),
      _prefs.remove(_expiryTimeKey),
      _prefs.remove(_userDataKey),
    ]);
    
    _notifyAuthChanged(false);
  }
  
  /// Lấy thông tin user đã lưu
  Future<Map<String, dynamic>?> getUserData() async {
    final data = _prefs.getString(_userDataKey);
    if (data == null) return null;
    
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing user data: $e');
      return null;
    }
  }
  
  /// Cập nhật thông tin user
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_userDataKey, jsonEncode(userData));
  }
  
  /// Thông báo khi auth state thay đổi
  void _notifyAuthChanged(bool isAuthenticated) {
    if (!_authChangedController.isClosed) {
      _authChangedController.add(isAuthenticated);
    }
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _authChangedController.close();
  }
} 