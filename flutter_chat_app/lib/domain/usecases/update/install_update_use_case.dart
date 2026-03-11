import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';

/// Parameters for [InstallUpdateUseCase].
class InstallUpdateParams {
  const InstallUpdateParams({required this.installerPath});

  final String installerPath;
}

/// Launches the downloaded installer and exits the current app process.
class InstallUpdateUseCase extends UseCase<void, InstallUpdateParams> {
  InstallUpdateUseCase(this._repository);

  final IUpdateRepository _repository;

  @override
  Future<Either<Failure, void>> call(InstallUpdateParams params) {
    return _repository.installUpdate(installerPath: params.installerPath);
  }
}
