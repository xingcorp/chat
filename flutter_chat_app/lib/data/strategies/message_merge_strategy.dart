import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Thuật toán merge tin nhắn local với server.
/// Pure function, không side effects, dễ test.
class MessageMergeStrategy {
  /// Merge local messages với server messages.
  ///
  /// Rules:
  /// 1. Server là source of truth — nếu server không có, message đã bị xóa
  /// 2. Cập nhật tin nhắn đã edit (server version wins)
  /// 3. Thêm tin nhắn mới từ server
  /// 4. Bảo toàn tin nhắn sending/pending (chưa có server ID)
  /// 5. Sort theo createdAt descending
  static List<ChatMessage> merge({
    required List<ChatMessage> localMessages,
    required List<ChatMessage> serverMessages,
  }) {
    // Server is empty — all local messages were deleted or none exist
    if (serverMessages.isEmpty) {
      // Only keep pending/sending messages
      return localMessages
          .where((msg) =>
              msg.localStatus == MessageStatus.sending ||
              msg.localStatus == MessageStatus.pending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Build server ID set for quick lookup
    final serverIds = serverMessages.map((msg) => msg.id).toSet();

    final Map<String, ChatMessage> mergedMap = {};

    // 1. Add all server messages (server is source of truth)
    for (final msg in serverMessages) {
      mergedMap[msg.id] = msg;
    }

    // 2. Preserve sending/pending messages that aren't confirmed by server yet
    for (final msg in localMessages) {
      final isSendingOrPending = msg.localStatus == MessageStatus.sending ||
          msg.localStatus == MessageStatus.pending;
      if (!isSendingOrPending) continue;

      // If server confirmed this message, use server version
      if (serverIds.contains(msg.id)) continue;

      // Keep local-only pending message
      mergedMap[msg.id] = msg;
    }

    // 3. Sort descending by createdAt
    final result = mergedMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }
}
