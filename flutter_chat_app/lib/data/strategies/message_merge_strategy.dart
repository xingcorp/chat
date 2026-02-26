import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Thuật toán merge tin nhắn local với server.
/// Pure function, không side effects, dễ test.
class MessageMergeStrategy {
  /// Merge local messages với server messages.
  ///
  /// Rules:
  /// 1. Deduplicate bằng message ID — server wins khi conflict
  /// 2. Loại bỏ tin nhắn có deletedAt từ server
  /// 3. Cập nhật tin nhắn đã edit (server version wins)
  /// 4. Thêm tin nhắn mới từ server vào đúng vị trí
  /// 5. Bảo toàn tin nhắn sending/pending (chưa có server ID)
  /// 6. Sort theo createdAt descending
  static List<ChatMessage> merge({
    required List<ChatMessage> localMessages,
    required List<ChatMessage> serverMessages,
  }) {
    if (localMessages.isEmpty) return List.from(serverMessages);
    if (serverMessages.isEmpty) return List.from(localMessages);

    final Map<String, ChatMessage> mergedMap = {};

    // 1. Add local messages first
    for (final msg in localMessages) {
      mergedMap[msg.id] = msg;
    }

    // 2. Override/add server messages (server wins)
    for (final msg in serverMessages) {
      if (msg.deletedAt != null) {
        // Server says deleted — remove from result
        mergedMap.remove(msg.id);
      } else {
        mergedMap[msg.id] = msg;
      }
    }

    // 3. Preserve sending/pending messages (local-only, no server confirmation)
    for (final msg in localMessages) {
      final isSendingOrPending = msg.localStatus == MessageStatus.sending ||
          msg.localStatus == MessageStatus.pending;
      if (!isSendingOrPending) continue;

      final isLocalOnly = msg.id.startsWith('draft_') || msg.clientId != null;
      if (!isLocalOnly) continue;

      // Check if server already confirmed this message (match by clientId)
      final serverConfirmed = msg.clientId != null &&
          serverMessages.any((s) => s.clientId == msg.clientId);

      if (!serverConfirmed) {
        mergedMap[msg.id] = msg; // Keep pending message
      }
    }

    // 4. Sort descending by createdAt
    final result = mergedMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }
}
