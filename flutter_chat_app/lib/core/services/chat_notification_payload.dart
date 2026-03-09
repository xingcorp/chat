import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Normalized notification payload for chat notifications across platforms.
class ChatNotificationPayload {
  const ChatNotificationPayload({
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.title,
    required this.body,
    required this.createdAtIso8601,
  });

  final String conversationId;
  final String messageId;
  final String senderId;
  final String senderName;
  final String title;
  final String body;
  final String createdAtIso8601;

  int get notificationId {
    final id = messageId.hashCode & 0x7fffffff;
    return id == 0 ? 1 : id;
  }

  factory ChatNotificationPayload.fromChatMessage(ChatMessage message) {
    final trimmedContent = message.content.trim();
    final fallbackBody = trimmedContent.isNotEmpty
        ? trimmedContent
        : getContentTypeName(message.contentType);

    return ChatNotificationPayload(
      conversationId: message.chatId,
      messageId: message.id,
      senderId: message.sender.id,
      senderName: message.sender.name,
      title: message.sender.name,
      body: fallbackBody,
      createdAtIso8601: message.createdAt.toIso8601String(),
    );
  }

  factory ChatNotificationPayload.fromJson(Map<String, dynamic> json) {
    return ChatNotificationPayload(
      conversationId: json['conversationId']?.toString() ?? '',
      messageId: json['messageId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAtIso8601: json['createdAtIso8601']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'conversationId': conversationId,
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'title': title,
      'body': body,
      'createdAtIso8601': createdAtIso8601,
    };
  }

  Map<String, dynamic> toNotificationData() {
    return <String, dynamic>{
      'metadata': <String, dynamic>{
        'conversationId': conversationId,
        'messageId': messageId,
        'senderId': senderId,
      },
      'senderName': senderName,
      'title': title,
      'body': body,
      'createdAtIso8601': createdAtIso8601,
    };
  }
}
