import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/network/auth/token_repository.dart';

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

  final TokenRepository _tokenRepository;
  
  /// Stream controller cho sự kiện đăng nhập/đăng xuất
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  StreamSubscription<AuthTokens?>? _tokensSubscription;
  
  /// Stream theo dõi trạng thái đăng nhập
  Stream<bool> get authStateStream => _authStateController.stream;
  
  /// Constructor
  AuthService(this._tokenRepository) {
    _tokensSubscription = _tokenRepository.tokensStream.listen((tokens) {
      final isLoggedIn = tokens != null && tokens.accessToken.isNotEmpty;
      if (!_authStateController.isClosed) {
        _authStateController.add(isLoggedIn);
      }
    });
  }
  
  @override
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  @override
  Future<String?> getAccessToken() async {
    try {
      return _tokenRepository.getAccessToken();
    } catch (e) {
      _logger.e('Lỗi khi lấy access token: $e');
      return null;
    }
  }
  
  @override
  Future<String?> getRefreshToken() async {
    try {
      return _tokenRepository.getRefreshToken();
    } catch (e) {
      _logger.e('Lỗi khi lấy refresh token: $e');
      return null;
    }
  }
  
  /// Lưu access token
  Future<bool> saveAccessToken(String token) async {
    try {
      await _tokenRepository.saveAccessToken(token);
      return true;
    } catch (e) {
      _logger.e('Lỗi khi lưu access token: $e');
      return false;
    }
  }
  
  /// Lưu refresh token
  Future<bool> saveRefreshToken(String token) async {
    try {
      await _tokenRepository.saveRefreshToken(token);
      return true;
    } catch (e) {
      _logger.e('Lỗi khi lưu refresh token: $e');
      return false;
    }
  }
  
  @override
  Future<bool> refreshToken() async {
    try {
      final newAccessToken = await _tokenRepository.refreshAccessToken();
      final ok = newAccessToken != null && newAccessToken.isNotEmpty;
      if (ok) {
        _logger.i('Đã làm mới token thành công');
      }
      return ok;
    } catch (e) {
      _logger.e('Lỗi khi làm mới token: $e');
      return false;
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _tokenRepository.clear();
      
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
    _tokensSubscription?.cancel();
    _authStateController.close();
  }
} 