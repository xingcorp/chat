import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Get Conversations Use Case
///
/// Retrieves list of conversations for the current user.
/// Implements offline-first strategy through repository.
///
/// **Requirements**: 2.1, 2.16, 2.17, 2.18
@injectable
class GetConversationsUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const GetConversationsUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to get conversations
  ///
  /// Returns Either<Failure, List<Chat>>
  /// - Left: Failure (NetworkFailure, ServerFailure, etc.)
  /// - Right: List of Chat entities
  Future<Either<Failure, List<Chat>>> call() async {
    _logger.info('GetConversationsUseCase: Starting operation');

    try {
      final result = await _repository.getChats();

      return result.fold(
        (failure) {
          _logger.error('GetConversationsUseCase: Failed', failure);
          return Left(failure);
        },
        (conversations) {
          _logger.info('GetConversationsUseCase: Success', {
            'count': conversations.length,
          });
          return Right(conversations);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('GetConversationsUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
