import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Send Message Use Case
///
/// Sends a new message to a conversation.
/// Implements online-first strategy with offline queuing.
///
/// **Requirements**: 2.9, 2.16, 2.17, 2.18
@injectable
class SendMessageUseCase {
  final IMessageRepository _repository;
  final AppLogger _logger;

  const SendMessageUseCase({
    required IMessageRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger;

  /// Execute use case to send a message
  ///
  /// [conversationId] - ID of the conversation
  /// [content] - Message content
  /// [type] - Message type (TEXT, IMAGE, VIDEO, etc.)
  /// [urls] - Optional list of attachment URLs
  /// [fileName] - Optional file name for attachments
  ///
  /// Returns Either<Failure, ChatMessage>
  /// - Left: Failure (NetworkFailure, ServerFailure, ValidationFailure, etc.)
  /// - Right: Sent ChatMessage entity
  Future<Either<Failure, ChatMessage>> call({
    required String conversationId,
    required String content,
    required String senderId,
    required String type,
    List<String> urls = const [],
    String? fileName,
    String? replyMessageId,
    String? forwardedFromMessageId,
  }) async {
    _logger.info('SendMessageUseCase: Starting operation', {
      'conversationId': conversationId,
      'type': type,
      'hasAttachments': urls.isNotEmpty,
    });

    // Validate inputs
    if (conversationId.trim().isEmpty) {
      _logger.error('SendMessageUseCase: Validation failed - empty conversationId');
      return const Left(ValidationFailure(message: 'Conversation ID cannot be empty'));
    }

    if (content.trim().isEmpty && urls.isEmpty) {
      _logger.error('SendMessageUseCase: Validation failed - empty content and no attachments');
      return const Left(ValidationFailure(message: 'Message must have content or attachments'));
    }

    if (senderId.trim().isEmpty) {
      _logger.error('SendMessageUseCase: Validation failed - empty senderId');
      return const Left(ValidationFailure(message: 'Sender ID cannot be empty'));
    }

    try {
      final result = await _repository.sendMessage(
        chatId: conversationId,
        content: content,
        senderId: senderId,
        contentType: type,
        attachmentIds: urls,
        replyMessageId: replyMessageId,
        fileName: fileName,
        forwardedFromMessageId: forwardedFromMessageId,
      );

      return result.fold(
        (failure) {
          _logger.error('SendMessageUseCase: Failed', failure);
          return Left(failure);
        },
        (message) {
          _logger.info('SendMessageUseCase: Success', {
            'messageId': message.id,
            'conversationId': conversationId,
          });
          return Right(message);
        },
      );
    } catch (e, stackTrace) {
      _logger.error('SendMessageUseCase: Unexpected error', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
