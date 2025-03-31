import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình cho ứng dụng
class AppConfig {
  /// URL cho API GraphQL
  static String get apiUrl => dotenv.env['GRAPHQL_API_URL'] ?? 'https://stg-office-api.smarthiz.vn/graphql';
  
  /// URL cho WebSocket
  static String get webSocketUrl => dotenv.env['GRAPHQL_WS_URL'] ?? 'wss://stg-office-api.smarthiz.vn/graphql';
  
  /// URL cho Long Polling
  static String get longPollingUrl => dotenv.env['SOCKET_URL'] ?? 'https://stg-office-api.smarthiz.vn/poll';
  
  /// Timeout cho các request (ms)
  static const int requestTimeout = 30000;
  
  /// Kích thước trang mặc định
  static const int defaultPageSize = 20;
  
  /// Flag cho phép ghi log
  static bool enableLogging = true;
  
  /// Flag cho chế độ offline
  static bool offlineMode = false;
  
  /// Thời gian giữ cache (giây)
  static const int cacheDuration = 86400; // 1 ngày
  
  /// Kích thước tối đa của cache (MB)
  static const int maxCacheSize = 100; // 100MB
  
  /// Cấu hình cho media
  static const MediaConfig mediaConfig = MediaConfig(
    maxImageSize: 10, // MB
    maxVideoSize: 50, // MB
    defaultImageQuality: 80, // 0-100
    defaultVideoQuality: 720, // 360, 480, 720, 1080
  );
  
  /// Cấu hình cho WebSocket
  static const WebSocketConfig webSocketConfig = WebSocketConfig(
    pingInterval: 30, // giây
    reconnectAttempts: 10,
    initialReconnectDelay: 1000, // ms
  );
  
  /// Cấu hình cho long polling
  static const LongPollingConfig longPollingConfig = LongPollingConfig(
    pollInterval: 1000, // ms
    timeout: 30000, // ms
  );
}

/// Cấu hình cho media
class MediaConfig {
  /// Kích thước tối đa của hình ảnh (MB)
  final int maxImageSize;
  
  /// Kích thước tối đa của video (MB)
  final int maxVideoSize;
  
  /// Chất lượng mặc định của hình ảnh (0-100)
  final int defaultImageQuality;
  
  /// Chất lượng mặc định của video (360, 480, 720, 1080)
  final int defaultVideoQuality;
  
  /// Constructor
  const MediaConfig({
    required this.maxImageSize,
    required this.maxVideoSize,
    required this.defaultImageQuality,
    required this.defaultVideoQuality,
  });
}

/// Cấu hình cho WebSocket
class WebSocketConfig {
  /// Thời gian giữa các lần ping (giây)
  final int pingInterval;
  
  /// Số lần thử kết nối lại tối đa
  final int reconnectAttempts;
  
  /// Thời gian chờ ban đầu giữa các lần thử kết nối lại (ms)
  final int initialReconnectDelay;
  
  /// Constructor
  const WebSocketConfig({
    required this.pingInterval,
    required this.reconnectAttempts,
    required this.initialReconnectDelay,
  });
}

/// Cấu hình cho long polling
class LongPollingConfig {
  /// Thời gian giữa các lần poll (ms)
  final int pollInterval;
  
  /// Thời gian timeout (ms)
  final int timeout;
  
  /// Constructor
  const LongPollingConfig({
    required this.pollInterval,
    required this.timeout,
  });
} 