/// Get Messages Use Case
///
/// Retrieves messages for a specific conversation.
/// Implements offline-first strategy with pagination support.
///
/// Author: Senior Flutter/Mobile Architect
library get_messages_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for getting messages
class GetMessagesParams extends Equatable {
  final String conversationId;
  final int limit;
  final String? cursor;

  const GetMessagesParams({
    required this.conversationId,
    this.limit = 20,
    this.cursor,
  });

  @override
  List<Object?> get props => [conversationId, limit, cursor];
}

/// Get messages use case implementation
///
/// Retrieves messages for a conversation with pagination.
/// Uses offline-first strategy for instant loading.
@injectable
class GetMessagesUseCase 
    implements UseCase<List<ChatMessage>, GetMessagesParams> {
  final IMessageRepository _repository;

  const GetMessagesUseCase(this._repository);

  @override
  Future<Result<List<ChatMessage>>> call(GetMessagesParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Get messages from repository
    final result = await _repository.getMessages(
      params.conversationId,
      limit: params.limit,
      cursor: params.cursor,
    );

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (messages) => Result.success(messages),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(GetMessagesParams params) {
    final errors = <String>[];

    // Conversation ID validation
    if (params.conversationId.isEmpty) {
      errors.add('Conversation ID cannot be empty');
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
