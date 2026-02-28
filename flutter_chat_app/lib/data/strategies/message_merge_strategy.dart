import 'package:flutter_chat_app/core/storage/tombstone_store.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Merge mode xac dinh cach xu ly local messages khong co trong server response.
enum MergeMode {
  /// Delta sync: server chi tra ve tin nhan moi/thay doi.
  /// Local messages KHONG co trong server response duoc GIU NGUYEN.
  delta,

  /// Full fetch: server tra ve toan bo trang dau tien (source of truth).
  /// Local messages KHONG co trong server response bi XOA (tru pending/sending).
  fullPage,
}

/// Thuat toan merge tin nhan local voi server.
/// Pure function, khong side effects, de test.
class MessageMergeStrategy {
  /// Merge local messages voi server messages va tombstones.
  ///
  /// [mergeMode] quyet dinh cach xu ly local messages:
  /// - [MergeMode.delta]: Union local + server, server wins khi trung ID.
  ///   Dung khi server chi tra ve tin nhan moi (delta sync).
  /// - [MergeMode.fullPage]: Server la source of truth, chi giu pending/sending local.
  ///   Dung khi server tra ve toan bo trang (initial load, gap recovery).
  ///
  /// Rules chung:
  /// 1. Server version wins khi trung ID (edit, reaction update, v.v.)
  /// 2. Bao toan tin nhan sending/pending (chua co server ID)
  /// 3. Merge tombstones (tin nhan da xoa) de hien thi placeholder
  /// 4. Sort theo createdAt descending
  static List<ChatMessage> merge({
    required List<ChatMessage> localMessages,
    required List<ChatMessage> serverMessages,
    List<MessageTombstone>? tombstones,
    MergeMode mergeMode = MergeMode.delta,
  }) {
    final Map<String, ChatMessage> mergedMap = {};

    // Step 1: Add local messages lam base
    // Trong delta mode: tat ca local messages deu duoc giu
    // Trong fullPage mode: chi giu pending/sending
    for (final msg in localMessages) {
      if (mergeMode == MergeMode.delta) {
        // Delta: giu tat ca local messages
        mergedMap[msg.id] = msg;
      } else {
        // FullPage: chi giu pending/sending
        final isSendingOrPending =
            msg.localStatus == MessageStatus.sending ||
            msg.localStatus == MessageStatus.pending;
        if (isSendingOrPending) {
          mergedMap[msg.id] = msg;
        }
      }
    }

    // Step 2: Apply server messages (server wins khi trung ID)
    for (final msg in serverMessages) {
      mergedMap[msg.id] = msg;
    }

    // Step 3: Apply tombstones cho messages KHONG co trong server response
    if (tombstones != null && tombstones.isNotEmpty) {
      final serverIds = serverMessages.map((msg) => msg.id).toSet();
      for (final tombstone in tombstones) {
        if (!serverIds.contains(tombstone.messageId)) {
          mergedMap[tombstone.messageId] = _createDeletedMessage(tombstone);
        }
      }
    }

    // Step 4: Sort descending by createdAt
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
