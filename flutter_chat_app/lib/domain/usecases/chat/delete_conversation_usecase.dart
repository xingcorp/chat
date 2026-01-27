/// Delete Conversation Use Case
///
/// Deletes a conversation permanently.
/// Validates input and handles deletion logic.
///
/// Author: Senior Flutter/Mobile Architect
library delete_conversation_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for deleting a conversation
class DeleteConversationParams extends Equatable {
  final String conversationId;

  const DeleteConversationParams({
    required this.conversationId,
  });

  @override
  List<Object> get props => [conversationId];
}

/// Delete conversation use case implementation
///
/// Permanently deletes a conversation and all its messages.
/// This action cannot be undone.
@injectable
class DeleteConversationUseCase 
    implements UseCase<bool, DeleteConversationParams> {
  final IChatRepository _repository;

  const DeleteConversationUseCase(this._repository);

  @override
  Future<Result<bool>> call(DeleteConversationParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Delete conversation through repository
    final result = await _repository.deleteChat(params.conversationId);

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (success) => Result.success(success),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(DeleteConversationParams params) {
    if (params.conversationId.isEmpty) {
      return const ValidationFailure(
        message: 'Conversation ID cannot be empty',
      );
    }
    return null;
  }
}
