import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';

/// Parameters for [DownloadUpdateUseCase].
class DownloadUpdateParams {
  const DownloadUpdateParams({
    required this.updateInfo,
    required this.onProgress,
  });

  final AppUpdateInfo updateInfo;
  final void Function(int received, int total) onProgress;
}

/// Downloads the update installer to a temporary directory.
///
/// Returns the local file path of the downloaded installer.
class DownloadUpdateUseCase extends UseCase<String, DownloadUpdateParams> {
  DownloadUpdateUseCase(this._repository);

  final IUpdateRepository _repository;

  @override
  Future<Either<Failure, String>> call(DownloadUpdateParams params) {
    return _repository.downloadUpdate(
      updateInfo: params.updateInfo,
      onProgress: params.onProgress,
    );
  }
}
