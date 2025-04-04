import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Interface for ChatRemoteDataSource
abstract class ChatRemoteDataSource {
  /// Get the list of chats for the current user
  Future<List<ChatModel>> getUserChats();
  
  /// Get details of a specific chat
  Future<ChatModel> getChatDetails(String chatId);
  
  /// Create a new direct chat with a user
  Future<ChatModel> createDirectChat(String userId);
  
  /// Create a new group chat
  Future<ChatModel> createGroupChat(String name, List<String> userIds);
  
  /// Update a chat's details
  Future<ChatModel> updateChat(String chatId, {String? name, String? avatarUrl});
  
  /// Add users to a group chat
  Future<bool> addUsersToChat(String chatId, List<String> userIds);
  
  /// Remove users from a group chat
  Future<bool> removeUsersFromChat(String chatId, List<String> userIds);
  
  /// Delete a chat
  Future<bool> deleteChat(String chatId);
  
  /// Leave a group chat
  Future<bool> leaveChat(String chatId);
  
  /// Subscribe to new/updated chats
  Stream<ChatModel> subscribeToChats();
}

/// Implementation of [ChatRemoteDataSource]
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final GraphQLClientWrapper _client;
  final SocketManager _socketManager;
  
  ChatRemoteDataSourceImpl(this._client, this._socketManager);
  
  @override
  Future<List<ChatModel>> getUserChats() async {
    // Query the GraphQL server for the user's chats
    final result = await _client.query(
      query: '''
        query GetUserChats {
          getUserChats {
            id
            name
            type
            avatarUrl
            lastActivity
            createdAt
            updatedAt
            participants {
              id
              username
              displayName
              avatarUrl
              lastSeen
            }
            lastMessage {
              id
              content
              type
              createdAt
              sender {
                id
                username
                displayName
              }
            }
          }
        }
      ''',
    );
    
    if (result.hasException) {
      throw Exception('Failed to get user chats: ${result.exception}');
    }
    
    final List<dynamic> chatsData = result.data?['getUserChats'] ?? [];
    return chatsData.map((chatData) => ChatModel.fromJson(chatData)).toList();
  }
  
  @override
  Future<ChatModel> getChatDetails(String chatId) async {
    // Query the GraphQL server for the chat details
    final result = await _client.query(
      query: '''
        query GetChatDetails(\$chatId: ID!) {
          getChatDetails(chatId: \$chatId) {
            id
            name
            type
            avatarUrl
            lastActivity
            createdAt
            updatedAt
            participants {
              id
              username
              displayName
              avatarUrl
              lastSeen
            }
            lastMessage {
              id
              content
              type
              createdAt
              sender {
                id
                username
                displayName
              }
            }
          }
        }
      ''',
      variables: {'chatId': chatId},
    );
    
    if (result.hasException) {
      throw Exception('Failed to get chat details: ${result.exception}');
    }
    
    final chatData = result.data?['getChatDetails'];
    if (chatData == null) {
      throw Exception('Chat not found');
    }
    
    return ChatModel.fromJson(chatData);
  }
  
  @override
  Future<ChatModel> createDirectChat(String userId) async {
    // Mutation to create a direct chat
    final result = await _client.mutate(
      mutation: '''
        mutation CreateDirectChat(\$userId: ID!) {
          createDirectChat(userId: \$userId) {
            id
            name
            type
            avatarUrl
            lastActivity
            createdAt
            updatedAt
            participants {
              id
              username
              displayName
              avatarUrl
            }
          }
        }
      ''',
      variables: {'userId': userId},
    );
    
    if (result.hasException) {
      throw Exception('Failed to create direct chat: ${result.exception}');
    }
    
    final chatData = result.data?['createDirectChat'];
    return ChatModel.fromJson(chatData);
  }
  
  @override
  Future<ChatModel> createGroupChat(String name, List<String> userIds) async {
    // Mutation to create a group chat
    final result = await _client.mutate(
      mutation: '''
        mutation CreateGroupChat(\$name: String!, \$userIds: [ID!]!) {
          createGroupChat(name: \$name, userIds: \$userIds) {
            id
            name
            type
            avatarUrl
            lastActivity
            createdAt
            updatedAt
            participants {
              id
              username
              displayName
              avatarUrl
            }
          }
        }
      ''',
      variables: {
        'name': name,
        'userIds': userIds,
      },
    );
    
    if (result.hasException) {
      throw Exception('Failed to create group chat: ${result.exception}');
    }
    
    final chatData = result.data?['createGroupChat'];
    return ChatModel.fromJson(chatData);
  }
  
  @override
  Future<ChatModel> updateChat(String chatId, {String? name, String? avatarUrl}) async {
    // Prepare variables, removing null values
    final variables = <String, dynamic>{'chatId': chatId};
    if (name != null) variables['name'] = name;
    if (avatarUrl != null) variables['avatarUrl'] = avatarUrl;
    
    // Mutation to update a chat
    final result = await _client.mutate(
      mutation: '''
        mutation UpdateChat(\$chatId: ID!, \$name: String, \$avatarUrl: String) {
          updateChat(chatId: \$chatId, name: \$name, avatarUrl: \$avatarUrl) {
            id
            name
            type
            avatarUrl
            lastActivity
            updatedAt
          }
        }
      ''',
      variables: variables,
    );
    
    if (result.hasException) {
      throw Exception('Failed to update chat: ${result.exception}');
    }
    
    final chatData = result.data?['updateChat'];
    return ChatModel.fromJson(chatData);
  }
  
  @override
  Future<bool> addUsersToChat(String chatId, List<String> userIds) async {
    // Mutation to add users to a chat
    final result = await _client.mutate(
      mutation: '''
        mutation AddUsersToChat(\$chatId: ID!, \$userIds: [ID!]!) {
          addUsersToChat(chatId: \$chatId, userIds: \$userIds)
        }
      ''',
      variables: {
        'chatId': chatId,
        'userIds': userIds,
      },
    );
    
    if (result.hasException) {
      throw Exception('Failed to add users to chat: ${result.exception}');
    }
    
    return result.data?['addUsersToChat'] ?? false;
  }
  
  @override
  Future<bool> removeUsersFromChat(String chatId, List<String> userIds) async {
    // Mutation to remove users from a chat
    final result = await _client.mutate(
      mutation: '''
        mutation RemoveUsersFromChat(\$chatId: ID!, \$userIds: [ID!]!) {
          removeUsersFromChat(chatId: \$chatId, userIds: \$userIds)
        }
      ''',
      variables: {
        'chatId': chatId,
        'userIds': userIds,
      },
    );
    
    if (result.hasException) {
      throw Exception('Failed to remove users from chat: ${result.exception}');
    }
    
    return result.data?['removeUsersFromChat'] ?? false;
  }
  
  @override
  Future<bool> deleteChat(String chatId) async {
    // Mutation to delete a chat
    final result = await _client.mutate(
      mutation: '''
        mutation DeleteChat(\$chatId: ID!) {
          deleteChat(chatId: \$chatId)
        }
      ''',
      variables: {'chatId': chatId},
    );
    
    if (result.hasException) {
      throw Exception('Failed to delete chat: ${result.exception}');
    }
    
    return result.data?['deleteChat'] ?? false;
  }
  
  @override
  Future<bool> leaveChat(String chatId) async {
    // Mutation to leave a chat
    final result = await _client.mutate(
      mutation: '''
        mutation LeaveChat(\$chatId: ID!) {
          leaveChat(chatId: \$chatId)
        }
      ''',
      variables: {'chatId': chatId},
    );
    
    if (result.hasException) {
      throw Exception('Failed to leave chat: ${result.exception}');
    }
    
    return result.data?['leaveChat'] ?? false;
  }
  
  @override
  Stream<ChatModel> subscribeToChats() {
    // Đảm bảo socket được kết nối
    _socketManager.connect();
    
    // Stream controller for chat updates
    return _socketManager
        .on<Map<String, dynamic>>('chat_updated')
        .map((data) => ChatModel.fromJson(data));
  }
} 