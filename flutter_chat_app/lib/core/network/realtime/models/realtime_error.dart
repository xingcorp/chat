import 'package:flutter_chat_app/core/network/realtime/models/realtime_error_type.dart';

/// Các mã lỗi cho dịch vụ realtime
enum RealtimeErrorCode {
  /// Lỗi kết nối
  connectionError,
  
  /// Lỗi tin nhắn
  messageError,
  
  /// Lỗi xác thực
  authenticationError,
  
  /// Lỗi giới hạn tốc độ
  rateLimitError,
  
  /// Lỗi đánh dấu đã đọc
  statusError,
  
  /// Lỗi không xác định
  unknown,
}

/// Đại diện cho một lỗi realtime
class RealtimeError implements Exception {
  /// Mã lỗi
  final RealtimeErrorCode code;
  
  /// Thông báo lỗi
  final String message;
  
  /// Dữ liệu chi tiết (nếu có)
  final dynamic details;
  
  /// Loại lỗi (tùy chọn)
  final RealtimeErrorType? errorType;
  
  /// Lỗi gốc
  final dynamic originalError;
  
  /// Thời gian xảy ra lỗi
  final DateTime timestamp;
  
  /// Constructor
  RealtimeError({
    required this.code,
    required this.message,
    this.details,
    this.errorType,
    this.originalError,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Tạo lỗi từ một ngoại lệ
  factory RealtimeError.fromException(dynamic exception, {
    StackTrace? stackTrace,
    RealtimeErrorType? type,
  }) {
    // Xác định loại lỗi từ exception
    RealtimeErrorType? errorType = type;
    RealtimeErrorCode errorCode = RealtimeErrorCode.unknown;
    String message = exception.toString();
    
    // Phân tích message để xác định loại lỗi nếu không có type
    if (type == null) {
      if (message.contains('timeout') || message.contains('timed out')) {
        errorType = RealtimeErrorType.timeout;
        errorCode = RealtimeErrorCode.connectionError;
      } else if (message.contains('network') || message.contains('connection')) {
        errorType = RealtimeErrorType.networkError;
        errorCode = RealtimeErrorCode.connectionError;
      } else if (message.contains('authentication') || message.contains('unauthorized')) {
        errorType = RealtimeErrorType.authError;
        errorCode = RealtimeErrorCode.authenticationError;
      } else if (message.contains('rate limit')) {
        errorType = RealtimeErrorType.rateLimitExceeded;
        errorCode = RealtimeErrorCode.rateLimitError;
      } else if (message.contains('server')) {
        errorType = RealtimeErrorType.serverError;
        errorCode = RealtimeErrorCode.unknown;
      } else if (message.contains('message')) {
        errorType = RealtimeErrorType.messageSendError;
        errorCode = RealtimeErrorCode.messageError;
      }
    }
    
    return RealtimeError(
      code: errorCode,
      message: message,
      details: {
        'exception': exception.toString(),
        'stackTrace': stackTrace?.toString(),
      },
      errorType: errorType,
      originalError: exception,
    );
  }
  
  /// Tạo lỗi từ JSON
  factory RealtimeError.fromJson(Map<String, dynamic> json) {
    return RealtimeError(
      code: RealtimeErrorCode.values.firstWhere(
        (e) => e.toString().split('.').last == json['code'],
        orElse: () => RealtimeErrorCode.unknown,
      ),
      message: json['message'] as String,
      details: json['details'],
      errorType: json['errorType'] != null ? 
          RealtimeErrorType.values.firstWhere(
            (e) => e.toString().split('.').last == json['errorType'],
            orElse: () => RealtimeErrorType.unknown,
          ) : null,
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Chuyển đổi lỗi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code.toString().split('.').last,
      'message': message,
      'details': details,
      'errorType': errorType?.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  @override
  String toString() {
    return 'RealtimeError{code: $code, message: $message, type: $errorType, timestamp: $timestamp}';
  }
} 