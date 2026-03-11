import 'package:flutter_chat_app/core/base/base_usecase.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';

/// Parameters for [VerifyUpdateUseCase].
class VerifyUpdateParams {
  const VerifyUpdateParams({
    required this.filePath,
    required this.expectedChecksum,
  });

  final String filePath;
  final String expectedChecksum;
}

/// Verifies the integrity of a downloaded installer via SHA-256 checksum.
class VerifyUpdateUseCase extends UseCase<bool, VerifyUpdateParams> {
  VerifyUpdateUseCase(this._repository);

  final IUpdateRepository _repository;

  @override
  Future<Either<Failure, bool>> call(VerifyUpdateParams params) {
    return _repository.verifyDownload(
      filePath: params.filePath,
      expectedChecksum: params.expectedChecksum,
    );
  }
}
