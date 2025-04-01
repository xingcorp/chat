import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';

/// Implementation of the message repository
@LazySingleton(as: IMessageRepository)
class MessageRepository implements IMessageRepository {
  final GraphQLClient _client;
  final LocalStorageService _localStorageService;
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _messageStorage = <String, List<ChatMessage>>{};
  
  /// Constructor
  MessageRepository(this._client, this._localStorageService);
  
  /// Get the GraphQL client
  GraphQLClient get client => _client;

  /// Get messages for a specific chat
  Future<List<ChatMessage>> getChatMessages(
    String chatId, {
    DateTime? since,
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(r'''
          query GetChatMessages($chatId: ID!, $limit: Int, $offset: Int, $since: DateTime) {
            chatMessages(chatId: $chatId, limit: $limit, offset: $offset, since: $since) {
              id
              content
              contentType
              sender {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              readBy {
                id
                username
              }
              attachments {
                id
                fileName
                size
                mimeType
                url
              }
              createdAt
              updatedAt
            }
          }
        '''),
        variables: {
          'chatId': chatId,
          'limit': limit,
          'offset': offset,
          if (since != null) 'since': since.toIso8601String(),
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to fetch messages: ${result.exception}');
    }
    
    final messagesData = result.data?['chatMessages'] as List<dynamic>?;
    if (messagesData == null) {
      return [];
    }
    
    final messages = messagesData
        .map((messageData) => ChatMessage.fromJson(messageData))
        .toList();
    
    // Store messages in memory cache
    _messageStorage[chatId] ??= [];
    
    // Add new messages to memory cache (avoid duplicates)
    for (final message in messages) {
      if (!_messageStorage[chatId]!.any((m) => m.id == message.id)) {
        _messageStorage[chatId]!.add(message);
      }
    }
    
    // Sort messages by creation time
    _messageStorage[chatId]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return messages;
  }

  /// Send a new message
  @override
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String contentType,
    List<String> attachmentIds = const [],
  }) async {
    // For now, creating a placeholder message
    // In a real implementation, you'd send this to the server
    final message = ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      content: content,
      contentType: _parseContentType(contentType),
      sender: MessageSender(
        id: senderId,
        name: 'User', // This should come from a user service
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Add to local storage
    await _saveMessageLocally(message);
    
    // Send to server - this is a placeholder
    
    // Notify listeners
    _messageStreamController.add(message);
    
    return message;
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead(String chatId, List<String> messageIds) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation MarkMessagesAsRead($chatId: ID!, $messageIds: [ID!]!) {
            markMessagesAsRead(chatId: $chatId, messageIds: $messageIds)
          }
        '''),
        variables: {
          'chatId': chatId,
          'messageIds': messageIds,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to mark messages as read: ${result.exception}');
    }
    
    final success = result.data?['markMessagesAsRead'] as bool? ?? false;
    
    if (success) {
      // Update read status in local cache
      _updateReadStatusInCache(chatId, messageIds);
    }
    
    return success;
  }

  /// Update read status in local cache
  void _updateReadStatusInCache(String chatId, List<String> messageIds) async {
    if (!_messageStorage.containsKey(chatId)) return;
    
    for (final messageId in messageIds) {
      final messageIndex = _messageStorage[chatId]!.indexWhere((m) => m.id == messageId);
      if (messageIndex >= 0) {
        // Update cached message (would need to add current user to readBy)
        // In a real app, you'd get the current user and add them to readBy
      }
    }
  }

  /// Get messages from local storage
  Future<List<ChatMessage>> getMessagesFromLocalStorage(String chatId) async {
    final messagesJson = _localStorageService.getString('chat_messages_$chatId');
    if (messagesJson == null) return [];
    
    List<dynamic> messagesList;
    try {
      messagesList = jsonDecode(messagesJson) as List<dynamic>;
    } catch (e) {
      debugPrint('Error parsing local messages: $e');
      return [];
    }
    
    return messagesList
        .map((messageData) => ChatMessage.fromJson(messageData))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Save message to local storage
  Future<void> saveMessageLocally(ChatMessage message) async {
    // Get current messages
    final messages = await getMessagesFromLocalStorage(message.chatId);
    
    // Check if message already exists
    if (!messages.any((m) => m.id == message.id)) {
      messages.add(message);
    }
    
    // Sort messages
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Save to storage
    final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _localStorageService.setString('chat_messages_${message.chatId}', messagesJson);
  }

  /// Get the timestamp of the latest message in a chat
  Future<DateTime?> getLatestMessageTimestamp(String chatId) async {
    final messages = await getMessagesFromLocalStorage(chatId);
    if (messages.isEmpty) return null;
    
    // Sort by created time (descending)
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return messages.first.createdAt;
  }

  /// Stream of new messages
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  /// Notify listeners about a new message
  void notifyNewMessage(ChatMessage message) {
    _messageStreamController.add(message);
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }

  @override
  Future<ChatMessage?> getMessageById(String messageId) async {
    // Implementation will depend on your GraphQL schema
    // This is a placeholder
    try {
      // Try to get from local storage first
      final localMessages = await _getLocalMessages(messageId);
      final localMessage = localMessages.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => throw Exception('Not found locally'),
      );
      return localMessage;
    } catch (_) {
      // If not found locally, try to get from server
      // Implementation for GraphQL query
      return null;
    }
  }

  @override
  Future<List<ChatMessage>> getRecentMessages(String chatId, int limit) async {
    // Try to get from local storage first
    try {
      final localMessages = await _getLocalMessages(chatId);
      if (localMessages.isNotEmpty) {
        // Sort by date desc and limit
        localMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return localMessages.take(limit).toList();
      }
    } catch (e) {
      debugPrint('Error getting local messages: $e');
    }

    // If no local messages or error, fetch from server
    // This is a placeholder - implement GraphQL query
    return [];
  }

  @override
  Future<List<ChatMessage>> getMessages(String chatId, {int limit = 20, String? cursor}) async {
    // Implementation for paginated message loading
    // This is a placeholder
    return [];
  }

  @override
  Future<void> markAsRead(String messageId) async {
    // Implementation will depend on your GraphQL schema
    // This is a placeholder
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    // Implementation will depend on your GraphQL schema
    // This is a placeholder
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    // Implementation will depend on your GraphQL schema
    // This is a placeholder
    return false;
  }

  @override
  Future<bool> updateMessage(String messageId, String newContent) async {
    // Implementation will depend on your GraphQL schema
    // This is a placeholder
    return false;
  }

  @override
  Future<bool> checkMessageConflict(String localId, String serverId) async {
    // Implementation to check if local and server messages have conflicts
    // This is a placeholder
    return false;
  }

  @override
  Future<void> syncMessages(String chatId, {int limit = 50}) async {
    // Implementation to sync local and server messages
    // This is a placeholder
  }
  
  /// Helper method to get messages from local storage
  Future<List<ChatMessage>> _getLocalMessages(String chatId) async {
    final messagesJson = _localStorageService.getString('chat_messages_$chatId');
    if (messagesJson == null || messagesJson.isEmpty) {
      return [];
    }
    
    List<dynamic> messagesList;
    try {
      messagesList = jsonDecode(messagesJson) as List<dynamic>;
    } catch (e) {
      debugPrint('Error parsing local messages: $e');
      return [];
    }
    
    return messagesList
        .map((msgJson) => ChatMessage.fromJson(msgJson as Map<String, dynamic>))
        .toList();
  }
  
  /// Helper method to save a message to local storage
  Future<void> _saveMessageLocally(ChatMessage message) async {
    final chatId = message.chatId;
    
    // Get existing messages
    final messages = await _getLocalMessages(chatId);
    
    // Add new message if it doesn't already exist
    if (!messages.any((m) => m.id == message.id)) {
      messages.add(message);
    }
    
    // Save to storage
    final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _localStorageService.setString('chat_messages_$chatId', messagesJson);
  }
  
  /// Helper method to parse content type string to enum
  ContentType _parseContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'text':
        return ContentType.text;
      case 'image':
        return ContentType.image;
      case 'video':
        return ContentType.video;
      case 'audio':
        return ContentType.audio;
      case 'file':
        return ContentType.file;
      case 'location':
        return ContentType.location;
      case 'link':
        return ContentType.link;
      case 'event':
        return ContentType.event;
      default:
        return ContentType.text;
    }
  }
} 