import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Get Conversation Detail Use Case
///
/// Retrieves detailed information for a specific conversation.
/// Implements online-first strategy for fresh data.
///
/// **Requirements**: 2.2, 2.16, 2.17, 2.18
@injectable
class GetConversationDetailUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const GetConversationDetailUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to get conversation detail
  ///
  /// [conversationId] - ID of the conversation to retrieve
  ///
  /// Returns Either<Failure, Chat?>
  /// - Left: Failure (NetworkFailure, ServerFailure, etc.)
  /// - Right: Chat entity or null if not found
  Future<Either<Failure, Chat?>> call(String conversationId) async {
    _logger.info('GetConversationDetailUseCase: Starting operation', {
      'conversationId': conversationId,
    });

    try {
      final result = await _repository.getChatById(conversationId);

      return result.fold(
        (failure) {
          _logger.error('GetConversationDetailUseCase: Failed', failure);
          return Left(failure);
        },
        (conversation) {
          _logger.info('GetConversationDetailUseCase: Success', {
            'conversationId': conversationId,
            'found': conversation != null,
          });
          return Right(conversation);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('GetConversationDetailUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
