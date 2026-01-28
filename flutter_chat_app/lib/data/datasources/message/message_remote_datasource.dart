import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/services/realtime_messaging_service.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:flutter_chat_app/data/mappers/socket_io_event_mapper.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:injectable/injectable.dart';

/// **Message Remote Data Source Interface**
///
/// Defines contract for fetching message data from backend API.
/// Uses DTOs for type-safe API communication.
abstract class IMessageRemoteDataSource {
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
  
  /// Subscribe to new messages via Socket.IO
  Stream<MessageDto> subscribeToMessages(String chatId);
  
  /// Subscribe to message read events via Socket.IO
  Stream<MessageReadEvent> subscribeToMessageRead(String chatId);
  
  /// Subscribe to message reactions via Socket.IO
  Stream<MessageReactionEvent> subscribeToMessageReactions(String chatId);
  
  /// Subscribe to message edits via Socket.IO
  Stream<MessageDto> subscribeToMessageEdits(String chatId);
  
  /// Subscribe to message deletes via Socket.IO
  Stream<MessageDeleteEvent> subscribeToMessageDeletes(String chatId);
  
  /// Subscribe to typing indicators via Socket.IO
  Stream<TypingIndicatorEvent> subscribeToTypingIndicators(String chatId);
}

/// **Message Remote Data Source Implementation**
///
/// Implements backend API communication using GraphQL and Socket.IO.
/// Returns DTOs for type-safe data transfer.
@LazySingleton(as: IMessageRemoteDataSource)
class MessageRemoteDataSourceImpl implements IMessageRemoteDataSource {
  final GraphQLClientWrapper _client;
  final RealtimeMessagingService _realtimeService;
  final SocketIOEventMapper _eventMapper;
  
  MessageRemoteDataSourceImpl(
    this._client,
    this._realtimeService,
    this._eventMapper,
  );
  
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
  Stream<ChatMessage> subscribeToMessages(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Join chat room
    _realtimeService.sendMessage(
      type: 'conversation:joined',
      data: {'conversationId': chatId},
    );
    
    // Listen to 'message:sent' event and map to ChatMessage
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:sent')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapMessageSent(msg.data));
  }
  
  @override
  Stream<MessageReadEvent> subscribeToMessageRead(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Listen to 'message:read' event
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:read')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapMessageRead(msg.data));
  }
  
  @override
  Stream<MessageReactionEvent> subscribeToMessageReactions(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Listen to 'message:reaction' event
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:reaction')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapMessageReaction(msg.data));
  }
  
  @override
  Stream<ChatMessage> subscribeToMessageEdits(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Listen to 'message:edit' event and map to ChatMessage
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:edit')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapMessageEdit(msg.data));
  }
  
  @override
  Stream<MessageDeleteEvent> subscribeToMessageDeletes(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Listen to 'message:delete' event
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:delete')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapMessageDelete(msg.data));
  }
  
  @override
  Stream<TypingIndicatorEvent> subscribeToTypingIndicators(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Listen to 'message:typing' event
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:typing')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) => _eventMapper.mapTypingIndicator(msg.data));
  }
}
