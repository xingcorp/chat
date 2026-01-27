/// Leave Conversation Use Case
///
/// Allows user to leave a group conversation.
/// Validates input and handles leave logic.
///
/// Author: Senior Flutter/Mobile Architect
library leave_conversation_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for leaving a conversation
class LeaveConversationParams extends Equatable {
  final String conversationId;

  const LeaveConversationParams({
    required this.conversationId,
  });

  @override
  List<Object> get props => [conversationId];
}

/// Leave conversation use case implementation
///
/// Allows user to leave a group conversation.
/// Removes user from conversation and updates local cache.
@injectable
class LeaveConversationUseCase 
    implements UseCase<bool, LeaveConversationParams> {
  final IChatRepository _repository;

  const LeaveConversationUseCase(this._repository);

  @override
  Future<Result<bool>> call(LeaveConversationParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Leave conversation through repository
    final result = await _repository.leaveChat(params.conversationId);

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (success) => Result.success(success),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(LeaveConversationParams params) {
    if (params.conversationId.isEmpty) {
      return const ValidationFailure(
        message: 'Conversation ID cannot be empty',
      );
    }
    return null;
  }
}
