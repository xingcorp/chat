import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/services/file_download_manager/file_download_manager_stub.dart'
    if (dart.library.html) 'package:flutter_chat_app/data/services/file_download_manager/file_download_manager_web.dart'
    if (dart.library.io) 'package:flutter_chat_app/data/services/file_download_manager/file_download_manager_io.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';

IFileDownloadManager createFileDownloadManager(AppLogger logger) {
  return createFileDownloadManagerImpl(logger);
}
