import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
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

  const SearchMessagesUseCase({
    required IChatRepository repository,
  }) : _repository = repository;

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
    // Validate input
    if (keyword.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Search keyword cannot be empty'));
    }

    try {
      final result = await _repository.searchMessages(
        keyword: keyword,
        conversationId: conversationId,
        limit: limit,
      );

      return result.fold(
        Left.new,
        Right.new,
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
