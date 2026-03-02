import 'dart:async';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/file_download_state.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';
import 'package:url_launcher/url_launcher.dart';

IFileDownloadManager createFileDownloadManagerImpl(AppLogger logger) {
  return _WebFileDownloadManager(logger);
}

class _WebFileDownloadManager implements IFileDownloadManager {
  _WebFileDownloadManager(this._logger);

  final AppLogger _logger;
  final Map<String, FileDownloadState> _states = <String, FileDownloadState>{};
  final Map<String, StreamController<FileDownloadState>> _controllers =
      <String, StreamController<FileDownloadState>>{};

  @override
  FileDownloadState stateOf(String key) {
    return _states[key] ?? FileDownloadState.idle(key);
  }

  @override
  Stream<FileDownloadState> watch(String key) async* {
    yield stateOf(key);
    yield* _controllerFor(key).stream;
  }

  @override
  Future<Either<Failure, FileDownloadState>> startDownload({
    required String key,
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    final Uri? resolvedUri = _resolveUri(url);
    if (resolvedUri == null) {
      return const Left(
        ValidationFailure(
          message: 'Invalid file URL.',
          code: 'invalid_input',
        ),
      );
    }

    final FileDownloadState current = stateOf(key);
    if (current.isInProgress) {
      return Right(current);
    }

    final FileDownloadState downloading = FileDownloadState(
      key: key,
      status: FileDownloadStatus.downloading,
      progress: 0,
      sourceUrl: resolvedUri.toString(),
      fileName: fileName ?? current.fileName,
    );
    _emit(downloading);

    try {
      final bool launched = await launchUrl(
        resolvedUri,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        final FileDownloadState failed = downloading.copyWith(
          status: FileDownloadStatus.failed,
          progress: 0,
          errorMessage: 'Unable to open file URL for download.',
        );
        _emit(failed);
        return const Left(
          DownloadFailure(
            message: 'Unable to open file URL for download.',
            code: 'download_failed',
          ),
        );
      }

      final FileDownloadState completed = downloading.copyWith(
        status: FileDownloadStatus.completed,
        progress: 100,
        clearErrorMessage: true,
      );
      _emit(completed);
      return Right(completed);
    } catch (error, stackTrace) {
      _logger.e(
        'Web file download failed',
        error: error,
        stackTrace: stackTrace,
      );
      final FileDownloadState failed = downloading.copyWith(
        status: FileDownloadStatus.failed,
        progress: 0,
        errorMessage: 'Web file download failed: $error',
      );
      _emit(failed);
      return Left(
        DownloadFailure(
          message: 'Web file download failed: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> cancelDownload(String key) async {
    final FileDownloadState current = stateOf(key);
    if (!current.isInProgress) {
      return const Right(null);
    }

    _emit(
      current.copyWith(
        status: FileDownloadStatus.canceled,
        progress: 0,
      ),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> openDownloadedFile(String key) async {
    final FileDownloadState current = stateOf(key);
    final String? sourceUrl = current.sourceUrl;
    if (sourceUrl == null || sourceUrl.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'No downloaded file available to open.',
          code: 'invalid_input',
        ),
      );
    }

    final Uri? uri = _resolveUri(sourceUrl);
    if (uri == null) {
      return const Left(
        ValidationFailure(
          message: 'Invalid file URL.',
          code: 'invalid_input',
        ),
      );
    }

    try {
      final bool launched = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!launched) {
        return const Left(
          DownloadFailure(
            message: 'Unable to open downloaded file.',
            code: 'download_failed',
          ),
        );
      }

      return const Right(null);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to open downloaded file on web',
        error: error,
        stackTrace: stackTrace,
      );
      return Left(
        DownloadFailure(
          message: 'Failed to open downloaded file: $error',
          code: 'download_failed',
        ),
      );
    }
  }

  StreamController<FileDownloadState> _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      StreamController<FileDownloadState>.broadcast,
    );
  }

  void _emit(FileDownloadState state) {
    _states[state.key] = state;
    _controllerFor(state.key).add(state);
  }

  Uri? _resolveUri(String rawUrl) {
    if (rawUrl.trim().isEmpty) {
      return null;
    }

    final Uri? parsed = Uri.tryParse(rawUrl.trim());
    if (parsed == null) {
      return null;
    }
    if (parsed.hasScheme) {
      return parsed;
    }

    return Uri.base.resolveUri(parsed);
  }
}
