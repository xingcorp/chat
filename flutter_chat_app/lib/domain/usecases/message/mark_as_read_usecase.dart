/// Mark As Read Use Case
///
/// Marks messages in a conversation as read.
/// Updates read status and sends read receipts.
///
/// Author: Senior Flutter/Mobile Architect
library mark_as_read_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for marking messages as read
class MarkAsReadParams extends Equatable {
  final String conversationId;

  const MarkAsReadParams({
    required this.conversationId,
  });

  @override
  List<Object> get props => [conversationId];
}

/// Mark as read use case implementation
///
/// Marks all messages in a conversation as read.
/// Sends read receipts to other participants.
@injectable
class MarkAsReadUseCase implements UseCase<void, MarkAsReadParams> {
  final IMessageRepository _repository;

  const MarkAsReadUseCase(this._repository);

  @override
  Future<Result<void>> call(MarkAsReadParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Mark messages as read through repository
    final result = await _repository.markChatAsRead(params.conversationId);

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (_) => const Result.success(null),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(MarkAsReadParams params) {
    if (params.conversationId.isEmpty) {
      return const ValidationFailure(
        message: 'Conversation ID cannot be empty',
      );
    }
    return null;
  }
}
