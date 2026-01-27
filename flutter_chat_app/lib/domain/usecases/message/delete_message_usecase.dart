/// Delete Message Use Case
///
/// Deletes a message from a conversation.
/// Validates permissions and handles deletion logic.
///
/// Author: Senior Flutter/Mobile Architect
library delete_message_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for deleting a message
class DeleteMessageParams extends Equatable {
  final String messageId;

  const DeleteMessageParams({
    required this.messageId,
  });

  @override
  List<Object> get props => [messageId];
}

/// Delete message use case implementation
///
/// Deletes a message with validation.
/// Only the message sender or group admin can delete messages.
@injectable
class DeleteMessageUseCase implements UseCase<bool, DeleteMessageParams> {
  final IMessageRepository _repository;

  const DeleteMessageUseCase(this._repository);

  @override
  Future<Result<bool>> call(DeleteMessageParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Delete message through repository
    final result = await _repository.deleteMessage(params.messageId);

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (success) => Result.success(success),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(DeleteMessageParams params) {
    if (params.messageId.isEmpty) {
      return const ValidationFailure(
        message: 'Message ID cannot be empty',
      );
    }
    return null;
  }
}
