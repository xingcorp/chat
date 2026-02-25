import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để block user (direct chat only)
@injectable
class BlockUserUseCase {
  final IChatInfoRepository _repository;

  BlockUserUseCase(this._repository);

  /// Execute use case
  ///
  /// [userId] - ID của user cần block
  Future<Either<Failure, void>> call({
    required String userId,
  }) async {
    return await _repository.blockUser(userId: userId);
  }
}
