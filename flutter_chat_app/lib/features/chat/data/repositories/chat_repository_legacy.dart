import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// Legacy implementation of the chat repository (DEPRECATED)
/// Use ChatRepositoryImpl instead for production
/// This class is kept for reference only and should not be used in production
// @LazySingleton(as: IChatRepository) // Commented out to avoid conflicts
class ChatRepositoryLegacy {
  final GraphQLClient _client;
  final LocalStorageService _localStorageService;
  
  /// Constructor
  ChatRepositoryLegacy(this._client, this._localStorageService);
  
  /// Get the GraphQL client
  
  GraphQLClient get client => _client;

  /// Get all chats for the current user
  
  Future<List<Chat>> getChats() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(r'''
          query GetChats {
            chats {
              id
              type
              name
              description
              avatar
              lastMessage {
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
                createdAt
                updatedAt
              }
              participants {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              owner {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              admins {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              unreadCount
              createdAt
              updatedAt
            }
          }
        '''),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to fetch chats: ${result.exception}');
    }
    
    final chatsData = result.data?['chats'] as List<dynamic>?;
    if (chatsData == null) {
      return [];
    }
    
    final chats = chatsData
        .map((chatData) => Chat.fromJson(chatData))
        .toList();
    
    // Save chats to local storage for offline access
    await _saveChatsToLocalStorage(chats);
    
    return chats;
  }

  /// Get a specific chat by ID
  
  Future<Chat?> getChatById(String chatId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(r'''
          query GetChat($chatId: ID!) {
            chat(id: $chatId) {
              id
              type
              name
              description
              avatar
              lastMessage {
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
                createdAt
                updatedAt
              }
              participants {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              owner {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              admins {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              unreadCount
              createdAt
              updatedAt
            }
          }
        '''),
        variables: {'chatId': chatId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to fetch chat: ${result.exception}');
    }
    
    final chatData = result.data?['chat'];
    if (chatData == null) {
      return null;
    }
    
    final chat = Chat.fromJson(chatData);
    
    // Save to local storage
    await saveChatLocally(chat);
    
    return chat;
  }

  /// Create a new chat
  
  Future<Chat> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    final type = isGroup ? 'GROUP' : 'DIRECT';
    
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation CreateChat($type: String!, $name: String, $participantIds: [ID!]!) {
            createChat(input: {
              type: $type,
              name: $name,
              participantIds: $participantIds
            }) {
              id
              type
              name
              description
              avatar
              participants {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              owner {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              admins {
                id
                username
              }
              unreadCount
              createdAt
              updatedAt
            }
          }
        '''),
        variables: {
          'type': type,
          'name': name,
          'participantIds': participantIds,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to create chat: ${result.exception}');
    }
    
    final chatData = result.data?['createChat'];
    if (chatData == null) {
      throw Exception('No data returned from create chat operation');
    }
    
    final chat = Chat.fromJson(chatData);
    
    // Save to local storage
    await saveChatLocally(chat);
    
    return chat;
  }

  /// Update an existing chat
  
  Future<Chat> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation UpdateChat($chatId: ID!, $name: String, $avatar: String) {
            updateChat(
              chatId: $chatId,
              input: {
                name: $name,
                avatar: $avatar
              }
            ) {
              id
              type
              name
              description
              avatar
              participants {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              owner {
                id
                username
                email
                fullName
                avatar
                isOnline
                lastSeen
              }
              admins {
                id
                username
              }
              unreadCount
              createdAt
              updatedAt
            }
          }
        '''),
        variables: {
          'chatId': chatId,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar': avatarUrl,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to update chat: ${result.exception}');
    }
    
    final chatData = result.data?['updateChat'];
    if (chatData == null) {
      throw Exception('No data returned from update chat operation');
    }
    
    final chat = Chat.fromJson(chatData);
    
    // Save to local storage
    await saveChatLocally(chat);
    
    return chat;
  }

  /// Add participants to a chat
  
  Future<bool> addParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation AddUsersToChat($chatId: ID!, $userIds: [ID!]!) {
            addUsersToChat(chatId: $chatId, userIds: $userIds) {
              id
            }
          }
        '''),
        variables: {
          'chatId': chatId,
          'userIds': userIds,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to add users to chat: ${result.exception}');
    }
    
    // If we get here, the operation was successful
    // Refresh the chat to get updated participants
    await getChatById(chatId);
    
    return true;
  }

  /// Remove participants from a chat
  
  Future<bool> removeParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation RemoveUsersFromChat($chatId: ID!, $userIds: [ID!]!) {
            removeUsersFromChat(chatId: $chatId, userIds: $userIds) {
              id
            }
          }
        '''),
        variables: {
          'chatId': chatId,
          'userIds': userIds,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to remove users from chat: ${result.exception}');
    }
    
    // If we get here, the operation was successful
    // Refresh the chat to get updated participants
    await getChatById(chatId);
    
    return true;
  }

  /// Leave a chat
  
  Future<bool> leaveChat(String chatId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation LeaveChat($chatId: ID!) {
            leaveChat(chatId: $chatId)
          }
        '''),
        variables: {
          'chatId': chatId,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to leave chat: ${result.exception}');
    }
    
    final success = result.data?['leaveChat'] as bool? ?? false;
    
    if (success) {
      // Remove chat from local storage
      await _localStorageService.remove('chat_$chatId');
      
      // Remove from chats list
      final chats = await getChatsFromLocalStorage();
      final updatedChats = chats.where((chat) => chat.id != chatId).toList();
      await _saveChatsToLocalStorage(updatedChats);
    }
    
    return success;
  }
  
  /// Delete a chat
  
  Future<bool> deleteChat(String chatId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation DeleteChat($chatId: ID!) {
            deleteChat(chatId: $chatId)
          }
        '''),
        variables: {
          'chatId': chatId,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to delete chat: ${result.exception}');
    }
    
    final success = result.data?['deleteChat'] as bool? ?? false;
    
    if (success) {
      // Remove chat from local storage
      await _localStorageService.remove('chat_$chatId');
      
      // Remove from chats list
      final chats = await getChatsFromLocalStorage();
      final updatedChats = chats.where((chat) => chat.id != chatId).toList();
      await _saveChatsToLocalStorage(updatedChats);
    }
    
    return success;
  }
  
  /// Mark a chat as read
  
  Future<bool> markChatAsRead(String chatId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(r'''
          mutation MarkChatAsRead($chatId: ID!) {
            markChatAsRead(chatId: $chatId)
          }
        '''),
        variables: {
          'chatId': chatId,
        },
      ),
    );
    
    if (result.hasException) {
      throw Exception('Failed to mark chat as read: ${result.exception}');
    }
    
    final success = result.data?['markChatAsRead'] as bool? ?? false;
    
    if (success) {
      // Update local chat to reflect read status
      final chat = await getChatFromLocalStorage(chatId);
      if (chat != null) {
        final updatedChat = chat.copyWith(unreadCount: 0);
        await saveChatLocally(updatedChat);
      }
    }
    
    return success;
  }
  
  /// Sync a chat with the server
  
  Future<void> syncChat(String chatId) async {
    await getChatById(chatId);
  }

  /// Save chats to local storage
  Future<void> _saveChatsToLocalStorage(List<Chat> chats) async {
    final chatsJson = jsonEncode(chats.map((chat) => chat.toJson()).toList());
    await _localStorageService.setString('chats', chatsJson);
    
    // Also save each chat individually
    for (final chat in chats) {
      await saveChatLocally(chat);
    }
  }

  /// Save a chat to local storage
  
  Future<void> saveChatLocally(Chat chat) async {
    final chatJson = jsonEncode(chat.toJson());
    await _localStorageService.setString('chat_${chat.id}', chatJson);
  }

  /// Get chats from local storage
  
  Future<List<Chat>> getChatsFromLocalStorage() async {
    final chatsJson = _localStorageService.getString('chats');
    if (chatsJson == null) return [];
    
    List<dynamic> chatsList;
    try {
      chatsList = jsonDecode(chatsJson) as List<dynamic>;
    } catch (e) {
      debugPrint('Error parsing local chats: $e');
      return [];
    }
    
    return chatsList
        .map((chatData) => Chat.fromJson(chatData))
        .toList();
  }

  /// Get a chat from local storage by ID
  Future<Chat?> getChatFromLocalStorage(String chatId) async {
    final chatJson = _localStorageService.getString('chat_$chatId');
    if (chatJson == null) return null;
    
    try {
      final chatData = jsonDecode(chatJson) as Map<String, dynamic>;
      return Chat.fromJson(chatData);
    } catch (e) {
      debugPrint('Error parsing local chat: $e');
      return null;
    }
  }
} 