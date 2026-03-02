import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/data/datasources/media/media_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/media/media_remote_datasource.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Implementation of media repository with offline-first strategy
@LazySingleton(as: IMediaRepository)
class MediaRepositoryImpl implements IMediaRepository {
  final IMediaRemoteDataSource _remoteDataSource;
  final IMediaLocalDataSource _localDataSource;
  final INetworkInfo _networkInfo;

  MediaRepositoryImpl({
    required IMediaRemoteDataSource remoteDataSource,
    required IMediaLocalDataSource localDataSource,
    required INetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, Attachment>> uploadMedia({
    required String filePath,
    required AttachmentType type,
    required String chatId,
    String? messageId,
    void Function(double progress)? onProgress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(
        message: 'No internet connection. Upload will be queued.',
      ));
    }

    try {
      final attachmentModel = await _remoteDataSource.uploadMedia(
        filePath: filePath,
        type: type,
        chatId: chatId,
        messageId: messageId,
        onProgress: onProgress,
      );

      try {
        await _localDataSource.cacheMedia(
          sourceFilePath: filePath,
          attachmentId: attachmentModel.id,
          type: type,
        );
        await _localDataSource.saveAttachmentMetadata(attachmentModel);
      } catch (e) {
        // Cache failure is not critical
      }

      return Right(attachmentModel.toDomain());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on FileException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Upload failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> downloadMedia({
    required String url,
    required String attachmentId,
    required AttachmentType type,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final cachedPath =
          await _localDataSource.getCachedMediaPath(attachmentId);
      if (cachedPath != null) {
        return Right(cachedPath);
      }

      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure(
          message: 'No internet connection. Cannot download media.',
        ));
      }

      final tempPath = await _buildTempPath(attachmentId: attachmentId);
      final downloadedPath = await _remoteDataSource.downloadMedia(
        url: url,
        savePath: tempPath,
        onProgress: onProgress,
      );

      final cachedPath2 = await _localDataSource.cacheMedia(
        sourceFilePath: downloadedPath,
        attachmentId: attachmentId,
        type: type,
      );

      return Right(cachedPath2);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      final String failureCode = switch (e.statusCode) {
        404 => 'file_not_found',
        507 => 'storage_full',
        _ => 'download_failed',
      };
      return Left(
        DownloadFailure(
          message: e.message,
          code: failureCode,
          details: <String, dynamic>{'statusCode': e.statusCode},
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Download failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getCachedMediaPath(
      String attachmentId) async {
    try {
      final cachedPath =
          await _localDataSource.getCachedMediaPath(attachmentId);
      return Right(cachedPath);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to get cached path: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCachedMedia(String attachmentId) async {
    try {
      await _localDataSource.deleteCachedMedia(attachmentId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to delete: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearMediaCache() async {
    try {
      await _localDataSource.clearMediaCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to clear: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getCacheSize() async {
    try {
      final size = await _localDataSource.getCacheSize();
      return Right(size);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to get size: $e'));
    }
  }

  @override
  Future<Either<Failure, Attachment>> getAttachment(String attachmentId) async {
    try {
      final cachedMetadata =
          await _localDataSource.getAttachmentMetadata(attachmentId);
      if (cachedMetadata != null) {
        return Right(cachedMetadata.toDomain());
      }

      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure(
          message: 'No internet connection and attachment not cached.',
        ));
      }

      final attachmentModel =
          await _remoteDataSource.getAttachment(attachmentId);

      try {
        await _localDataSource.saveAttachmentMetadata(attachmentModel);
      } catch (e) {
        // Cache failure is not critical
      }

      return Right(attachmentModel.toDomain());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed to get attachment: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Attachment>>> getMessageAttachments(
    String messageId,
  ) async {
    try {
      if (!await _networkInfo.isConnected) {
        return const Right([]);
      }

      final attachmentModels =
          await _remoteDataSource.getMessageAttachments(messageId);

      for (final model in attachmentModels) {
        try {
          await _localDataSource.saveAttachmentMetadata(model);
        } catch (e) {
          // Continue
        }
      }

      final attachments = attachmentModels.map((m) => m.toDomain()).toList();
      return Right(attachments);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Attachment>>> getChatAttachments({
    required String chatId,
    AttachmentType? type,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        return const Right([]);
      }

      final attachmentModels = await _remoteDataSource.getChatAttachments(
        chatId: chatId,
        type: type,
      );

      for (final model in attachmentModels) {
        try {
          await _localDataSource.saveAttachmentMetadata(model);
        } catch (e) {
          // Continue
        }
      }

      final attachments = attachmentModels.map((m) => m.toDomain()).toList();
      return Right(attachments);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Failed: $e'));
    }
  }

  Future<String> _buildTempPath({
    required String attachmentId,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      return p.join(tempDir.path, attachmentId);
    } catch (_) {
      // Fallback for test/runtime environments where temp directory provider is unavailable.
      return '/tmp/$attachmentId';
    }
  }
}
