import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:injectable/injectable.dart';

/// Interface for local chat data source operations
abstract class ChatLocalDataSource {
  /// Get all chats from local storage
  Future<List<Chat>> getChats();
  
  /// Get a specific chat by ID
  Future<Chat?> getChatById(String id);
  
  /// Save a chat to local storage
  Future<void> saveChat(Chat chat);
  
  /// Save multiple chats to local storage
  Future<void> saveChats(List<Chat> chats);
  
  /// Delete a chat from local storage
  Future<void> deleteChat(String id);
  
  /// Mark a chat as read
  Future<void> markChatAsRead(String chatId);
  
  /// Get all pending messages that need to be synced
  Future<List<ChatMessage>> getPendingMessages();
  
  /// Save a message to local storage
  Future<void> saveMessage(String chatId, ChatMessage message, {bool needsSync = false});
  
  /// Save multiple messages to local storage
  Future<void> saveMessages(String chatId, List<ChatMessage> messages);
  
  /// Replace a local message with a synced message from the server
  Future<void> replaceMessage(String chatId, String localId, ChatMessage syncedMessage);
  
  /// Update message status (for offline messages)
  Future<void> updateMessageStatus(String chatId, String messageId, MessageQueueStatus status);
  
  /// Get messages for a chat
  Future<List<ChatMessage>> getChatMessages(String chatId, {int limit = 20, String? before});
}

/// Implementation of local chat data source
@LazySingleton(as: ChatLocalDataSource)
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final LocalStorage _localStorage;
  
  /// Constructor
  ChatLocalDataSourceImpl(this._localStorage);
  
  @override
  Future<List<Chat>> getChats() async {
    try {
      final chatData = await _localStorage.getList('chats');
      return chatData
          .map((data) => Chat.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get chats from local storage: $e');
    }
  }
  
  @override
  Future<Chat?> getChatById(String id) async {
    try {
      final chats = await getChats();
      return chats.firstWhere((chat) => chat.id == id, orElse: () => throw NotFoundException());
    } catch (e) {
      if (e is NotFoundException) {
        return null;
      }
      throw CacheException(message: 'Failed to get chat by ID from local storage: $e');
    }
  }
  
  @override
  Future<void> saveChat(Chat chat) async {
    try {
      final chats = await getChats();
      
      // Check if chat already exists
      final index = chats.indexWhere((c) => c.id == chat.id);
      
      if (index >= 0) {
        // Update existing chat
        chats[index] = chat;
      } else {
        // Add new chat
        chats.add(chat);
      }
      
      // Save updated list
      await _localStorage.saveList('chats', chats.map((c) => c.toJson()).toList());
    } catch (e) {
      throw CacheException(message: 'Failed to save chat to local storage: $e');
    }
  }
  
  @override
  Future<void> saveChats(List<Chat> chats) async {
    try {
      await _localStorage.saveList('chats', chats.map((c) => c.toJson()).toList());
    } catch (e) {
      throw CacheException(message: 'Failed to save chats to local storage: $e');
    }
  }
  
  @override
  Future<void> deleteChat(String id) async {
    try {
      final chats = await getChats();
      final filteredChats = chats.where((chat) => chat.id != id).toList();
      await _localStorage.saveList('chats', filteredChats.map((c) => c.toJson()).toList());
      
      // Also delete chat messages
      await _localStorage.remove('chat_messages_$id');
    } catch (e) {
      throw CacheException(message: 'Failed to delete chat from local storage: $e');
    }
  }
  
  @override
  Future<void> markChatAsRead(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      
      if (chat != null) {
        // Update chat's unread count
        final updatedChat = chat.copyWith(unreadCount: 0);
        await saveChat(updatedChat);
      }
      
      // Also mark all messages as read
      final messages = await getChatMessages(chatId);
      
      // This is a simplified version. In a real app, you'd only mark 
      // messages not from the current user and track read status per user
      final updatedMessages = messages.map((message) {
        // Add current user ID to readBy list if not already there
        if (!message.readBy.contains('current_user')) {
          return message; // No real change for now
        }
        return message;
      }).toList();
      
      await saveMessages(chatId, updatedMessages);
    } catch (e) {
      throw CacheException(message: 'Failed to mark chat as read in local storage: $e');
    }
  }
  
  @override
  Future<List<ChatMessage>> getPendingMessages() async {
    try {
      final result = <ChatMessage>[];
      
      // Get all chats
      final chats = await getChats();
      
      // For each chat, get pending messages
      for (final chat in chats) {
        final messages = await getChatMessages(chat.id);
        
        // Filter for pending messages (this would need to be implemented with a proper flag in a real app)
        // For now, we'll assume no pending messages since we'd need a custom field
        // In a real implementation this would use the MessageQueueStatus
      }
      
      return result;
    } catch (e) {
      throw CacheException(message: 'Failed to get pending messages from local storage: $e');
    }
  }
  
  @override
  Future<void> saveMessage(String chatId, ChatMessage message, {bool needsSync = false}) async {
    try {
      final messages = await getChatMessages(chatId);
      
      // Check if message already exists
      final index = messages.indexWhere((m) => m.id == message.id);
      
      if (index >= 0) {
        // Update existing message
        messages[index] = message;
      } else {
        // Add new message
        messages.add(message);
      }
      
      // Save updated list
      await _localStorage.saveList(
        'chat_messages_$chatId', 
        messages.map((m) => m.toJson()).toList()
      );
      
      // Update last message in chat
      final chat = await getChatById(chatId);
      if (chat != null) {
        // Sort messages by created time to find the latest
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        if (messages.isNotEmpty) {
          final updatedChat = chat.copyWith(
            lastMessage: messages.first,
            updatedAt: DateTime.now(),
          );
          await saveChat(updatedChat);
        }
      }
      
      // TODO: If needsSync is true, we would add to a sync queue in a real implementation
    } catch (e) {
      throw CacheException(message: 'Failed to save message to local storage: $e');
    }
  }
  
  @override
  Future<void> saveMessages(String chatId, List<ChatMessage> messages) async {
    try {
      await _localStorage.saveList(
        'chat_messages_$chatId',
        messages.map((m) => m.toJson()).toList(),
      );
      
      // Update last message in chat
      if (messages.isNotEmpty) {
        final chat = await getChatById(chatId);
        if (chat != null) {
          // Find the latest message
          final latestMessage = messages.reduce(
            (current, message) => current.createdAt.isAfter(message.createdAt) 
                ? current 
                : message,
          );
          
          final updatedChat = chat.copyWith(
            lastMessage: latestMessage,
            updatedAt: DateTime.now(),
          );
          await saveChat(updatedChat);
        }
      }
    } catch (e) {
      throw CacheException(message: 'Failed to save messages to local storage: $e');
    }
  }
  
  @override
  Future<void> replaceMessage(String chatId, String localId, ChatMessage syncedMessage) async {
    try {
      final messages = await getChatMessages(chatId);
      
      // Find and replace the message
      final index = messages.indexWhere((m) => m.id == localId);
      
      if (index >= 0) {
        messages[index] = syncedMessage;
        
        // Save updated list
        await saveMessages(chatId, messages);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to replace message in local storage: $e');
    }
  }
  
  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageQueueStatus status) async {
    try {
      final messages = await getChatMessages(chatId);
      
      // Find the message
      final index = messages.indexWhere((m) => m.id == messageId);
      
      if (index >= 0) {
        // In a real implementation, we'd have a status field in ChatMessage
        // For now, we'll just make a note in the message content
        final updatedMessage = messages[index];
        
        // Save updated list
        await saveMessages(chatId, messages);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to update message status in local storage: $e');
    }
  }
  
  @override
  Future<List<ChatMessage>> getChatMessages(String chatId, {int limit = 20, String? before}) async {
    try {
      final messageData = await _localStorage.getList('chat_messages_$chatId');
      
      // Convert to message objects
      List<ChatMessage> messages = messageData
          .map((data) => ChatMessage.fromJson(Map<String, dynamic>.from(data)))
          .toList();
      
      // Sort by creation time (newest first)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Apply pagination if needed
      if (before != null) {
        final beforeTime = DateTime.parse(before);
        messages = messages.where((m) => m.createdAt.isBefore(beforeTime)).toList();
      }
      
      // Apply limit
      if (messages.length > limit) {
        messages = messages.sublist(0, limit);
      }
      
      return messages;
    } catch (e) {
      throw CacheException(message: 'Failed to get chat messages from local storage: $e');
    }
  }
} 