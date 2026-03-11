import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';

/// Parameters for [SkipVersionUseCase].
class SkipVersionParams {
  const SkipVersionParams({required this.version});

  final String version;
}

/// Marks a version as 'skipped' so it will not prompt the user again.
class SkipVersionUseCase extends UseCase<void, SkipVersionParams> {
  SkipVersionUseCase(this._repository);

  final IUpdateRepository _repository;

  @override
  Future<Either<Failure, void>> call(SkipVersionParams params) {
    return _repository.skipVersion(params.version);
  }
}
