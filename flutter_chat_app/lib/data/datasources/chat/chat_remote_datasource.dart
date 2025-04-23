import 'package:flutter_chat_app/core/network/graphql_client.dart';
// import 'package:flutter_chat_app/core/network/socket_manager.dart'; // Remove old import
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart'; // Add new import
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io; // No longer needed directly here

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
  // final SocketManager _socketManager; // Change type
  final EnhancedSocketManager _enhancedSocketManager;
  
  // ChatRemoteDataSourceImpl(this._client, this._socketManager); // Update constructor parameter type
  ChatRemoteDataSourceImpl(this._client, this._enhancedSocketManager);
  
  @override
  Future<List<ChatModel>> getUserChats() async {
    // Query the GraphQL server for the user's chats
    final result = await _client.query(
      '''
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
    
    final List<dynamic> chatsData = result['data']?['getUserChats'] ?? [];
    return chatsData.map((chatData) => ChatModel.fromMap(chatData)).toList();
  }
  
  @override
  Future<ChatModel> getChatDetails(String chatId) async {
    // Query the GraphQL server for the chat details
    final result = await _client.query(
      '''
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
    
    final chatData = result['data']?['getChatDetails'];
    if (chatData == null) {
      throw Exception('Chat not found or failed to fetch details');
    }
    
    return ChatModel.fromMap(chatData);
  }
  
  @override
  Future<ChatModel> createDirectChat(String userId) async {
    // Mutation to create a direct chat
    final result = await _client.mutate(
      '''
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
    
    final chatData = result['data']?['createDirectChat'];
    if (chatData == null) {
      throw Exception('Failed to create direct chat');
    }
    
    return ChatModel.fromMap(chatData);
  }
  
  @override
  Future<ChatModel> createGroupChat(String name, List<String> userIds) async {
    // Mutation to create a group chat
    final result = await _client.mutate(
      '''
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
    
    final chatData = result['data']?['createGroupChat'];
    if (chatData == null) {
      throw Exception('Failed to create group chat');
    }
    
    return ChatModel.fromMap(chatData);
  }
  
  @override
  Future<ChatModel> updateChat(String chatId, {String? name, String? avatarUrl}) async {
    // Prepare variables, removing null values
    final variables = <String, dynamic>{'chatId': chatId};
    if (name != null) variables['name'] = name;
    if (avatarUrl != null) variables['avatarUrl'] = avatarUrl;
    
    // Mutation to update a chat
    final result = await _client.mutate(
      '''
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
    
    final chatData = result['data']?['updateChat'];
    if (chatData == null) {
      throw Exception('Failed to update chat');
    }
    
    return ChatModel.fromMap(chatData);
  }
  
  @override
  Future<bool> addUsersToChat(String chatId, List<String> userIds) async {
    // Mutation to add users to a chat
    final result = await _client.mutate(
      '''
        mutation AddUsersToChat(\$chatId: ID!, \$userIds: [ID!]!) {
          addUsersToChat(chatId: \$chatId, userIds: \$userIds)
        }
      ''',
      variables: {
        'chatId': chatId,
        'userIds': userIds,
      },
    );
    
    return result['data']?['addUsersToChat'] ?? false;
  }
  
  @override
  Future<bool> removeUsersFromChat(String chatId, List<String> userIds) async {
    // Mutation to remove users from a chat
    final result = await _client.mutate(
      '''
        mutation RemoveUsersFromChat(\$chatId: ID!, \$userIds: [ID!]!) {
          removeUsersFromChat(chatId: \$chatId, userIds: \$userIds)
        }
      ''',
      variables: {
        'chatId': chatId,
        'userIds': userIds,
      },
    );
    
    return result['data']?['removeUsersFromChat'] ?? false;
  }
  
  @override
  Future<bool> deleteChat(String chatId) async {
    // Mutation to delete a chat
    final result = await _client.mutate(
      '''
        mutation DeleteChat(\$chatId: ID!) {
          deleteChat(chatId: \$chatId)
        }
      ''',
      variables: {'chatId': chatId},
    );
    
    return result['data']?['deleteChat'] ?? false;
  }
  
  @override
  Future<bool> leaveChat(String chatId) async {
    // Mutation to leave a chat
    final result = await _client.mutate(
      '''
        mutation LeaveChat(\$chatId: ID!) {
          leaveChat(chatId: \$chatId)
        }
      ''',
      variables: {'chatId': chatId},
    );
    
    return result['data']?['leaveChat'] ?? false;
  }
  
  @override
  Stream<ChatModel> subscribeToChats() {
    // Đảm bảo socket được kết nối (Có thể không cần nếu AppBloc quản lý)
    // _socketManager.connect();
    _enhancedSocketManager.connect(); // Use enhanced manager
    
    // Stream controller for chat updates
    // return _socketManager
    return _enhancedSocketManager // Use enhanced manager
        .on<Map<String, dynamic>>('chat_updated')
        .map((data) => ChatModel.fromMap(data));
  }
} 