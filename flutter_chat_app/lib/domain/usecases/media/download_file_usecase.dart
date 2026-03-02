import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/services/i_file_downloader.dart';

class DownloadFileParams {
  const DownloadFileParams({
    required this.url,
    this.fileName,
    this.headers,
  });

  final String url;
  final String? fileName;
  final Map<String, String>? headers;
}

class DownloadFileUseCase {
  const DownloadFileUseCase(this._fileDownloader);

  final IFileDownloader _fileDownloader;

  Future<Either<Failure, String>> call(DownloadFileParams params) {
    return _fileDownloader.downloadFromUrl(
      url: params.url,
      fileName: params.fileName,
      headers: params.headers,
    );
  }
}
