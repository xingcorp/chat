import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Get Local Conversations Use Case
///
/// Retrieves conversations from local cache only (Isar DB).
/// Used for cache-first loading: show cached data instantly,
/// then refresh from network in background.
///
/// **Requirements**: 2.1, 2.16, 2.17, 2.18
@injectable
class GetLocalConversationsUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const GetLocalConversationsUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to get cached conversations from local storage
  ///
  /// Returns Either<Failure, List<Chat>>
  /// - Left: Failure (CacheFailure)
  /// - Right: List of cached Chat entities (may be empty on first launch)
  Future<Either<Failure, List<Chat>>> call() async {
    _logger.info('GetLocalConversationsUseCase: Loading from local cache');

    try {
      final result = await _repository.getChatsFromLocalStorage();

      return result.fold(
        (failure) {
          _logger.error('GetLocalConversationsUseCase: Failed', failure);
          return Left(failure);
        },
        (chats) {
          _logger.info('GetLocalConversationsUseCase: Success', {
            'count': chats.length,
          });
          return Right(chats);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('GetLocalConversationsUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
