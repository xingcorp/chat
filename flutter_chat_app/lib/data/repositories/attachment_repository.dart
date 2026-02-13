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
/// Implements attachment operations using storageGeneratePresignedUrls API.
/// Matches Angular frontend upload-file.service.ts implementation.
///
/// **Upload Flow (matching Angular):**
/// 1. Call storageGeneratePresignedUrls → get presignedUrl, path, url
/// 2. PUT file binary to presignedUrl with Content-Type header
/// 3. Use url in chatMessageAdd (urls field)
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

      // Get file info
      final filename = file.path.split(Platform.pathSeparator).last;
      final extension = filename.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      // Step 1: Generate presigned upload URL
      // Matching Angular: uploadFileService.storageGeneratePresignedUrls({files: [...]})
      final uploadResponse = await _chatObjectDataSource.generateUploadLinks(
        files: [
          GeneratePresignedUrlParams(
            fileName: filename,
            fileType: mimeType,
          ),
        ],
      );

      if (uploadResponse.data.isEmpty) {
        throw Exception('No upload data returned from server');
      }

      final uploadData = uploadResponse.data.first;

      _logger.debug('Upload link generated', {
        'id': uploadData.id,
        'path': uploadData.path,
        'url': uploadData.url,
      });

      // Step 2: Upload file binary to presigned URL
      // Matching Angular: uploadFileService.uploadMessageFileS3Observable(file, presignedUrl)
      await _chatObjectDataSource.uploadFile(
        presignedUrl: uploadData.presignedUrl,
        filePath: file.path,
        contentType: mimeType,
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      _logger.info('File uploaded successfully');

      final fileSize = await file.length();

      // Return result with url for use in chatMessageAdd
      // Matching Angular: urls: [uploadData.url]
      return Right(
        AttachmentUploadResult(
          id: uploadData.id,
          url: uploadData.url ?? uploadData.path,
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
  /// Matching Angular: fileType passed to storageGeneratePresignedUrls
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
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';

      default:
        return 'application/octet-stream';
    }
  }
}
