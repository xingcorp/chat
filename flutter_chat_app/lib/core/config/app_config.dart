import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình cho ứng dụng
class AppConfig {
  /// API URL
  static String get apiUrl => _getConfigValue('API_URL', 'https://stg-office-api.smarthiz.vn/graphql');
  
  /// WebSocket URL
  static String get webSocketUrl => _getConfigValue('WS_URL', 'wss://stg-office-api.smarthiz.vn/graphql');
  
  /// URL cho Long Polling
  static String get longPollingUrl => _getConfigValue('SOCKET_URL', 'https://stg-office-api.smarthiz.vn/poll');
  
  /// Phiên bản ứng dụng
  static String get appVersion => _getConfigValue('APP_VERSION', '1.0.0');
  
  /// Môi trường hiện tại (development, staging, production)
  static String get environment => _getConfigValue('ENVIRONMENT', 'development');
  
  /// Kích thước lô cho đồng bộ hóa dữ liệu
  static int get syncBatchSize => int.tryParse(_getConfigValue('SYNC_BATCH_SIZE', '50')) ?? 50;
  
  /// Timeout cho các request (ms)
  static int get httpTimeout => int.tryParse(_getConfigValue('HTTP_TIMEOUT', '30000')) ?? 30000;
  
  /// Thời gian chờ tối đa cho WebSocket (ms)
  static int get wsTimeout => int.tryParse(_getConfigValue('WS_TIMEOUT', '30000')) ?? 30000;
  
  /// Số lần thử lại tối đa cho các yêu cầu
  static int get maxRetryAttempts => int.tryParse(_getConfigValue('MAX_RETRY_ATTEMPTS', '3')) ?? 3;
  
  /// Bật/tắt debug
  static bool get enableDebug => _getConfigValue('ENABLE_DEBUG', 'false').toLowerCase() == 'true';
  
  /// Khóa API cho dịch vụ thứ ba
  static String get mapApiKey => _getConfigValue('MAP_API_KEY', '');
  
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
  
  /// Lấy giá trị từ .env hoặc trả về giá trị mặc định
  static String _getConfigValue(String key, String defaultValue) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      // Nếu dotenv chưa được khởi tạo, trả về giá trị mặc định
      return defaultValue;
    }
  }
  
  /// Kiểm tra xem ứng dụng có đang chạy trong môi trường sản xuất không
  static bool get isProduction => environment == 'production';
  
  /// Kiểm tra xem ứng dụng có đang chạy trong môi trường staging không
  static bool get isStaging => environment == 'staging';
  
  /// Kiểm tra xem ứng dụng có đang chạy trong môi trường phát triển không
  static bool get isDevelopment => environment == 'development';
  
  /// Ghi log với điều kiện debug
  static void log(String message, {bool force = false}) {
    if (enableDebug || force) {
      debugPrint('[AppConfig] $message');
    }
  }
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