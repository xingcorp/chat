import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';
import 'package:flutter_chat_app/domain/services/i_media_gallery_saver.dart';
import 'package:gal/gal.dart';

/// `gal`-based implementation for writing media into system gallery.
class GalMediaGallerySaver implements IMediaGallerySaver {
  GalMediaGallerySaver(this._logger, this._fileDownloader);

  final AppLogger _logger;
  final IFileDownloader _fileDownloader;

  @override
  bool get isSupported {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia => false,
      TargetPlatform.linux => false,
      TargetPlatform.windows => false,
    };
  }

  @override
  Future<Either<Failure, void>> fallbackDownloadFromUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Missing media url for fallback download.',
          code: 'invalid_input',
        ),
      );
    }

    try {
      final Either<Failure, String> result =
          await _fileDownloader.downloadFromUrl(url: url);
      if (result.isLeft) {
        return Left(result.left);
      }
      return const Right(null);
    } catch (error, stackTrace) {
      _logger.e(
        'Fallback download failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Fallback download failed: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> ensureAccess() async {
    if (!isSupported) {
      return const Left(
        DownloadFailure(
          message: 'Saving to gallery is not supported on this platform.',
          code: 'unsupported_platform',
        ),
      );
    }

    try {
      final bool hasAccess = await Gal.hasAccess(toAlbum: true);
      if (hasAccess) {
        return const Right(null);
      }

      final bool granted = await Gal.requestAccess(toAlbum: true);
      if (granted) {
        return const Right(null);
      }

      return const Left(
        PermissionFailure(
          message: 'Gallery permission denied.',
          code: 'access_denied',
        ),
      );
    } on GalException catch (error, stackTrace) {
      _logger.e(
        'Gal permission check failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(_mapGalError(error));
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected gallery permission error',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        UnexpectedFailure(
          message: 'Unexpected gallery permission error: $error',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveImageFromPath({
    required String path,
    String? album,
  }) async {
    if (!isSupported) {
      return const Left(
        DownloadFailure(
          message: 'Saving to gallery is not supported on this platform.',
          code: 'unsupported_platform',
        ),
      );
    }

    try {
      await Gal.putImage(path, album: album);
      return const Right(null);
    } on GalException catch (error, stackTrace) {
      _logger.e(
        'Failed to save image from path',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(_mapGalError(error));
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error while saving image from path',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        UnexpectedFailure(
          message: 'Unexpected error while saving image from path: $error',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveImageFromBytes({
    required Uint8List bytes,
    required String name,
    String? album,
  }) async {
    if (!isSupported) {
      return const Left(
        DownloadFailure(
          message: 'Saving to gallery is not supported on this platform.',
          code: 'unsupported_platform',
        ),
      );
    }

    try {
      await Gal.putImageBytes(bytes, name: name, album: album);
      return const Right(null);
    } on GalException catch (error, stackTrace) {
      _logger.e(
        'Failed to save image from bytes',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(_mapGalError(error));
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error while saving image from bytes',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        UnexpectedFailure(
          message: 'Unexpected error while saving image from bytes: $error',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveVideoFromPath({
    required String path,
    String? album,
  }) async {
    if (!isSupported) {
      return const Left(
        DownloadFailure(
          message: 'Saving to gallery is not supported on this platform.',
          code: 'unsupported_platform',
        ),
      );
    }

    try {
      await Gal.putVideo(path, album: album);
      return const Right(null);
    } on GalException catch (error, stackTrace) {
      _logger.e(
        'Failed to save video from path',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(_mapGalError(error));
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error while saving video from path',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        UnexpectedFailure(
          message: 'Unexpected error while saving video from path: $error',
        ),
      );
    }
  }

  Failure _mapGalError(GalException error) {
    final String message = error.toString();
    final String code = error.type.name;

    if (code == 'accessDenied') {
      return PermissionFailure(
        message: message,
        code: 'access_denied',
      );
    }

    if (code == 'notEnoughSpace') {
      return DownloadFailure(
        message: message,
        code: 'storage_full',
      );
    }

    if (code == 'notSupportedFormat' || code == 'unsupportedFormat') {
      return ValidationFailure(
        message: message,
        code: 'invalid_format',
      );
    }

    return DownloadFailure(
      message: message,
      code: code,
    );
  }
}
