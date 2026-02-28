import 'package:flutter_chat_app/core/storage/tombstone_store.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Thuật toán merge tin nhắn local với server.
/// Pure function, không side effects, dễ test.
class MessageMergeStrategy {
  /// Merge local messages với server messages và tombstones.
  ///
  /// Rules:
  /// 1. Server là source of truth — nếu server không có, message đã bị xóa
  /// 2. Cập nhật tin nhắn đã edit (server version wins)
  /// 3. Thêm tin nhắn mới từ server
  /// 4. Bảo toàn tin nhắn sending/pending (chưa có server ID)
  /// 5. Merge tombstones (tin nhắn đã xóa) để hiển thị placeholder
  /// 6. Sort theo createdAt descending
  static List<ChatMessage> merge({
    required List<ChatMessage> localMessages,
    required List<ChatMessage> serverMessages,
    List<MessageTombstone>? tombstones,
  }) {
    // Server is empty — all local messages were deleted or none exist
    if (serverMessages.isEmpty) {
      // Only keep pending/sending messages + tombstones
      final result = <ChatMessage>[];
      
      // Add pending/sending messages
      result.addAll(localMessages.where((msg) =>
          msg.localStatus == MessageStatus.sending ||
          msg.localStatus == MessageStatus.pending));
      
      // Add tombstones as deleted messages
      if (tombstones != null && tombstones.isNotEmpty) {
        result.addAll(tombstones.map((t) => _createDeletedMessage(t)));
      }
      
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    }

    // Build server ID set for quick lookup
    final serverIds = serverMessages.map((msg) => msg.id).toSet();

    final Map<String, ChatMessage> mergedMap = {};

    // 1. Add all server messages (server is source of truth)
    for (final msg in serverMessages) {
      mergedMap[msg.id] = msg;
    }

    // 2. Add tombstones (messages that were deleted locally)
    // Tombstones are only added if the message is NOT in server response
    if (tombstones != null && tombstones.isNotEmpty) {
      for (final tombstone in tombstones) {
        if (!serverIds.contains(tombstone.messageId)) {
          mergedMap[tombstone.messageId] = _createDeletedMessage(tombstone);
        }
      }
    }

    // 3. Preserve sending/pending messages that aren't confirmed by server yet
    for (final msg in localMessages) {
      final isSendingOrPending = msg.localStatus == MessageStatus.sending ||
          msg.localStatus == MessageStatus.pending;
      if (!isSendingOrPending) continue;

      // If server confirmed this message, use server version
      if (serverIds.contains(msg.id)) continue;

      // Keep local-only pending message
      mergedMap[msg.id] = msg;
    }

    // 4. Sort descending by createdAt
    final result = mergedMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  /// Create a deleted message placeholder from a tombstone
  static ChatMessage _createDeletedMessage(MessageTombstone tombstone) {
    return ChatMessage(
      id: tombstone.messageId,
      chatId: tombstone.chatId,
      content: '', // Empty content for deleted message
      contentType: ContentType.text,
      sender: MessageSender(
        id: tombstone.senderId ?? 'unknown',
        name: tombstone.senderName ?? 'Unknown',
      ),
      createdAt: tombstone.messageCreatedAt,
      updatedAt: tombstone.deletedAt,
      deletedAt: tombstone.deletedAt, // Mark as deleted
    );
  }
}
