import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class RemoveReactionUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const RemoveReactionUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, bool>> call({
    required String messageId,
    required String code,
  }) async {
    _logger.info('RemoveReactionUseCase: Starting operation', {
      'messageId': messageId,
      'code': code,
    });

    if (messageId.trim().isEmpty) {
      _logger.error('RemoveReactionUseCase: Validation failed - empty messageId');
      return const Left(ValidationFailure(message: 'Message ID cannot be empty'));
    }

    if (code.trim().isEmpty) {
      _logger.error('RemoveReactionUseCase: Validation failed - empty code');
      return const Left(ValidationFailure(message: 'Reaction code cannot be empty'));
    }

    try {
      final result = await _repository.updateReaction(
        messageId: messageId,
        code: code,
        act: 'REMOVE',
      );

      return result.fold(
        (failure) {
          _logger.error('RemoveReactionUseCase: Failed', failure);
          return Left(failure);
        },
        (success) {
          _logger.info('RemoveReactionUseCase: Success', {
            'messageId': messageId,
          });
          return Right(success);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('RemoveReactionUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
