/// Search Conversations Use Case
///
/// Searches conversations by keyword.
/// Implements offline-first search with server fallback.
///
/// Author: Senior Flutter/Mobile Architect
library search_conversations_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for searching conversations
class SearchConversationsParams extends Equatable {
  final String keyword;
  final int limit;

  const SearchConversationsParams({
    required this.keyword,
    this.limit = 20,
  });

  @override
  List<Object> get props => [keyword, limit];
}

/// Search conversations use case implementation
///
/// Searches conversations by keyword with offline-first strategy.
/// Returns cached results immediately and syncs with server.
@injectable
class SearchConversationsUseCase 
    implements UseCase<List<Chat>, SearchConversationsParams> {
  final IChatRepository _repository;

  const SearchConversationsUseCase(this._repository);

  @override
  Future<Result<List<Chat>>> call(SearchConversationsParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Search conversations through repository
    final result = await _repository.searchChats(
      params.keyword,
      limit: params.limit,
    );

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (conversations) => Result.success(conversations),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(SearchConversationsParams params) {
    final errors = <String>[];

    // Keyword validation
    if (params.keyword.isEmpty) {
      errors.add('Search keyword cannot be empty');
    } else if (params.keyword.length < 2) {
      errors.add('Search keyword must be at least 2 characters');
    }

    // Limit validation
    if (params.limit < 1) {
      errors.add('Limit must be at least 1');
    } else if (params.limit > 100) {
      errors.add('Limit cannot exceed 100');
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(message: errors.join(', '));
    }

    return null;
  }
}
