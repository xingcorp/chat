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