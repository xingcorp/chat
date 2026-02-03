/// Enum để phân loại các loại lỗi tin nhắn 
/// cho chiến lược retry khác nhau
enum MessageErrorType {
  /// Lỗi kết nối mạng (mất kết nối, timeout...)
  /// Retry ngay khi có mạng trở lại
  networkError,
  
  /// Lỗi từ máy chủ (500, 503...)
  /// Retry với backoff để tránh quá tải máy chủ
  serverError,
  
  /// Lỗi xác thực (401, 403...)
  /// Cần xử lý đăng nhập lại trước khi retry
  authError,
  
  /// Lỗi xác nhận dữ liệu (400, 422...)
  /// Có thể không cần retry nếu dữ liệu không hợp lệ
  validationError,
  
  /// Lỗi về tập tin (không tìm thấy, không thể đọc...)
  /// Cần kiểm tra lại tập tin trước khi retry
  fileError,
  
  /// Lỗi giới hạn tốc độ (429 Too Many Requests)
  /// Cần tạm dừng và retry sau thời gian giới hạn
  rateLimitError,
  
  /// Lỗi không xác định
  /// Retry thông thường với backoff
  unknown,
}

/// Extension methods cho MessageErrorType
extension MessageErrorTypeX on MessageErrorType {
  /// Kiểm tra xem lỗi có thể retry không
  bool get canRetry =>
      this != MessageErrorType.validationError;
  
  /// Kiểm tra lỗi có cần xử lý đặc biệt không
  bool get requiresUserIntervention =>
      this == MessageErrorType.authError ||
      this == MessageErrorType.validationError;
  
  /// Kiểm tra lỗi có liên quan đến mạng không
  bool get isNetworkRelated =>
      this == MessageErrorType.networkError ||
      this == MessageErrorType.serverError ||
      this == MessageErrorType.rateLimitError;
      
  /// Trả về thông báo lỗi mô tả cho người dùng
  String get userFriendlyMessage {
    switch (this) {
      case MessageErrorType.networkError:
        return 'Kết nối mạng không ổn định. Tin nhắn sẽ được gửi khi có kết nối.';
      case MessageErrorType.serverError:
        return 'Máy chủ đang gặp sự cố. Đang thử lại.';
      case MessageErrorType.authError:
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      case MessageErrorType.validationError:
        return 'Tin nhắn không hợp lệ. Vui lòng kiểm tra lại.';
      case MessageErrorType.fileError:
        return 'Có lỗi xảy ra với tập tin đính kèm. Vui lòng kiểm tra lại.';
      case MessageErrorType.rateLimitError:
        return 'Bạn đang gửi tin nhắn quá nhanh. Vui lòng thử lại sau.';
      case MessageErrorType.unknown:
        return 'Có lỗi xảy ra. Đang thử lại.';
    }
  }
} 