import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Edit Message Use Case
///
/// Edits an existing message content.
/// Implements online-first strategy for real-time sync.
///
/// **Requirements**: 2.10, 2.16, 2.17, 2.18
@injectable
class EditMessageUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const EditMessageUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to edit a message
  ///
  /// [messageId] - ID of the message to edit
  /// [content] - New message content
  ///
  /// Returns Either<Failure, bool>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: true if successfully edited
  Future<Either<Failure, bool>> call({
    required String messageId,
    required String content,
  }) async {
    _logger.info('EditMessageUseCase: Starting operation', {
      'messageId': messageId,
    });

    // Validate inputs
    if (messageId.trim().isEmpty) {
      _logger.error('EditMessageUseCase: Validation failed - empty messageId');
      return const Left(ValidationFailure(message: 'Message ID cannot be empty'));
    }

    if (content.trim().isEmpty) {
      _logger.error('EditMessageUseCase: Validation failed - empty content');
      return const Left(ValidationFailure(message: 'Message content cannot be empty'));
    }

    try {
      final result = await _repository.updateMessage(messageId, content);

      return result.fold(
        (failure) {
          _logger.error('EditMessageUseCase: Failed', failure);
          return Left(failure);
        },
        (success) {
          _logger.info('EditMessageUseCase: Success', {
            'messageId': messageId,
          });
          return Right(success);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('EditMessageUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
