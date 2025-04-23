/// Enum định nghĩa các trạng thái kết nối
enum ConnectionState {
  /// Trạng thái ban đầu, chưa kết nối
  initial,
  
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Đang kết nối lại
  reconnecting,
  
  /// Đang chờ mạng
  waitingForNetwork,
  
  /// Đã ngắt kết nối
  disconnected,
  
  /// Lỗi kết nối
  error,
  
  /// Đã đóng
  closed,
}

/// Các trạng thái kết nối realtime
enum RealtimeConnectionState {
  /// Đang kết nối
  connecting,
  
  /// Đã kết nối
  connected,
  
  /// Đang kết nối lại
  reconnecting,
  
  /// Đã ngắt kết nối
  disconnected,
  
  /// Lỗi
  error,
  
  /// Đã đóng
  closed,
}

/// Các loại kết nối realtime
enum RealtimeConnectionType {
  /// WebSocket
  webSocket,
  
  /// Long polling
  longPolling,
  
  /// Không có kết nối
  none,
} 