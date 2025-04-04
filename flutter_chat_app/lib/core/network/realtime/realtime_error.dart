import 'package:flutter/foundation.dart';

/// Định nghĩa các loại lỗi realtime
enum RealtimeErrorType {
  /// Lỗi kết nối mạng
  networkError,
  
  /// Lỗi timeout
  timeout,
  
  /// Lỗi xác thực
  authError,
  
  /// Lỗi từ server
  serverError,
  
  /// Lỗi khi gửi tin nhắn
  messageSendError,
  
  /// Lỗi định dạng tin nhắn
  messageFormatError,
  
  /// Lỗi WebSocket
  webSocketError,
  
  /// Lỗi từ rate limiting
  rateLimitExceeded,
  
  /// Lỗi connection pool đã đầy
  connectionPoolExhausted,
  
  /// Lỗi kết nối bị ngắt bởi server
  serverDisconnect,
  
  /// Lỗi không xác định
  unknown,
}

/// Class mô tả lỗi Realtime 
class RealtimeError {
  /// Loại lỗi
  final RealtimeErrorType type;
  
  /// Mã lỗi (nếu có)
  final String? code;
  
  /// Thông báo lỗi
  final String message;
  
  /// Thông tin chi tiết về lỗi
  final dynamic details;
  
  /// Lỗi gốc
  final dynamic originalError;
  
  /// Thời gian xảy ra lỗi
  final DateTime timestamp;
  
  /// Constructor
  RealtimeError({
    required this.type,
    this.code,
    required this.message,
    this.details,
    this.originalError,
  }) : timestamp = DateTime.now();
  
  /// Tạo RealtimeError từ một exception
  factory RealtimeError.fromException(dynamic exception, {RealtimeErrorType? type}) {
    if (exception is RealtimeError) {
      return exception;
    }
    
    String message = 'Đã xảy ra lỗi không xác định';
    RealtimeErrorType errorType = type ?? RealtimeErrorType.unknown;
    String? errorCode;
    
    if (exception is Exception || exception is Error) {
      message = exception.toString();
      // Phân tích loại lỗi từ message nếu không có type được chỉ định
      if (type == null) {
        if (message.contains('timeout') || message.contains('timed out')) {
          errorType = RealtimeErrorType.timeout;
        } else if (message.contains('network') || message.contains('connection')) {
          errorType = RealtimeErrorType.networkError;
        } else if (message.contains('authentication') || message.contains('unauthorized') || 
                  message.contains('401')) {
          errorType = RealtimeErrorType.authError;
        } else if (message.contains('rate limit') || message.contains('429')) {
          errorType = RealtimeErrorType.rateLimitExceeded;
        } else if (message.contains('server') || message.contains('5')) {
          errorType = RealtimeErrorType.serverError;
        }
      }
    }
    
    return RealtimeError(
      type: errorType,
      code: errorCode,
      message: message,
      originalError: exception,
    );
  }
  
  /// Factory cho lỗi kết nối mạng
  factory RealtimeError.networkError(String message, {dynamic details, dynamic originalError}) {
    return RealtimeError(
      type: RealtimeErrorType.networkError,
      message: message,
      details: details,
      originalError: originalError,
    );
  }
  
  /// Factory cho lỗi timeout
  factory RealtimeError.timeout(String message, {dynamic details, dynamic originalError}) {
    return RealtimeError(
      type: RealtimeErrorType.timeout,
      message: message,
      details: details,
      originalError: originalError,
    );
  }
  
  /// Factory cho lỗi xác thực
  factory RealtimeError.authError(String message, {String? code, dynamic details, dynamic originalError}) {
    return RealtimeError(
      type: RealtimeErrorType.authError,
      code: code,
      message: message,
      details: details,
      originalError: originalError,
    );
  }
  
  /// Factory cho lỗi server
  factory RealtimeError.serverError(String message, {String? code, dynamic details, dynamic originalError}) {
    return RealtimeError(
      type: RealtimeErrorType.serverError,
      code: code,
      message: message,
      details: details,
      originalError: originalError,
    );
  }
  
  /// Factory cho lỗi rate limit
  factory RealtimeError.rateLimitExceeded(String message, {Duration? retryAfter, dynamic originalError}) {
    return RealtimeError(
      type: RealtimeErrorType.rateLimitExceeded,
      message: message,
      details: {'retryAfter': retryAfter},
      originalError: originalError,
    );
  }
  
  /// Factory cho lỗi WebSocket
  factory RealtimeError.webSocketError(String message, {int? closeCode, String? closeReason, dynamic originalError}) {
    return RealtimeError(
      type: RealtimeErrorType.webSocketError,
      code: closeCode?.toString(),
      message: message,
      details: {'closeReason': closeReason},
      originalError: originalError,
    );
  }
  
  /// Chuyển đổi thành chuỗi để debug
  @override
  String toString() {
    return 'RealtimeError: $message (type: $type${code != null ? ', code: $code' : ''})';
  }
  
  /// Log lỗi
  void log() {
    debugPrint('$this');
    if (details != null) {
      debugPrint('Details: $details');
    }
    if (originalError != null) {
      debugPrint('Original error: $originalError');
    }
  }
}

/// Enum định nghĩa các loại lỗi mạng
enum RealtimeConnectionErrorType {
  /// Lỗi không có mạng
  noConnection,
  
  /// Lỗi timeout kết nối
  connectionTimeout,
  
  /// Lỗi server từ chối kết nối
  connectionRefused,
  
  /// Lỗi server ngắt kết nối
  disconnectedByServer,
  
  /// Lỗi client ngắt kết nối
  disconnectedByClient,
  
  /// Lỗi ping/pong timeout
  pingPongTimeout,
  
  /// Lỗi không tìm thấy máy chủ
  hostNotFound,
  
  /// Lỗi thay đổi mạng
  networkChanged,
  
  /// Lỗi xác thực
  authenticationFailed,
  
  /// Lỗi kết nối bị reset
  connectionReset,
  
  /// Lỗi không xác định
  unknown,
}

/// Class quản lý rate limiting
class RateLimitInfo {
  /// Số request tối đa trong khoảng thời gian
  final int limit;
  
  /// Số request đã sử dụng
  final int used;
  
  /// Thời gian reset (Unix timestamp)
  final int resetTimestamp;
  
  /// Thời gian phải đợi trước khi thử lại (ms)
  final int retryAfterMs;
  
  /// Constructor
  RateLimitInfo({
    required this.limit,
    required this.used,
    required this.resetTimestamp,
    required this.retryAfterMs,
  });
  
  /// Tạo từ headers
  factory RateLimitInfo.fromHeaders(Map<String, List<String>> headers) {
    final limit = int.tryParse(headers['x-ratelimit-limit']?.first ?? '100') ?? 100;
    final used = int.tryParse(headers['x-ratelimit-used']?.first ?? '0') ?? 0;
    final reset = int.tryParse(headers['x-ratelimit-reset']?.first ?? '0') ?? 0;
    final retryAfter = int.tryParse(headers['retry-after']?.first ?? '0') ?? 0;
    
    return RateLimitInfo(
      limit: limit,
      used: used,
      resetTimestamp: reset,
      retryAfterMs: retryAfter * 1000, // Convert to ms
    );
  }
  
  /// Kiểm tra có bị rate limit không
  bool get isRateLimited => used >= limit;
  
  /// Lấy thời gian còn lại trước khi reset (ms)
  int get remainingTimeMs {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (resetTimestamp - now) * 1000;
  }
  
  /// Lấy số request còn lại
  int get remaining => limit - used;
  
  @override
  String toString() {
    return 'RateLimitInfo(limit: $limit, used: $used, remaining: $remaining, resetIn: ${remainingTimeMs}ms)';
  }
} 