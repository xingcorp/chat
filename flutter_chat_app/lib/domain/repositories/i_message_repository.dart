import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// **ENTERPRISE MESSAGE REPOSITORY INTERFACE**
///
/// Unified interface for message operations with comprehensive error handling
/// and performance optimization for real-time messaging (<100ms delivery).
///
/// **Error Handling**: All methods return Either<Failure, T> for consistent error management
/// **Performance**: Optimized for WhatsApp/Telegram-level real-time messaging
/// **Architecture**: Clean Architecture with SOLID principles
abstract class IMessageRepository {
  /// **Lấy tin nhắn theo ID**
  ///
  /// **Strategy**: executeOfflineFirst (cached data priority)
  /// **Performance**: <50ms for cached messages
  /// **Returns**: Either<Failure, ChatMessage> - null-safe with proper error handling
  Future<Either<Failure, ChatMessage?>> getMessageById(String messageId);

  /// **Lấy danh sách tin nhắn gần đây của một chat**
  ///
  /// **Strategy**: executeOfflineFirst (immediate UI response)
  /// **Performance**: <100ms for recent messages, background sync
  /// **Use Case**: Chat screen initial load, pull-to-refresh
  Future<Either<Failure, List<ChatMessage>>> getRecentMessages(String chatId, int limit);

  /// **Lấy danh sách tin nhắn của một chat với phân trang**
  ///
  /// **Strategy**: executeOfflineFirst with background sync
  /// **Performance**: <150ms for paginated loading
  /// **Use Case**: Infinite scroll, message history browsing
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId, {int limit = 20, String? cursor});

  /// **Đánh dấu tin nhắn đã đọc**
  ///
  /// **Strategy**: executeOnlineFirst (real-time status update)
  /// **Performance**: <100ms for read receipts
  /// **Critical**: Real-time read status for messaging UX
  Future<Either<Failure, void>> markAsRead(String messageId);

  /// **Đánh dấu tất cả tin nhắn trong chat đã đọc**
  ///
  /// **Strategy**: executeOnlineFirst (batch read operation)
  /// **Performance**: <200ms for bulk operations
  /// **Use Case**: Mark all as read, chat opened event
  Future<Either<Failure, void>> markChatAsRead(String chatId);

  /// **Xóa tin nhắn**
  ///
  /// **Strategy**: executeOnlineFirst (immediate server sync)
  /// **Performance**: <150ms for delete operations
  /// **Security**: Proper authorization and cascade deletion
  /// **chatId**: Required for efficient O(1) local cache deletion
  Future<Either<Failure, bool>> deleteMessage(String chatId, String messageId);

  /// **Cập nhật nội dung tin nhắn**
  ///
  /// **Strategy**: executeOnlineFirst (real-time edit sync)
  /// **Performance**: <100ms for message edits
  /// **Use Case**: Message editing, typo corrections
  Future<Either<Failure, bool>> updateMessage(String messageId, String newContent);

  /// **Gửi tin nhắn mới - CRITICAL REAL-TIME OPERATION**
  ///
  /// **Strategy**: executeOnlineFirst with offline queuing
  /// **Performance**: <100ms delivery target (WhatsApp standard)
  /// **Reliability**: Offline queue, retry mechanism, status tracking
  /// **Critical**: Core messaging functionality
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String contentType,
    List<String> attachmentIds = const [],
    String? replyMessageId,
    String? fileName,
    String? forwardedFromMessageId,
    /// For pending direct chats (no server conversation yet).
    /// When provided, the backend auto-creates the conversation on first message.
    String? receiverId,
  });

  /// **Kiểm tra xung đột tin nhắn**
  ///
  /// **Strategy**: executeRemoteOnly (server authority)
  /// **Performance**: <200ms for conflict resolution
  /// **Use Case**: Sync conflicts, duplicate detection
  Future<Either<Failure, bool>> checkMessageConflict(String localId, String serverId);

  /// **Đồng bộ tin nhắn giữa local và server**
  ///
  /// **Strategy**: executeSyncStrategy (background operation)
  /// **Performance**: Background process, non-blocking UI
  /// **Use Case**: App startup, connectivity restored, periodic sync
  Future<Either<Failure, void>> syncMessages(String chatId, {int limit = 50});

  /// **Search messages**
  ///
  /// Uses backend chatSearch query with filters.
  Future<Either<Failure, List<ChatMessage>>> searchMessages({
    required String keyword,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<String>? messageTypes,
    int? from,
    int? to,
    int page = 0,
    int size = 100,
  });

  /// **Update reaction**
  ///
  /// Uses backend chatMessageUpdateReaction mutation.
  Future<Either<Failure, bool>> updateReaction({
    required String messageId,
    required String code,
    required String act,
  });

  // === Phase 2 + 3: Two-Phase Render & Delta Sync ===

  /// **Lấy tin nhắn từ local storage only (cho two-phase render phase 1)**
  ///
  /// Returns cached/local messages without hitting the server.
  /// Returns empty list (not failure) if no local data exists.
  Future<Either<Failure, List<ChatMessage>>> getMessagesFromLocal(
    String chatId, {
    int limit = 20,
  });

  /// **Lấy tin nhắn delta từ timestamp**
  ///
  /// Sử dụng tham số `from` của backend API.
  /// Returns tin nhắn có createdAt >= fromTimestamp.
  /// Merges with local data and enforces cache limit.
  Future<Either<Failure, List<ChatMessage>>> getMessagesDelta(
    String chatId, {
    required int fromTimestamp,
    int limit = 20,
  });

  /// **Retry gửi lại pending messages cho 1 chat cụ thể**
  ///
  /// **Strategy**: Tìm messages có status=pending trong chat, gửi lại lên server
  /// **Anti-duplicate**: Lock status pending→sending trước khi gửi
  /// **Use Case**: Reconnection detected khi user đang ở trong chat
  /// **Returns**: Số messages đã retry thành công
  Future<Either<Failure, int>> retryPendingMessages(String chatId);

  /// **Retry gửi lại TẤT CẢ pending messages cross-chat**
  ///
  /// **Strategy**: Scan all chats, gửi lại pending messages theo thứ tự FIFO
  /// **Use Case**: Connectivity restored (global sync)
  /// **Returns**: Số messages đã retry thành công
  Future<Either<Failure, int>> retryAllPendingMessages();

  /// **Persist a socket-received message to local storage (Isar)**
  ///
  /// Used by real-time handler to ensure all incoming messages are cached
  /// immediately, following the Signal/Telegram offline-first pattern.
  /// This prevents stale/incomplete data when the UI re-reads from Isar.
  ///
  /// **Parameters**: [message] - The domain ChatMessage entity from socket
  /// **Returns**: Right(void) on success, Left(Failure) on error
  Future<Either<Failure, void>> persistSocketMessage(ChatMessage message);
}
