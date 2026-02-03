/// **Socket.IO Event Mapper**
///
/// Maps backend Socket.IO events to domain entities.
/// Follows Clean Architecture - belongs to data layer.
///
/// **Backend Socket.IO Events:**
/// - message:sent → New message
/// - message:read → Message read status
/// - message:reaction → Message reaction
/// - message:edit → Message edited
/// - message:delete → Message deleted
/// - message:typing → Typing indicator

import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Event types from Socket.IO
enum SocketIOEventType {
  messageSent,
  messageRead,
  messageReaction,
  messageEdit,
  messageDelete,
  messageTyping,
  conversationJoined,
  conversationLeaved,
}

/// Typing indicator event
class TypingIndicatorEvent {
  final String chatId;
  final String userId;
  final String userName;
  final bool isTyping;
  final DateTime timestamp;

  const TypingIndicatorEvent({
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.isTyping,
    required this.timestamp,
  });
}

/// Message read event
class MessageReadEvent {
  final String messageId;
  final String chatId;
  final String userId;
  final DateTime timestamp;

  const MessageReadEvent({
    required this.messageId,
    required this.chatId,
    required this.userId,
    required this.timestamp,
  });
}

/// Message reaction event
class MessageReactionEvent {
  final String messageId;
  final String chatId;
  final String userId;
  final String reactionCode;
  final String action; // 'add' or 'remove'
  final DateTime timestamp;

  const MessageReactionEvent({
    required this.messageId,
    required this.chatId,
    required this.userId,
    required this.reactionCode,
    required this.action,
    required this.timestamp,
  });
}

/// Message delete event
class MessageDeleteEvent {
  final String messageId;
  final String chatId;
  final DateTime timestamp;

  const MessageDeleteEvent({
    required this.messageId,
    required this.chatId,
    required this.timestamp,
  });
}

/// **Socket.IO Event Mapper**
///
/// Converts raw Socket.IO event data to domain entities.
/// Handles data validation and error cases.
@singleton
class SocketIOEventMapper {
  /// Map message:sent event to ChatMessage
  ///
  /// Expected data structure:
  /// ```json
  /// {
  ///   "conversationId": "chat-123",
  ///   "message": {
  ///     "id": "msg-456",
  ///     "content": "Hello",
  ///     "type": "text",
  ///     "senderId": "user-789",
  ///     "senderName": "John Doe",
  ///     "senderAvatar": "https://...",
  ///     "createdAt": "2024-01-28T10:00:00Z",
  ///     "attachments": [],
  ///     "reactions": []
  ///   }
  /// }
  /// ```
  ChatMessage mapMessageSent(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final conversationId = data['conversationId'] as String;

      return ChatMessage(
        id: messageData['id'] as String,
        chatId: conversationId,
        content: messageData['content'] as String? ?? '',
        contentType: _parseContentType(messageData['type'] as String?),
        sender: MessageSender(
          id: messageData['senderId'] as String,
          name: messageData['senderName'] as String? ?? 'Unknown',
          avatar: messageData['senderAvatar'] as String?,
        ),
        createdAt: _parseDateTime(messageData['createdAt']),
        updatedAt: _parseDateTime(messageData['updatedAt'] ?? messageData['createdAt']),
        readBy: _parseStringList(messageData['readBy']),
        deliveredTo: _parseStringList(messageData['deliveredTo']),
        attachments: _parseAttachments(messageData['attachments']),
        reactions: _parseReactions(messageData['reactions']),
      );
    } catch (e) {
      throw FormatException('Failed to map message:sent event: $e');
    }
  }

  /// Map message:read event to MessageReadEvent
  ///
  /// Expected data structure:
  /// ```json
  /// {
  ///   "conversationId": "chat-123",
  ///   "messageId": "msg-456",
  ///   "reader": {
  ///     "id": "user-789",
  ///     "name": "John Doe"
  ///   },
  ///   "timestamp": "2024-01-28T10:00:00Z"
  /// }
  /// ```
  MessageReadEvent mapMessageRead(Map<String, dynamic> data) {
    try {
      final reader = data['reader'] as Map<String, dynamic>;

      return MessageReadEvent(
        messageId: data['messageId'] as String,
        chatId: data['conversationId'] as String,
        userId: reader['id'] as String,
        timestamp: _parseDateTime(data['timestamp']),
      );
    } catch (e) {
      throw FormatException('Failed to map message:read event: $e');
    }
  }

  /// Map message:reaction event to MessageReactionEvent
  ///
  /// Expected data structure:
  /// ```json
  /// {
  ///   "conversationId": "chat-123",
  ///   "messageId": "msg-456",
  ///   "user": {
  ///     "id": "user-789",
  ///     "name": "John Doe"
  ///   },
  ///   "reaction": {
  ///     "code": "👍",
  ///     "action": "add"
  ///   },
  ///   "timestamp": "2024-01-28T10:00:00Z"
  /// }
  /// ```
  MessageReactionEvent mapMessageReaction(Map<String, dynamic> data) {
    try {
      final user = data['user'] as Map<String, dynamic>;
      final reaction = data['reaction'] as Map<String, dynamic>;

      return MessageReactionEvent(
        messageId: data['messageId'] as String,
        chatId: data['conversationId'] as String,
        userId: user['id'] as String,
        reactionCode: reaction['code'] as String,
        action: reaction['action'] as String,
        timestamp: _parseDateTime(data['timestamp']),
      );
    } catch (e) {
      throw FormatException('Failed to map message:reaction event: $e');
    }
  }

  /// Map message:edit event to ChatMessage
  ///
  /// Expected data structure:
  /// ```json
  /// {
  ///   "conversationId": "chat-123",
  ///   "message": {
  ///     "id": "msg-456",
  ///     "content": "Hello (edited)",
  ///     "editedAt": "2024-01-28T10:05:00Z"
  ///   }
  /// }
  /// ```
  ChatMessage mapMessageEdit(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final conversationId = data['conversationId'] as String;

      return ChatMessage(
        id: messageData['id'] as String,
        chatId: conversationId,
        content: messageData['content'] as String? ?? '',
        contentType: _parseContentType(messageData['type'] as String?),
        sender: MessageSender(
          id: messageData['senderId'] as String,
          name: messageData['senderName'] as String? ?? 'Unknown',
          avatar: messageData['senderAvatar'] as String?,
        ),
        createdAt: _parseDateTime(messageData['createdAt']),
        updatedAt: _parseDateTime(messageData['updatedAt'] ?? messageData['editedAt']),
        editedAt: _parseDateTime(messageData['editedAt']),
        readBy: _parseStringList(messageData['readBy']),
        deliveredTo: _parseStringList(messageData['deliveredTo']),
        attachments: _parseAttachments(messageData['attachments']),
        reactions: _parseReactions(messageData['reactions']),
      );
    } catch (e) {
      throw FormatException('Failed to map message:edit event: $e');
    }
  }

  /// Map message:delete event to MessageDeleteEvent
  ///
  /// Expected data structure:
  /// ```json
  /// {
  ///   "conversationId": "chat-123",
  ///   "messageId": "msg-456",
  ///   "timestamp": "2024-01-28T10:00:00Z"
  /// }
  /// ```
  MessageDeleteEvent mapMessageDelete(Map<String, dynamic> data) {
    try {
      return MessageDeleteEvent(
        messageId: data['messageId'] as String,
        chatId: data['conversationId'] as String,
        timestamp: _parseDateTime(data['timestamp']),
      );
    } catch (e) {
      throw FormatException('Failed to map message:delete event: $e');
    }
  }

  /// Map message:typing event to TypingIndicatorEvent
  ///
  /// Expected data structure:
  /// ```json
  /// {
  ///   "conversationId": "chat-123",
  ///   "user": {
  ///     "id": "user-789",
  ///     "name": "John Doe"
  ///   },
  ///   "isTyping": true,
  ///   "timestamp": "2024-01-28T10:00:00Z"
  /// }
  /// ```
  TypingIndicatorEvent mapTypingIndicator(Map<String, dynamic> data) {
    try {
      final user = data['user'] as Map<String, dynamic>;

      return TypingIndicatorEvent(
        chatId: data['conversationId'] as String,
        userId: user['id'] as String,
        userName: user['name'] as String? ?? 'Unknown',
        isTyping: data['isTyping'] as bool? ?? false,
        timestamp: _parseDateTime(data['timestamp']),
      );
    } catch (e) {
      throw FormatException('Failed to map message:typing event: $e');
    }
  }

  /// Parse content type from string
  ContentType _parseContentType(String? type) {
    if (type == null) return ContentType.text;

    switch (type.toLowerCase()) {
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

  /// Parse DateTime from string or timestamp
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.now();
  }

  /// Parse list of strings
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value.map((e) => e.toString()).toList();
  }

  /// Parse attachments
  List<MessageAttachment> _parseAttachments(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .map((item) {
          try {
            if (item is! Map<String, dynamic>) return null;
            return MessageAttachment(
              id: item['id'] as String,
              url: item['url'] as String,
              type: item['type'] as String,
              size: item['size'] as int? ?? 0,
              name: item['name'] as String? ?? '',
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MessageAttachment>()
        .toList();
  }

  /// Parse reactions
  List<MessageReaction> _parseReactions(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .map((item) {
          try {
            if (item is! Map<String, dynamic>) return null;
            return MessageReaction(
              code: item['code'] as String,
              userId: item['userId'] as String,
              createdAt: _parseDateTime(item['createdAt']),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MessageReaction>()
        .toList();
  }
}
