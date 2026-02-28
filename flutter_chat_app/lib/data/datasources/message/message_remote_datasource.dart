import 'package:graphql_flutter/graphql_flutter.dart' show FetchPolicy;
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/services/realtime_messaging_service.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:flutter_chat_app/data/mappers/socket_io_event_mapper.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

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
  /// Returns null for DEL action (partial response), MessageDto for EDIT action
  Future<MessageDto?> editMessage({
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
@lazySingleton
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
    
    // CRITICAL: Use networkOnly to bypass GraphQL HiveStore cache.
    // The app has its own cache layers (AppCacheManager + Isar).
    // Using the default cacheAndNetwork policy returns stale cached
    // responses when the same query variables are used, which causes
    // the "new messages not showing" bug.
    final result = await _client.query(
      ChatQueries.getMessageList,
      variables: variables,
      fetchPolicy: FetchPolicy.networkOnly,
      operationName: 'GetMessageList',
    );
    
    final data = result['chatMessageList'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch message list');
    }

    if (kDebugMode) {
      final messages = data['messages'];
      if (messages is List) {
        final eventCount = messages.where((m) {
          if (m is! Map<String, dynamic>) return false;
          final t = (m['type'] as String?)?.toLowerCase();
          return t == 'log' || t == 'event' || t == 'system';
        }).length;
        debugPrint(
          '[getMessageList] conversationId=$conversationId size=$size received=${messages.length} eventCount=$eventCount',
        );

        for (final m in messages) {
          if (m is! Map<String, dynamic>) continue;
          final t = (m['type'] as String?)?.toLowerCase();
          if (t != 'log' && t != 'event' && t != 'system') continue;
          final actionType = m['actionType'];
          final targetUsers = m['targetUsers'];
          debugPrint(
            '[getMessageList:event] id=${m['id']} type=${m['type']} actionType=$actionType targetUsers=${targetUsers is List ? targetUsers.length : 0} message=${m['message']}',
          );
          break;
        }
      }
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
      operationName: 'SendMessage',
    );
    
    final data = result['chatMessageAdd'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to send message');
    }

    if (kDebugMode) {
      final t = (data['type'] as String?)?.toLowerCase();
      if (t == 'log' || t == 'event' || t == 'system') {
        debugPrint(
          '[sendMessage:event] id=${data['id']} type=${data['type']} actionType=${data['actionType']} targetUsers=${(data['targetUsers'] as List?)?.length ?? 0} message=${data['message']}',
        );
      }
    }
    
    return MessageDto.fromJson(data);
  }
  
  @override
  Future<MessageDto?> editMessage({
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
      operationName: 'EditMessage',
    );
    
    final data = result['chatMessageEdit'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to edit message');
    }
    
    // For DEL action, mutation only returns partial fields (id, message, editAt, deletedAt)
    // MessageDto requires all fields, so return null for delete operations
    if (act == 'DEL') {
      return null; // Delete success - no need to parse partial response
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
      operationName: 'MarkAsRead',
    );
    
    final data = result['chatMessageUpdateRead'] as Map<String, dynamic>?;
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
      operationName: 'UpdateReaction',
    );
    
    final data = result['chatMessageUpdateReaction'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to update reaction');
    }

    // Backend returns a partial message payload for reaction updates (id + reactions).
    // MessageDto requires additional fields, but repository callers only need success.
    // Build a minimal DTO payload to avoid runtime parsing errors.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final minimal = <String, dynamic>{
      'id': data['id'] ?? messageId,
      'message': '',
      'urls': const <String>[],
      'type': 'TEXT',
      'createdAt': nowMs,
      'senderId': '',
      'conversationId': '',
      'readerIds': const <String>[],
      'reactions': (data['reactions'] as List?) ?? const <dynamic>[],
      'mentionTo': const <dynamic>[],
    };

    return MessageDto.fromJson(minimal);
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
      operationName: 'DeleteHistory',
    );
    
    final data = result['chatMessageDeleteHistory'] as Map<String, dynamic>?;
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
      fetchPolicy: FetchPolicy.networkOnly,
      operationName: 'SearchMessages',
    );
    
    final data = result['chatSearch'] as List<dynamic>?;
    if (data == null) {
      throw Exception('Failed to search messages');
    }
    
    return data.map((json) => MessageDto.fromJson(json as Map<String, dynamic>)).toList();
  }
  
  @override
  Stream<MessageDto> subscribeToMessages(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Join chat room
    _realtimeService.sendMessage(
      type: 'conversation:joined',
      data: {'conversationId': chatId},
    );
    
    // Listen to 'message:sent' event and map to MessageDto
    // Use MessageDto.fromJson directly to preserve system event fields (targetUsers, actionType, etc.)
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:sent')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) {
          final messageData = msg.data['message'] as Map<String, dynamic>?;
          if (messageData == null) {
            throw FormatException('No message data in message:sent event');
          }
          return MessageDto.fromJson(messageData);
        });
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
  Stream<MessageDto> subscribeToMessageEdits(String chatId) {
    // Ensure connection
    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }
    
    // Listen to 'message:edit' event and map to MessageDto
    return _realtimeService.messages
        .where((msg) => msg.type == 'message:edit')
        .where((msg) => msg.data['conversationId'] == chatId)
        .map((msg) {
          final chatMessage = _eventMapper.mapMessageEdit(msg.data);
          return _chatMessageToDto(chatMessage);
        });
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
  
  /// Helper method to convert ChatMessage (domain entity) to MessageDto (data DTO)
  MessageDto _chatMessageToDto(ChatMessage message) {
    final senderImageUrls = <String>[];
    final senderAvatar = message.sender.avatar;
    if (senderAvatar != null && senderAvatar.isNotEmpty) {
      senderImageUrls.add(senderAvatar);
    }

    final reactorIdsByCode = <String, Set<String>>{};
    for (final reaction in message.reactions) {
      reactorIdsByCode
          .putIfAbsent(reaction.code, () => <String>{})
          .add(reaction.userId);
    }

    return MessageDto(
      id: message.id,
      content: message.content,
      urls: message.attachments.map((a) => a.url).toList(),
      type: message.contentType.toString().split('.').last,
      createdAt: message.createdAt.millisecondsSinceEpoch,
      editAt: message.editedAt?.millisecondsSinceEpoch,
      deletedAt: null, // Not available in ChatMessage
      replyMessageId: null, // Not available in ChatMessage
      replyMessage: null, // Not available in ChatMessage
      forwardedFromMessageId: null, // Not available in ChatMessage
      fileName: message.attachments.isNotEmpty ? message.attachments.first.name : null,
      senderId: message.sender.id,
      sender: SenderDto(
        id: message.sender.id,
        fullName: message.sender.name,
        imageUrls: senderImageUrls,
      ),
      chatId: message.chatId,
      readerIds: message.readBy,
      reactions: reactorIdsByCode.entries
          .map(
            (e) => ReactionDto(
              code: e.key,
              reactorIds: e.value.toList(),
              reactors: const [],
            ),
          )
          .toList(),
      mentionTo: [], // Not available in ChatMessage
    );
  }
}
