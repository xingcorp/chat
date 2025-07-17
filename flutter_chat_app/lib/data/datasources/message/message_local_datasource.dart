import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';

/// Interface for message local data source operations
abstract class MessageLocalDataSource {
  /// Get all messages for a specific chat
  Future<List<MessageModel>> getMessagesForChat(String chatId);
  
  /// Save a message to local storage
  Future<void> saveMessage(MessageModel message);
  
  /// Save multiple messages to local storage
  Future<void> saveMessages(List<MessageModel> messages);
  
  /// Delete a message
  Future<void> deleteMessage(String messageId);
  
  /// Delete all messages for a chat
  Future<void> deleteMessagesForChat(String chatId);
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId);
  
  /// Get stream of messages for a chat
  Stream<List<MessageModel>> watchMessagesForChat(String chatId);
  
  /// Get unread message count for a chat
  Future<int> getUnreadCountForChat(String chatId, String userId);
}

/// Implementation of [MessageLocalDataSource] using local storage
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  final LocalStorage _localStorage;
  
  /// Constructor
  MessageLocalDataSourceImpl(this._localStorage);
  
  @override
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    try {
      final messagesList = await _localStorage.getList('messages_$chatId');

      final messages = messagesList
          .map((json) => MessageModel.fromMap(json as Map<String, dynamic>))
          .toList();

      // Sort by timestamp descending
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return messages;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
  
  @override
  Future<void> saveMessage(MessageModel message) async {
    try {
      // Get existing messages for this chat
      final existingMessages = await getMessagesForChat(message.chatId);

      // Add or update the message
      final messageIndex = existingMessages.indexWhere((m) => m.localId == message.localId);
      if (messageIndex >= 0) {
        existingMessages[messageIndex] = message;
      } else {
        existingMessages.add(message);
      }

      // Save updated list
      final messagesList = existingMessages.map((m) => m.toMap()).toList();
      await _localStorage.saveList('messages_${message.chatId}', messagesList);
    } catch (e) {
      throw CacheException(message: 'Failed to save message: $e');
    }
  }
  
  @override
  Future<void> saveMessages(List<MessageModel> messages) async {
    if (messages.isEmpty) return;

    try {
      // Group messages by chat ID
      final messagesByChatId = <String, List<MessageModel>>{};

      for (final message in messages) {
        if (messagesByChatId.containsKey(message.chatId)) {
          messagesByChatId[message.chatId]!.add(message);
        } else {
          messagesByChatId[message.chatId] = [message];
        }
      }

      // Save messages by chat
      for (final chatId in messagesByChatId.keys) {
        final existingMessages = await getMessagesForChat(chatId);
        final newMessages = messagesByChatId[chatId]!;

        // Merge new messages with existing ones
        final allMessages = <MessageModel>[...existingMessages];
        for (final newMessage in newMessages) {
          final existingIndex = allMessages.indexWhere((m) => m.localId == newMessage.localId);
          if (existingIndex >= 0) {
            allMessages[existingIndex] = newMessage;
          } else {
            allMessages.add(newMessage);
          }
        }

        // Save updated list
        final messagesList = allMessages.map((m) => m.toMap()).toList();
        await _localStorage.saveList('messages_$chatId', messagesList);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to save messages: $e');
    }
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    // TODO: Implement proper message deletion
    // For now, this is a placeholder implementation
    throw UnimplementedError('deleteMessage not yet implemented');
  }
  
  @override
  Future<void> deleteMessagesForChat(String chatId) async {
    await _localStorage.remove('messages_$chatId');
  }
  
  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await getMessagesForChat(chatId);
    
    // Find unread messages not sent by the user
    final unreadMessages = messages.where(
      (msg) => msg.senderId != userId && 
              !(msg.readBy?.contains(userId) ?? false),
    ).toList();
    
    if (unreadMessages.isEmpty) return;
    
    // Mark each message as read
    for (final message in unreadMessages) {
      final readBy = message.readBy ?? [];
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        
        final updatedMessage = message.copyWith(readBy: readBy);
        await saveMessage(updatedMessage);
      }
    }
  }
  
  @override
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    // TODO: Implement proper stream watching
    // For now, return empty stream
    return Stream.empty();
  }
  
  @override
  Future<int> getUnreadCountForChat(String chatId, String userId) async {
    final messages = await getMessagesForChat(chatId);
    
    // Count messages not sent by user and not read by user
    return messages.where(
      (msg) => msg.senderId != userId &&
              !msg.readBy.contains(userId),
    ).length;
  }
} 