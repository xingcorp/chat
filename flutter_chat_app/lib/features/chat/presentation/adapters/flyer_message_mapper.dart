import 'package:flutter_chat_core/flutter_chat_core.dart' as flyer;
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Maps domain [ChatMessage] ↔ Flyer Chat [flyer.Message] sealed types.
///
/// This is the single bridge between our domain layer and the Flyer Chat UI
/// plugin. All field name differences are resolved here.
///
/// Domain ChatMessage fields   → Flyer Chat Message fields
/// ─────────────────────────────────────────────────────────
/// id                          → id
/// sender.id                   → authorId
/// content                     → text / (not used for media)
/// contentType                 → Message.text / .image / .video / ...
/// urls                        → source (first url for media)
/// fileName                    → name (for file messages)
/// reactions (List)            → reactions (Map<String, List<String>>)
/// readBy                      → seenAt (derived)
/// createdAt                   → createdAt
/// editedAt                    → editedAt
/// deletedAt                   → deletedAt
class FlyerMessageMapper {
  const FlyerMessageMapper();

  /// Convert domain [ChatMessage] → Flyer Chat [flyer.Message].
  flyer.Message toFlyer(ChatMessage msg) {
    final reactions = _mapReactions(msg.reactions);
    final metadata = _buildMetadata(msg);

    switch (msg.contentType) {
      case ContentType.image:
        return flyer.Message.image(
          id: msg.id,
          authorId: msg.sender.id,
          source: msg.urls.isNotEmpty ? msg.urls.first : '',
          text: msg.content.isNotEmpty ? msg.content : null,
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          editedAt: msg.editedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          seenAt: msg.readBy.isNotEmpty ? msg.updatedAt : null,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: metadata,
        );

      case ContentType.video:
        return flyer.Message.video(
          id: msg.id,
          authorId: msg.sender.id,
          source: msg.urls.isNotEmpty ? msg.urls.first : '',
          text: msg.content.isNotEmpty ? msg.content : null,
          name: msg.fileName,
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          editedAt: msg.editedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          seenAt: msg.readBy.isNotEmpty ? msg.updatedAt : null,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: metadata,
        );

      case ContentType.audio:
        return flyer.Message.audio(
          id: msg.id,
          authorId: msg.sender.id,
          source: msg.urls.isNotEmpty ? msg.urls.first : '',
          duration: Duration.zero, // Parsed from metadata if available
          text: msg.content.isNotEmpty ? msg.content : null,
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          editedAt: msg.editedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          seenAt: msg.readBy.isNotEmpty ? msg.updatedAt : null,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: metadata,
        );

      case ContentType.file:
        return flyer.Message.file(
          id: msg.id,
          authorId: msg.sender.id,
          source: msg.urls.isNotEmpty ? msg.urls.first : '',
          name: msg.fileName ?? 'file',
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          editedAt: msg.editedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          seenAt: msg.readBy.isNotEmpty ? msg.updatedAt : null,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: metadata,
        );

      case ContentType.event:
        return flyer.Message.system(
          id: msg.id,
          authorId: msg.sender.id,
          text: msg.content,
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: metadata,
        );

      case ContentType.location:
        // Location stored as custom message with metadata
        return flyer.Message.custom(
          id: msg.id,
          authorId: msg.sender.id,
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          editedAt: msg.editedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          seenAt: msg.readBy.isNotEmpty ? msg.updatedAt : null,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: {
            ...metadata,
            'subtype': 'location',
            'text': msg.content,
            if (msg.urls.isNotEmpty) 'url': msg.urls.first,
          },
        );

      case ContentType.text:
      case ContentType.link:
      default:
        return flyer.Message.text(
          id: msg.id,
          authorId: msg.sender.id,
          text: msg.content,
          createdAt: msg.createdAt,
          updatedAt: msg.updatedAt,
          editedAt: msg.editedAt,
          deletedAt: msg.deletedAt,
          sentAt: msg.createdAt,
          seenAt: msg.readBy.isNotEmpty ? msg.updatedAt : null,
          reactions: reactions,
          status: _mapStatus(msg.status),
          metadata: metadata,
        );
    }
  }

  /// Batch convert.
  List<flyer.Message> toFlyerList(List<ChatMessage> messages) {
    return messages.map(toFlyer).toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Domain [MessageStatus] → Flyer [flyer.MessageStatus].
  flyer.MessageStatus? _mapStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
      case MessageStatus.sending:
        return flyer.MessageStatus.sending;
      case MessageStatus.sent:
        return flyer.MessageStatus.sent;
      case MessageStatus.delivered:
        return flyer.MessageStatus.delivered;
      case MessageStatus.read:
        return flyer.MessageStatus.seen;
      case MessageStatus.failed:
        return flyer.MessageStatus.error;
    }
  }

  /// Domain reactions `List<MessageReaction>` → Flyer `Map<String, List<UserID>>`.
  ///
  /// Domain stores each reaction as {code, userId, createdAt}.
  /// Flyer expects grouped: {"👍": ["user1", "user2"], "❤️": ["user3"]}.
  Map<String, List<String>>? _mapReactions(List<MessageReaction> reactions) {
    if (reactions.isEmpty) return null;

    final grouped = <String, List<String>>{};
    for (final r in reactions) {
      grouped.putIfAbsent(r.code, () => []).add(r.userId);
    }
    return grouped;
  }

  /// Build metadata map carrying domain-specific data through Flyer.
  ///
  /// This allows custom builders to access original domain fields
  /// that Flyer's sealed Message types don't natively support
  /// (e.g. mentionTo, forwardedFromMessageId, replyToMessageId, urls).
  Map<String, dynamic> _buildMetadata(ChatMessage msg) {
    return {
      'chatId': msg.chatId,
      'senderName': msg.sender.name,
      'senderAvatar': msg.sender.avatar,
      if (msg.forwardedFromMessageId != null)
        'forwardedFromMessageId': msg.forwardedFromMessageId,
      if (msg.mentionTo.isNotEmpty)
        'mentionTo': msg.mentionTo
            .map((m) => {'id': m.id, 'name': m.name})
            .toList(),
      if (msg.urls.length > 1)
        'additionalUrls': msg.urls.sublist(1),
      if (msg.fileName != null) 'fileName': msg.fileName,
    };
  }
}
