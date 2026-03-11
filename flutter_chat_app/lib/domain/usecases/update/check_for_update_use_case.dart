import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';

/// Checks if a newer version of the app is available.
///
/// Returns [AppUpdateInfo] if an update is available, `null` if up-to-date.
/// Also updates the last-check timestamp on success.
class CheckForUpdateUseCase extends NoParamsUseCase<AppUpdateInfo?> {
  CheckForUpdateUseCase(this._repository);

  final IUpdateRepository _repository;

  @override
  Future<Either<Failure, AppUpdateInfo?>> call() async {
    final result = await _repository.checkForUpdate();
    // Update last check timestamp on success
    if (result.isRight) {
      await _repository.setLastCheckTimestamp(DateTime.now());
    }
    return result;
  }
}
