import 'dart:async';
import 'dart:io';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

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

/// **ENTERPRISE ATTACHMENT REPOSITORY INTERFACE**
///
/// Updated interface for attachment operations with Either<Failure, T> error handling
/// and enterprise-grade performance optimization.
///
/// **Error Handling**: All methods return Either<Failure, T> for consistent error management
/// **Performance**: Optimized for enterprise attachment standards
/// **Architecture**: Clean Architecture with SOLID principles
abstract class IAttachmentRepository {
  /// **Upload attachment to server - ONLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOnlineFirst (server upload required)
  /// **Performance**: <5s for typical attachments
  /// **Use Case**: Message attachments, file sharing
  Future<Either<Failure, AttachmentUploadResult>> uploadAttachment({
    required String messageId,
    required String chatId,
    required File file,
    void Function(double progress)? onProgress,
  });
  
  /// **Download attachment from server - ONLINE-FIRST WITH CACHE**
  ///
  /// **Strategy**: executeOfflineFirst (cached files priority)
  /// **Performance**: <100ms for cached files, <5s for downloads
  /// **Use Case**: Attachment viewing, file downloads
  Future<Either<Failure, String>> downloadAttachment({
    required String attachmentId,
    required String destination,
    void Function(double progress)? onProgress,
  });

  /// **Delete attachment from server - ONLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOnlineFirst (server deletion required)
  /// **Performance**: <2s for deletion process
  /// **Use Case**: Attachment cleanup, privacy management
  Future<Either<Failure, bool>> deleteAttachment(String attachmentId);

  /// **Get attachment information - OFFLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOfflineFirst (cached info priority)
  /// **Performance**: <50ms for cached info
  /// **Use Case**: Attachment metadata display
  Future<Either<Failure, AttachmentUploadResult>> getAttachmentInfo(String attachmentId);

  /// **Get temporary URL for attachment - ONLINE-FIRST STRATEGY**
  ///
  /// **Strategy**: executeOnlineFirst (server URL generation)
  /// **Performance**: <1s for URL generation
  /// **Use Case**: Secure attachment access, temporary sharing
  Future<Either<Failure, String>> getTemporaryUrl(String attachmentId, {int expiryMinutes = 60});
} 