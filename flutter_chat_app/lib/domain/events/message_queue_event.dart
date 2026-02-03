import 'package:flutter_chat_app/shared/domain/entities/message_error_type.dart';

/// Các loại sự kiện của message queue
enum MessageQueueEventType {
  /// Tin nhắn được thêm vào hàng đợi
  messageEnqueued,
  
  /// Bắt đầu gửi tin nhắn
  messageSending,
  
  /// Tin nhắn đã được gửi thành công
  messageSent,
  
  /// Tin nhắn đã được gửi nhưng chưa nhận được phản hồi
  messageDelivered,
  
  /// Tin nhắn đã được đọc
  messageRead,
  
  /// Tin nhắn gửi thất bại
  messageFailed,
  
  /// Tin nhắn thất bại và đã được lên lịch thử lại
  messageRetryScheduled,
  
  /// Tin nhắn đã bị hủy
  messageCancelled,
  
  /// Hàng đợi đã bị tạm dừng
  queuePaused,
  
  /// Hàng đợi đã được tiếp tục
  queueResumed,
  
  /// Hàng đợi đã bị xóa
  queueCleared,
  
  /// Tin nhắn đã bị xóa khỏi hàng đợi
  messageRemoved,
  
  /// Tập tin đính kèm đã được thêm vào hàng đợi
  attachmentEnqueued,
  
  /// Bắt đầu tải lên tập tin đính kèm
  attachmentUploading,
  
  /// Tập tin đính kèm đã được tải lên thành công
  attachmentUploaded,
  
  /// Bắt đầu tải xuống tập tin đính kèm
  attachmentDownloading,
  
  /// Tập tin đính kèm đã được tải xuống thành công
  attachmentDownloaded,
  
  /// Tập tin đính kèm xử lý thất bại
  attachmentFailed,
  
  /// Tiến độ tải lên/tải xuống tập tin đính kèm cập nhật
  attachmentProgressUpdated,
}

/// Sự kiện phát sinh từ message queue system
class MessageQueueEvent {
  /// Loại sự kiện
  final MessageQueueEventType type;
  
  /// ID của tin nhắn liên quan (nếu có)
  final String? messageId;
  
  /// ID của tập tin đính kèm liên quan (nếu có)
  final String? attachmentId;
  
  /// ID trên server (nếu có)
  final String? serverId;
  
  /// Thông báo lỗi (nếu có)
  final String? error;
  
  /// Loại lỗi (nếu có)
  final MessageErrorType? errorType;
  
  /// Thời gian dự kiến thử lại (nếu có)
  final DateTime? scheduledTime;
  
  /// Tiến độ xử lý (nếu có)
  final double? progress;
  
  /// Thời gian phát sinh sự kiện
  final DateTime timestamp;
  
  /// Constructor
  MessageQueueEvent({
    required this.type,
    this.messageId,
    this.attachmentId,
    this.serverId,
    this.error,
    this.errorType,
    this.scheduledTime,
    this.progress,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Kiểm tra xem có phải là sự kiện liên quan đến tập tin đính kèm không
  bool get isAttachmentEvent =>
      type == MessageQueueEventType.attachmentEnqueued ||
      type == MessageQueueEventType.attachmentUploading ||
      type == MessageQueueEventType.attachmentUploaded ||
      type == MessageQueueEventType.attachmentDownloading ||
      type == MessageQueueEventType.attachmentDownloaded ||
      type == MessageQueueEventType.attachmentFailed ||
      type == MessageQueueEventType.attachmentProgressUpdated;
      
  /// Kiểm tra xem có phải là sự kiện lỗi không
  bool get isErrorEvent =>
      type == MessageQueueEventType.messageFailed ||
      type == MessageQueueEventType.attachmentFailed;
      
  /// Kiểm tra xem có phải là sự kiện thành công không
  bool get isSuccessEvent =>
      type == MessageQueueEventType.messageSent ||
      type == MessageQueueEventType.messageDelivered ||
      type == MessageQueueEventType.messageRead ||
      type == MessageQueueEventType.attachmentUploaded ||
      type == MessageQueueEventType.attachmentDownloaded;
      
  /// Trả về mô tả sự kiện
  String get description {
    switch (type) {
      case MessageQueueEventType.messageEnqueued:
        return 'Message added to queue';
      case MessageQueueEventType.messageSending:
        return 'Sending message';
      case MessageQueueEventType.messageSent:
        return 'Message sent successfully';
      case MessageQueueEventType.messageDelivered:
        return 'Message delivered';
      case MessageQueueEventType.messageRead:
        return 'Message read';
      case MessageQueueEventType.messageFailed:
        return 'Message failed: $error';
      case MessageQueueEventType.messageRetryScheduled:
        return 'Message scheduled for retry at ${scheduledTime?.toString() ?? "unknown time"}';
      case MessageQueueEventType.messageCancelled:
        return 'Message cancelled';
      case MessageQueueEventType.queuePaused:
        return 'Queue paused';
      case MessageQueueEventType.queueResumed:
        return 'Queue resumed';
      case MessageQueueEventType.queueCleared:
        return 'Queue cleared';
      case MessageQueueEventType.messageRemoved:
        return 'Message removed from queue';
      case MessageQueueEventType.attachmentEnqueued:
        return 'Attachment added to queue';
      case MessageQueueEventType.attachmentUploading:
        return 'Uploading attachment';
      case MessageQueueEventType.attachmentUploaded:
        return 'Attachment uploaded successfully';
      case MessageQueueEventType.attachmentDownloading:
        return 'Downloading attachment';
      case MessageQueueEventType.attachmentDownloaded:
        return 'Attachment downloaded successfully';
      case MessageQueueEventType.attachmentFailed:
        return 'Attachment failed: $error';
      case MessageQueueEventType.attachmentProgressUpdated:
        return 'Attachment progress: ${(progress ?? 0) * 100}%';
    }
  }
} 