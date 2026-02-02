import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Get Messages Use Case
///
/// Retrieves messages for a specific conversation.
/// Implements offline-first strategy with pagination support.
///
/// **Requirements**: 2.8, 2.16, 2.17, 2.18
@injectable
class GetMessagesUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const GetMessagesUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to get messages
  ///
  /// [conversationId] - ID of the conversation
  /// [limit] - Maximum number of messages to retrieve (default: 20, max: 100)
  /// [cursor] - Pagination cursor for loading more messages
  ///
  /// Returns Either<Failure, List<ChatMessage>>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: List of ChatMessage entities
  Future<Either<Failure, List<ChatMessage>>> call({
    required String conversationId,
    int limit = 20,
    String? cursor,
  }) async {
    _logger.info('GetMessagesUseCase: Starting operation', {
      'conversationId': conversationId,
      'limit': limit,
      'hasCursor': cursor != null,
    });

    // Validate inputs
    if (conversationId.trim().isEmpty) {
      _logger.error('GetMessagesUseCase: Validation failed - empty conversationId');
      return const Left(ValidationFailure(message: 'Conversation ID cannot be empty'));
    }

    if (limit < 1) {
      _logger.error('GetMessagesUseCase: Validation failed - invalid limit');
      return const Left(ValidationFailure(message: 'Limit must be at least 1'));
    }

    if (limit > 100) {
      _logger.error('GetMessagesUseCase: Validation failed - limit too large');
      return const Left(ValidationFailure(message: 'Limit cannot exceed 100'));
    }

    try {
      final result = await _repository.getMessages(
        conversationId,
        limit: limit,
        cursor: cursor,
      );

      return result.fold(
        (failure) {
          _logger.error('GetMessagesUseCase: Failed', failure);
          return Left(failure);
        },
        (messages) {
          _logger.info('GetMessagesUseCase: Success', {
            'conversationId': conversationId,
            'messageCount': messages.length,
          });
          return Right(messages);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('GetMessagesUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
