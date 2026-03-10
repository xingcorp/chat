import 'package:flutter_chat_app/core/services/notification_localizer.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
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
    this.conversationType = ChatType.direct,
    this.conversationName = '',
    this.senderAvatarUrl,
    this.isMention = false,
    this.contentType = ContentType.text,
    this.macosSubtitle,
    this.avatarFilePath,
  });

  final String conversationId;
  final String messageId;
  final String senderId;
  final String senderName;
  final String title;
  final String body;
  final String createdAtIso8601;

  /// Whether this is a direct or group conversation.
  final ChatType conversationType;

  /// Display name of the conversation (group name or sender name for direct).
  final String conversationName;

  /// Sender avatar URL (for downloading avatar for notification icon).
  final String? senderAvatarUrl;

  /// Whether the current user was @mentioned in this message.
  final bool isMention;

  /// Content type of the original message.
  final ContentType contentType;

  /// macOS-specific subtitle field.
  ///
  /// - Group chat: sender name (title already shows group name).
  /// - Direct chat: `null` (title already shows sender name).
  final String? macosSubtitle;

  /// Local file path of the downloaded avatar image.
  ///
  /// Used by:
  /// - Windows: `WindowsImage` with `appLogoOverride` + `circle` crop
  /// - macOS: `DarwinNotificationAttachment`
  ///
  /// `null` if download failed/timed out — notification falls back to app icon.
  final String? avatarFilePath;

  int get notificationId {
    final id = messageId.hashCode & 0x7fffffff;
    return id == 0 ? 1 : id;
  }

  /// Builds a rich notification payload using [Chat] metadata + [ChatMessage].
  ///
  /// Title/body/subtitle logic:
  /// - **Direct**: title=senderName, body=content or contentTypeLabel
  /// - **Group**: title=groupName, subtitle=senderName,
  ///   body="SenderName: content"
  /// - **Mention**: body prefixed with "@Bạn" / "@You"
  /// - **Event**: body=event description, no sender prefix
  factory ChatNotificationPayload.fromMessageWithChat({
    required ChatMessage message,
    required Chat chat,
    required bool isMention,
  }) {
    final isGroup = chat.type == ChatType.group ||
        chat.type == ChatType.channel;
    final isEvent = message.contentType == ContentType.event;
    final senderName = message.sender.name;

    // ── Resolve content body ──
    final String? contentTypeLabel = NotificationLocalizer.getContentTypeLabel(
      message.contentType,
      fileName: message.fileName ?? _extractFileNameFromUrls(message.urls),
    );
    // For text and event types, use actual message content; otherwise label.
    final String contentBody = contentTypeLabel ??
        (message.content.trim().isNotEmpty
            ? message.content.trim()
            : getContentTypeName(message.contentType));

    // ── Build title ──
    final String title = isGroup
        ? (chat.name ?? senderName)
        : senderName;

    // ── Build body ──
    final String body;
    if (isEvent) {
      // System events: show event text, no sender prefix.
      body = message.content.trim().isNotEmpty
          ? message.content.trim()
          : getContentTypeName(message.contentType);
    } else if (isGroup && isMention) {
      body = NotificationLocalizer.formatGroupMentionBody(
        senderName: senderName,
        content: contentBody,
      );
    } else if (!isGroup && isMention) {
      body = NotificationLocalizer.formatMentionBody(content: contentBody);
    } else if (isGroup) {
      body = NotificationLocalizer.formatGroupBody(
        senderName: senderName,
        content: contentBody,
      );
    } else {
      // Direct, no mention.
      body = contentBody;
    }

    // ── macOS subtitle ──
    // Group → sender name (so macOS shows: Title=GroupName, Subtitle=Sender)
    // Direct → null (title already IS the sender)
    final String? macosSubtitle =
        isGroup && !isEvent ? senderName : null;

    return ChatNotificationPayload(
      conversationId: message.chatId,
      messageId: message.id,
      senderId: message.sender.id,
      senderName: senderName,
      title: title,
      body: body,
      createdAtIso8601: message.createdAt.toIso8601String(),
      conversationType: chat.type,
      conversationName: chat.name ?? senderName,
      senderAvatarUrl: message.sender.avatar,
      isMention: isMention,
      contentType: message.contentType,
      macosSubtitle: macosSubtitle,
    );
  }

  /// Legacy factory — used as fallback when [Chat] metadata is unavailable.
  factory ChatNotificationPayload.fromChatMessage(ChatMessage message) {
    final trimmedContent = message.content.trim();
    final String? contentTypeLabel = NotificationLocalizer.getContentTypeLabel(
      message.contentType,
      fileName: message.fileName ?? _extractFileNameFromUrls(message.urls),
    );
    final fallbackBody = contentTypeLabel ??
        (trimmedContent.isNotEmpty
            ? trimmedContent
            : getContentTypeName(message.contentType));

    return ChatNotificationPayload(
      conversationId: message.chatId,
      messageId: message.id,
      senderId: message.sender.id,
      senderName: message.sender.name,
      title: message.sender.name,
      body: fallbackBody,
      createdAtIso8601: message.createdAt.toIso8601String(),
      senderAvatarUrl: message.sender.avatar,
      contentType: message.contentType,
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
      conversationName: json['conversationName']?.toString() ?? '',
      isMention: json['isMention'] == true,
      macosSubtitle: json['macosSubtitle']?.toString(),
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
      'conversationName': conversationName,
      'isMention': isMention,
      if (macosSubtitle != null) 'macosSubtitle': macosSubtitle,
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

  /// Tries to extract a human-readable file name from URL list.
  static String? _extractFileNameFromUrls(List<String> urls) {
    if (urls.isEmpty) return null;
    final uri = Uri.tryParse(urls.first);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.last;
  }
}
