import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Leave Conversation Use Case
///
/// Allows user to leave a conversation (group or direct chat).
/// Implements remote-only strategy for server confirmation.
///
/// **Requirements**: 2.5, 2.16, 2.17, 2.18
@injectable
class LeaveConversationUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const LeaveConversationUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to leave a conversation
  ///
  /// [conversationId] - ID of the conversation to leave
  ///
  /// Returns Either<Failure, bool>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: true if successfully left
  Future<Either<Failure, bool>> call(String conversationId) async {
    _logger.info('LeaveConversationUseCase: Starting operation', {
      'conversationId': conversationId,
    });

    // Validate input
    if (conversationId.trim().isEmpty) {
      _logger.error('LeaveConversationUseCase: Validation failed - empty conversationId');
      return const Left(ValidationFailure(message: 'Conversation ID cannot be empty'));
    }

    try {
      final result = await _repository.leaveChat(conversationId);

      return result.fold(
        (failure) {
          _logger.error('LeaveConversationUseCase: Failed', failure);
          return Left(failure);
        },
        (success) {
          _logger.info('LeaveConversationUseCase: Success', {
            'conversationId': conversationId,
          });
          return Right(success);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('LeaveConversationUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
