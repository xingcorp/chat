/// Class đại diện cho một tin nhắn đang chờ gửi
class PendingMessage {
  /// Loại tin nhắn
  final String type;
  
  /// Dữ liệu tin nhắn
  final dynamic data;
  
  /// Metadata bổ sung
  final Map<String, dynamic>? metadata;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Số lần thử gửi
  int retryCount = 0;
  
  /// Constructor
  PendingMessage(this.type, this.data, {this.metadata}) 
      : createdAt = DateTime.now();
} 