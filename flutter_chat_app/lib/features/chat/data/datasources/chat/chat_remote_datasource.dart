import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/enhanced_socket_manager.dart';
import 'package:flutter_chat_app/data/dtos/chat_dto.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

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

  /// Get conversation members with detailed user info (department, title, code)
  /// Separate API to avoid performance impact on conversation list
  Future<ChatDto> getConversationMembers(String conversationId);
  
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
  
  /// Add members to group
  Future<void> addMembersToGroup({
    required String conversationId,
    required List<String> memberIds,
  });
  
  /// Remove members from group
  Future<void> removeMembersFromGroup({
    required String conversationId,
    required List<String> memberIds,
  });
  
  /// Search conversations
  Future<ChatListResponseDto> searchConversations({
    required String keyword,
    int limit = 20,
  });
  
  /// Alias methods for compatibility
  Future<ChatListResponseDto> getChats({
    int size = 25,
    int page = 0,
    String? keyword,
    String? type,
  }) => getConversationList(size: size, page: page, keyword: keyword, type: type);
  
  Future<ChatDto> getChatById(String chatId) => getConversationDetail(conversationId: chatId);
  
  Future<ChatDto> createGroupChat({
    required String name,
    String? imgUrl,
    String? description,
    required String groupType,
    required List<String> memberIds,
  }) => createGroup(
    name: name,
    imgUrl: imgUrl,
    description: description,
    groupType: groupType,
    memberIds: memberIds,
  );
  
  Future<ChatDto> createDirectChat({
    required String receiverId,
  }) => getConversationDetail(receiverId: receiverId);
  
  Future<ChatDto> updateChat({
    required String conversationId,
    String? name,
    String? imgUrl,
    String? description,
  }) => updateGroup(
    conversationId: conversationId,
    name: name,
    imgUrl: imgUrl,
    description: description,
  );
  
  Future<Map<String, dynamic>> deleteChat(String chatId) => deleteConversation(chatId);
  
  Future<MessageListResponseDto> getChatMessages({
    required String conversationId,
    int size = 100,
    Map<String, dynamic>? lastKey,
  }) => getMessageList(
    conversationId: conversationId,
    size: size,
    lastKey: lastKey,
  );
  
  Future<void> addUsersToChat({
    required String conversationId,
    required List<String> userIds,
  }) => addMembersToGroup(
    conversationId: conversationId,
    memberIds: userIds,
  );
  
  Future<void> removeUsersFromChat({
    required String conversationId,
    required List<String> userIds,
  }) => removeMembersFromGroup(
    conversationId: conversationId,
    memberIds: userIds,
  );
  
  Future<String> leaveChat(String chatId) => leaveConversation(chatId);
  
  Future<ChatDto> getChatDetails(String chatId) => getConversationDetail(conversationId: chatId);
  
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
      fetchPolicy: FetchPolicy.networkOnly,
      operationName: 'GetConversationList',
    );
    
    final data = result['chatConversationList'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch conversation list');
    }

    final dto = ChatListResponseDto.fromJson(data);
    return dto;
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
      fetchPolicy: FetchPolicy.networkOnly,
      operationName: 'GetConversationDetail',
    );
    
    final data = result['chatConversationDetail'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch conversation detail');
    }
    
    return ChatDto.fromJson(data);
  }

  @override
  Future<ChatDto> getConversationMembers(String conversationId) async {
    // CRITICAL: Use networkOnly to bypass GraphQL HiveStore cache.
    // The app has its own cache layers (AppCacheManager + Isar).
    // Using the default cacheAndNetwork policy can return stale cached
    // member data (e.g. admin=false), causing the admin badge and
    // remove-member button to disappear intermittently.
    final result = await _client.query(
      ChatQueries.getConversationMembers,
      variables: {'conversationId': conversationId},
      fetchPolicy: FetchPolicy.networkOnly,
      operationName: 'GetConversationMembers',
    );

    final data = result['chatConversationDetail'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to fetch conversation members');
    }

    try {
      return ChatDto.fromJson(data);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[ChatRemoteDataSourceImpl] ChatDto.fromJson failed for getConversationMembers(conversationId=$conversationId): $e',
        );
        debugPrint(st.toString());

        final rawMembers = data['members'];
        if (rawMembers is List) {
          for (var i = 0; i < rawMembers.length; i++) {
            final m = rawMembers[i];
            if (m is! Map) {
              debugPrint('[ChatRemoteDataSourceImpl] members[$i] type=${m.runtimeType} value=$m');
              continue;
            }
            final user = m['user'];
            final departments = (user is Map) ? user['departments'] : null;
            final imageUrls = (user is Map) ? user['imageUrls'] : null;
            debugPrint(
              '[ChatRemoteDataSourceImpl] members[$i] id=${m['id']} (type=${m['id']?.runtimeType}) '
              'userId=${m['userId']} (type=${m['userId']?.runtimeType}) '
              'user.id=${(user is Map) ? user['id'] : null} (type=${(user is Map) ? user['id']?.runtimeType : null}) '
              'user.fullname=${(user is Map) ? user['fullname'] : null} (type=${(user is Map) ? user['fullname']?.runtimeType : null}) '
              'user.imageUrls.type=${imageUrls?.runtimeType} '
              'user.departments.type=${departments?.runtimeType}',
            );
            if (departments is List && departments.isNotEmpty) {
              final dep0 = departments.first;
              if (dep0 is Map) {
                final department = dep0['department'];
                final title = dep0['title'];
                debugPrint(
                  '[ChatRemoteDataSourceImpl] members[$i].user.departments[0] '
                  'department.type=${department.runtimeType} title.type=${title.runtimeType} '
                  'department.name=${(department is Map) ? department['name'] : null} '
                  'title.name=${(title is Map) ? title['name'] : null}',
                );
              } else {
                debugPrint(
                  '[ChatRemoteDataSourceImpl] members[$i].user.departments[0] type=${dep0.runtimeType} value=$dep0',
                );
              }
            }
          }
        } else {
          debugPrint(
            '[ChatRemoteDataSourceImpl] chatConversationDetail.members type=${rawMembers.runtimeType} value=$rawMembers',
          );
        }
      }
      rethrow;
    }
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
      operationName: 'CreateGroup',
    );
    
    final data = result['chatGroupAdd'] as Map<String, dynamic>?;
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
      operationName: 'EditGroup',
    );
    
    final data = result['chatGroupEdit'] as Map<String, dynamic>?;
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
      operationName: 'LeaveConversation',
    );
    
    final data = result['chatConversationLeave'] as Map<String, dynamic>?;
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
      operationName: 'DeleteConversation',
    );
    
    final data = result['chatConversationDelete'] as Map<String, dynamic>?;
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
      operationName: 'GetMessageList',
    );
    
    final data = result['chatMessageList'] as Map<String, dynamic>?;
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
      operationName: 'SendMessage',
    );
    
    final data = result['chatMessageAdd'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Failed to send message');
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
    
    debugPrint('[SearchMessages] Variables: $variables');
    
    final result = await _client.query(
      ChatQueries.searchMessages,
      variables: variables,
      operationName: 'SearchMessages',
    );
    
    debugPrint('[SearchMessages] Result: $result');
    
    final data = result['chatSearch'] as List<dynamic>?;
    if (data == null) {
      debugPrint('[SearchMessages] No data returned');
      return [];
    }
    
    debugPrint('[SearchMessages] Found ${data.length} results');
    return data.map((json) => MessageDto.fromJson(json as Map<String, dynamic>)).toList();
  }
  
  @override
  Future<void> addMembersToGroup({
    required String conversationId,
    required List<String> memberIds,
  }) async {
    // Get current members and merge with new ones to avoid replacing existing members
    final chat = await getConversationDetail(conversationId: conversationId);
    final currentMemberIds = chat.members
        .map((m) => m.userId)
        .whereType<String>()
        .toSet();
    final mergedMemberIds = {...currentMemberIds, ...memberIds}.toList();
    await updateGroup(
      conversationId: conversationId,
      memberIds: mergedMemberIds,
    );
  }
  
  @override
  Future<void> removeMembersFromGroup({
    required String conversationId,
    required List<String> memberIds,
  }) async {
    // Backend uses editGroup with updated memberIds to remove members
    // Get current members, filter out the ones to remove, then call updateGroup
    final chat = await getConversationDetail(conversationId: conversationId);
    final remainingMemberIds = chat.members
        .map((m) => m.userId)
        .whereType<String>()
        .where((id) => !memberIds.contains(id))
        .toList();
    await updateGroup(
      conversationId: conversationId,
      memberIds: remainingMemberIds,
    );
  }
  
  @override
  Future<ChatListResponseDto> searchConversations({
    required String keyword,
    int limit = 20,
  }) async {
    return getConversationList(
      keyword: keyword,
      size: limit,
    );
  }
  
  @override
  Stream<ChatDto> subscribeToChats() {
    _socketManager.connect();
    
    return _socketManager
        .on<Map<String, dynamic>>('chat_updated')
        .map((data) => ChatDto.fromJson(data));
  }
  
  // Implement alias methods
  @override
  Future<ChatListResponseDto> getChats({
    int size = 25,
    int page = 0,
    String? keyword,
    String? type,
  }) => getConversationList(size: size, page: page, keyword: keyword, type: type);
  
  @override
  Future<ChatDto> getChatById(String chatId) => getConversationDetail(conversationId: chatId);
  
  @override
  Future<ChatDto> createGroupChat({
    required String name,
    String? imgUrl,
    String? description,
    required String groupType,
    required List<String> memberIds,
  }) => createGroup(
    name: name,
    imgUrl: imgUrl,
    description: description,
    groupType: groupType,
    memberIds: memberIds,
  );
  
  @override
  Future<ChatDto> createDirectChat({
    required String receiverId,
  }) => getConversationDetail(receiverId: receiverId);
  
  @override
  Future<ChatDto> updateChat({
    required String conversationId,
    String? name,
    String? imgUrl,
    String? description,
  }) => updateGroup(
    conversationId: conversationId,
    name: name,
    imgUrl: imgUrl,
    description: description,
  );
  
  @override
  Future<Map<String, dynamic>> deleteChat(String chatId) => deleteConversation(chatId);
  
  @override
  Future<MessageListResponseDto> getChatMessages({
    required String conversationId,
    int size = 100,
    Map<String, dynamic>? lastKey,
  }) => getMessageList(
    conversationId: conversationId,
    size: size,
    lastKey: lastKey,
  );
  
  @override
  Future<void> addUsersToChat({
    required String conversationId,
    required List<String> userIds,
  }) => addMembersToGroup(
    conversationId: conversationId,
    memberIds: userIds,
  );
  
  @override
  Future<void> removeUsersFromChat({
    required String conversationId,
    required List<String> userIds,
  }) => removeMembersFromGroup(
    conversationId: conversationId,
    memberIds: userIds,
  );
  
  @override
  Future<String> leaveChat(String chatId) => leaveConversation(chatId);
  
  @override
  Future<ChatDto> getChatDetails(String chatId) => getConversationDetail(conversationId: chatId);
}
