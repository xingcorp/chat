import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';

IFileDownloader createFileDownloaderImpl(AppLogger logger) {
  return _UnsupportedFileDownloader(logger);
}

class _UnsupportedFileDownloader implements IFileDownloader {
  const _UnsupportedFileDownloader(this._logger);

  final AppLogger _logger;

  @override
  Future<Either<Failure, String>> downloadFromUrl({
    required String url,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    _logger.w('File download is not supported on this platform.', context: {
      'url': url,
      'fileName': fileName,
    });
    return const Left(
      DownloadFailure(
        message: 'File download is not supported on this platform.',
        code: 'unsupported_platform',
      ),
    );
  }
}
