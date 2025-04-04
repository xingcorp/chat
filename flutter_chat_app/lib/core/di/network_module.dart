import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/cache/network_response_cache.dart';
import '../network/auth/token_manager.dart';
import '../network/realtime/realtime_connection_service.dart';

/// Module đăng ký các dependencies liên quan đến network
@module
abstract class NetworkModule {
  /// Đăng ký Connectivity plugin
  @lazySingleton
  Connectivity get connectivity => Connectivity();
  
  /// Đăng ký SharedPreferences
  @preResolve
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();
  
  /// Đăng ký base URL cho API
  @Named('apiBaseUrl')
  String get apiBaseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com/v1',
  );
  
  /// Đăng ký cấu hình realtime
  @Named('realtimeConfig')
  RealtimeConnectionConfig get realtimeConfig => RealtimeConnectionConfig(
    webSocketUrl: const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: 'wss://api.example.com/ws',
    ),
    httpUrl: const String.fromEnvironment(
      'REALTIME_HTTP_URL',
      defaultValue: 'https://api.example.com/realtime',
    ),
    authToken: '', // Sẽ được cập nhật sau khi đăng nhập
  );
} 