import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SearchMessagesUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const SearchMessagesUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, List<ChatMessage>>> call({
    required String query,
    required String chatId,
    int limit = 20,
  }) async {
    _logger.info('SearchMessagesUseCase: Starting operation', {
      'query': query,
      'chatId': chatId,
      'limit': limit,
    });

    if (query.trim().isEmpty) {
      _logger.error('SearchMessagesUseCase: Validation failed - empty query');
      return const Left(ValidationFailure(message: 'Search query cannot be empty'));
    }

    if (chatId.trim().isEmpty) {
      _logger.error('SearchMessagesUseCase: Validation failed - empty chatId');
      return const Left(ValidationFailure(message: 'Chat ID cannot be empty'));
    }

    if (limit <= 0) {
      _logger.error('SearchMessagesUseCase: Validation failed - invalid limit');
      return const Left(ValidationFailure(message: 'Limit must be greater than 0'));
    }

    try {
      final result = await _repository.searchMessages(
        keyword: query,
        conversationIds: [chatId],
        size: limit,
      );

      return result.fold(
        (failure) {
          _logger.error('SearchMessagesUseCase: Failed', failure);
          return Left(failure);
        },
        (messages) {
          _logger.info('SearchMessagesUseCase: Success', {
            'chatId': chatId,
            'count': messages.length,
          });
          return Right(messages);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('SearchMessagesUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
