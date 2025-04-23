import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';

/// Interface for remote message data source operations
abstract class MessageRemoteDataSource {
  /// Get messages for a specific chat
  Future<List<MessageModel>> getChatMessages(String chatId, {int limit = 20, String? cursor});
  
  /// Send a message
  Future<MessageModel> sendMessage(MessageModel message);
  
  /// Delete a message
  Future<bool> deleteMessage(String messageId);
  
  /// Mark messages as read
  Future<bool> markMessagesAsRead(String chatId);
  
  /// Subscribe to new messages for a specific chat
  Stream<MessageModel> subscribeToMessages(String chatId);
  
  /// Subscribe to typing indicators for a specific chat
  Stream<Map<String, dynamic>> subscribeToTypingIndicators(String chatId);
}

/// Implementation of [MessageRemoteDataSource]
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final GraphQLClientWrapper _client;
  final EnhancedSocketManager _enhancedSocketManager;
  
  /// Constructor
  MessageRemoteDataSourceImpl(this._client, this._enhancedSocketManager);
  
  @override
  Future<List<MessageModel>> getChatMessages(String chatId, {int limit = 20, String? cursor}) async {
    final variables = <String, dynamic>{
      'chatId': chatId,
      'limit': limit,
    };
    
    if (cursor != null) {
      variables['cursor'] = cursor;
    }
    
    final result = await _client.query(
      '''
      query GetChatMessages(\$chatId: ID!, \$limit: Int, \$cursor: String) {
        getChatMessages(chatId: \$chatId, limit: \$limit, cursor: \$cursor) {
          id
          chatId
          senderId
          content
          type
          attachments {
            id
            url
            type
            filename
            size
            metadata
          }
          createdAt
          updatedAt
          readBy
          sender {
            id
            username
            displayName
            avatarUrl
          }
        }
      }
      ''',
      variables: variables,
    );
    
    if (result['data'] == null || result['data']['getChatMessages'] == null) {
      return [];
    }
    
    final List<dynamic> messagesData = result['data']['getChatMessages'];
    return messagesData
        .map((messageData) => MessageModel.fromMap(messageData))
        .toList();
  }
  
  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    // Prepare message data
    final messageData = message.toMap();
    
    // Remove client-only fields
    messageData.remove('localId');
    messageData.remove('status');
    messageData.remove('isSending');
    
    final result = await _client.mutate(
      '''
      mutation SendMessage(\$chatId: ID!, \$content: String!, \$type: MessageType!, \$attachments: [AttachmentInput]) {
        sendMessage(
          input: {
            chatId: \$chatId,
            content: \$content,
            type: \$type,
            attachments: \$attachments
          }
        ) {
          id
          chatId
          senderId
          content
          type
          attachments {
            id
            url
            type
            filename
            size
            metadata
          }
          createdAt
          updatedAt
          readBy
          sender {
            id
            username
            displayName
            avatarUrl
          }
        }
      }
      ''',
      variables: {
        'chatId': message.chatId,
        'content': message.content,
        'type': message.type.toString().split('.').last.toUpperCase(),
        'attachments': null, // TODO: Handle attachment upload separately
      },
    );
    
    if (result['data'] == null || result['data']['sendMessage'] == null) {
      throw Exception('Failed to send message');
    }
    
    final sentMessageData = result['data']['sendMessage'];
    return MessageModel.fromMap(sentMessageData);
  }
  
  @override
  Future<bool> deleteMessage(String messageId) async {
    final result = await _client.mutate(
      '''
      mutation DeleteMessage(\$messageId: ID!) {
        deleteMessage(messageId: \$messageId)
      }
      ''',
      variables: {'messageId': messageId},
    );
    
    if (result['data'] == null) {
      return false;
    }
    
    return result['data']['deleteMessage'] ?? false;
  }
  
  @override
  Future<bool> markMessagesAsRead(String chatId) async {
    final result = await _client.mutate(
      '''
      mutation MarkMessagesAsRead(\$chatId: ID!) {
        markMessagesAsRead(chatId: \$chatId)
      }
      ''',
      variables: {'chatId': chatId},
    );
    
    if (result['data'] == null) {
      return false;
    }
    
    return result['data']['markMessagesAsRead'] ?? false;
  }
  
  @override
  Stream<MessageModel> subscribeToMessages(String chatId) {
    // Đảm bảo socket được kết nối (Có thể không cần nếu AppBloc quản lý)
    _enhancedSocketManager.connect();
    
    // Tham gia vào chat room
    _enhancedSocketManager.emit('join_chat', {'chatId': chatId});
    
    // Lắng nghe sự kiện 'new_message' cho chat cụ thể
    return _enhancedSocketManager
        .on<Map<String, dynamic>>('new_message')
        .where((data) => data.containsKey('chatId') && data['chatId'] == chatId)
        .map((data) => MessageModel.fromMap(data));
  }
  
  @override
  Stream<Map<String, dynamic>> subscribeToTypingIndicators(String chatId) {
    // Đảm bảo socket được kết nối (Có thể không cần nếu AppBloc quản lý)
    _enhancedSocketManager.connect();
    
    // Tham gia vào chat room
    _enhancedSocketManager.emit('join_chat', {'chatId': chatId});
    
    // Lắng nghe sự kiện 'typing' cho chat cụ thể
    return _enhancedSocketManager
        .on<Map<String, dynamic>>('typing')
        .where((data) => data.containsKey('chatId') && data['chatId'] == chatId);
  }
} 