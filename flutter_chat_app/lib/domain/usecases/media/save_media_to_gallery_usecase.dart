import 'dart:typed_data';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:flutter_chat_app/domain/services/i_media_gallery_saver.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';

/// Media type supported by gallery save flow.
enum GalleryMediaType {
  image,
  video,
}

/// Parameters for [SaveMediaToGalleryUseCase].
class SaveMediaToGalleryParams {
  const SaveMediaToGalleryParams({
    this.url,
    this.localPath,
    this.bytes,
    this.fileName,
    required this.mediaType,
    this.mediaId,
    this.album,
  });

  /// Remote media URL.
  final String? url;

  /// Existing local file path to save.
  final String? localPath;

  /// Optional image bytes (for edited images).
  final Uint8List? bytes;

  /// Name used when saving bytes.
  final String? fileName;

  /// Target media type.
  final GalleryMediaType mediaType;

  /// Stable media id used for cache/download key.
  final String? mediaId;

  /// Optional custom album.
  final String? album;
}

/// Unified entry point for saving image/video into gallery across the app.
class SaveMediaToGalleryUseCase {
  SaveMediaToGalleryUseCase({
    required IMediaRepository mediaRepository,
    required IMediaGallerySaver gallerySaver,
    required AppLogger logger,
  })  : _mediaRepository = mediaRepository,
        _gallerySaver = gallerySaver,
        _logger = logger;

  static const String defaultAlbum = 'OXII Chat';

  final IMediaRepository _mediaRepository;
  final IMediaGallerySaver _gallerySaver;
  final AppLogger _logger;

  Future<Either<Failure, void>> call(SaveMediaToGalleryParams params) async {
    if (!_gallerySaver.isSupported) {
      return _gallerySaver.fallbackDownloadFromUrl(params.url);
    }

    final Either<Failure, void> accessResult =
        await _gallerySaver.ensureAccess();
    if (accessResult.isLeft) {
      return accessResult;
    }

    if (params.bytes != null) {
      if (params.mediaType != GalleryMediaType.image) {
        return const Left(
          ValidationFailure(
            message: 'Bytes input is only supported for images.',
            code: 'invalid_input',
          ),
        );
      }

      final String fileName = params.fileName ?? _buildDefaultImageName();
      return _gallerySaver.saveImageFromBytes(
        bytes: params.bytes!,
        name: fileName,
        album: params.album ?? defaultAlbum,
      );
    }

    final Either<Failure, String> localPathResult =
        await _resolveLocalPath(params);
    if (localPathResult.isLeft) {
      return Left<Failure, void>(localPathResult.left);
    }

    return _saveFromLocalPath(
      localPath: localPathResult.right,
      mediaType: params.mediaType,
      album: params.album ?? defaultAlbum,
    );
  }

  Future<Either<Failure, String>> _resolveLocalPath(
    SaveMediaToGalleryParams params,
  ) async {
    if (params.localPath != null && params.localPath!.isNotEmpty) {
      return Right(params.localPath!);
    }

    if (params.url == null || params.url!.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Either url, localPath, or bytes must be provided.',
          code: 'invalid_input',
        ),
      );
    }

    final AttachmentType attachmentType =
        params.mediaType == GalleryMediaType.image
            ? AttachmentType.image
            : AttachmentType.video;
    final String attachmentId =
        params.mediaId ?? params.url.hashCode.toString();

    _logger.i(
      'SaveMediaToGalleryUseCase: downloading media before save',
      <String, dynamic>{
        'url': params.url,
        'attachmentId': attachmentId,
        'mediaType': params.mediaType.name,
      },
    );

    final Either<Failure, String> downloadResult =
        await _mediaRepository.downloadMedia(
      url: params.url!,
      attachmentId: attachmentId,
      type: attachmentType,
    );

    if (downloadResult.isLeft) {
      return Left<Failure, String>(downloadResult.left);
    }

    return Right(downloadResult.right);
  }

  Future<Either<Failure, void>> _saveFromLocalPath({
    required String localPath,
    required GalleryMediaType mediaType,
    required String album,
  }) {
    return switch (mediaType) {
      GalleryMediaType.image => _gallerySaver.saveImageFromPath(
          path: localPath,
          album: album,
        ),
      GalleryMediaType.video => _gallerySaver.saveVideoFromPath(
          path: localPath,
          album: album,
        ),
    };
  }

  String _buildDefaultImageName() {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    return 'image_$millis.jpg';
  }
}
