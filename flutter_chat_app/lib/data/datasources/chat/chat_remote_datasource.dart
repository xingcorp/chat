import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';
import 'package:flutter_chat_app/data/dtos/chat_dto.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:injectable/injectable.dart';

/// **Chat Remote Data Source Interface**
///
/// Defines contract for fetching chat data from backend API.
/// Uses DTOs for type-safe API communication.
abstract class IChatRemoteDataSource {
  /// Get paginated list of conversations
  Future<ChatListResponseDto> getConversationList({
    int size = 25,
    int page = 0,
    String? keyword,
    String? type,
  });
  
  /// Get conversation details by ID or receiverId
  Future<ChatDto> getConversationDetail({
    String? conversationId,
    String? receiverId,
  });
  
  /// Create a new group conversation
  Future<ChatDto> createGroup({
    required String name,
    String? imgUrl,
    String? description,
    required String groupType,
    required List<String> memberIds,
  });
  
  /// Update group information
  Future<ChatDto> updateGroup({
    required String conversationId,
    String? name,
    String? imgUrl,
    String? description,
    String? groupType,
    List<String>? memberIds,
    List<String>? adminIds,
  });
  
  /// Leave a conversation
  Future<String> leaveConversation(String conversationId);
  
  /// Delete a conversation
  Future<Map<String, dynamic>> deleteConversation(String conversationId);
  
  /// Get messages for a conversation
  Future<MessageListResponseDto> getMessageList({
    required String conversationId,
    int size = 100,
    Map<String, dynamic>? lastKey,
    String? type,
    String order = 'DESC',
    int? from,
  });
  
  /// Send a message
  Future<MessageDto> sendMessage({
    String? conversationId,
    String? receiverId,
    required String type,
    required String message,
    List<String>? urls,
    String? fileName,
    String? replyMessageId,
    String? forwardedFromMessageId,
    required int createdAt,
  });
  
  /// Edit or delete a message
  Future<MessageDto> editMessage({
    required String messageId,
    required String act,
    String? message,
  });
  
  /// Mark messages as read
  Future<String> markAsRead({
    required String conversationId,
    required int readCount,
  });
  
  /// Add or remove reaction
  Future<MessageDto> updateReaction({
    required String messageId,
    required String code,
    required String act,
  });
  
  /// Delete message history
  Future<Map<String, dynamic>> deleteHistory(String conversationId);
  
  /// Search messages
  Future<List<MessageDto>> searchMessages({
    required String keyword,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<String>? messageTypes,
    int? from,
    int? to,
    int page = 0,
    int size = 100,
  });
  
  /// Subscribe to chat updates via Socket.IO
  Stream<ChatDto> subscribeToChats();
}

/// **Chat Remote Data Source Implementation**
///
/// Implements backend API communication using GraphQL and Socket.IO.
/// Returns DTOs for type-safe data transfer.
@LazySingleton(as: IChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements IChatRemoteDataSource {
  final GraphQLClientWrapper _client;
  final EnhancedSocketManager _socketManager;
  
  ChatRemoteDataSourceImpl(
    this._client,
    this._socketManager,
  );
  
  @override
  Future<ChatListResponseDto> getConversationList({
    int size = 25,
    int page = 0,
    String? keyword,
    String? type,
  }) async {
    final variables = <String, dynamic>{
      'filters': {
        'size': size,
        'page': page,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (type != null) 'type': type,
      },
    };
    
    final result = await _client.query(
      ChatQueries.getConversationList,
      variables: variables,
    );
    
    final data = result['data']?['chatConversationList'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch conversation list');
    }
    
    return ChatListResponseDto.fromJson(data);
  }
  
  @override
  Future<ChatDto> getConversationDetail({
    String? conversationId,
    String? receiverId,
  }) async {
    if (conversationId == null && receiverId == null) {
      throw ArgumentError('Either conversationId or receiverId must be provided');
    }
    
    final variables = <String, dynamic>{
      if (conversationId != null) 'conversationId': conversationId,
      if (receiverId != null) 'receiverId': receiverId,
    };
    
    final result = await _client.query(
      ChatQueries.getConversationDetail,
      variables: variables,
    );
    
    final data = result['data']?['chatConversationDetail'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch conversation detail');
    }
    
    return ChatDto.fromJson(data);
  }
  
  @override
  Future<ChatDto> createGroup({
    required String name,
    String? imgUrl,
    String? description,
    required String groupType,
    required List<String> memberIds,
  }) async {
    final variables = <String, dynamic>{
      'arguments': {
        'name': name,
        if (imgUrl != null) 'imgUrl': imgUrl,
        if (description != null) 'description': description,
        'groupType': groupType,
        'memberIds': memberIds,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.createGroup,
      variables: variables,
    );
    
    final data = result['data']?['chatGroupAdd'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to create group');
    }
    
    return ChatDto.fromJson(data);
  }
  
  @override
  Future<ChatDto> updateGroup({
    required String conversationId,
    String? name,
    String? imgUrl,
    String? description,
    String? groupType,
    List<String>? memberIds,
    List<String>? adminIds,
  }) async {
    final variables = <String, dynamic>{
      'arguments': {
        'conversationId': conversationId,
        if (name != null) 'name': name,
        if (imgUrl != null) 'imgUrl': imgUrl,
        if (description != null) 'description': description,
        if (groupType != null) 'groupType': groupType,
        if (memberIds != null) 'memberIds': memberIds,
        if (adminIds != null) 'adminIds': adminIds,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.editGroup,
      variables: variables,
    );
    
    final data = result['data']?['chatGroupEdit'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to update group');
    }
    
    return ChatDto.fromJson(data);
  }
  
  @override
  Future<String> leaveConversation(String conversationId) async {
    final variables = <String, dynamic>{
      'arguments': {
        'conversationId': conversationId,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.leaveConversation,
      variables: variables,
    );
    
    final data = result['data']?['chatConversationLeave'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to leave conversation');
    }
    
    return data['id'] as String;
  }
  
  @override
  Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    final variables = <String, dynamic>{
      'arguments': {
        'conversationId': conversationId,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.deleteConversation,
      variables: variables,
    );
    
    final data = result['data']?['chatConversationDelete'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to delete conversation');
    }
    
    return data;
  }
  
  @override
  Future<MessageListResponseDto> getMessageList({
    required String conversationId,
    int size = 100,
    Map<String, dynamic>? lastKey,
    String? type,
    String order = 'DESC',
    int? from,
  }) async {
    final variables = <String, dynamic>{
      'filters': {
        'conversationId': conversationId,
        'size': size,
        if (lastKey != null) 'lastKey': lastKey,
        if (type != null) 'type': type,
        'order': order,
        if (from != null) 'from': from,
      },
    };
    
    final result = await _client.query(
      ChatQueries.getMessageList,
      variables: variables,
    );
    
    final data = result['data']?['chatMessageList'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch message list');
    }
    
    return MessageListResponseDto.fromJson(data);
  }
  
  @override
  Future<MessageDto> sendMessage({
    String? conversationId,
    String? receiverId,
    required String type,
    required String message,
    List<String>? urls,
    String? fileName,
    String? replyMessageId,
    String? forwardedFromMessageId,
    required int createdAt,
  }) async {
    if (conversationId == null && receiverId == null) {
      throw ArgumentError('Either conversationId or receiverId must be provided');
    }
    
    final variables = <String, dynamic>{
      'arguments': {
        if (conversationId != null) 'conversationId': conversationId,
        if (receiverId != null) 'receiverId': receiverId,
        'type': type,
        'message': message,
        if (urls != null && urls.isNotEmpty) 'urls': urls,
        if (fileName != null) 'fileName': fileName,
        if (replyMessageId != null) 'replyMessageId': replyMessageId,
        if (forwardedFromMessageId != null) 'forwardedFromMessageId': forwardedFromMessageId,
        'createdAt': createdAt,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.sendMessage,
      variables: variables,
    );
    
    final data = result['data']?['chatMessageAdd'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to send message');
    }
    
    return MessageDto.fromJson(data);
  }
  
  @override
  Future<MessageDto> editMessage({
    required String messageId,
    required String act,
    String? message,
  }) async {
    final variables = <String, dynamic>{
      'arguments': {
        'messageId': messageId,
        'act': act,
        if (message != null) 'message': message,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.editMessage,
      variables: variables,
    );
    
    final data = result['data']?['chatMessageEdit'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to edit message');
    }
    
    return MessageDto.fromJson(data);
  }
  
  @override
  Future<String> markAsRead({
    required String conversationId,
    required int readCount,
  }) async {
    final variables = <String, dynamic>{
      'arguments': {
        'conversationId': conversationId,
        'readCount': readCount,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.markAsRead,
      variables: variables,
    );
    
    final data = result['data']?['chatMessageUpdateRead'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to mark as read');
    }
    
    return data['conversationId'] as String;
  }
  
  @override
  Future<MessageDto> updateReaction({
    required String messageId,
    required String code,
    required String act,
  }) async {
    final variables = <String, dynamic>{
      'arguments': {
        'messageId': messageId,
        'code': code,
        'act': act,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.updateReaction,
      variables: variables,
    );
    
    final data = result['data']?['chatMessageUpdateReaction'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to update reaction');
    }
    
    return MessageDto.fromJson(data);
  }
  
  @override
  Future<Map<String, dynamic>> deleteHistory(String conversationId) async {
    final variables = <String, dynamic>{
      'arguments': {
        'conversationId': conversationId,
      },
    };
    
    final result = await _client.mutate(
      ChatMutations.deleteHistory,
      variables: variables,
    );
    
    final data = result['data']?['chatMessageDeleteHistory'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to delete history');
    }
    
    return data;
  }
  
  @override
  Future<List<MessageDto>> searchMessages({
    required String keyword,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<String>? messageTypes,
    int? from,
    int? to,
    int page = 0,
    int size = 100,
  }) async {
    final variables = <String, dynamic>{
      'filters': {
        'keyword': keyword,
        if (conversationIds != null) 'conversationIds': conversationIds,
        if (senderIds != null) 'senderIds': senderIds,
        if (messageTypes != null) 'messageTypes': messageTypes,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        'page': page,
        'size': size,
      },
    };
    
    final result = await _client.query(
      ChatQueries.searchMessages,
      variables: variables,
    );
    
    final data = result['data']?['chatSearch'] as List<dynamic>?;
    if (data == null) {
      throw Exception('Failed to search messages');
    }
    
    return data.map((json) => MessageDto.fromJson(json as Map<String, dynamic>)).toList();
  }
  
  @override
  Stream<ChatDto> subscribeToChats() {
    _socketManager.connect();
    
    return _socketManager
        .on<Map<String, dynamic>>('chat_updated')
        .map((data) => ChatDto.fromJson(data));
  }
}
