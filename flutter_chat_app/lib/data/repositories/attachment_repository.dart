import 'dart:io';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/dtos/chat_object_dto.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat_object/chat_object_remote_datasource.dart';
import 'package:injectable/injectable.dart';

/// **Attachment Repository Implementation**
///
/// Implements attachment operations using new ChatObject API.
/// Integrates with AttachmentQueueService for offline support.
@LazySingleton(as: IAttachmentRepository)
class AttachmentRepository implements IAttachmentRepository {
  final IChatObjectRemoteDataSource _chatObjectDataSource;
  final AppLogger _logger;

  AttachmentRepository(
    this._chatObjectDataSource,
    this._logger,
  );

  @override
  Future<Either<Failure, AttachmentUploadResult>> uploadAttachment({
    required String messageId,
    required String chatId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      _logger.info('AttachmentRepository: Uploading file', {
        'messageId': messageId,
        'chatId': chatId,
        'filePath': file.path,
      });

      // Step 1: Generate upload link
      final filename = file.path.split(Platform.pathSeparator).last;
      final extension = filename.split('.').last.toLowerCase();
      final mimetype = _getMimeType(extension);

      final uploadResponse = await _chatObjectDataSource.generateUploadLink(
        filename: filename,
        conversationId: chatId,
        type: ChatObjectType.message,
        mimetype: mimetype,
      );

      _logger.debug('Upload link generated', {
        'path': uploadResponse.path,
      });

      // Step 2: Upload file to GCP
      await _chatObjectDataSource.uploadFile(
        uploadUrl: uploadResponse.uploadUrl,
        filePath: file.path,
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      _logger.info('File uploaded successfully');

      // Step 3: Get download URL
      final urlResponse = await _chatObjectDataSource.getObjectUrl(
        uploadResponse.path,
      );

      final fileSize = await file.length();

      return Right(
        AttachmentUploadResult(
          id: uploadResponse.path,
          url: urlResponse.url,
          size: fileSize,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to upload attachment', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to upload attachment: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> downloadAttachment({
    required String attachmentId,
    required String destination,
    void Function(double progress)? onProgress,
  }) async {
    try {
      _logger.info('AttachmentRepository: Downloading attachment', {
        'attachmentId': attachmentId,
        'destination': destination,
      });

      // Get download URL from path
      final urlResponse = await _chatObjectDataSource.getObjectUrl(attachmentId);

      // TODO: Implement actual download logic with progress
      // For now, just return the URL
      return Right(urlResponse.url);
    } catch (e, stackTrace) {
      _logger.error('Failed to download attachment', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to download attachment: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAttachment(String attachmentId) async {
    try {
      _logger.info('AttachmentRepository: Deleting attachment', {
        'attachmentId': attachmentId,
      });

      // Note: Backend doesn't have delete endpoint yet
      // This is a placeholder for future implementation
      return const Right(true);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete attachment', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to delete attachment: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, AttachmentUploadResult>> getAttachmentInfo(
    String attachmentId,
  ) async {
    try {
      _logger.info('AttachmentRepository: Getting attachment info', {
        'attachmentId': attachmentId,
      });

      final urlResponse = await _chatObjectDataSource.getObjectUrl(attachmentId);

      return Right(
        AttachmentUploadResult(
          id: attachmentId,
          url: urlResponse.url,
          size: 0, // Size unknown without download
          createdAt: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to get attachment info', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to get attachment info: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getTemporaryUrl(
    String attachmentId, {
    int expiryMinutes = 60,
  }) async {
    try {
      _logger.info('AttachmentRepository: Getting temporary URL', {
        'attachmentId': attachmentId,
        'expiryMinutes': expiryMinutes,
      });

      final urlResponse = await _chatObjectDataSource.getObjectUrl(attachmentId);

      // Firebase URLs are already temporary with expiry
      return Right(urlResponse.url);
    } catch (e, stackTrace) {
      _logger.error('Failed to get temporary URL', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to get temporary URL: ${e.toString()}'),
      );
    }
  }

  /// Determine MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';

      default:
        return 'application/octet-stream';
    }
  }
}
