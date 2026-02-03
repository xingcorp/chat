/// Trạng thái của tập tin đính kèm trong hàng đợi
enum AttachmentQueueStatus {
  /// Đang chờ: Tập tin đính kèm đã được thêm vào hàng đợi
  pending,
  
  /// Đang tải lên: Tập tin đính kèm đang được tải lên server
  uploading,
  
  /// Đã tải lên: Tập tin đính kèm đã được tải lên thành công
  uploaded,
  
  /// Đang chờ tải xuống: Tập tin đính kèm đang chờ để tải xuống
  downloadPending,
  
  /// Đang tải xuống: Tập tin đính kèm đang được tải xuống từ server
  downloading,
  
  /// Đã tải xuống: Tập tin đính kèm đã được tải xuống thành công
  downloaded,
  
  /// Thất bại: Tập tin đính kèm xử lý thất bại
  failed,
  
  /// Đã hủy: Tập tin đính kèm đã bị hủy
  cancelled,
  
  /// Chờ mạng: Đang chờ kết nối mạng để tiếp tục
  waitingForNetwork,
  
  /// Bị tạm dừng: Đã bị tạm dừng bởi người dùng
  paused,
}

/// Extension methods for AttachmentQueueStatus
extension AttachmentQueueStatusX on AttachmentQueueStatus {
  /// Kiểm tra trạng thái là trạng thái cuối cùng
  bool get isTerminal => 
    this == AttachmentQueueStatus.uploaded || 
    this == AttachmentQueueStatus.downloaded ||
    this == AttachmentQueueStatus.failed || 
    this == AttachmentQueueStatus.cancelled;
    
  /// Kiểm tra xem có thể thử lại không
  bool get canRetry => 
    this == AttachmentQueueStatus.failed ||
    this == AttachmentQueueStatus.waitingForNetwork;
    
  /// Kiểm tra xem đã xử lý thành công chưa
  bool get isSuccessful => 
    this == AttachmentQueueStatus.uploaded || 
    this == AttachmentQueueStatus.downloaded;
    
  /// Kiểm tra xem attachment đang trong quá trình xử lý
  bool get isProcessing =>
    this == AttachmentQueueStatus.uploading ||
    this == AttachmentQueueStatus.downloading;
    
  /// Kiểm tra xem attachment đang trong trạng thái có thể tạm dừng
  bool get canBePaused =>
    isProcessing || 
    this == AttachmentQueueStatus.pending ||
    this == AttachmentQueueStatus.downloadPending;
} 