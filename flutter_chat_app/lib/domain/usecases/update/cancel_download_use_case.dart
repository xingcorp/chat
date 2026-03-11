import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';

/// Cancels an in-progress update download.
class CancelDownloadUseCase extends NoParamsUseCase<void> {
  CancelDownloadUseCase(this._repository);

  final IUpdateRepository _repository;

  @override
  Future<Either<Failure, void>> call() {
    return _repository.cancelDownload();
  }
}
