import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

part 'media_event.dart';
part 'media_state.dart';

/// **ENTERPRISE MEDIA BLOC**
///
/// Manages media operations with IMediaRepository integration
/// and Either<Failure, T> error handling for enterprise-grade reliability.
///
/// **Performance Targets:**
/// - Upload operations: <5s for typical files
/// - Download operations: <5s for typical files
/// - Cache operations: <100ms
/// - Thumbnail generation: <500ms
/// - Memory management: Efficient handling of large media files
///
/// **Architecture**: Clean Architecture + BLoC pattern + Either error handling
@injectable
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final IMediaRepository _mediaRepository;
  final Logger _logger = Logger();

  /// Constructor
  MediaBloc({
    required IMediaRepository mediaRepository,
  }) : _mediaRepository = mediaRepository,
       super(MediaStateX.initial) {
    on<UploadMedia>(_onUploadMedia);
    on<DownloadMedia>(_onDownloadMedia);
    on<GetCachedMedia>(_onGetCachedMedia);
    on<CompressImage>(_onCompressImage);
    on<GenerateThumbnail>(_onGenerateThumbnail);
    on<DeleteMedia>(_onDeleteMedia);
    on<ClearMediaCache>(_onClearMediaCache);
    on<GetCacheSize>(_onGetCacheSize);
    on<ValidateMedia>(_onValidateMedia);
    on<ClearMediaError>(_onClearMediaError);
  }

  /// **Upload media file - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <5s for typical files
  /// **Strategy**: Server upload with progress tracking
  Future<void> _onUploadMedia(
    UploadMedia event,
    Emitter<MediaState> emit,
  ) async {
    _logger.i('Uploading media: ${event.file.path}');

    emit(MediaStateX.uploading(
      fileName: event.file.path.split('/').last,
      progress: 0.0,
    ));

    final result = await _mediaRepository.uploadMedia(
      messageId: event.messageId,
      chatId: event.chatId,
      file: event.file,
      onProgress: (progress) {
        emit(MediaStateX.uploading(
          fileName: event.file.path.split('/').last,
          progress: progress,
        ));
      },
    );

    result.fold(
      (failure) {
        _logger.e('Failed to upload media: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (uploadResult) {
        _logger.i('Media uploaded successfully: ${uploadResult.id}');
        emit(MediaStateX.uploadSuccess(result: uploadResult));
      },
    );
  }

  /// **Download media file - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <100ms for cached, <5s for downloads
  /// **Strategy**: Cache → Download with progress tracking
  Future<void> _onDownloadMedia(
    DownloadMedia event,
    Emitter<MediaState> emit,
  ) async {
    _logger.i('Downloading media: ${event.url}');

    emit(MediaStateX.downloading(
      url: event.url,
      progress: 0.0,
    ));

    final result = await _mediaRepository.downloadMedia(
      url: event.url,
      messageId: event.messageId,
      useCache: event.useCache,
      onProgress: (progress) {
        emit(MediaStateX.downloading(
          url: event.url,
          progress: progress,
        ));
      },
    );

    result.fold(
      (failure) {
        _logger.e('Failed to download media: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (file) {
        if (file != null) {
          _logger.i('Media downloaded successfully: ${file.path}');
          emit(MediaStateX.downloadSuccess(file: file));
        } else {
          emit(MediaStateX.error(message: 'Không thể tải xuống media'));
        }
      },
    );
  }

  /// **Get cached media - OFFLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <50ms for cache retrieval
  /// **Strategy**: Memory cache → Disk cache
  Future<void> _onGetCachedMedia(
    GetCachedMedia event,
    Emitter<MediaState> emit,
  ) async {
    _logger.t('Getting cached media: ${event.url}');

    emit(MediaStateX.loading);

    final result = await _mediaRepository.getCachedMedia(
      event.url,
      key: event.key,
    );

    result.fold(
      (failure) {
        _logger.w('Failed to get cached media: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (file) {
        if (file != null) {
          _logger.t('Cached media retrieved: ${file.path}');
          emit(MediaStateX.cacheSuccess(file: file));
        } else {
          emit(MediaStateX.error(message: 'Media không có trong cache'));
        }
      },
    );
  }

  /// **Compress image - OFFLINE OPERATION**
  ///
  /// **Performance**: <1s for typical images
  /// **Strategy**: Local processing with progress indication
  Future<void> _onCompressImage(
    CompressImage event,
    Emitter<MediaState> emit,
  ) async {
    _logger.i('Compressing image: ${event.file.path}');

    emit(MediaStateX.processing(
      operation: 'Đang nén ảnh...',
      progress: 0.5, // Indeterminate progress
    ));

    final result = await _mediaRepository.compressImage(
      event.file,
      quality: event.quality,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to compress image: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (compressedFile) {
        if (compressedFile != null) {
          _logger.i('Image compressed successfully: ${compressedFile.path}');
          emit(MediaStateX.compressionSuccess(file: compressedFile));
        } else {
          emit(MediaStateX.error(message: 'Không thể nén ảnh'));
        }
      },
    );
  }

  /// **Generate thumbnail - OFFLINE OPERATION**
  ///
  /// **Performance**: <500ms for thumbnail generation
  /// **Strategy**: Local processing with progress indication
  Future<void> _onGenerateThumbnail(
    GenerateThumbnail event,
    Emitter<MediaState> emit,
  ) async {
    _logger.i('Generating thumbnail: ${event.file.path}');

    emit(MediaStateX.processing(
      operation: 'Đang tạo thumbnail...',
      progress: 0.5, // Indeterminate progress
    ));

    final result = await _mediaRepository.generateThumbnail(
      event.file,
      size: event.size,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to generate thumbnail: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (thumbnailFile) {
        if (thumbnailFile != null) {
          _logger.i('Thumbnail generated successfully: ${thumbnailFile.path}');
          emit(MediaStateX.thumbnailSuccess(file: thumbnailFile));
        } else {
          emit(MediaStateX.error(message: 'Không thể tạo thumbnail'));
        }
      },
    );
  }

  /// **Delete media - ONLINE-FIRST STRATEGY**
  ///
  /// **Performance**: <2s for deletion process
  /// **Strategy**: Server deletion with local cache cleanup
  Future<void> _onDeleteMedia(
    DeleteMedia event,
    Emitter<MediaState> emit,
  ) async {
    _logger.i('Deleting media: ${event.mediaId}');

    emit(MediaStateX.processing(
      operation: 'Đang xóa media...',
      progress: 0.5,
    ));

    final result = await _mediaRepository.deleteMedia(event.mediaId);

    result.fold(
      (failure) {
        _logger.e('Failed to delete media: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (success) {
        if (success) {
          _logger.i('Media deleted successfully: ${event.mediaId}');
          emit(MediaStateX.deleteSuccess(mediaId: event.mediaId));
        } else {
          emit(MediaStateX.error(message: 'Không thể xóa media'));
        }
      },
    );
  }

  /// **Clear media cache - OFFLINE OPERATION**
  ///
  /// **Performance**: <1s for complete cache clear
  /// **Strategy**: Bulk cache cleanup
  Future<void> _onClearMediaCache(
    ClearMediaCache event,
    Emitter<MediaState> emit,
  ) async {
    _logger.i('Clearing media cache');

    emit(MediaStateX.processing(
      operation: 'Đang xóa cache...',
      progress: 0.5,
    ));

    final result = await _mediaRepository.clearMediaCache();

    result.fold(
      (failure) {
        _logger.e('Failed to clear media cache: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (success) {
        if (success) {
          _logger.i('Media cache cleared successfully');
          emit(MediaStateX.cacheClearSuccess);
        } else {
          emit(MediaStateX.error(message: 'Không thể xóa cache'));
        }
      },
    );
  }

  /// **Get cache size - OFFLINE OPERATION**
  ///
  /// **Performance**: <100ms for size calculation
  /// **Strategy**: Local storage analysis
  Future<void> _onGetCacheSize(
    GetCacheSize event,
    Emitter<MediaState> emit,
  ) async {
    _logger.t('Getting cache size');

    emit(MediaStateX.loading);

    final result = await _mediaRepository.getCacheSize();

    result.fold(
      (failure) {
        _logger.e('Failed to get cache size: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (size) {
        _logger.t('Cache size: $size bytes');
        emit(MediaStateX.cacheSizeResult(sizeInBytes: size));
      },
    );
  }

  /// **Validate media file - OFFLINE OPERATION**
  ///
  /// **Performance**: <200ms for file validation
  /// **Strategy**: Local file validation
  Future<void> _onValidateMedia(
    ValidateMedia event,
    Emitter<MediaState> emit,
  ) async {
    _logger.t('Validating media file: ${event.file.path}');

    emit(MediaStateX.processing(
      operation: 'Đang kiểm tra file...',
      progress: 0.5,
    ));

    final result = await _mediaRepository.validateMedia(event.file);

    result.fold(
      (failure) {
        _logger.e('Failed to validate media: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (validationResult) {
        _logger.t('Media validation result: ${validationResult.isValid}');
        emit(MediaStateX.validationResult(result: validationResult));
      },
    );
  }

  /// **Clear media error state**
  Future<void> _onClearMediaError(
    ClearMediaError event,
    Emitter<MediaState> emit,
  ) async {
    _logger.t('Clearing media error state');
    emit(MediaStateX.initial);
  }

  /// **Helper method to convert Failure to user-friendly error message**
  String _getErrorMessage(Failure failure) {
    if (failure is ConnectionFailure) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    } else if (failure is ServerFailure) {
      return 'Lỗi server. Vui lòng thử lại sau.';
    } else if (failure is CacheFailure) {
      return 'Lỗi cache. Dữ liệu có thể không được cập nhật.';
    } else if (failure is ValidationFailure) {
      return 'File không hợp lệ. Vui lòng chọn file khác.';
    } else {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Đã xảy ra lỗi không xác định.';
    }
  }
}
