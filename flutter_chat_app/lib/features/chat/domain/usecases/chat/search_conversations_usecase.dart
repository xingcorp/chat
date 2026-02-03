import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Search Conversations Use Case
///
/// Searches conversations by name or content.
/// Implements local-first strategy for instant results.
///
/// **Requirements**: 2.7, 2.16, 2.17, 2.18
@injectable
class SearchConversationsUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const SearchConversationsUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to search conversations
  ///
  /// [query] - Search query string
  /// [limit] - Maximum number of results (default: 20)
  ///
  /// Returns Either<Failure, List<Chat>>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: List of matching Chat entities
  Future<Either<Failure, List<Chat>>> call({
    required String query,
    int limit = 20,
  }) async {
    _logger.info('SearchConversationsUseCase: Starting operation', {
      'query': query,
      'limit': limit,
    });

    // Validate input
    if (query.trim().isEmpty) {
      _logger.error('SearchConversationsUseCase: Validation failed - empty query');
      return const Left(ValidationFailure(message: 'Search query cannot be empty'));
    }

    if (limit <= 0) {
      _logger.error('SearchConversationsUseCase: Validation failed - invalid limit');
      return const Left(ValidationFailure(message: 'Limit must be greater than 0'));
    }

    try {
      final result = await _repository.searchChats(query, limit: limit);

      return result.fold(
        (failure) {
          _logger.error('SearchConversationsUseCase: Failed', failure);
          return Left(failure);
        },
        (conversations) {
          _logger.info('SearchConversationsUseCase: Success', {
            'query': query,
            'resultCount': conversations.length,
          });
          return Right(conversations);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('SearchConversationsUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
