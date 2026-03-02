import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/services/file_download_state.dart';

abstract class IFileDownloadManager {
  FileDownloadState stateOf(String key);

  Stream<FileDownloadState> watch(String key);

  Future<Either<Failure, FileDownloadState>> startDownload({
    required String key,
    required String url,
    String? fileName,
    Map<String, String>? headers,
  });

  Future<Either<Failure, void>> cancelDownload(String key);

  Future<Either<Failure, void>> openDownloadedFile(String key);
}
