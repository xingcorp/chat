import 'dart:async';
import 'dart:io';

/// Kết quả tải lên tập tin đính kèm
class AttachmentUploadResult {
  /// ID của tập tin đính kèm trên server
  final String id;
  
  /// URL truy cập tập tin
  final String url;
  
  /// Kích thước của tập tin (bytes)
  final int size;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Constructor
  AttachmentUploadResult({
    required this.id,
    required this.url,
    required this.size,
    required this.createdAt,
  });
  
  /// Tạo từ JSON
  factory AttachmentUploadResult.fromJson(Map<String, dynamic> json) {
    return AttachmentUploadResult(
      id: json['id'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  /// Chuyển thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'size': size,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Interface cho việc tương tác với repository tập tin đính kèm
abstract class IAttachmentRepository {
  /// Tải tập tin lên server
  /// 
  /// [messageId]: ID của tin nhắn mà tập tin thuộc về
  /// [chatId]: ID của chat mà tin nhắn thuộc về
  /// [file]: Tập tin cần tải lên
  /// [onProgress]: Callback để cập nhật tiến độ tải lên (0.0 - 1.0)
  /// 
  /// Trả về stream chứa kết quả tải lên
  Stream<AttachmentUploadResult> uploadAttachment({
    required String messageId,
    required String chatId,
    required File file,
    void Function(double progress)? onProgress,
  });
  
  /// Tải tập tin từ server
  /// 
  /// [attachmentId]: ID của tập tin cần tải xuống
  /// [destination]: Đường dẫn lưu tập tin
  /// [onProgress]: Callback để cập nhật tiến độ tải xuống (0.0 - 1.0)
  /// 
  /// Trả về stream chứa đường dẫn tập tin đã tải xuống
  Stream<String> downloadAttachment({
    required String attachmentId,
    required String destination,
    void Function(double progress)? onProgress,
  });
  
  /// Xóa tập tin từ server
  /// 
  /// [attachmentId]: ID của tập tin cần xóa
  /// 
  /// Trả về true nếu xóa thành công
  Future<bool> deleteAttachment(String attachmentId);
  
  /// Lấy thông tin của tập tin
  /// 
  /// [attachmentId]: ID của tập tin cần lấy thông tin
  /// 
  /// Trả về thông tin của tập tin
  Future<AttachmentUploadResult> getAttachmentInfo(String attachmentId);
  
  /// Lấy URL tạm thời cho tập tin
  /// 
  /// [attachmentId]: ID của tập tin
  /// [expiryMinutes]: Thời gian hết hạn tính bằng phút
  /// 
  /// Trả về URL tạm thời
  Future<String> getTemporaryUrl(String attachmentId, {int expiryMinutes = 60});
} 