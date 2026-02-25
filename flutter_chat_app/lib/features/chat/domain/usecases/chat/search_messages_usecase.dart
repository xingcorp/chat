import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Search Messages Use Case
///
/// Searches messages by keyword within conversations.
///
/// **Requirements**: Message search feature
@injectable
class SearchMessagesUseCase {
  final IChatRepository _repository;
  final AppLogger _logger;

  const SearchMessagesUseCase({
    required IChatRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to search messages
  ///
  /// [keyword] - Search keyword string
  /// [conversationId] - Optional conversation ID to limit search scope
  /// [limit] - Maximum number of results (default: 50)
  ///
  /// Returns Either<Failure, List<MessageSearchResult>>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: List of matching message results
  Future<Either<Failure, List<MessageSearchResult>>> call({
    required String keyword,
    String? conversationId,
    int limit = 50,
  }) async {
    _logger.info('SearchMessagesUseCase: Starting operation', {
      'keyword': keyword,
      'conversationId': conversationId,
      'limit': limit,
    });

    // Validate input
    if (keyword.trim().isEmpty) {
      _logger.error('SearchMessagesUseCase: Validation failed - empty keyword');
      return const Left(ValidationFailure(message: 'Search keyword cannot be empty'));
    }

    if (limit <= 0) {
      _logger.error('SearchMessagesUseCase: Validation failed - invalid limit');
      return const Left(ValidationFailure(message: 'Limit must be greater than 0'));
    }

    try {
      final result = await _repository.searchMessages(
        keyword: keyword,
        conversationId: conversationId,
        limit: limit,
      );

      return result.fold(
        (failure) {
          _logger.error('SearchMessagesUseCase: Failed', failure);
          return Left(failure);
        },
        (messages) {
          _logger.info('SearchMessagesUseCase: Success', {
            'keyword': keyword,
            'resultCount': messages.length,
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
