/// Loại metric theo dõi hiệu suất Socket.IO
enum SocketMetricType {
  /// Độ trễ của kết nối
  latency,
  
  /// Số lượng tin nhắn gửi đi
  messagesSent,
  
  /// Số lượng tin nhắn nhận được
  messagesReceived,
  
  /// Số lượng lần kết nối lại
  reconnections,
  
  /// Thời gian hoạt động
  uptime,
  
  /// Thời gian không hoạt động
  downtime,
  
  /// Tỷ lệ lỗi
  errorRate,
}

/// Loại lỗi kết nối Socket.IO
enum SocketErrorType {
  /// Lỗi kết nối mạng
  networkError,
  
  /// Lỗi timeout
  timeout,
  
  /// Lỗi xác thực
  authError,
  
  /// Lỗi từ server
  serverError,
  
  /// Lỗi transport
  transportError,
  
  /// Lỗi khi gửi tin nhắn
  messagingError,
  
  /// Lỗi không xác định
  unknown,
} 