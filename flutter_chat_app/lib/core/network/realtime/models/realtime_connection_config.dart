/// Cấu hình cho kết nối realtime
class RealtimeConnectionConfig {
  /// URL WebSocket
  final String webSocketUrl;
  
  /// URL HTTP
  final String httpUrl;
  
  /// Token xác thực
  final String authToken;
  
  /// Số lần thử kết nối lại tối đa
  final int maxReconnectAttempts;
  
  /// Độ trễ kết nối lại ban đầu (ms)
  final int initialReconnectDelay;
  
  /// Hệ số tăng thời gian chờ
  final double reconnectBackoffFactor;
  
  /// Timeout kết nối (ms)
  final int connectionTimeout;
  
  /// Thời gian giữa các ping (ms)
  final int pingInterval;
  
  /// Timeout ping (ms)
  final int pingTimeout;
  
  /// Thời gian giữa các long polling (ms)
  final int longPollingInterval;
  
  /// Giới hạn tin nhắn mỗi giây
  final int messageRateLimit;
  
  /// Thời gian chờ backoff khi rate limit (ms)
  final int rateLimitBackoffMs;
  
  /// Có sử dụng connection pool không
  final bool useConnectionPool;
  
  /// Kích thước connection pool tối đa
  final int maxConnectionPoolSize;
  
  /// Headers bổ sung
  final Map<String, String> additionalHeaders;

  /// Constructor
  const RealtimeConnectionConfig({
    required this.webSocketUrl,
    required this.httpUrl,
    required this.authToken,
    this.maxReconnectAttempts = 10,
    this.initialReconnectDelay = 1000,
    this.reconnectBackoffFactor = 1.5,
    this.connectionTimeout = 10000,
    this.pingInterval = 30000,
    this.pingTimeout = 5000,
    this.longPollingInterval = 3000,
    this.messageRateLimit = 30,
    this.rateLimitBackoffMs = 1000,
    this.useConnectionPool = false,
    this.maxConnectionPoolSize = 5,
    this.additionalHeaders = const {},
  });

  /// Tạo bản sao với các giá trị đã sửa đổi
  RealtimeConnectionConfig copyWith({
    String? webSocketUrl,
    String? httpUrl,
    String? authToken,
    int? maxReconnectAttempts,
    int? initialReconnectDelay,
    double? reconnectBackoffFactor,
    int? connectionTimeout,
    int? pingInterval,
    int? pingTimeout,
    int? longPollingInterval,
    int? messageRateLimit,
    int? rateLimitBackoffMs,
    bool? useConnectionPool,
    int? maxConnectionPoolSize,
    Map<String, String>? additionalHeaders,
  }) {
    return RealtimeConnectionConfig(
      webSocketUrl: webSocketUrl ?? this.webSocketUrl,
      httpUrl: httpUrl ?? this.httpUrl,
      authToken: authToken ?? this.authToken,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      initialReconnectDelay: initialReconnectDelay ?? this.initialReconnectDelay,
      reconnectBackoffFactor: reconnectBackoffFactor ?? this.reconnectBackoffFactor,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      pingInterval: pingInterval ?? this.pingInterval,
      pingTimeout: pingTimeout ?? this.pingTimeout,
      longPollingInterval: longPollingInterval ?? this.longPollingInterval,
      messageRateLimit: messageRateLimit ?? this.messageRateLimit,
      rateLimitBackoffMs: rateLimitBackoffMs ?? this.rateLimitBackoffMs,
      useConnectionPool: useConnectionPool ?? this.useConnectionPool,
      maxConnectionPoolSize: maxConnectionPoolSize ?? this.maxConnectionPoolSize,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
    );
  }
}

/// Cấu hình realtime bổ sung
class RealtimeConfig {
  /// Có hỗ trợ long polling không
  final bool supportLongPolling;
  
  /// Có tự động kết nối lại không
  final bool autoReconnect;
  
  /// Có sử dụng batching không
  final bool useBatching;
  
  /// Có xử lý ngoại tuyến không
  final bool handleOffline;
  
  /// Constructor
  const RealtimeConfig({
    this.supportLongPolling = true,
    this.autoReconnect = true,
    this.useBatching = true,
    this.handleOffline = true,
  });
} 