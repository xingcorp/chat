import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [IMessageRepository]
class MessageRepositoryImpl implements IMessageRepository {
  final NetworkInfo _networkInfo;
  final MessageLocalDataSource _localDataSource;
  final MessageRemoteDataSource _remoteDataSource;
  final _uuid = Uuid();

  /// Constructor
  MessageRepositoryImpl(
    this._networkInfo,
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<ChatMessage?> getMessageById(String messageId) async {
    try {
      // Try to get message from local storage first
      final messages = await _localDataSource.getMessagesForChat('all'); // This would need refinement
      
      final message = messages.firstWhere(
        (m) => m.localId == messageId || m.serverId == messageId,
        orElse: () => throw NotFoundException(message: 'Message not found'),
      );
      
      return message.toDomain();
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException(message: 'Failed to get message: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getRecentMessages(String chatId, int limit) async {
    return getMessages(chatId, limit: limit);
  }

  @override
  Future<List<ChatMessage>> getMessages(String chatId, {int limit = 20, String? cursor}) async {
    if (await _networkInfo.isConnected) {
      try {
        // Get messages from server
        final remoteMessages = await _remoteDataSource.getChatMessages(
          chatId,
          limit: limit,
          cursor: cursor,
        );

        // Save to local cache
        await _localDataSource.saveMessages(remoteMessages);

        // Convert to domain entities
        return remoteMessages.map((model) => model.toDomain()).toList();
      } catch (e) {
        // On error, fall back to local data
        final localMessages = await _localDataSource.getMessagesForChat(chatId);
        return localMessages.map((model) => model.toDomain()).toList();
      }
    } else {
      // No internet connection, use local data
      final localMessages = await _localDataSource.getMessagesForChat(chatId);
      return localMessages.map((model) => model.toDomain()).toList();
    }
  }

  @override
  Future<void> markAsRead(String messageId) async {
    try {
      // Implementation would depend on how messages are marked as read
      // This is a placeholder
    } catch (e) {
      throw CacheException(message: 'Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    if (await _networkInfo.isConnected) {
      try {
        // Mark as read on server
        await _remoteDataSource.markMessagesAsRead(chatId);
        
        // Get current user ID (this would come from auth/user repository)
        const userId = 'current_user_id'; // Placeholder
        
        // Mark messages as read locally
        await _localDataSource.markMessagesAsRead(chatId, userId);
      } catch (e) {
        throw ServerException(message: 'Failed to mark chat as read: $e');
      }
    } else {
      // Offline - just mark locally
      const userId = 'current_user_id'; // Placeholder
      await _localDataSource.markMessagesAsRead(chatId, userId);
    }
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      // Delete on server
      final success = await _remoteDataSource.deleteMessage(messageId);
      
      if (success) {
        // Delete locally
        await _localDataSource.deleteMessage(messageId);
      }
      
      return success;
    } catch (e) {
      throw ServerException(message: 'Failed to delete message: $e');
    }
  }

  @override
  Future<bool> updateMessage(String messageId, String newContent) async {
    // This would typically call a server API to update a message
    // Since we haven't defined this in our data sources, this is a placeholder
    return false;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String contentType,
    List<String> attachmentIds = const [],
  }) async {
    // Create local message with pending status
    final localId = _uuid.v4();
    final messageType = _parseMessageType(contentType);
    
    final localMessage = MessageModel(
      localId: localId,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: messageType,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    // Save to local storage immediately
    await _localDataSource.saveMessage(localMessage);
    
    // Try to send to server if online
    if (await _networkInfo.isConnected) {
      try {
        // Send to server
        final sentMessage = await _remoteDataSource.sendMessage(localMessage);
        
        // Update local copy with server ID and success status
        final updatedMessage = sentMessage.copyWith(
          localId: localId, // Retain local ID for reference
          status: MessageStatus.sent,
        );
        
        // Save updated message
        await _localDataSource.saveMessage(updatedMessage);
        
        return updatedMessage.toDomain();
      } catch (e) {
        // Mark as failed in local storage
        final failedMessage = localMessage.copyWith(
          status: MessageStatus.failed,
        );
        
        await _localDataSource.saveMessage(failedMessage);
        
        throw ServerException(message: 'Failed to send message: $e');
      }
    } else {
      // Offline - mark as pending and return local message
      final pendingMessage = localMessage.copyWith(
        status: MessageStatus.pending,
      );
      
      await _localDataSource.saveMessage(pendingMessage);
      
      return pendingMessage.toDomain();
    }
  }

  @override
  Future<bool> checkMessageConflict(String localId, String serverId) async {
    // Implementation would depend on specific conflict resolution logic
    return false;
  }

  @override
  Future<void> syncMessages(String chatId, {int limit = 50}) async {
    if (!(await _networkInfo.isConnected)) {
      return; // Can't sync without internet
    }

    try {
      // Get messages from server
      final remoteMessages = await _remoteDataSource.getChatMessages(
        chatId,
        limit: limit,
      );

      // Get local messages
      final localMessages = await _localDataSource.getMessagesForChat(chatId);

      // Find messages to add (in remote but not local)
      final localIds = localMessages.map((m) => m.serverId).toSet();
      final messagesToAdd = remoteMessages.where(
        (m) => m.serverId != null && !localIds.contains(m.serverId),
      ).toList();

      // Save new messages
      if (messagesToAdd.isNotEmpty) {
        await _localDataSource.saveMessages(messagesToAdd);
      }

      // Find pending messages that need to be sent
      final pendingMessages = localMessages.where(
        (m) => m.status == MessageStatus.pending,
      ).toList();

      // Try to send pending messages
      for (final message in pendingMessages) {
        try {
          final sentMessage = await _remoteDataSource.sendMessage(message);
          final updatedMessage = sentMessage.copyWith(
            localId: message.localId,
            status: MessageStatus.sent,
          );
          await _localDataSource.saveMessage(updatedMessage);
        } catch (e) {
          // Mark as failed if sending fails
          final failedMessage = message.copyWith(
            status: MessageStatus.failed,
          );
          await _localDataSource.saveMessage(failedMessage);
        }
      }
    } catch (e) {
      // Log error but don't throw, as this is a background sync
      print('Failed to sync messages for chat $chatId: $e');
    }
  }

  // Helper method to parse message type from string
  MessageType _parseMessageType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'audio': return MessageType.audio;
      case 'file': return MessageType.file;
      case 'location': return MessageType.location;
      default: return MessageType.text;
    }
  }
} 