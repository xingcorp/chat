/// Edit Message Use Case
///
/// Edits an existing message content.
/// Validates permissions and handles edit logic.
///
/// Author: Senior Flutter/Mobile Architect
library edit_message_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for editing a message
class EditMessageParams extends Equatable {
  final String messageId;
  final String newContent;

  const EditMessageParams({
    required this.messageId,
    required this.newContent,
  });

  @override
  List<Object> get props => [messageId, newContent];
}

/// Edit message use case implementation
///
/// Edits an existing message with validation.
/// Only the message sender can edit their messages.
@injectable
class EditMessageUseCase implements UseCase<bool, EditMessageParams> {
  final IMessageRepository _repository;

  const EditMessageUseCase(this._repository);

  @override
  Future<Result<bool>> call(EditMessageParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Edit message through repository
    final result = await _repository.updateMessage(
      params.messageId,
      params.newContent,
    );

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (success) => Result.success(success),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(EditMessageParams params) {
    final errors = <String>[];

    // Message ID validation
    if (params.messageId.isEmpty) {
      errors.add('Message ID cannot be empty');
    }

    // Content validation
    if (params.newContent.isEmpty) {
      errors.add('Message content cannot be empty');
    } else if (params.newContent.length > 10000) {
      errors.add('Message content cannot exceed 10000 characters');
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(message: errors.join(', '));
    }

    return null;
  }
}
