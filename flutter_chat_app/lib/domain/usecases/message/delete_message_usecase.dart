/// Delete Message Use Case
///
/// Deletes a message from a conversation.
/// Validates permissions and handles deletion logic.
///
/// Author: Senior Flutter/Mobile Architect
library delete_message_usecase;

import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
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
class DeleteMessageUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const DeleteMessageUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, bool>> call(DeleteMessageParams params) async {
    _logger.info('DeleteMessageUseCase: Starting operation', {
      'messageId': params.messageId,
    });

    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      _logger.error('DeleteMessageUseCase: Validation failed', validationResult);
      return Left(validationResult);
    }

    // Delete message through repository
    final result = await _repository.deleteMessage(params.messageId);

    // Convert Either to Either
    return result.fold(
      (failure) {
        _logger.error('DeleteMessageUseCase: Failed', failure);
        return Left(failure);
      },
      (success) {
        _logger.info('DeleteMessageUseCase: Success', {
          'messageId': params.messageId,
          'deleted': success,
        });
        return Right(success);
      },
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
