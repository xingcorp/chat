import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:flutter_chat_app/domain/repositories/i_media_repository.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart' as base;

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
class MediaBloc extends BaseBloc<MediaEvent, MediaState> {
  final IMediaRepository _mediaRepository;
  final AppLogger _logger;

  /// Constructor
  MediaBloc({
    required IMediaRepository mediaRepository,
    required AppLogger logger,
  })  : _mediaRepository = mediaRepository,
        _logger = logger,
        super(MediaStateX.initial) {
    on<UploadMedia>(_onUploadMedia);
    on<DownloadMedia>(_onDownloadMedia);
    on<GetCachedMedia>(_onGetCachedMedia);
    on<ClearMediaCache>(_onClearMediaCache);
    on<GetCacheSize>(_onGetCacheSize);
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

    // Determine attachment type from file extension
    final fileName = event.file.path.split('/').last.toLowerCase();
    AttachmentType type = AttachmentType.other;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png') || fileName.endsWith('.gif')) {
      type = AttachmentType.image;
    } else if (fileName.endsWith('.mp4') || fileName.endsWith('.mov') || fileName.endsWith('.avi')) {
      type = AttachmentType.video;
    } else if (fileName.endsWith('.mp3') || fileName.endsWith('.wav') || fileName.endsWith('.m4a')) {
      type = AttachmentType.audio;
    } else if (fileName.endsWith('.pdf') || fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      type = AttachmentType.document;
    }

    final result = await _mediaRepository.uploadMedia(
      filePath: event.file.path,
      type: type,
      chatId: event.chatId,
      messageId: event.messageId,
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
      (attachment) {
        _logger.i('Media uploaded successfully: ${attachment.id}');
        emit(MediaStateX.uploadSuccess(result: attachment));
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

    // Determine attachment type from URL extension
    final urlLower = event.url.toLowerCase();
    AttachmentType type = AttachmentType.other;
    if (urlLower.contains('.jpg') || urlLower.contains('.jpeg') || urlLower.contains('.png') || urlLower.contains('.gif')) {
      type = AttachmentType.image;
    } else if (urlLower.contains('.mp4') || urlLower.contains('.mov') || urlLower.contains('.avi')) {
      type = AttachmentType.video;
    } else if (urlLower.contains('.mp3') || urlLower.contains('.wav') || urlLower.contains('.m4a')) {
      type = AttachmentType.audio;
    } else if (urlLower.contains('.pdf') || urlLower.contains('.doc') || urlLower.contains('.docx')) {
      type = AttachmentType.document;
    }

    // Generate attachmentId from messageId or URL
    final attachmentId = event.messageId ?? event.url.hashCode.toString();

    final result = await _mediaRepository.downloadMedia(
      url: event.url,
      attachmentId: attachmentId,
      type: type,
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
      (filePath) {
        _logger.i('Media downloaded successfully: $filePath');
        emit(MediaStateX.downloadSuccess(file: File(filePath)));
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
    _logger.d('Getting cached media: ${event.url}');

    emit(MediaStateX.loading);

    // Use key as attachmentId, or generate from URL
    final attachmentId = event.key ?? event.url.hashCode.toString();

    final result = await _mediaRepository.getCachedMediaPath(attachmentId);

    result.fold(
      (failure) {
        _logger.w('Failed to get cached media: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (filePath) {
        if (filePath != null) {
          _logger.d('Cached media retrieved: $filePath');
          emit(MediaStateX.cacheSuccess(file: File(filePath)));
        } else {
          emit(MediaStateX.error(message: 'Media không có trong cache'));
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
      (_) {
        _logger.i('Media cache cleared successfully');
        emit(MediaStateX.cacheClearSuccess);
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
    _logger.d('Getting cache size');

    emit(MediaStateX.loading);

    final result = await _mediaRepository.getCacheSize();

    result.fold(
      (failure) {
        _logger.e('Failed to get cache size: ${failure.message}');
        emit(MediaStateX.error(message: _getErrorMessage(failure)));
      },
      (size) {
        _logger.d('Cache size: $size bytes');
        emit(MediaStateX.cacheSizeResult(sizeInBytes: size));
      },
    );
  }

  /// **Clear media error state**
  Future<void> _onClearMediaError(
    ClearMediaError event,
    Emitter<MediaState> emit,
  ) async {
    _logger.d('Clearing media error state');
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
