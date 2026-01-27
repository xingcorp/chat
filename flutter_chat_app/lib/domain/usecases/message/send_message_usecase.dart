/// Send Message Use Case
///
/// Sends a new message to a conversation.
/// Implements online-first strategy with offline queue support.
///
/// Author: Senior Flutter/Mobile Architect
library send_message_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// Parameters for sending a message
class SendMessageParams extends Equatable {
  final String conversationId;
  final String content;
  final String senderId;
  final String contentType;
  final List<String> attachmentIds;

  const SendMessageParams({
    required this.conversationId,
    required this.content,
    required this.senderId,
    this.contentType = 'text',
    this.attachmentIds = const [],
  });

  @override
  List<Object> get props => [
        conversationId,
        content,
        senderId,
        contentType,
        attachmentIds,
      ];
}

/// Send message use case implementation
///
/// Sends a new message with validation and offline support.
/// Message is saved locally immediately and synced when online.
@injectable
class SendMessageUseCase 
    implements UseCase<ChatMessage, SendMessageParams> {
  final IMessageRepository _repository;

  const SendMessageUseCase(this._repository);

  @override
  Future<Result<ChatMessage>> call(SendMessageParams params) async {
    // Validate input
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Send message through repository
    final result = await _repository.sendMessage(
      chatId: params.conversationId,
      content: params.content,
      senderId: params.senderId,
      contentType: params.contentType,
      attachmentIds: params.attachmentIds,
    );

    // Convert Either to Result
    return result.fold(
      (failure) => Result.failure(failure),
      (message) => Result.success(message),
    );
  }

  /// Validate parameters
  ValidationFailure? _validateParams(SendMessageParams params) {
    final errors = <String>[];

    // Conversation ID validation
    if (params.conversationId.isEmpty) {
      errors.add('Conversation ID cannot be empty');
    }

    // Sender ID validation
    if (params.senderId.isEmpty) {
      errors.add('Sender ID cannot be empty');
    }

    // Content validation
    if (params.content.isEmpty && params.attachmentIds.isEmpty) {
      errors.add('Message must have content or attachments');
    }

    // Content length validation
    if (params.content.length > 10000) {
      errors.add('Message content cannot exceed 10000 characters');
    }

    // Content type validation
    final validTypes = ['text', 'image', 'video', 'audio', 'file', 'location'];
    if (!validTypes.contains(params.contentType.toLowerCase())) {
      errors.add('Invalid content type: ${params.contentType}');
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(message: errors.join(', '));
    }

    return null;
  }
}
