/// Enum định nghĩa chất lượng mạng
enum NetworkQuality {
  /// Chất lượng rất tốt (độ trễ < 100ms)
  excellent,
  
  /// Chất lượng tốt (độ trễ < 200ms)
  good,
  
  /// Chất lượng trung bình (độ trễ < 500ms)
  fair,
  
  /// Chất lượng kém (độ trễ >= 500ms)
  poor,
  
  /// Không xác định
  unknown,
} 