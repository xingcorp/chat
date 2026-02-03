/// Trạng thái của tin nhắn trong hàng đợi
enum MessageQueueStatus {
  /// Đang soạn: Tin nhắn vẫn đang trong quá trình soạn
  draft,
  
  /// Đang chờ: Tin nhắn đã được thêm vào hàng đợi
  pending,
  
  /// Đang gửi: Tin nhắn đang được gửi
  sending,
  
  /// Đã gửi: Tin nhắn đã được gửi đến server
  sent,
  
  /// Đã nhận: Tin nhắn đã được nhận bởi người nhận
  delivered,
  
  /// Đã đọc: Tin nhắn đã được đọc bởi người nhận
  read,
  
  /// Thất bại: Tin nhắn gửi thất bại
  failed,
  
  /// Đã hủy: Tin nhắn đã bị hủy
  cancelled,
  
  /// Xung đột: Tin nhắn bị xung đột với dữ liệu từ server
  conflicted,
}

/// Extension methods for MessageQueueStatus
extension MessageQueueStatusX on MessageQueueStatus {
  /// Whether the message is in a terminal state
  bool get isTerminal => 
    this == MessageQueueStatus.sent || 
    this == MessageQueueStatus.failed || 
    this == MessageQueueStatus.cancelled ||
    this == MessageQueueStatus.conflicted;
    
  /// Whether the message is in a state that can be retried
  bool get canRetry => 
    this == MessageQueueStatus.failed;
    
  /// Whether the message has been successfully delivered
  bool get isSuccessful => 
    this == MessageQueueStatus.sent || 
    this == MessageQueueStatus.delivered || 
    this == MessageQueueStatus.read;
} 