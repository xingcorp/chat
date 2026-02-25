import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để unblock user
@injectable
class UnblockUserUseCase {
  final IChatInfoRepository _repository;

  UnblockUserUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String userId,
  }) async {
    return await _repository.unblockUser(userId: userId);
  }
}
