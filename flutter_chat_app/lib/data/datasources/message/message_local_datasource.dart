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
      final messages = await _localStorage.getCollection<MessageModel>(
        'messages_$chatId',
        fromJson: MessageModel.fromJson,
      );
      
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
    await _localStorage.saveItem<MessageModel>(
      'messages_${message.chatId}',
      message.localId, // Use localId as key
      message,
      toJson: (msg) => msg.toJson(),
    );
  }
  
  @override
  Future<void> saveMessages(List<MessageModel> messages) async {
    if (messages.isEmpty) return;
    
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
      await _localStorage.saveItems<MessageModel>(
        'messages_$chatId',
        {for (var msg in messagesByChatId[chatId]!) msg.localId: msg},
        toJson: (msg) => msg.toJson(),
      );
    }
  }
  
  @override
  Future<void> deleteMessage(String messageId) async {
    // Note: To delete a message, we need to know its chat ID
    // This implementation assumes the message is found in some chat
    
    // Get all chats
    final chatKeys = await _localStorage.getKeys('chat_');
    
    // Search message in each chat
    for (final chatKey in chatKeys) {
      final chatId = chatKey.replaceFirst('chat_', '');
      final messages = await getMessagesForChat(chatId);
      
      // Find message
      final message = messages.firstWhere(
        (msg) => msg.localId == messageId || msg.serverId == messageId,
        orElse: () => MessageModel(
          localId: '',
          chatId: '',
          senderId: '',
          content: '',
          type: MessageType.text,
          createdAt: DateTime.now(),
        ),
      );
      
      // If message found
      if (message.localId.isNotEmpty) {
        await _localStorage.deleteItem('messages_$chatId', messageId);
        return;
      }
    }
  }
  
  @override
  Future<void> deleteMessagesForChat(String chatId) async {
    await _localStorage.deleteCollection('messages_$chatId');
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
    return _localStorage.watchCollection<MessageModel>(
      'messages_$chatId',
      fromJson: MessageModel.fromJson,
      sort: (a, b) => b.createdAt.compareTo(a.createdAt),
    );
  }
  
  @override
  Future<int> getUnreadCountForChat(String chatId, String userId) async {
    final messages = await getMessagesForChat(chatId);
    
    // Count messages not sent by user and not read by user
    return messages.where(
      (msg) => msg.senderId != userId && 
              !(msg.readBy?.contains(userId) ?? false),
    ).length;
  }
} 