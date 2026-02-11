import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';

/// Repository interface for media operations
/// 
/// Handles upload, download, and caching of media files
/// following Clean Architecture principles.
abstract class IMediaRepository {
  /// Upload a media file
  /// 
  /// [filePath] - Local path to the file
  /// [type] - Type of attachment (image, video, audio, file)
  /// [chatId] - ID of the chat this media belongs to
  /// [messageId] - Optional message ID for linking
  /// 
  /// Returns [Either<Failure, Attachment>] with uploaded attachment info
  Future<Either<Failure, Attachment>> uploadMedia({
    required String filePath,
    required AttachmentType type,
    required String chatId,
    String? messageId,
    void Function(double progress)? onProgress,
  });
  
  /// Download a media file
  /// 
  /// [url] - Remote URL of the media
  /// [attachmentId] - ID of the attachment
  /// [type] - Type of attachment
  /// 
  /// Returns [Either<Failure, String>] with local file path
  Future<Either<Failure, String>> downloadMedia({
    required String url,
    required String attachmentId,
    required AttachmentType type,
    void Function(double progress)? onProgress,
  });
  
  /// Get cached media file path
  /// 
  /// [attachmentId] - ID of the attachment
  /// 
  /// Returns [Either<Failure, String?>] with local file path if cached
  Future<Either<Failure, String?>> getCachedMediaPath(String attachmentId);
  
  /// Delete cached media file
  /// 
  /// [attachmentId] - ID of the attachment to delete
  /// 
  /// Returns [Either<Failure, void>]
  Future<Either<Failure, void>> deleteCachedMedia(String attachmentId);
  
  /// Clear all cached media
  /// 
  /// Returns [Either<Failure, void>]
  Future<Either<Failure, void>> clearMediaCache();
  
  /// Get cache size in bytes
  /// 
  /// Returns [Either<Failure, int>] with total cache size
  Future<Either<Failure, int>> getCacheSize();
  
  /// Get attachment info by ID
  /// 
  /// [attachmentId] - ID of the attachment
  /// 
  /// Returns [Either<Failure, Attachment>]
  Future<Either<Failure, Attachment>> getAttachment(String attachmentId);
  
  /// Get all attachments for a message
  /// 
  /// [messageId] - ID of the message
  /// 
  /// Returns [Either<Failure, List<Attachment>>]
  Future<Either<Failure, List<Attachment>>> getMessageAttachments(
    String messageId,
  );
  
  /// Get all attachments for a chat
  /// 
  /// [chatId] - ID of the chat
  /// [type] - Optional filter by attachment type
  /// 
  /// Returns [Either<Failure, List<Attachment>>]
  Future<Either<Failure, List<Attachment>>> getChatAttachments({
    required String chatId,
    AttachmentType? type,
  });
}
