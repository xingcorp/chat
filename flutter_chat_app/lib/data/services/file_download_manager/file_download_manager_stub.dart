import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/file_download_state.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';

IFileDownloadManager createFileDownloadManagerImpl(AppLogger logger) {
  return _UnsupportedFileDownloadManager(logger);
}

class _UnsupportedFileDownloadManager implements IFileDownloadManager {
  _UnsupportedFileDownloadManager(this._logger);

  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> cancelDownload(String key) async {
    return const Left(
      DownloadFailure(
        message: 'File download is not supported on this platform.',
        code: 'unsupported_platform',
      ),
    );
  }

  @override
  Future<Either<Failure, void>> openDownloadedFile(String key) async {
    return const Left(
      DownloadFailure(
        message: 'Opening downloaded file is not supported on this platform.',
        code: 'unsupported_platform',
      ),
    );
  }

  @override
  FileDownloadState stateOf(String key) {
    return FileDownloadState.idle(key);
  }

  @override
  Future<Either<Failure, FileDownloadState>> startDownload({
    required String key,
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    _logger.w(
      'File download manager is not supported on this platform.',
      context: <String, dynamic>{
        'key': key,
        'url': url,
        'fileName': fileName,
      },
    );
    return const Left(
      DownloadFailure(
        message: 'File download is not supported on this platform.',
        code: 'unsupported_platform',
      ),
    );
  }

  @override
  Stream<FileDownloadState> watch(String key) async* {
    yield FileDownloadState.idle(key);
  }
}
