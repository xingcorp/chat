import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddReactionUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const AddReactionUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, bool>> call({
    required String messageId,
    required String code,
  }) async {
    _logger.info('AddReactionUseCase: Starting operation', {
      'messageId': messageId,
      'code': code,
    });

    if (messageId.trim().isEmpty) {
      _logger.error('AddReactionUseCase: Validation failed - empty messageId');
      return const Left(ValidationFailure(message: 'Message ID cannot be empty'));
    }

    if (code.trim().isEmpty) {
      _logger.error('AddReactionUseCase: Validation failed - empty code');
      return const Left(ValidationFailure(message: 'Reaction code cannot be empty'));
    }

    try {
      final result = await _repository.updateReaction(
        messageId: messageId,
        code: code,
        act: '1', // ADD = 1 per backend enum ChatMessageReactionAct
      );

      return result.fold(
        (failure) {
          _logger.error('AddReactionUseCase: Failed', failure);
          return Left(failure);
        },
        (success) {
          _logger.info('AddReactionUseCase: Success', {
            'messageId': messageId,
          });
          return Right(success);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('AddReactionUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
