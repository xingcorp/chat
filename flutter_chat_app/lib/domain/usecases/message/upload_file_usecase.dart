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
/// Contains the storage path, url for use in messages, and optional download URL
class UploadFileResult {
  /// Unique file ID from storage service
  final String id;

  /// Storage path for referencing the file
  final String storagePath;

  /// URL for use in chatMessageAdd (urls field)
  /// This is the CDN URL returned by storageGeneratePresignedUrls
  final String url;

  /// Optional download URL (if requested separately)
  final String? downloadUrl;

  const UploadFileResult({
    required this.id,
    required this.storagePath,
    required this.url,
    this.downloadUrl,
  });

  // Legacy getter for backward compatibility
  String get path => storagePath;
}

/// Upload File Use Case
///
/// Handles the complete file upload flow matching Angular frontend:
/// 1. Generate pre-signed upload URL via storageGeneratePresignedUrls
/// 2. Upload file binary directly to presigned URL
/// 3. Return url for use in chatMessageAdd
///
/// **Matching Angular:** upload-file.service.ts
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
  /// [onProgress] - Optional upload progress callback
  /// [getDownloadUrl] - Whether to fetch download URL after upload
  ///
  /// Returns Either<Failure, UploadFileResult>
  Future<Either<Failure, UploadFileResult>> call({
    required String filePath,
    ProgressCallback? onProgress,
    bool getDownloadUrl = false,
  }) async {
    _logger.info('UploadFileUseCase: Starting upload', {
      'filePath': filePath,
    });

    try {
      // Extract filename and determine MIME type
      final filename = path.basename(filePath);
      final extension = path.extension(filePath).toLowerCase();
      final mimeType = _getMimeType(extension);

      _logger.debug('UploadFileUseCase: File info', {
        'filename': filename,
        'mimeType': mimeType,
      });

      // Step 1: Generate presigned upload URL
      // Matching Angular: storageGeneratePresignedUrls({files: [...]})
      final uploadResponse = await _dataSource.generateUploadLinks(
        files: [
          GeneratePresignedUrlParams(
            fileName: filename,
            fileType: mimeType,
          ),
        ],
      );

      if (uploadResponse.data.isEmpty) {
        return const Left(
          UnexpectedFailure(message: 'No upload data returned from server'),
        );
      }

      final uploadData = uploadResponse.data.first;

      _logger.info('UploadFileUseCase: Upload link generated', {
        'id': uploadData.id,
        'path': uploadData.path,
        'url': uploadData.url,
      });

      // Step 2: Upload file binary to presigned URL
      // Matching Angular: uploadMessageFileS3Observable
      await _dataSource.uploadFile(
        presignedUrl: uploadData.presignedUrl,
        filePath: filePath,
        contentType: mimeType,
        onProgress: onProgress,
      );

      _logger.info('UploadFileUseCase: File uploaded successfully');

      // Step 3: Optionally get download URL from separate endpoint
      String? downloadUrl;
      if (getDownloadUrl) {
        final urlResponse = await _dataSource.getObjectUrl(uploadData.path);
        downloadUrl = urlResponse.url;
        _logger.debug('UploadFileUseCase: Download URL retrieved');
      }

      return Right(
        UploadFileResult(
          id: uploadData.id,
          storagePath: uploadData.path,
          url: uploadData.url ?? uploadData.path,
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
  /// Matching Angular: fileType passed to storageGeneratePresignedUrls
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
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';

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
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';

      // Archives
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/vnd.rar';
      case '.7z':
        return 'application/x-7z-compressed';

      default:
        return 'application/octet-stream';
    }
  }
}
