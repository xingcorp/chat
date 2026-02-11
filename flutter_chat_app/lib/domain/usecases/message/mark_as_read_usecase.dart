/// Mark As Read Use Case
///
/// Marks messages in a conversation as read.
/// Updates read status and sends read receipts.
///
/// Author: Senior Flutter/Mobile Architect
library mark_as_read_usecase;

import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
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
class MarkAsReadUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const MarkAsReadUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    _logger.info('MarkAsReadUseCase: Starting operation', {
      'conversationId': params.conversationId,
    });

    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      _logger.error('MarkAsReadUseCase: Validation failed', validationResult);
      return Left(validationResult);
    }

    // Mark messages as read through repository
    final result = await _repository.markChatAsRead(params.conversationId);

    // Convert Either to Either
    return result.fold(
      (failure) {
        _logger.error('MarkAsReadUseCase: Failed', failure);
        return Left(failure);
      },
      (_) {
        _logger.info('MarkAsReadUseCase: Success', {
          'conversationId': params.conversationId,
        });
        return const Right(null);
      },
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
