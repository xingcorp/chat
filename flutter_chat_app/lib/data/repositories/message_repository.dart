import 'dart:async';
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
  @override
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
  Future<ChatMessage> sendMessage(
    String chatId,
    String content,
    ContentType contentType, {
    List<String> attachmentIds = const [],
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation SendMessage($chatId: ID!, $content: String!, $contentType: String!, $attachmentIds: [ID!]) {
            sendMessage(input: {
              chatId: $chatId,
              content: $content,
              contentType: $contentType,
              attachmentIds: $attachmentIds
            }) {
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
          'content': content,
          'contentType': contentType.toString().split('.').last,
          'attachmentIds': attachmentIds,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to send message: ${result.exception}');
    }
    
    final messageData = result.data?['sendMessage'];
    if (messageData == null) {
      throw Exception('No data returned from send message operation');
    }
    
    final message = ChatMessage.fromJson(messageData);
    
    // Add to memory cache
    _messageStorage[chatId] ??= [];
    _messageStorage[chatId]!.add(message);
    
    // Sort messages
    _messageStorage[chatId]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Save to local storage
    await saveMessageLocally(message);
    
    return message;
  }

  /// Mark messages as read
  @override
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
  @override
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
  @override
  Future<void> saveMessageLocally(ChatMessage message) async {
    // Get current messages
    final messages = await getMessagesFromLocalStorage(message.id);
    
    // Check if message already exists
    if (!messages.any((m) => m.id == message.id)) {
      messages.add(message);
    }
    
    // Sort messages
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Save to storage
    final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _localStorageService.setString('chat_messages_${message.id}', messagesJson);
  }

  /// Get the timestamp of the latest message in a chat
  @override
  Future<DateTime?> getLatestMessageTimestamp(String chatId) async {
    final messages = await getMessagesFromLocalStorage(chatId);
    if (messages.isEmpty) return null;
    
    // Sort by created time (descending)
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return messages.first.createdAt;
  }

  /// Stream of new messages
  @override
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  /// Notify listeners about a new message
  void notifyNewMessage(ChatMessage message) {
    _messageStreamController.add(message);
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
} 