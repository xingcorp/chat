import 'package:dio/dio.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/dtos/chat_object_dto.dart';
import 'package:flutter_chat_app/features/chat/data/datasources/chat_object/chat_object_remote_datasource.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

/// Upload File Result
///
/// Contains the storage path and optional download URL
class UploadFileResult {
  /// Storage path for referencing the file in messages
  final String path;

  /// Optional download URL (if requested)
  final String? downloadUrl;

  const UploadFileResult({
    required this.path,
    this.downloadUrl,
  });
}

/// Upload File Use Case
///
/// Handles the complete file upload flow:
/// 1. Generate pre-signed upload URL from backend
/// 2. Upload file directly to GCP Cloud Storage
/// 3. Optionally get download URL
///
/// **Two-Step Upload Process:**
/// - Step 1: Backend generates secure upload URL
/// - Step 2: Client uploads directly to cloud storage
/// - Step 3: Use returned path in message
@injectable
class UploadFileUseCase {
  final IChatObjectRemoteDataSource _dataSource;
  final AppLogger _logger;

  const UploadFileUseCase({
    required IChatObjectRemoteDataSource dataSource,
    required AppLogger logger,
  })  : _dataSource = dataSource,
        _logger = logger;

  /// Execute file upload
  ///
  /// [filePath] - Local file path to upload
  /// [conversationId] - Required for MESSAGE type
  /// [type] - Upload type (MESSAGE, GROUP, STORY)
  /// [onProgress] - Optional upload progress callback
  /// [getDownloadUrl] - Whether to fetch download URL after upload
  ///
  /// Returns Either<Failure, UploadFileResult>
  Future<Either<Failure, UploadFileResult>> call({
    required String filePath,
    String? conversationId,
    ChatObjectType type = ChatObjectType.message,
    ProgressCallback? onProgress,
    bool getDownloadUrl = false,
  }) async {
    _logger.info('UploadFileUseCase: Starting upload', {
      'filePath': filePath,
      'conversationId': conversationId,
      'type': type.name,
    });

    try {
      // Validate inputs
      if (type == ChatObjectType.message && conversationId == null) {
        return const Left(
          ValidationFailure(
            message: 'conversationId is required for MESSAGE type uploads',
          ),
        );
      }

      // Extract filename and determine MIME type
      final filename = path.basename(filePath);
      final extension = path.extension(filePath).toLowerCase();
      final mimetype = _getMimeType(extension);

      _logger.debug('UploadFileUseCase: File info', {
        'filename': filename,
        'mimetype': mimetype,
      });

      // Step 1: Generate upload link
      final uploadResponse = await _dataSource.generateUploadLink(
        filename: filename,
        conversationId: conversationId,
        type: type,
        mimetype: mimetype,
      );

      _logger.info('UploadFileUseCase: Upload link generated', {
        'path': uploadResponse.path,
      });

      // Step 2: Upload file to GCP
      await _dataSource.uploadFile(
        uploadUrl: uploadResponse.uploadUrl,
        filePath: filePath,
        onProgress: onProgress,
      );

      _logger.info('UploadFileUseCase: File uploaded successfully');

      // Step 3: Optionally get download URL
      String? downloadUrl;
      if (getDownloadUrl) {
        final urlResponse = await _dataSource.getObjectUrl(uploadResponse.path);
        downloadUrl = urlResponse.url;
        _logger.debug('UploadFileUseCase: Download URL retrieved');
      }

      return Right(
        UploadFileResult(
          path: uploadResponse.path,
          downloadUrl: downloadUrl,
        ),
      );
    } on DioException catch (e, stackTrace) {
      _logger.error('UploadFileUseCase: Network error', e, stackTrace);
      return Left(
        NetworkFailure(
          message: 'Failed to upload file: ${e.message}',
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('UploadFileUseCase: Unexpected error', e, stackTrace);
      return Left(
        UnexpectedFailure(message: 'Upload failed: ${e.toString()}'),
      );
    }
  }

  /// Determine MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension) {
      // Images
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.svg':
        return 'image/svg+xml';

      // Videos
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      case '.webm':
        return 'video/webm';

      // Audio
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';

      // Documents
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.csv':
        return 'text/csv';

      // Archives
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';

      default:
        return 'application/octet-stream';
    }
  }
}
