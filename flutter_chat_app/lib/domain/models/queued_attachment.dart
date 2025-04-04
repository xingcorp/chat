import 'dart:io';

import 'package:flutter_chat_app/domain/entities/attachment_queue_status.dart';
import 'package:flutter_chat_app/domain/entities/message_error_type.dart';

/// Enum định nghĩa các loại tập tin đính kèm
enum AttachmentType {
  /// Hình ảnh
  image,
  
  /// Video
  video,
  
  /// Âm thanh
  audio,
  
  /// Tài liệu (PDF, DOC, ...)
  document,
  
  /// Khác
  other,
}

/// Model đại diện cho tập tin đính kèm trong hàng đợi
class QueuedAttachment {
  /// ID tập tin đính kèm trên local
  final String localId;
  
  /// ID của tin nhắn mà tập tin đính kèm thuộc về
  final String messageId;
  
  /// ID của chat mà tin nhắn thuộc về
  final String chatId;
  
  /// Đường dẫn đến file trên thiết bị
  final String filePath;
  
  /// Loại tập tin đính kèm
  final AttachmentType type;
  
  /// Trạng thái hiện tại của tập tin đính kèm
  final AttachmentQueueStatus status;
  
  /// ID của tập tin đính kèm trên server (sau khi tải lên thành công)
  final String? serverId;
  
  /// URL của tập tin đính kèm trên server
  final String? serverUrl;
  
  /// Thông báo lỗi (nếu có)
  final String? errorMessage;
  
  /// Loại lỗi (nếu có)
  final MessageErrorType? errorType;
  
  /// Kích thước tập tin (byte)
  final int fileSize;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Thời gian cập nhật gần nhất
  final DateTime updatedAt;
  
  /// Số lần thử lại
  final int retryCount;
  
  /// Thời gian dự kiến thử lại tiếp theo
  final DateTime? nextRetryTime;
  
  /// Tiến độ xử lý (0-100%)
  final double progress;
  
  /// Constructor
  QueuedAttachment({
    required this.localId,
    required this.messageId,
    required this.chatId,
    required this.filePath,
    required this.type,
    required this.status,
    this.serverId,
    this.serverUrl,
    this.errorMessage,
    this.errorType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.nextRetryTime,
    this.progress = 0.0,
  });
  
  /// Tạo một bản sao của tập tin đính kèm với các thông tin đã thay đổi
  QueuedAttachment copyWith({
    String? localId,
    String? messageId,
    String? chatId,
    String? filePath,
    AttachmentType? type,
    AttachmentQueueStatus? status,
    String? serverId,
    String? serverUrl,
    String? errorMessage,
    MessageErrorType? errorType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    DateTime? nextRetryTime,
    double? progress,
  }) {
    return QueuedAttachment(
      localId: localId ?? this.localId,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      status: status ?? this.status,
      serverId: serverId ?? this.serverId,
      serverUrl: serverUrl ?? this.serverUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryTime: nextRetryTime ?? this.nextRetryTime,
      progress: progress ?? this.progress,
    );
  }
  
  /// Chuyển đổi tập tin đính kèm thành Map
  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'messageId': messageId,
      'chatId': chatId,
      'filePath': filePath,
      'type': type.index,
      'status': status.index,
      'serverId': serverId,
      'serverUrl': serverUrl,
      'errorMessage': errorMessage,
      'errorType': errorType?.index,
      'fileSize': fileSize,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'nextRetryTime': nextRetryTime?.millisecondsSinceEpoch,
      'progress': progress,
    };
  }
  
  /// Tạo tập tin đính kèm từ Map
  factory QueuedAttachment.fromMap(Map<String, dynamic> map) {
    return QueuedAttachment(
      localId: map['localId'] as String,
      messageId: map['messageId'] as String,
      chatId: map['chatId'] as String,
      filePath: map['filePath'] as String,
      type: AttachmentType.values[map['type'] as int],
      status: AttachmentQueueStatus.values[map['status'] as int],
      serverId: map['serverId'] as String?,
      serverUrl: map['serverUrl'] as String?,
      errorMessage: map['errorMessage'] as String?,
      errorType: map['errorType'] != null 
          ? MessageErrorType.values[map['errorType'] as int] 
          : null,
      fileSize: map['fileSize'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      retryCount: map['retryCount'] as int,
      nextRetryTime: map['nextRetryTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRetryTime'] as int)
          : null,
      progress: map['progress'] as double,
    );
  }
  
  /// Factory để tạo mới tập tin đính kèm từ đường dẫn file
  factory QueuedAttachment.create({
    required String messageId,
    required String chatId, 
    required String filePath,
    required AttachmentType type,
  }) {
    final file = File(filePath);
    return QueuedAttachment(
      localId: DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: messageId,
      chatId: chatId,
      filePath: filePath,
      type: type,
      status: AttachmentQueueStatus.pending,
      fileSize: file.existsSync() ? file.lengthSync() : 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Kiểm tra xem tập tin đính kèm có thể thử lại không
  bool get canRetry => status.canRetry;
  
  /// Kiểm tra xem tập tin đính kèm đã ở trạng thái cuối cùng chưa
  bool get isTerminal => status.isTerminal;
  
  /// Kiểm tra xem tập tin đính kèm đã được xử lý thành công chưa
  bool get isSuccessful => status.isSuccessful;
  
  /// Kiểm tra xem file còn tồn tại trên thiết bị không
  bool get fileExists => File(filePath).existsSync();
  
  /// Kiểm tra xem có đang xử lý không
  bool get isProcessing => status.isProcessing;
  
  /// Kiểm tra xem có thể tạm dừng không
  bool get canBePaused => status.canBePaused;
  
  /// Kiểm tra xem có phải là loại hình ảnh không
  bool get isImage => type == AttachmentType.image;
  
  /// Kiểm tra xem có phải là loại video không
  bool get isVideo => type == AttachmentType.video;
  
  /// Kiểm tra xem có phải là loại âm thanh không
  bool get isAudio => type == AttachmentType.audio;
  
  /// Kiểm tra xem có phải là loại tài liệu không
  bool get isDocument => type == AttachmentType.document;
  
  /// Trả về tên file từ đường dẫn
  String get fileName {
    return filePath.split('/').last;
  }
} 