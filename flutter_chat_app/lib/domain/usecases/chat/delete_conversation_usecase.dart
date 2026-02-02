import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Delete Conversation Use Case
///
/// Deletes a conversation from user's chat list.
/// Implements remote-only strategy for server confirmation.
///
/// **Requirements**: 2.6, 2.16, 2.17, 2.18
@injectable
class DeleteConversationUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const DeleteConversationUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to delete a conversation
  ///
  /// [conversationId] - ID of the conversation to delete
  ///
  /// Returns Either<Failure, bool>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: true if successfully deleted
  Future<Either<Failure, bool>> call(String conversationId) async {
    _logger.info('DeleteConversationUseCase: Starting operation', {
      'conversationId': conversationId,
    });

    // Validate input
    if (conversationId.trim().isEmpty) {
      _logger.error('DeleteConversationUseCase: Validation failed - empty conversationId');
      return const Left(ValidationFailure(message: 'Conversation ID cannot be empty'));
    }

    try {
      final result = await _repository.deleteChat(conversationId);

      return result.fold(
        (failure) {
          _logger.error('DeleteConversationUseCase: Failed', failure);
          return Left(failure);
        },
        (success) {
          _logger.info('DeleteConversationUseCase: Success', {
            'conversationId': conversationId,
          });
          return Right(success);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('DeleteConversationUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
