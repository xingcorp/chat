import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/models/offline_operation_model.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:injectable/injectable.dart';

/// **Offline Operation Processor**
///
/// Processes queued offline operations by delegating to appropriate repositories.
/// Follows Clean Architecture by using domain layer interfaces.
///
/// **Architecture:** Service Layer → Domain Layer (Repositories)
/// **Pattern:** Strategy pattern for operation-specific processing
/// **Error Handling:** Throws exceptions for failed operations (caught by queue service)
@singleton
class OfflineOperationProcessor {
  final IMessageRepository _messageRepository;
  final IChatRepository _chatRepository;
  final AppLogger _logger;

  OfflineOperationProcessor({
    required IMessageRepository messageRepository,
    required IChatRepository chatRepository,
    required AppLogger logger,
  })  : _messageRepository = messageRepository,
        _chatRepository = chatRepository,
        _logger = logger;

  /// Process a single offline operation
  ///
  /// Delegates to appropriate repository based on operation type.
  /// Throws exception if operation fails (for retry logic).
  Future<void> processOperation(OfflineOperationModel operation) async {
    _logger.debug('Processing offline operation: ${operation.type.name}');

    try {
      switch (operation.type) {
        case OperationType.sendMessage:
          await _processSendMessage(operation);
          break;

        case OperationType.editMessage:
          await _processEditMessage(operation);
          break;

        case OperationType.deleteMessage:
          await _processDeleteMessage(operation);
          break;

        case OperationType.createGroup:
          await _processCreateGroup(operation);
          break;

        case OperationType.editGroup:
          await _processEditGroup(operation);
          break;

        case OperationType.leaveConversation:
          await _processLeaveConversation(operation);
          break;

        case OperationType.deleteConversation:
          await _processDeleteConversation(operation);
          break;

        case OperationType.markAsRead:
          await _processMarkAsRead(operation);
          break;

        case OperationType.addReaction:
          await _processAddReaction(operation);
          break;

        case OperationType.removeReaction:
          await _processRemoveReaction(operation);
          break;
      }

      _logger.info('Successfully processed offline operation: ${operation.type.name}');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to process offline operation: ${operation.type.name}',
        e,
        stackTrace,
      );
      rethrow; // Let queue service handle retry logic
    }
  }

  /// Process send message operation
  Future<void> _processSendMessage(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _messageRepository.sendMessage(
      chatId: data['chatId'] as String,
      content: data['content'] as String,
      senderId: data['senderId'] as String,
      contentType: data['contentType'] as String,
      attachmentIds: List<String>.from(data['attachmentIds'] as List? ?? []),
    );

    result.fold(
      (failure) {
        _logger.error('Send message failed: ${failure.message}');
        throw Exception('Send message failed: ${failure.message}');
      },
      (message) {
        _logger.info('Message sent successfully: ${message.id}');
      },
    );
  }

  /// Process edit message operation
  Future<void> _processEditMessage(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _messageRepository.updateMessage(
      data['messageId'] as String,
      data['newContent'] as String,
    );

    result.fold(
      (failure) {
        _logger.error('Edit message failed: ${failure.message}');
        throw Exception('Edit message failed: ${failure.message}');
      },
      (success) {
        _logger.info('Message edited successfully');
      },
    );
  }

  /// Process delete message operation
  Future<void> _processDeleteMessage(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _messageRepository.deleteMessage(
      data['chatId'] as String,
      data['messageId'] as String,
    );

    result.fold(
      (failure) {
        _logger.error('Delete message failed: ${failure.message}');
        throw Exception('Delete message failed: ${failure.message}');
      },
      (success) {
        _logger.info('Message deleted successfully');
      },
    );
  }

  /// Process create group operation
  Future<void> _processCreateGroup(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _chatRepository.createChat(
      name: data['name'] as String,
      participantIds: List<String>.from(data['participantIds'] as List),
      isGroup: data['isGroup'] as bool? ?? true,
    );

    result.fold(
      (failure) {
        _logger.error('Create group failed: ${failure.message}');
        throw Exception('Create group failed: ${failure.message}');
      },
      (chat) {
        _logger.info('Group created successfully: ${chat.id}');
      },
    );
  }

  /// Process edit group operation
  Future<void> _processEditGroup(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _chatRepository.updateChat(
      chatId: data['chatId'] as String,
      name: data['name'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
    );

    result.fold(
      (failure) {
        _logger.error('Edit group failed: ${failure.message}');
        throw Exception('Edit group failed: ${failure.message}');
      },
      (chat) {
        _logger.info('Group edited successfully: ${chat.id}');
      },
    );
  }

  /// Process leave conversation operation
  Future<void> _processLeaveConversation(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _chatRepository.leaveChat(
      data['chatId'] as String,
    );

    result.fold(
      (failure) {
        _logger.error('Leave conversation failed: ${failure.message}');
        throw Exception('Leave conversation failed: ${failure.message}');
      },
      (success) {
        _logger.info('Left conversation successfully');
      },
    );
  }

  /// Process delete conversation operation
  Future<void> _processDeleteConversation(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _chatRepository.deleteChat(
      data['chatId'] as String,
    );

    result.fold(
      (failure) {
        _logger.error('Delete conversation failed: ${failure.message}');
        throw Exception('Delete conversation failed: ${failure.message}');
      },
      (success) {
        _logger.info('Conversation deleted successfully');
      },
    );
  }

  /// Process mark as read operation
  Future<void> _processMarkAsRead(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final result = await _messageRepository.markChatAsRead(
      data['chatId'] as String,
    );

    result.fold(
      (failure) {
        _logger.error('Mark as read failed: ${failure.message}');
        throw Exception('Mark as read failed: ${failure.message}');
      },
      (success) {
        _logger.info('Marked as read successfully');
      },
    );
  }

  /// Process add reaction operation
  Future<void> _processAddReaction(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final messageId = data['messageId'] as String?;
    final code = data['code'] as String?;

    if (messageId == null || messageId.isEmpty || code == null || code.isEmpty) {
      throw Exception('Add reaction failed: invalid payload');
    }

    final result = await _messageRepository.updateReaction(
      messageId: messageId,
      code: code,
      act: 'ADD',
    );

    result.fold(
      (failure) {
        _logger.error('Add reaction failed: ${failure.message}');
        throw Exception('Add reaction failed: ${failure.message}');
      },
      (_) {
        _logger.info('Reaction added successfully');
      },
    );
  }

  /// Process remove reaction operation
  Future<void> _processRemoveReaction(OfflineOperationModel operation) async {
    final data = operation.dataMap;

    final messageId = data['messageId'] as String?;
    final code = data['code'] as String?;

    if (messageId == null || messageId.isEmpty || code == null || code.isEmpty) {
      throw Exception('Remove reaction failed: invalid payload');
    }

    final result = await _messageRepository.updateReaction(
      messageId: messageId,
      code: code,
      act: 'REMOVE',
    );

    result.fold(
      (failure) {
        _logger.error('Remove reaction failed: ${failure.message}');
        throw Exception('Remove reaction failed: ${failure.message}');
      },
      (_) {
        _logger.info('Reaction removed successfully');
      },
    );
  }
}
